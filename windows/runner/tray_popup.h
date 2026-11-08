#ifndef RUNNER_TRAY_POPUP_H_
#define RUNNER_TRAY_POPUP_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

namespace Gdiplus {
class Bitmap;
}

// What the tray popup shows.
struct TrayPopupState {
  std::wstring title;
  std::wstring artist;
  std::wstring art_path;  // a local picture file, or empty
  bool playing = false;
  bool has_track = false;
  std::wstring show_label = L"Show Prism";
  std::wstring quit_label = L"Quit";
};

// The tray icon's right-click popup: a small dark panel with the song (cover,
// title, artist), previous / play-pause / next buttons, then "Show Prism" and
// "Quit". Drawn with GDI+ because a Win32 menu can't be styled. Closes when it
// loses focus, on Esc, and after Show / Quit; the playback buttons keep it open.
class TrayPopup {
 public:
  // [on_action] gets "open", "toggle", "previous", "next" or "quit".
  explicit TrayPopup(std::function<void(const char*)> on_action);
  ~TrayPopup();

  TrayPopup(const TrayPopup&) = delete;
  TrayPopup& operator=(const TrayPopup&) = delete;

  // Opens next to [anchor] (the cursor), inside that monitor's work area.
  void ShowAt(POINT anchor);
  void Update(const TrayPopupState& state);
  void Close();
  bool visible() const { return hwnd_ && ::IsWindowVisible(hwnd_); }

 private:
  enum Part { kNone = -1, kPrevious, kToggle, kNext, kOpen, kQuit, kPartCount };

  static LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);
  LRESULT Handle(UINT message, WPARAM wparam, LPARAM lparam);
  void EnsureWindow();
  void Layout();
  void Paint(HDC hdc);
  Part HitTest(POINT p) const;
  void Press(Part part);
  void LoadArt();

  std::function<void(const char*)> on_action_;
  HWND hwnd_ = nullptr;
  ULONG_PTR gdiplus_token_ = 0;
  TrayPopupState state_;
  std::wstring loaded_art_;
  std::unique_ptr<Gdiplus::Bitmap> art_;
  double scale_ = 1.0;
  SIZE size_{};
  RECT parts_[kPartCount]{};
  RECT cover_{};
  Part hover_ = kNone;
  Part down_ = kNone;
  bool tracking_ = false;
};

#endif  // RUNNER_TRAY_POPUP_H_
