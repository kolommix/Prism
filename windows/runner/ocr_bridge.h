#ifndef RUNNER_OCR_BRIDGE_H_
#define RUNNER_OCR_BRIDGE_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>

// Window message that brings a finished text reading back onto the platform
// thread (the reading runs on its own thread so the window never waits).
constexpr UINT kOcrDoneMessage = WM_APP + 0x61;

// Reads the text in a picture with Windows' own text recognition
// (Windows.Media.Ocr: on this PC, nothing leaves it) via "prism/ocr".
//
// Dart -> native: "read" {path} -> {width, height, engines: [{lang, lines:
//                 [[{text, x, y, w, h}, ...words], ...]}]}
// Every installed reading language reads the picture once; Dart merges them.
class OcrBridge {
 public:
  OcrBridge(HWND hwnd, flutter::BinaryMessenger* messenger);
  ~OcrBridge();

  OcrBridge(const OcrBridge&) = delete;
  OcrBridge& operator=(const OcrBridge&) = delete;

  // Called from FlutterWindow::MessageHandler for kOcrDoneMessage.
  void Finish(LPARAM job);

 private:
  struct Impl;
  std::unique_ptr<Impl> impl_;
};

#endif  // RUNNER_OCR_BRIDGE_H_
