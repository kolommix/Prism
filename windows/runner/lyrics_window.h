#ifndef RUNNER_LYRICS_WINDOW_H_
#define RUNNER_LYRICS_WINDOW_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <climits>
#include <memory>
#include <string>
#include <vector>

// A small window with the line being sung, always on top of other apps, with
// a see-through background ("prism/lyricswindow"). It is its own window, so it
// stays while Prism is minimized or hidden in the tray.
//
// Dart -> native: "show" {x, y, w, fontSize, opacity, locked, labels}
//                 "hide"
//                 "text" {current, next}
//                 "style" {fontSize, opacity, locked}
// Native -> Dart: "closed"                       (Close in its menu)
//                 "moved" {x, y, w}              (after a drag or resize)
//                 "style" {fontSize, opacity, locked}  (changed in its menu)
//
// Drag it anywhere to move, drag a side to make it wider or narrower,
// right-click for the menu. Locked: clicks go through it to what is below.
class LyricsWindow {
 public:
  explicit LyricsWindow(flutter::BinaryMessenger* messenger);
  ~LyricsWindow();

  LyricsWindow(const LyricsWindow&) = delete;
  LyricsWindow& operator=(const LyricsWindow&) = delete;

 private:
  static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam);
  LRESULT Handle(UINT msg, WPARAM wparam, LPARAM lparam);
  void HandleCall(const flutter::MethodCall<flutter::EncodableValue>& call,
                  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void EnsureWindow();
  void ApplyLock();
  void Render();
  void ShowMenu(POINT at);
  void SendStyle();
  void SendMoved();
  double Scale() const;

  HWND hwnd_ = nullptr;
  ULONG_PTR gdiplus_token_ = 0;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;

  std::wstring current_;
  std::wstring next_;
  double font_size_ = 30;  // at 96 dpi
  double opacity_ = 0.45;  // background, 0 = fully see-through
  bool locked_ = false;
  bool hover_ = false;
  bool visible_ = false;
  int x_ = INT_MIN, y_ = INT_MIN;  // screen pixels
  int width_ = 0;                  // screen pixels, 0 = default
  std::vector<std::wstring> labels_;
};

#endif  // RUNNER_LYRICS_WINDOW_H_
