#ifndef RUNNER_DROP_BRIDGE_H_
#define RUNNER_DROP_BRIDGE_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <oleidl.h>
#include <windows.h>

#include <memory>

// Files and links dragged onto the window go to Dart over "prism/drop":
// "enter", "leave" and "drop" with {files: [paths], text: link}.
class DropBridge : public IDropTarget {
 public:
  DropBridge(HWND window, flutter::BinaryMessenger* messenger);
  virtual ~DropBridge();

  // IUnknown. Lifetime belongs to FlutterWindow, so the count is only for OLE.
  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID id, void** out) override;
  ULONG STDMETHODCALLTYPE AddRef() override;
  ULONG STDMETHODCALLTYPE Release() override;

  // IDropTarget.
  HRESULT STDMETHODCALLTYPE DragEnter(IDataObject* data, DWORD keys, POINTL point, DWORD* effect) override;
  HRESULT STDMETHODCALLTYPE DragOver(DWORD keys, POINTL point, DWORD* effect) override;
  HRESULT STDMETHODCALLTYPE DragLeave() override;
  HRESULT STDMETHODCALLTYPE Drop(IDataObject* data, DWORD keys, POINTL point, DWORD* effect) override;

 private:
  void Send(const char* method, std::unique_ptr<flutter::EncodableValue> args = nullptr);

  HWND window_;
  bool registered_ = false;
  DWORD effect_ = DROPEFFECT_NONE;
  LONG count_ = 1;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_DROP_BRIDGE_H_
