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

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  // A shared playlist opened while Prism is running: hand it to that window.
  for (const auto& arg : command_line_arguments) {
    const bool link = arg.rfind("liner://", 0) == 0;
    const bool file = arg.size() > 6 && arg.compare(arg.size() - 6, 6, ".liner") == 0;
    if (!link && !file) continue;
    HWND running = ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Prism");
    if (running) {
      COPYDATASTRUCT data{};
      data.dwData = kDeepLinkCopyData;
      data.cbData = static_cast<DWORD>(arg.size());
      data.lpData = const_cast<char*>(arg.data());
      ::SendMessageW(running, WM_COPYDATA, 0, reinterpret_cast<LPARAM>(&data));
      ::SetForegroundWindow(running);
      ::CoUninitialize();
      return EXIT_SUCCESS;
    }
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

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
