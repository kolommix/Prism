#include "ocr_bridge.h"

#include <flutter/standard_method_codec.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Globalization.h>
#include <winrt/Windows.Graphics.Imaging.h>
#include <winrt/Windows.Media.Ocr.h>
#include <winrt/Windows.Storage.Streams.h>
#include <winrt/Windows.Storage.h>

#include <algorithm>
#include <string>
#include <thread>

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;
using winrt::Windows::Graphics::Imaging::BitmapAlphaMode;
using winrt::Windows::Graphics::Imaging::BitmapDecoder;
using winrt::Windows::Graphics::Imaging::BitmapInterpolationMode;
using winrt::Windows::Graphics::Imaging::BitmapPixelFormat;
using winrt::Windows::Graphics::Imaging::BitmapTransform;
using winrt::Windows::Graphics::Imaging::ColorManagementMode;
using winrt::Windows::Graphics::Imaging::ExifOrientationMode;
using winrt::Windows::Graphics::Imaging::SoftwareBitmap;
using winrt::Windows::Media::Ocr::OcrEngine;

namespace {

struct Job {
  std::unique_ptr<flutter::MethodResult<EncodableValue>> result;
  std::string path;
  EncodableValue value;
  std::string error;
};

// Decodes the picture upright (phone photos carry their turn in EXIF) and
// small enough for the reader; tiny screenshots are made bigger, which reads
// small letters better.
SoftwareBitmap Load(std::string path) {
  // StorageFile wants Windows separators ("C:\\a/b.png" is refused).
  std::replace(path.begin(), path.end(), '/', '\\');
  auto file = winrt::Windows::Storage::StorageFile::GetFileFromPathAsync(winrt::to_hstring(path)).get();
  auto stream = file.OpenAsync(winrt::Windows::Storage::FileAccessMode::Read).get();
  auto decoder = BitmapDecoder::CreateAsync(stream).get();
  const double w = decoder.OrientedPixelWidth(), h = decoder.OrientedPixelHeight();
  const double longest = (std::max)(w, h);
  const double max = static_cast<double>(OcrEngine::MaxImageDimension());
  double scale = 1;
  if (longest > max) scale = max / longest;
  if ((std::max)(w, h) < 1200) scale = (std::min)(2.0, max / longest);
  BitmapTransform transform;
  transform.InterpolationMode(BitmapInterpolationMode::Fant);
  if (scale != 1) {
    // Scaled sizes are before the turn, so use the stored (unturned) size.
    transform.ScaledWidth(static_cast<uint32_t>(decoder.PixelWidth() * scale));
    transform.ScaledHeight(static_cast<uint32_t>(decoder.PixelHeight() * scale));
  }
  return decoder
      .GetSoftwareBitmapAsync(BitmapPixelFormat::Bgra8, BitmapAlphaMode::Premultiplied, transform,
                              ExifOrientationMode::RespectExifOrientation, ColorManagementMode::DoNotColorManage)
      .get();
}

EncodableValue Read(const std::string& path) {
  auto bitmap = Load(path);
  EncodableList engines;
  int count = 0;
  for (auto const& language : OcrEngine::AvailableRecognizerLanguages()) {
    if (++count > 4) break;
    auto engine = OcrEngine::TryCreateFromLanguage(language);
    if (!engine) continue;
    auto result = engine.RecognizeAsync(bitmap).get();
    EncodableList lines;
    for (auto const& line : result.Lines()) {
      EncodableList words;
      for (auto const& word : line.Words()) {
        auto r = word.BoundingRect();
        words.push_back(EncodableValue(EncodableMap{
            {EncodableValue("text"), EncodableValue(winrt::to_string(word.Text()))},
            {EncodableValue("x"), EncodableValue(static_cast<double>(r.X))},
            {EncodableValue("y"), EncodableValue(static_cast<double>(r.Y))},
            {EncodableValue("w"), EncodableValue(static_cast<double>(r.Width))},
            {EncodableValue("h"), EncodableValue(static_cast<double>(r.Height))},
        }));
      }
      lines.push_back(EncodableValue(std::move(words)));
    }
    engines.push_back(EncodableValue(EncodableMap{
        {EncodableValue("lang"), EncodableValue(winrt::to_string(language.LanguageTag()))},
        {EncodableValue("lines"), EncodableValue(std::move(lines))},
    }));
  }
  return EncodableValue(EncodableMap{
      {EncodableValue("width"), EncodableValue(static_cast<int32_t>(bitmap.PixelWidth()))},
      {EncodableValue("height"), EncodableValue(static_cast<int32_t>(bitmap.PixelHeight()))},
      {EncodableValue("engines"), EncodableValue(std::move(engines))},
  });
}

}  // namespace

struct OcrBridge::Impl {
  HWND hwnd = nullptr;
  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel;

  void HandleCall(const flutter::MethodCall<EncodableValue>& call,
                  std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    if (call.method_name() != "read") {
      result->NotImplemented();
      return;
    }
    const auto* args = std::get_if<EncodableMap>(call.arguments());
    const EncodableValue* path = nullptr;
    if (args) {
      auto it = args->find(EncodableValue("path"));
      if (it != args->end()) path = &it->second;
    }
    if (!path || !std::holds_alternative<std::string>(*path)) {
      result->Error("ocr", "no path");
      return;
    }
    auto* job = new Job{std::move(result), std::get<std::string>(*path), EncodableValue(), std::string()};
    HWND target = hwnd;
    std::thread([job, target]() {
      winrt::init_apartment(winrt::apartment_type::multi_threaded);
      try {
        job->value = Read(job->path);
      } catch (const winrt::hresult_error& e) {
        job->error = winrt::to_string(e.message());
        if (job->error.empty()) job->error = "hresult " + std::to_string(e.code());
      } catch (const std::exception& e) {
        job->error = e.what();
      } catch (...) {
        job->error = "unknown";
      }
      winrt::uninit_apartment();
      if (!::PostMessage(target, kOcrDoneMessage, 0, reinterpret_cast<LPARAM>(job))) delete job;
    }).detach();
  }
};

OcrBridge::OcrBridge(HWND hwnd, flutter::BinaryMessenger* messenger) : impl_(std::make_unique<Impl>()) {
  impl_->hwnd = hwnd;
  impl_->channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, "prism/ocr", &flutter::StandardMethodCodec::GetInstance());
  impl_->channel->SetMethodCallHandler(
      [impl = impl_.get()](const auto& call, auto result) { impl->HandleCall(call, std::move(result)); });
}

OcrBridge::~OcrBridge() {
  if (impl_->channel) impl_->channel->SetMethodCallHandler(nullptr);
}

void OcrBridge::Finish(LPARAM raw) {
  std::unique_ptr<Job> job(reinterpret_cast<Job*>(raw));
  if (!job) return;
  if (job->error.empty()) {
    job->result->Success(job->value);
  } else {
    job->result->Error("ocr", job->error);
  }
}
