#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  // Drag and drop needs OLE on this thread (drop_bridge.cpp).
  ::OleInitialize(nullptr);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  // One Prism at a time. A second start brings the running window forward and
  // hands over a shared playlist if it was opened with one. The mutex lives as
  // long as this process.
  HANDLE single = ::CreateMutexW(nullptr, FALSE, L"Local\\Prism.kolommix.OneWindow");
  if (single && ::GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND running = nullptr;
    // The first one may still be starting: wait up to 5 s for its window.
    for (int i = 0; i < 50 && !running; ++i) {
      running = ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Prism");
      if (!running) ::Sleep(100);
    }
    if (running) {
      DWORD pid = 0;
      ::GetWindowThreadProcessId(running, &pid);
      ::AllowSetForegroundWindow(pid);
      for (const auto& arg : command_line_arguments) {
        const bool link = arg.rfind("liner://", 0) == 0;
        const bool file = arg.size() > 6 && arg.compare(arg.size() - 6, 6, ".liner") == 0;
        if (!link && !file) continue;
        COPYDATASTRUCT data{};
        data.dwData = kDeepLinkCopyData;
        data.cbData = static_cast<DWORD>(arg.size());
        data.lpData = const_cast<char*>(arg.data());
        ::SendMessageW(running, WM_COPYDATA, 0, reinterpret_cast<LPARAM>(&data));
      }
      COPYDATASTRUCT show{};
      show.dwData = kShowWindowCopyData;
      ::SendMessageW(running, WM_COPYDATA, 0, reinterpret_cast<LPARAM>(&show));
    }
    ::CloseHandle(single);
    ::OleUninitialize();
    ::CoUninitialize();
    return EXIT_SUCCESS;
  }

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1360, 820);
  if (!window.Create(L"Prism", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::OleUninitialize();
  ::CoUninitialize();
  return EXIT_SUCCESS;
}
