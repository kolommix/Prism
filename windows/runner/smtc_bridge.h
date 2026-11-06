#ifndef RUNNER_SMTC_BRIDGE_H_
#define RUNNER_SMTC_BRIDGE_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>

// Window message used to hop SMTC button presses (raised on a WinRT thread
// pool thread) back onto the platform thread before talking to Flutter.
constexpr UINT kSmtcButtonMessage = WM_APP + 0x51;

// Bridges Windows' System Media Transport Controls (the media overlay that
// appears when pressing hardware media keys, plus the lock screen / Bluetooth
// controls) to Dart via the "prism/smtc" method channel.
//
// Dart -> native:  "update"   {title, artist, album, artPath, playing, enabled}
//                  "timeline" {positionMs, durationMs}
// Native -> Dart:  "button"   "play" | "pause" | "next" | "previous" | "stop"
class SmtcBridge {
 public:
  SmtcBridge(HWND hwnd, flutter::BinaryMessenger* messenger);
  ~SmtcBridge();

  SmtcBridge(const SmtcBridge&) = delete;
  SmtcBridge& operator=(const SmtcBridge&) = delete;

  // Called from FlutterWindow::MessageHandler for kSmtcButtonMessage.
  void DispatchButton(WPARAM button);

 private:
  struct Impl;
  std::unique_ptr<Impl> impl_;
};

#endif  // RUNNER_SMTC_BRIDGE_H_
