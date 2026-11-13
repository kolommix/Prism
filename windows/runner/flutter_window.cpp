#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  smtc_bridge_ = std::make_unique<SmtcBridge>(
      GetHandle(), flutter_controller_->engine()->messenger());
  deep_link_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "prism/deeplink",
      &flutter::StandardMethodCodec::GetInstance());
  window_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "prism/window",
      &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() == "setFullScreen") {
      const auto* on = std::get_if<bool>(call.arguments());
      if (on) SetFullScreen(*on);
      result->Success();
    } else if (call.method_name() == "isFullScreen") {
      result->Success(flutter::EncodableValue(full_screen_));
    } else {
      result->NotImplemented();
    }
  });
  drop_bridge_ = std::make_unique<DropBridge>(
      GetHandle(), flutter_controller_->engine()->messenger());
  lyrics_window_ = std::make_unique<LyricsWindow>(flutter_controller_->engine()->messenger());
  hotkey_bridge_ = std::make_unique<HotkeyBridge>(
      GetHandle(), flutter_controller_->engine()->messenger());
  ocr_bridge_ = std::make_unique<OcrBridge>(
      GetHandle(), flutter_controller_->engine()->messenger());
  tray_bridge_ = std::make_unique<TrayBridge>(
      GetHandle(), flutter_controller_->engine()->messenger());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  frame_pump_.Start(GetHandle());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

// Saves the window as it is, then covers the whole monitor with no title bar or
// frame. Leaving puts everything back, also the maximized state.
void FlutterWindow::SetFullScreen(bool on) {
  if (on == full_screen_) return;
  HWND hwnd = GetHandle();
  if (on) {
    style_before_full_screen_ = ::GetWindowLongPtr(hwnd, GWL_STYLE);
    ex_style_before_full_screen_ = ::GetWindowLongPtr(hwnd, GWL_EXSTYLE);
    placement_before_full_screen_.length = sizeof(WINDOWPLACEMENT);
    ::GetWindowPlacement(hwnd, &placement_before_full_screen_);
    // A maximized window keeps its frame sizes, so leave that state first.
    if (::IsZoomed(hwnd)) ::SendMessage(hwnd, WM_SYSCOMMAND, SC_RESTORE, 0);
    MONITORINFO monitor{};
    monitor.cbSize = sizeof(MONITORINFO);
    ::GetMonitorInfo(::MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST), &monitor);
    ::SetWindowLongPtr(hwnd, GWL_STYLE,
                       style_before_full_screen_ & ~(WS_CAPTION | WS_THICKFRAME | WS_MAXIMIZE));
    ::SetWindowLongPtr(hwnd, GWL_EXSTYLE,
                       ex_style_before_full_screen_ &
                           ~(WS_EX_DLGMODALFRAME | WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE | WS_EX_STATICEDGE));
    const RECT& r = monitor.rcMonitor;
    ::SetWindowPos(hwnd, HWND_TOP, r.left, r.top, r.right - r.left, r.bottom - r.top,
                   SWP_NOOWNERZORDER | SWP_FRAMECHANGED | SWP_SHOWWINDOW);
  } else {
    ::SetWindowLongPtr(hwnd, GWL_STYLE, style_before_full_screen_);
    ::SetWindowLongPtr(hwnd, GWL_EXSTYLE, ex_style_before_full_screen_);
    ::SetWindowPlacement(hwnd, &placement_before_full_screen_);
    ::SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                   SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
  }
  full_screen_ = on;
}

void FlutterWindow::OnDestroy() {
  window_channel_ = nullptr;
  drop_bridge_ = nullptr;
  ocr_bridge_ = nullptr;
  hotkey_bridge_ = nullptr;
  lyrics_window_ = nullptr;
  frame_pump_.Stop();
  smtc_bridge_ = nullptr;
  tray_bridge_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (message == WM_COPYDATA) {
    const auto* data = reinterpret_cast<const COPYDATASTRUCT*>(lparam);
    if (data && data->dwData == kDeepLinkCopyData && deep_link_) {
      std::string text(static_cast<const char*>(data->lpData), data->cbData);
      deep_link_->InvokeMethod("open", std::make_unique<flutter::EncodableValue>(text));
      return TRUE;
    }
    if (data && data->dwData == kShowWindowCopyData) {
      // Hidden in the tray, minimized or behind other windows: bring it back.
      if (!::IsWindowVisible(hwnd)) ::ShowWindow(hwnd, SW_SHOW);
      if (::IsIconic(hwnd)) ::ShowWindow(hwnd, SW_RESTORE);
      ::SetForegroundWindow(hwnd);
      return TRUE;
    }
  }
  // Full screen: the client area is the whole window. Must come before the
  // plugins, or window_manager's hidden title bar trims 8 px off three sides.
  if (message == WM_NCCALCSIZE && wparam && full_screen_) {
    return 0;
  }
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case kSmtcButtonMessage:
      if (smtc_bridge_) smtc_bridge_->DispatchButton(wparam);
      return 0;
    case WM_HOTKEY:
      if (hotkey_bridge_) hotkey_bridge_->Pressed(wparam);
      return 0;
    case kOcrDoneMessage:
      if (ocr_bridge_) {
        ocr_bridge_->Finish(lparam);
      }
      return 0;
    case kTrayCallbackMessage:
      if (tray_bridge_) tray_bridge_->HandleTrayMessage(lparam);
      return 0;
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
