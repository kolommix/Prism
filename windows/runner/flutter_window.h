#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/flutter_view_controller.h>

#include <memory>

#include "smtc_bridge.h"
#include "tray_bridge.h"
#include "frame_pump.h"
#include "win32_window.h"

// A window that does nothing but host a Flutter view.
// WM_COPYDATA tag for a shared playlist from a second start of the app.
constexpr ULONG_PTR kDeepLinkCopyData = 0x4C494E52;  // "LINR"

class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Starts frames in step with the screen.
  FramePump frame_pump_;

  // Media keys / Windows media overlay (see smtc_bridge.h).
  std::unique_ptr<SmtcBridge> smtc_bridge_;

  // Notification-area icon (see tray_bridge.h).
  std::unique_ptr<TrayBridge> tray_bridge_;

  // Passes liner:// links and .liner paths to Dart.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> deep_link_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
