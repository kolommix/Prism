#include "tray_bridge.h"

#include <flutter/standard_method_codec.h>
#include <shellapi.h>

#include "resource.h"

namespace {

constexpr UINT kTrayIconId = 1;

enum MenuId : UINT {
  kMenuOpen = 1,
  kMenuToggle,
  kMenuPrevious,
  kMenuNext,
  kMenuQuit,
};

std::wstring Utf8ToWide(const std::string& s) {
  if (s.empty()) return std::wstring();
  const int len = ::MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), nullptr, 0);
  std::wstring out(len, L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), out.data(), len);
  return out;
}

}  // namespace

TrayBridge::TrayBridge(HWND hwnd, flutter::BinaryMessenger* messenger) : hwnd_(hwnd) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "prism/tray", &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() == "show") {
      std::wstring tooltip = L"Prism";
      bool playing = false;
      if (const auto* args = std::get_if<flutter::EncodableMap>(call.arguments())) {
        auto t = args->find(flutter::EncodableValue("tooltip"));
        if (t != args->end()) {
          if (const auto* s = std::get_if<std::string>(&t->second)) tooltip = Utf8ToWide(*s);
        }
        auto l = args->find(flutter::EncodableValue("labels"));
        if (l != args->end()) {
          if (const auto* list = std::get_if<flutter::EncodableList>(&l->second)) {
            std::vector<std::wstring> labels;
            for (const auto& item : *list) {
              if (const auto* s = std::get_if<std::string>(&item)) labels.push_back(Utf8ToWide(*s));
            }
            if (labels.size() == 6) labels_ = std::move(labels);
          }
        }
        auto p = args->find(flutter::EncodableValue("playing"));
        if (p != args->end()) {
          if (const auto* b = std::get_if<bool>(&p->second)) playing = *b;
        }
      }
      Show(tooltip, playing);
      result->Success();
    } else if (call.method_name() == "hide") {
      Hide();
      result->Success();
    } else {
      result->NotImplemented();
    }
  });
}

TrayBridge::~TrayBridge() {
  Hide();
  channel_->SetMethodCallHandler(nullptr);
}

void TrayBridge::Show(const std::wstring& tooltip, bool playing) {
  playing_ = playing;
  NOTIFYICONDATAW nid{};
  nid.cbSize = sizeof(nid);
  nid.hWnd = hwnd_;
  nid.uID = kTrayIconId;
  nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  nid.uCallbackMessage = kTrayCallbackMessage;
  nid.hIcon = static_cast<HICON>(::LoadImageW(::GetModuleHandleW(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON),
                                              IMAGE_ICON, ::GetSystemMetrics(SM_CXSMICON),
                                              ::GetSystemMetrics(SM_CYSMICON), LR_DEFAULTCOLOR));
  // Tooltip is limited to 128 chars including the terminator.
  wcsncpy_s(nid.szTip, tooltip.c_str(), _TRUNCATE);
  ::Shell_NotifyIconW(visible_ ? NIM_MODIFY : NIM_ADD, &nid);
  visible_ = true;
  if (nid.hIcon) ::DestroyIcon(nid.hIcon);
}

void TrayBridge::Hide() {
  if (!visible_) return;
  NOTIFYICONDATAW nid{};
  nid.cbSize = sizeof(nid);
  nid.hWnd = hwnd_;
  nid.uID = kTrayIconId;
  ::Shell_NotifyIconW(NIM_DELETE, &nid);
  visible_ = false;
}

void TrayBridge::HandleTrayMessage(LPARAM lparam) {
  switch (LOWORD(lparam)) {
    case WM_LBUTTONUP:
    case WM_LBUTTONDBLCLK:
      Send("open");
      break;
    case WM_RBUTTONUP:
    case WM_CONTEXTMENU:
      ShowMenu();
      break;
    default:
      break;
  }
}

void TrayBridge::ShowMenu() {
  HMENU menu = ::CreatePopupMenu();
  ::AppendMenuW(menu, MF_STRING, kMenuOpen, labels_[0].c_str());
  ::AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  ::AppendMenuW(menu, MF_STRING, kMenuToggle, playing_ ? labels_[1].c_str() : labels_[2].c_str());
  ::AppendMenuW(menu, MF_STRING, kMenuPrevious, labels_[3].c_str());
  ::AppendMenuW(menu, MF_STRING, kMenuNext, labels_[4].c_str());
  ::AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  ::AppendMenuW(menu, MF_STRING, kMenuQuit, labels_[5].c_str());

  POINT pt;
  ::GetCursorPos(&pt);
  // Required so the menu closes when clicking elsewhere.
  ::SetForegroundWindow(hwnd_);
  const UINT cmd = ::TrackPopupMenu(menu, TPM_RETURNCMD | TPM_NONOTIFY | TPM_RIGHTBUTTON, pt.x, pt.y, 0, hwnd_,
                                    nullptr);
  ::DestroyMenu(menu);

  switch (cmd) {
    case kMenuOpen:
      Send("open");
      break;
    case kMenuToggle:
      Send("toggle");
      break;
    case kMenuPrevious:
      Send("previous");
      break;
    case kMenuNext:
      Send("next");
      break;
    case kMenuQuit:
      Send("quit");
      break;
    default:
      break;
  }
}

void TrayBridge::Send(const char* action) {
  channel_->InvokeMethod("action", std::make_unique<flutter::EncodableValue>(std::string(action)));
}
