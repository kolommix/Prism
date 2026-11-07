#include "drop_bridge.h"

#include <flutter/standard_method_codec.h>
#include <shellapi.h>

#include <string>
#include <vector>

#include "utils.h"

namespace {

// The format browsers use for a dragged link.
CLIPFORMAT UrlFormat() {
  static const CLIPFORMAT format =
      static_cast<CLIPFORMAT>(::RegisterClipboardFormatW(L"UniformResourceLocatorW"));
  return format;
}

FORMATETC FormatOf(CLIPFORMAT format) {
  return FORMATETC{format, nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL};
}

bool Has(IDataObject* data, CLIPFORMAT format) {
  FORMATETC f = FormatOf(format);
  return data->QueryGetData(&f) == S_OK;
}

std::string TextOf(IDataObject* data, CLIPFORMAT format) {
  FORMATETC f = FormatOf(format);
  STGMEDIUM medium{};
  if (data->GetData(&f, &medium) != S_OK) return "";
  std::string out;
  if (const auto* text = static_cast<const wchar_t*>(::GlobalLock(medium.hGlobal))) {
    out = Utf8FromUtf16(text);
    ::GlobalUnlock(medium.hGlobal);
  }
  ::ReleaseStgMedium(&medium);
  return out;
}

std::vector<std::string> FilesOf(IDataObject* data) {
  std::vector<std::string> out;
  FORMATETC f = FormatOf(CF_HDROP);
  STGMEDIUM medium{};
  if (data->GetData(&f, &medium) != S_OK) return out;
  if (auto drop = static_cast<HDROP>(::GlobalLock(medium.hGlobal))) {
    const UINT count = ::DragQueryFileW(drop, 0xFFFFFFFF, nullptr, 0);
    for (UINT i = 0; i < count; i++) {
      const UINT length = ::DragQueryFileW(drop, i, nullptr, 0);
      std::wstring path(length + 1, L'\0');
      ::DragQueryFileW(drop, i, path.data(), length + 1);
      out.push_back(Utf8FromUtf16(path.c_str()));
    }
    ::GlobalUnlock(medium.hGlobal);
  }
  ::ReleaseStgMedium(&medium);
  return out;
}

}  // namespace

DropBridge::DropBridge(HWND window, flutter::BinaryMessenger* messenger) : window_(window) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "prism/drop", &flutter::StandardMethodCodec::GetInstance());
  registered_ = ::RegisterDragDrop(window_, this) == S_OK;
}

DropBridge::~DropBridge() {
  if (registered_) ::RevokeDragDrop(window_);
}

HRESULT DropBridge::QueryInterface(REFIID id, void** out) {
  if (id == IID_IUnknown || id == IID_IDropTarget) {
    *out = static_cast<IDropTarget*>(this);
    AddRef();
    return S_OK;
  }
  *out = nullptr;
  return E_NOINTERFACE;
}

ULONG DropBridge::AddRef() {
  return ::InterlockedIncrement(&count_);
}

ULONG DropBridge::Release() {
  return ::InterlockedDecrement(&count_);
}

HRESULT DropBridge::DragEnter(IDataObject* data, DWORD, POINTL, DWORD* effect) {
  const bool wanted = Has(data, CF_HDROP) || Has(data, UrlFormat()) || Has(data, CF_UNICODETEXT);
  effect_ = wanted ? DROPEFFECT_COPY : DROPEFFECT_NONE;
  *effect = effect_;
  if (wanted) Send("enter");
  return S_OK;
}

HRESULT DropBridge::DragOver(DWORD, POINTL, DWORD* effect) {
  *effect = effect_;
  return S_OK;
}

HRESULT DropBridge::DragLeave() {
  if (effect_ != DROPEFFECT_NONE) Send("leave");
  effect_ = DROPEFFECT_NONE;
  return S_OK;
}

HRESULT DropBridge::Drop(IDataObject* data, DWORD, POINTL, DWORD* effect) {
  flutter::EncodableList files;
  for (const auto& path : FilesOf(data)) files.emplace_back(path);
  std::string text = TextOf(data, UrlFormat());
  if (text.empty()) text = TextOf(data, CF_UNICODETEXT);
  flutter::EncodableMap args;
  args[flutter::EncodableValue("files")] = flutter::EncodableValue(files);
  args[flutter::EncodableValue("text")] = flutter::EncodableValue(text);
  Send("drop", std::make_unique<flutter::EncodableValue>(args));
  *effect = effect_;
  effect_ = DROPEFFECT_NONE;
  ::SetForegroundWindow(window_);
  return S_OK;
}

void DropBridge::Send(const char* method, std::unique_ptr<flutter::EncodableValue> args) {
  channel_->InvokeMethod(method, std::move(args));
}
