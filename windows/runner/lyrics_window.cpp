#include "lyrics_window.h"

#include <flutter/standard_method_codec.h>
#include <objidl.h>
#include <windowsx.h>

#include <algorithm>
#include <climits>

// The runner builds with NOMINMAX; GDI+ headers still want min/max.
namespace Gdiplus {
using std::max;
using std::min;
}  // namespace Gdiplus
#include <gdiplus.h>

#include <flutter_windows.h>

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

namespace {

constexpr wchar_t kClassName[] = L"PRISM_LYRICS_WINDOW";

// Base sizes at 96 dpi.
constexpr int kDefaultWidth = 760;
constexpr int kMinWidth = 240;
constexpr int kPad = 16;
constexpr int kGap = 6;
constexpr int kEdge = 8;
constexpr float kRadius = 14;

enum MenuCommand { kLock = 1, kBigger, kSmaller, kMoreSeeThrough, kLessSeeThrough, kClose };

// Menu labels from Dart, in this order (English fallback).
const wchar_t* kFallbackLabels[] = {L"Lock (clicks go through)", L"Bigger text",       L"Smaller text",
                                    L"More see-through",         L"Less see-through", L"Close"};

std::wstring Wide(const std::string& s) {
  if (s.empty()) return std::wstring();
  const int n = ::MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), nullptr, 0);
  std::wstring out(n, L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), out.data(), n);
  return out;
}

const EncodableValue* Find(const EncodableMap& m, const char* key) {
  auto it = m.find(EncodableValue(key));
  return it == m.end() ? nullptr : &it->second;
}

double GetDouble(const EncodableMap& m, const char* key, double fallback) {
  const auto* v = Find(m, key);
  if (!v) return fallback;
  if (const auto* d = std::get_if<double>(v)) return *d;
  if (const auto* i = std::get_if<int32_t>(v)) return *i;
  if (const auto* l = std::get_if<int64_t>(v)) return static_cast<double>(*l);
  return fallback;
}

bool GetBool(const EncodableMap& m, const char* key, bool fallback) {
  const auto* v = Find(m, key);
  const auto* b = v ? std::get_if<bool>(v) : nullptr;
  return b ? *b : fallback;
}

std::wstring GetString(const EncodableMap& m, const char* key) {
  const auto* v = Find(m, key);
  const auto* s = v ? std::get_if<std::string>(v) : nullptr;
  return s ? Wide(*s) : std::wstring();
}

void AddRoundRect(Gdiplus::GraphicsPath& path, Gdiplus::RectF r, float radius) {
  const float d = radius * 2;
  path.AddArc(r.X, r.Y, d, d, 180, 90);
  path.AddArc(r.X + r.Width - d, r.Y, d, d, 270, 90);
  path.AddArc(r.X + r.Width - d, r.Y + r.Height - d, d, d, 0, 90);
  path.AddArc(r.X, r.Y + r.Height - d, d, d, 90, 90);
  path.CloseFigure();
}

std::unique_ptr<Gdiplus::FontFamily> TextFamily() {
  // Semibold: headings stay at weight 600.
  for (const wchar_t* name : {L"Segoe UI Semibold", L"Segoe UI", L"Arial"}) {
    auto family = std::make_unique<Gdiplus::FontFamily>(name);
    if (family->GetLastStatus() == Gdiplus::Ok) return family;
  }
  return nullptr;
}

}  // namespace

LyricsWindow::LyricsWindow(flutter::BinaryMessenger* messenger) {
  Gdiplus::GdiplusStartupInput input;
  Gdiplus::GdiplusStartup(&gdiplus_token_, &input, nullptr);
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, "prism/lyricswindow", &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) { HandleCall(call, std::move(result)); });
}

LyricsWindow::~LyricsWindow() {
  if (channel_) channel_->SetMethodCallHandler(nullptr);
  if (hwnd_) ::DestroyWindow(hwnd_);
  hwnd_ = nullptr;
  if (gdiplus_token_) Gdiplus::GdiplusShutdown(gdiplus_token_);
}

void LyricsWindow::HandleCall(const flutter::MethodCall<EncodableValue>& call,
                              std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const auto* args = std::get_if<EncodableMap>(call.arguments());
  const auto& name = call.method_name();
  if (name == "hide") {
    visible_ = false;
    if (hwnd_) ::ShowWindow(hwnd_, SW_HIDE);
    result->Success();
    return;
  }
  if (!args) {
    result->Error("lyricswindow", "no arguments");
    return;
  }
  if (name == "text") {
    current_ = GetString(*args, "current");
    next_ = GetString(*args, "next");
    if (visible_) Render();
  } else if (name == "style" || name == "show") {
    font_size_ = std::clamp(GetDouble(*args, "fontSize", font_size_), 14.0, 96.0);
    opacity_ = std::clamp(GetDouble(*args, "opacity", opacity_), 0.0, 0.95);
    locked_ = GetBool(*args, "locked", locked_);
    if (name == "show") {
      if (const auto* labels = Find(*args, "labels")) {
        if (const auto* list = std::get_if<EncodableList>(labels)) {
          labels_.clear();
          for (const auto& l : *list) {
            if (const auto* s = std::get_if<std::string>(&l)) labels_.push_back(Wide(*s));
          }
        }
      }
      const auto* x = Find(*args, "x");
      if (x && !x->IsNull()) {
        x_ = static_cast<int>(GetDouble(*args, "x", 0));
        y_ = static_cast<int>(GetDouble(*args, "y", 0));
      }
      width_ = static_cast<int>(GetDouble(*args, "w", width_));
      EnsureWindow();
      visible_ = true;
      ApplyLock();
      Render();
      ::ShowWindow(hwnd_, SW_SHOWNOACTIVATE);
      ::SetWindowPos(hwnd_, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    } else if (hwnd_) {
      ApplyLock();
      if (visible_) Render();
    }
  } else {
    result->NotImplemented();
    return;
  }
  result->Success();
}

double LyricsWindow::Scale() const {
  POINT p{x_, y_};
  HMONITOR monitor = hwnd_ ? ::MonitorFromWindow(hwnd_, MONITOR_DEFAULTTONEAREST)
                           : ::MonitorFromPoint(p, MONITOR_DEFAULTTOPRIMARY);
  return FlutterDesktopGetDpiForMonitor(monitor) / 96.0;
}

void LyricsWindow::EnsureWindow() {
  if (!hwnd_) {
    static bool registered = false;
    if (!registered) {
      WNDCLASSEXW wc{};
      wc.cbSize = sizeof(wc);
      wc.lpfnWndProc = WndProc;
      wc.hInstance = ::GetModuleHandleW(nullptr);
      wc.hCursor = ::LoadCursorW(nullptr, IDC_SIZEALL);
      wc.lpszClassName = kClassName;
      ::RegisterClassExW(&wc);
      registered = true;
    }
    // Not owned by the main window: it stays when that one is minimized.
    hwnd_ = ::CreateWindowExW(WS_EX_LAYERED | WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE, kClassName,
                              L"Prism lyrics", WS_POPUP, 0, 0, 10, 10, nullptr, nullptr, ::GetModuleHandleW(nullptr),
                              this);
  }
  // A saved place that is on no screen any more (a monitor unplugged):
  // bottom middle of the main screen.
  POINT p{x_ + 20, y_ + 20};
  if (x_ == INT_MIN || !::MonitorFromPoint(p, MONITOR_DEFAULTTONULL)) {
    MONITORINFO info{};
    info.cbSize = sizeof(info);
    ::GetMonitorInfo(::MonitorFromPoint(POINT{0, 0}, MONITOR_DEFAULTTOPRIMARY), &info);
    const double scale = Scale();
    if (width_ <= 0) width_ = static_cast<int>(kDefaultWidth * scale);
    x_ = (info.rcWork.left + info.rcWork.right - width_) / 2;
    y_ = info.rcWork.bottom - static_cast<int>(200 * scale);
  }
}

void LyricsWindow::ApplyLock() {
  if (!hwnd_) return;
  LONG_PTR ex = ::GetWindowLongPtr(hwnd_, GWL_EXSTYLE);
  ex = locked_ ? (ex | WS_EX_TRANSPARENT) : (ex & ~WS_EX_TRANSPARENT);
  ::SetWindowLongPtr(hwnd_, GWL_EXSTYLE, ex);
  if (locked_) hover_ = false;
}

void LyricsWindow::Render() {
  if (!hwnd_) return;
  using namespace Gdiplus;
  const double scale = Scale();
  auto s = [scale](double v) { return static_cast<float>(v * scale); };
  if (width_ <= 0) width_ = static_cast<int>(kDefaultWidth * scale);
  width_ = (std::max)(width_, static_cast<int>(kMinWidth * scale));
  const int w = width_;
  const float pad = s(kPad), gap = s(kGap);
  const float big = s(font_size_), small_size = s(font_size_ * 0.62);
  auto family = TextFamily();
  if (!family) return;

  StringFormat format;
  format.SetAlignment(StringAlignmentCenter);
  format.SetLineAlignment(StringAlignmentNear);
  format.SetTrimming(StringTrimmingWord);

  // Heights of the two lines, wrapped to the width.
  const float textW = w - 2 * pad;
  auto measure = [&](const std::wstring& text, float size) -> float {
    if (text.empty()) return 0;
    GraphicsPath path;
    path.AddString(text.c_str(), -1, family.get(), FontStyleRegular, size, RectF(0, 0, textW, 10000), &format);
    RectF bounds;
    path.GetBounds(&bounds);
    return (std::max)(bounds.GetBottom(), size);
  };
  const std::wstring& line = current_.empty() ? std::wstring(L"♪") : current_;
  const float h1 = measure(line, big) + s(4);
  const float h2 = measure(next_, small_size) + (next_.empty() ? 0 : s(4));
  const int h = static_cast<int>(pad + h1 + (next_.empty() ? 0 : gap + h2) + pad + 0.5f);

  // Per-pixel alpha: draw premultiplied BGRA straight into a DIB.
  BITMAPINFO bi{};
  bi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bi.bmiHeader.biWidth = w;
  bi.bmiHeader.biHeight = -h;  // top-down
  bi.bmiHeader.biPlanes = 1;
  bi.bmiHeader.biBitCount = 32;
  bi.bmiHeader.biCompression = BI_RGB;
  void* bits = nullptr;
  HDC screen = ::GetDC(nullptr);
  HDC mem = ::CreateCompatibleDC(screen);
  HBITMAP dib = ::CreateDIBSection(screen, &bi, DIB_RGB_COLORS, &bits, nullptr, 0);
  if (!dib || !bits) {
    if (dib) ::DeleteObject(dib);
    ::DeleteDC(mem);
    ::ReleaseDC(nullptr, screen);
    return;
  }
  HGDIOBJ old = ::SelectObject(mem, dib);
  {
    Bitmap canvas(w, h, w * 4, PixelFormat32bppPARGB, static_cast<BYTE*>(bits));
    Graphics g(&canvas);
    g.SetSmoothingMode(SmoothingModeAntiAlias);
    g.SetCompositingQuality(CompositingQualityHighQuality);
    g.Clear(Color(0, 0, 0, 0));

    // Background: the chosen see-through black. Never fully invisible while
    // it can be dragged (a pixel with no color takes no clicks); while the
    // mouse is over it, enough to show where it is.
    double alpha = opacity_;
    if (!locked_ && hover_) alpha = (std::max)(alpha, 0.4);
    BYTE a = static_cast<BYTE>(alpha * 255 + 0.5);
    if (!locked_ && a < 2) a = 2;
    GraphicsPath bg;
    AddRoundRect(bg, RectF(0.5f, 0.5f, w - 1.0f, h - 1.0f), s(kRadius));
    SolidBrush fill(Color(a, 14, 14, 16));
    g.FillPath(&fill, &bg);
    if (!locked_ && hover_) {
      Pen border(Color(60, 255, 255, 255), s(1));
      g.DrawPath(&border, &bg);
    }

    // Text: white with a soft dark edge, readable on any background.
    auto draw = [&](const std::wstring& text, float size, float top, BYTE textAlpha) {
      GraphicsPath path;
      path.AddString(text.c_str(), -1, family.get(), FontStyleRegular, size, RectF(pad, top, textW, 10000), &format);
      Pen edge(Color(static_cast<BYTE>(textAlpha * 0.6), 0, 0, 0), (std::max)(2.0f, size / 9));
      edge.SetLineJoin(LineJoinRound);
      g.DrawPath(&edge, &path);
      SolidBrush ink(Color(textAlpha, 255, 255, 255));
      g.FillPath(&ink, &path);
    };
    draw(line, big, pad, 255);
    if (!next_.empty()) draw(next_, small_size, pad + h1 + gap, 150);
  }

  POINT dst{x_, y_};
  SIZE size{w, h};
  POINT src{0, 0};
  BLENDFUNCTION blend{AC_SRC_OVER, 0, 255, AC_SRC_ALPHA};
  ::UpdateLayeredWindow(hwnd_, screen, &dst, &size, mem, &src, 0, &blend, ULW_ALPHA);
  ::SelectObject(mem, old);
  ::DeleteObject(dib);
  ::DeleteDC(mem);
  ::ReleaseDC(nullptr, screen);
}

void LyricsWindow::ShowMenu(POINT at) {
  auto label = [this](int i) { return i < static_cast<int>(labels_.size()) ? labels_[i].c_str() : kFallbackLabels[i]; };
  HMENU menu = ::CreatePopupMenu();
  ::AppendMenuW(menu, MF_STRING, kBigger, label(1));
  ::AppendMenuW(menu, MF_STRING, kSmaller, label(2));
  ::AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  ::AppendMenuW(menu, MF_STRING | (opacity_ <= 0.001 ? MF_GRAYED : 0), kMoreSeeThrough, label(3));
  ::AppendMenuW(menu, MF_STRING | (opacity_ >= 0.94 ? MF_GRAYED : 0), kLessSeeThrough, label(4));
  ::AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  ::AppendMenuW(menu, MF_STRING, kLock, label(0));
  ::AppendMenuW(menu, MF_STRING, kClose, label(5));
  // The menu needs a foreground window to close when clicking elsewhere.
  ::SetForegroundWindow(hwnd_);
  const int cmd = ::TrackPopupMenu(menu, TPM_RETURNCMD | TPM_RIGHTBUTTON | TPM_NONOTIFY, at.x, at.y, 0, hwnd_, nullptr);
  ::DestroyMenu(menu);
  switch (cmd) {
    case kBigger:
      font_size_ = (std::min)(96.0, font_size_ + 4);
      break;
    case kSmaller:
      font_size_ = (std::max)(14.0, font_size_ - 4);
      break;
    case kMoreSeeThrough:
      opacity_ = (std::max)(0.0, opacity_ - 0.15);
      if (opacity_ < 0.05) opacity_ = 0;
      break;
    case kLessSeeThrough:
      opacity_ = (std::min)(0.95, opacity_ + 0.15);
      break;
    case kLock:
      locked_ = true;
      ApplyLock();
      break;
    case kClose:
      visible_ = false;
      ::ShowWindow(hwnd_, SW_HIDE);
      if (channel_) channel_->InvokeMethod("closed", nullptr);
      return;
    default:
      return;
  }
  Render();
  SendStyle();
}

void LyricsWindow::SendStyle() {
  if (!channel_) return;
  channel_->InvokeMethod("style", std::make_unique<EncodableValue>(EncodableMap{
                                      {EncodableValue("fontSize"), EncodableValue(font_size_)},
                                      {EncodableValue("opacity"), EncodableValue(opacity_)},
                                      {EncodableValue("locked"), EncodableValue(locked_)},
                                  }));
}

void LyricsWindow::SendMoved() {
  if (!channel_) return;
  channel_->InvokeMethod("moved", std::make_unique<EncodableValue>(EncodableMap{
                                      {EncodableValue("x"), EncodableValue(x_)},
                                      {EncodableValue("y"), EncodableValue(y_)},
                                      {EncodableValue("w"), EncodableValue(width_)},
                                  }));
}

LRESULT CALLBACK LyricsWindow::WndProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) {
  if (msg == WM_NCCREATE) {
    auto* create = reinterpret_cast<CREATESTRUCT*>(lparam);
    ::SetWindowLongPtr(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(create->lpCreateParams));
  }
  auto* self = reinterpret_cast<LyricsWindow*>(::GetWindowLongPtr(hwnd, GWLP_USERDATA));
  if (self && self->hwnd_ == hwnd) return self->Handle(msg, wparam, lparam);
  return ::DefWindowProc(hwnd, msg, wparam, lparam);
}

LRESULT LyricsWindow::Handle(UINT msg, WPARAM wparam, LPARAM lparam) {
  switch (msg) {
    case WM_NCHITTEST: {
      if (locked_) return HTTRANSPARENT;
      POINT p{GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
      RECT r;
      ::GetWindowRect(hwnd_, &r);
      const int edge = static_cast<int>(kEdge * Scale());
      if (p.x < r.left + edge) return HTLEFT;
      if (p.x >= r.right - edge) return HTRIGHT;
      return HTCAPTION;  // drag anywhere to move
    }
    case WM_NCMOUSEMOVE:
    case WM_MOUSEMOVE:
      if (!hover_) {
        hover_ = true;
        TRACKMOUSEEVENT t{sizeof(t), TME_LEAVE | (msg == WM_NCMOUSEMOVE ? TME_NONCLIENT : 0u), hwnd_, 0};
        ::TrackMouseEvent(&t);
        Render();
      }
      break;
    case WM_NCMOUSELEAVE:
    case WM_MOUSELEAVE:
      if (hover_) {
        hover_ = false;
        Render();
      }
      break;
    case WM_NCRBUTTONUP:
    case WM_RBUTTONUP: {
      POINT p{GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
      if (msg == WM_RBUTTONUP) ::ClientToScreen(hwnd_, &p);
      ShowMenu(p);
      return 0;
    }
    case WM_NCLBUTTONDBLCLK:
      return 0;  // no maximize
    case WM_WINDOWPOSCHANGED: {
      const auto* pos = reinterpret_cast<const WINDOWPOS*>(lparam);
      if (!(pos->flags & SWP_NOMOVE)) {
        x_ = pos->x;
        y_ = pos->y;
      }
      if (!(pos->flags & SWP_NOSIZE) && pos->cx != width_) {
        width_ = pos->cx;
        Render();  // text wraps to the new width; the height follows
      }
      return 0;
    }
    case WM_EXITSIZEMOVE:
      SendMoved();
      return 0;
    case WM_DPICHANGED:
      Render();
      return 0;
    case WM_MOUSEACTIVATE:
      return MA_NOACTIVATE;  // never take the focus from a game or another app
  }
  return ::DefWindowProc(hwnd_, msg, wparam, lparam);
}
