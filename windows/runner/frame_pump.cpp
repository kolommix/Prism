#include "frame_pump.h"

#include <dwmapi.h>

namespace {

// Flutter's message-only window for this process (other Flutter apps have one
// with the same class name).
HWND FindTaskRunnerWindow() {
  const DWORD me = ::GetCurrentProcessId();
  HWND found = nullptr;
  while ((found = ::FindWindowExW(HWND_MESSAGE, found,
                                  L"FlutterTaskRunnerWindow", nullptr))) {
    DWORD owner = 0;
    ::GetWindowThreadProcessId(found, &owner);
    if (owner == me) {
      return found;
    }
  }
  return nullptr;
}

}  // namespace

FramePump::~FramePump() { Stop(); }

void FramePump::Start(HWND top_level) {
  if (thread_.joinable()) {
    return;
  }
  stop_ = false;
  thread_ = std::thread([this, top_level] { Run(top_level); });
}

void FramePump::Stop() {
  stop_ = true;
  if (thread_.joinable()) {
    thread_.join();
  }
}

void FramePump::Run(HWND top_level) {
  ::SetThreadPriority(::GetCurrentThread(), THREAD_PRIORITY_ABOVE_NORMAL);
  HWND runner = nullptr;
  while (!stop_) {
    if (!runner || !::IsWindow(runner)) {
      runner = FindTaskRunnerWindow();
      if (!runner) {
        ::Sleep(200);
        continue;
      }
    }
    // Nothing on screen (tray, minimized): no need to wake anything.
    if (!::IsWindowVisible(top_level) || ::IsIconic(top_level)) {
      ::Sleep(100);
      continue;
    }
    if (FAILED(::DwmFlush())) {
      ::Sleep(8);
    }
    ::PostMessageW(runner, WM_NULL, 0, 0);
  }
}
