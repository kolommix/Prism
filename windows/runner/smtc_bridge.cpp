#include "smtc_bridge.h"

#include <flutter/standard_method_codec.h>
#include <systemmediatransportcontrolsinterop.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Media.h>
#include <winrt/Windows.Storage.Streams.h>
#include <winrt/Windows.Storage.h>

#include <optional>
#include <string>

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using winrt::Windows::Media::MediaPlaybackStatus;
using winrt::Windows::Media::MediaPlaybackType;
using winrt::Windows::Media::SystemMediaTransportControls;
using winrt::Windows::Media::SystemMediaTransportControlsButton;
using winrt::Windows::Media::SystemMediaTransportControlsTimelineProperties;

std::optional<std::string> GetString(const EncodableMap& map, const char* key) {
  auto it = map.find(EncodableValue(key));
  if (it == map.end()) return std::nullopt;
  if (auto s = std::get_if<std::string>(&it->second)) return *s;
  return std::nullopt;
}

bool GetBool(const EncodableMap& map, const char* key, bool fallback) {
  auto it = map.find(EncodableValue(key));
  if (it == map.end()) return fallback;
  if (auto b = std::get_if<bool>(&it->second)) return *b;
  return fallback;
}

int64_t GetInt(const EncodableMap& map, const char* key) {
  auto it = map.find(EncodableValue(key));
  if (it == map.end()) return 0;
  if (auto i = std::get_if<int32_t>(&it->second)) return *i;
  if (auto l = std::get_if<int64_t>(&it->second)) return *l;
  return 0;
}

winrt::hstring ToH(const std::optional<std::string>& s) {
  return s ? winrt::to_hstring(*s) : winrt::hstring();
}

// TimeSpan is in 100ns ticks.
winrt::Windows::Foundation::TimeSpan Ms(int64_t ms) {
  return winrt::Windows::Foundation::TimeSpan{ms * 10000};
}

}  // namespace

struct SmtcBridge::Impl {
  HWND hwnd = nullptr;
  SystemMediaTransportControls smtc{nullptr};
  winrt::event_token button_token{};
  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel;

  void HandleCall(const flutter::MethodCall<EncodableValue>& call,
                  std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    const auto* args = std::get_if<EncodableMap>(call.arguments());
    if (!smtc || !args) {
      result->Success();
      return;
    }
    try {
      if (call.method_name() == "update") {
        Update(*args);
      } else if (call.method_name() == "timeline") {
        Timeline(*args);
      } else {
        result->NotImplemented();
        return;
      }
      result->Success();
    } catch (const winrt::hresult_error& e) {
      result->Error("smtc", winrt::to_string(e.message()));
    }
  }

  void Update(const EncodableMap& args) {
    const bool enabled = GetBool(args, "enabled", true);
    smtc.IsEnabled(enabled);
    smtc.IsPlayEnabled(enabled);
    smtc.IsPauseEnabled(enabled);
    smtc.IsNextEnabled(enabled);
    smtc.IsPreviousEnabled(enabled);
    smtc.IsStopEnabled(enabled);
    smtc.PlaybackStatus(GetBool(args, "playing", false) ? MediaPlaybackStatus::Playing
                                                        : MediaPlaybackStatus::Paused);

    auto updater = smtc.DisplayUpdater();
    updater.Type(MediaPlaybackType::Music);
    auto music = updater.MusicProperties();
    music.Title(ToH(GetString(args, "title")));
    music.Artist(ToH(GetString(args, "artist")));
    music.AlbumTitle(ToH(GetString(args, "album")));

    auto art = GetString(args, "artPath");
    if (!art || art->empty()) {
      updater.Thumbnail(nullptr);
      updater.Update();
      return;
    }
    // Streamed songs (YouTube, SoundCloud) have an https cover.
    if (art->rfind("http", 0) == 0) {
      try {
        updater.Thumbnail(winrt::Windows::Storage::Streams::RandomAccessStreamReference::CreateFromUri(
            winrt::Windows::Foundation::Uri(winrt::to_hstring(*art))));
      } catch (...) {
        updater.Thumbnail(nullptr);
      }
      updater.Update();
      return;
    }
    // Loading the file is async; SMTC objects are agile so finishing the
    // update on the completion thread is fine. Never block the UI thread.
    updater.Update();
    auto op = winrt::Windows::Storage::StorageFile::GetFileFromPathAsync(winrt::to_hstring(*art));
    op.Completed([updater](auto const& async, winrt::Windows::Foundation::AsyncStatus status) {
      if (status != winrt::Windows::Foundation::AsyncStatus::Completed) return;
      try {
        updater.Thumbnail(
            winrt::Windows::Storage::Streams::RandomAccessStreamReference::CreateFromFile(async.GetResults()));
        updater.Update();
      } catch (...) {
      }
    });
  }

  void Timeline(const EncodableMap& args) {
    SystemMediaTransportControlsTimelineProperties tl;
    const int64_t duration = GetInt(args, "durationMs");
    tl.StartTime(Ms(0));
    tl.MinSeekTime(Ms(0));
    tl.Position(Ms(GetInt(args, "positionMs")));
    tl.MaxSeekTime(Ms(duration));
    tl.EndTime(Ms(duration));
    smtc.UpdateTimelineProperties(tl);
  }
};

SmtcBridge::SmtcBridge(HWND hwnd, flutter::BinaryMessenger* messenger)
    : impl_(std::make_unique<Impl>()) {
  impl_->hwnd = hwnd;
  impl_->channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, "prism/smtc", &flutter::StandardMethodCodec::GetInstance());

  try {
    auto interop = winrt::get_activation_factory<SystemMediaTransportControls,
                                                 ISystemMediaTransportControlsInterop>();
    SystemMediaTransportControls smtc{nullptr};
    winrt::check_hresult(interop->GetForWindow(
        hwnd, winrt::guid_of<SystemMediaTransportControls>(), winrt::put_abi(smtc)));
    impl_->smtc = smtc;
    impl_->smtc.IsEnabled(false);
    impl_->button_token = impl_->smtc.ButtonPressed(
        [hwnd](auto const&, winrt::Windows::Media::SystemMediaTransportControlsButtonPressedEventArgs const& e) {
          // Raised on a background thread: hop to the platform thread.
          ::PostMessage(hwnd, kSmtcButtonMessage, static_cast<WPARAM>(e.Button()), 0);
        });
  } catch (...) {
    // SMTC unavailable (very old Windows / Server core): media keys just won't work.
    impl_->smtc = nullptr;
  }

  Impl* impl = impl_.get();
  impl_->channel->SetMethodCallHandler(
      [impl](const auto& call, auto result) { impl->HandleCall(call, std::move(result)); });
}

SmtcBridge::~SmtcBridge() {
  if (impl_->smtc) {
    try {
      impl_->smtc.ButtonPressed(impl_->button_token);
      impl_->smtc.IsEnabled(false);
    } catch (...) {
    }
  }
  impl_->channel->SetMethodCallHandler(nullptr);
}

void SmtcBridge::DispatchButton(WPARAM button) {
  const char* name = nullptr;
  switch (static_cast<SystemMediaTransportControlsButton>(button)) {
    case SystemMediaTransportControlsButton::Play:
      name = "play";
      break;
    case SystemMediaTransportControlsButton::Pause:
      name = "pause";
      break;
    case SystemMediaTransportControlsButton::Next:
      name = "next";
      break;
    case SystemMediaTransportControlsButton::Previous:
      name = "previous";
      break;
    case SystemMediaTransportControlsButton::Stop:
      name = "stop";
      break;
    default:
      return;
  }
  impl_->channel->InvokeMethod("button", std::make_unique<EncodableValue>(std::string(name)));
}
