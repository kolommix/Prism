#ifndef RUNNER_TRAY_BRIDGE_H_
#define RUNNER_TRAY_BRIDGE_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>
#include <string>
#include <vector>

// Callback message the notification-area icon sends to our window.
constexpr UINT kTrayCallbackMessage = WM_APP + 0x52;

// Minimal system tray icon with a playback context menu, exposed to Dart
// through the "prism/tray" method channel.
//
// Dart -> native:  "show" {tooltip, playing}   (creates/updates the icon)
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
  void Show(const std::wstring& tooltip, bool playing);
  void Hide();
  void ShowMenu();
  void Send(const char* action);

  HWND hwnd_;
  bool visible_ = false;
  bool playing_ = false;
  // Menu text from Dart: open, pause, play, previous, next, quit.
  std::vector<std::wstring> labels_ = {L"Open Prism", L"Pause", L"Play", L"Previous", L"Next", L"Quit"};
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_TRAY_BRIDGE_H_
