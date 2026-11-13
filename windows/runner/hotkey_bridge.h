#ifndef RUNNER_HOTKEY_BRIDGE_H_
#define RUNNER_HOTKEY_BRIDGE_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>
#include <vector>

// System-wide hotkeys (they work while Prism is hidden or another app has
// the focus) via RegisterHotKey, over "prism/hotkeys".
//
// Dart -> native: "set" [{id, mods, vk, repeat}] -> [ids Windows refused]
//                 (mods: 1 Alt, 2 Ctrl, 4 Shift, 8 Win). An empty list clears.
// Native -> Dart: "pressed" id
class HotkeyBridge {
 public:
  HotkeyBridge(HWND hwnd, flutter::BinaryMessenger* messenger);
  ~HotkeyBridge();

  HotkeyBridge(const HotkeyBridge&) = delete;
  HotkeyBridge& operator=(const HotkeyBridge&) = delete;

  // Called from FlutterWindow::MessageHandler for WM_HOTKEY.
  void Pressed(WPARAM id);

 private:
  void Clear();

  HWND hwnd_;
  std::vector<int> registered_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_HOTKEY_BRIDGE_H_
