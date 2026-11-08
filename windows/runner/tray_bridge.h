#ifndef RUNNER_TRAY_BRIDGE_H_
#define RUNNER_TRAY_BRIDGE_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>
#include <string>
#include <vector>

#include "tray_popup.h"

// Callback message the notification-area icon sends to our window.
constexpr UINT kTrayCallbackMessage = WM_APP + 0x52;

// System tray icon with a playback popup (tray_popup.cpp), exposed to Dart
// through the "prism/tray" method channel.
//
// Dart -> native:  "show" {tooltip, playing, labels, title, artist, artPath}
//                  (creates/updates the icon and the popup)
//                  "hide"
// Native -> Dart:  "action" "open" | "toggle" | "next" | "previous" | "quit"
class TrayBridge {
 public:
  TrayBridge(HWND hwnd, flutter::BinaryMessenger* messenger);
  ~TrayBridge();

  TrayBridge(const TrayBridge&) = delete;
  TrayBridge& operator=(const TrayBridge&) = delete;

  // Called from FlutterWindow::MessageHandler for kTrayCallbackMessage.
  void HandleTrayMessage(LPARAM lparam);

 private:
  void Show(const std::wstring& tooltip);
  void Hide();
  void ShowMenu();
  void Send(const char* action);

  HWND hwnd_;
  bool visible_ = false;
  std::unique_ptr<TrayPopup> popup_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_TRAY_BRIDGE_H_
