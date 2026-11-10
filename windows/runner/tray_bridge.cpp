#include "tray_bridge.h"

#include <flutter/standard_method_codec.h>
#include <shellapi.h>

#include "resource.h"

namespace {

constexpr UINT kTrayIconId = 1;

std::wstring Utf8ToWide(const std::string& s) {
  if (s.empty()) return std::wstring();
  const int len = ::MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), nullptr, 0);
  std::wstring out(len, L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), out.data(), len);
  return out;
}

}  // namespace

TrayBridge::TrayBridge(HWND hwnd, flutter::BinaryMessenger* messenger)
    : hwnd_(hwnd), popup_(std::make_unique<TrayPopup>([this](const char* action) { Send(action); })) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "prism/tray", &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() == "show") {
      std::wstring tooltip = L"Prism";
      TrayPopupState state;
      if (const auto* args = std::get_if<flutter::EncodableMap>(call.arguments())) {
        auto text = [args](const char* key) -> std::wstring {
          auto it = args->find(flutter::EncodableValue(key));
          if (it == args->end()) return std::wstring();
          const auto* s = std::get_if<std::string>(&it->second);
          return s ? Utf8ToWide(*s) : std::wstring();
        };
        if (auto t = text("tooltip"); !t.empty()) tooltip = t;
        state.title = text("title");
        state.artist = text("artist");
        state.art_path = text("artPath");
        state.has_track = !state.title.empty();
        auto l = args->find(flutter::EncodableValue("labels"));
        if (l != args->end()) {
          if (const auto* list = std::get_if<flutter::EncodableList>(&l->second)) {
            std::vector<std::wstring> labels;
            for (const auto& item : *list) {
              if (const auto* s = std::get_if<std::string>(&item)) labels.push_back(Utf8ToWide(*s));
            }
            // open, pause, play, previous, next, quit
            if (labels.size() == 6) {
              state.show_label = labels[0];
              state.quit_label = labels[5];
            }
          }
        }
        auto p = args->find(flutter::EncodableValue("playing"));
        if (p != args->end()) {
          if (const auto* b = std::get_if<bool>(&p->second)) state.playing = *b;
        }
      }
      popup_->Update(state);
      Show(tooltip);
      result->Success();
    } else if (call.method_name() == "hide") {
      Hide();
      result->Success();
    } else {
      result->NotImplemented();
    }
  });
}

TrayBridge::~TrayBridge() {
  Hide();
  channel_->SetMethodCallHandler(nullptr);
}

void TrayBridge::Show(const std::wstring& tooltip) {
  NOTIFYICONDATAW nid{};
  nid.cbSize = sizeof(nid);
  nid.hWnd = hwnd_;
  nid.uID = kTrayIconId;
  nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  nid.uCallbackMessage = kTrayCallbackMessage;
  // The tray size at this window's scaling (16 px at 100 %, 24 at 150 %...).
  // GetSystemMetrics alone says 16 at any scaling, and Windows then
  // stretched the 16 px picture: blurry.
  const UINT dpi = ::GetDpiForWindow(hwnd_);
  const int size = ::GetSystemMetricsForDpi(SM_CXSMICON, dpi ? dpi : 96);
  nid.hIcon = static_cast<HICON>(::LoadImageW(::GetModuleHandleW(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON),
                                              IMAGE_ICON, size, size, LR_DEFAULTCOLOR));
  // Tooltip is limited to 128 chars including the terminator.
  wcsncpy_s(nid.szTip, tooltip.c_str(), _TRUNCATE);
  ::Shell_NotifyIconW(visible_ ? NIM_MODIFY : NIM_ADD, &nid);
  visible_ = true;
  if (nid.hIcon) ::DestroyIcon(nid.hIcon);
}

void TrayBridge::Hide() {
  popup_->Close();
  if (!visible_) return;
  NOTIFYICONDATAW nid{};
  nid.cbSize = sizeof(nid);
  nid.hWnd = hwnd_;
  nid.uID = kTrayIconId;
  ::Shell_NotifyIconW(NIM_DELETE, &nid);
  visible_ = false;
}

void TrayBridge::HandleTrayMessage(LPARAM lparam) {
  switch (LOWORD(lparam)) {
    case WM_LBUTTONUP:
    case WM_LBUTTONDBLCLK:
      Send("open");
      break;
    case WM_RBUTTONUP:
    case WM_CONTEXTMENU:
      ShowMenu();
      break;
    default:
      break;
  }
}

void TrayBridge::ShowMenu() {
  POINT pt;
  ::GetCursorPos(&pt);
  popup_->ShowAt(pt);
}

void TrayBridge::Send(const char* action) {
  channel_->InvokeMethod("action", std::make_unique<flutter::EncodableValue>(std::string(action)));
}
