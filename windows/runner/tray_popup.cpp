#include "tray_popup.h"

#include <algorithm>
#include <dwmapi.h>
#include <objidl.h>
#include <windowsx.h>

// The runner builds with NOMINMAX; GDI+ headers still want min/max.
namespace Gdiplus {
using std::max;
using std::min;
}  // namespace Gdiplus
#include <gdiplus.h>

#include <flutter_windows.h>

namespace {

constexpr wchar_t kClassName[] = L"PRISM_TRAY_POPUP";

// Base sizes at 96 dpi.
constexpr int kWidth = 288;
constexpr int kPad = 12;
constexpr int kCover = 48;
constexpr int kButton = 40;
constexpr int kPlayButton = 44;
constexpr int kRow = 36;

// Colors: the app's black & white look; the amber LED marks "playing".
const Gdiplus::Color kBackground(255, 22, 22, 24);
const Gdiplus::Color kText(255, 245, 245, 245);
const Gdiplus::Color kMuted(150, 245, 245, 245);
const Gdiplus::Color kHover(22, 255, 255, 255);
const Gdiplus::Color kPressed(40, 255, 255, 255);
const Gdiplus::Color kLine(24, 255, 255, 255);
const Gdiplus::Color kLed(255, 255, 176, 32);

// Icon font glyphs for the rows (Windows 11 font first, Windows 10 one as the fallback).
constexpr wchar_t kGlyphOpen[] = L"\xE8A7";
constexpr wchar_t kGlyphQuit[] = L"\xE7E8";
constexpr wchar_t kGlyphMusic[] = L"\xE8D6";

void AddRoundRect(Gdiplus::GraphicsPath& path, Gdiplus::RectF r, float radius) {
  const float d = radius * 2;
  path.AddArc(r.X, r.Y, d, d, 180, 90);
  path.AddArc(r.X + r.Width - d, r.Y, d, d, 270, 90);
  path.AddArc(r.X + r.Width - d, r.Y + r.Height - d, d, d, 0, 90);
  path.AddArc(r.X, r.Y + r.Height - d, d, d, 90, 90);
  path.CloseFigure();
}

Gdiplus::RectF ToF(const RECT& r) {
  return Gdiplus::RectF(static_cast<float>(r.left), static_cast<float>(r.top), static_cast<float>(r.right - r.left),
                        static_cast<float>(r.bottom - r.top));
}

bool Inside(const RECT& r, POINT p) { return p.x >= r.left && p.x < r.right && p.y >= r.top && p.y < r.bottom; }

std::unique_ptr<Gdiplus::FontFamily> IconFamily() {
  for (const wchar_t* name : {L"Segoe Fluent Icons", L"Segoe MDL2 Assets"}) {
    auto family = std::make_unique<Gdiplus::FontFamily>(name);
    if (family->GetLastStatus() == Gdiplus::Ok) return family;
  }
  return nullptr;
}

}  // namespace

TrayPopup::TrayPopup(std::function<void(const char*)> on_action) : on_action_(std::move(on_action)) {
  Gdiplus::GdiplusStartupInput input;
  Gdiplus::GdiplusStartup(&gdiplus_token_, &input, nullptr);
}

TrayPopup::~TrayPopup() {
  if (hwnd_) ::DestroyWindow(hwnd_);
  art_.reset();
  if (gdiplus_token_) Gdiplus::GdiplusShutdown(gdiplus_token_);
}

void TrayPopup::EnsureWindow() {
  if (hwnd_) return;
  static bool registered = false;
  if (!registered) {
    WNDCLASSEXW wc{};
    wc.cbSize = sizeof(wc);
    wc.style = CS_DROPSHADOW;
    wc.lpfnWndProc = WndProc;
    wc.hInstance = ::GetModuleHandleW(nullptr);
    wc.hCursor = ::LoadCursorW(nullptr, IDC_ARROW);
    wc.lpszClassName = kClassName;
    ::RegisterClassExW(&wc);
    registered = true;
  }
  hwnd_ = ::CreateWindowExW(WS_EX_TOOLWINDOW | WS_EX_TOPMOST, kClassName, L"Prism", WS_POPUP, 0, 0, 10, 10, nullptr,
                            nullptr, ::GetModuleHandleW(nullptr), this);
  // Windows 11: rounded corners, a dark frame and a thin border like its own flyouts.
  const DWORD round = 2;  // DWMWCP_ROUND
  ::DwmSetWindowAttribute(hwnd_, 33 /* DWMWA_WINDOW_CORNER_PREFERENCE */, &round, sizeof(round));
  const BOOL dark = TRUE;
  ::DwmSetWindowAttribute(hwnd_, 20 /* DWMWA_USE_IMMERSIVE_DARK_MODE */, &dark, sizeof(dark));
  const COLORREF border = RGB(58, 58, 60);
  ::DwmSetWindowAttribute(hwnd_, 34 /* DWMWA_BORDER_COLOR */, &border, sizeof(border));
}

void TrayPopup::Layout() {
  auto s = [this](int v) { return static_cast<int>(v * scale_ + 0.5); };
  const int w = s(kWidth), pad = s(kPad);
  int y = pad;
  cover_ = {pad, y, pad + s(kCover), y + s(kCover)};
  y += s(kCover) + s(10);
  // Controls, centered.
  const int b = s(kButton), play = s(kPlayButton), gap = s(14);
  const int total = b * 2 + play + gap * 2;
  int x = (w - total) / 2;
  const int mid = y + play / 2;
  parts_[kPrevious] = {x, mid - b / 2, x + b, mid + b / 2};
  x += b + gap;
  parts_[kToggle] = {x, y, x + play, y + play};
  x += play + gap;
  parts_[kNext] = {x, mid - b / 2, x + b, mid + b / 2};
  y += play + s(10);
  y += s(1) + s(6);  // line
  const int inset = s(6);
  parts_[kOpen] = {inset, y, w - inset, y + s(kRow)};
  y += s(kRow);
  parts_[kQuit] = {inset, y, w - inset, y + s(kRow)};
  y += s(kRow) + s(6);
  size_ = {w, y};
}

void TrayPopup::ShowAt(POINT anchor) {
  EnsureWindow();
  HMONITOR monitor = ::MonitorFromPoint(anchor, MONITOR_DEFAULTTONEAREST);
  scale_ = FlutterDesktopGetDpiForMonitor(monitor) / 96.0;
  Layout();
  MONITORINFO info{};
  info.cbSize = sizeof(info);
  ::GetMonitorInfo(monitor, &info);
  const RECT& work = info.rcWork;
  // Above and to the left of the cursor (the taskbar is usually at the bottom
  // right), kept inside the work area wherever the taskbar is.
  const int gap = static_cast<int>(8 * scale_);
  int x = anchor.x - size_.cx + gap * 2;
  int y = anchor.y - size_.cy - gap;
  x = std::clamp(x, static_cast<int>(work.left + gap), static_cast<int>(work.right - size_.cx - gap));
  y = std::clamp(y, static_cast<int>(work.top + gap), static_cast<int>(work.bottom - size_.cy - gap));
  hover_ = down_ = kNone;
  ::SetWindowPos(hwnd_, HWND_TOPMOST, x, y, size_.cx, size_.cy, SWP_SHOWWINDOW);
  // Focus is how it knows to close when the user clicks elsewhere.
  ::SetForegroundWindow(hwnd_);
  ::InvalidateRect(hwnd_, nullptr, FALSE);
}

void TrayPopup::Update(const TrayPopupState& state) {
  state_ = state;
  if (state_.art_path != loaded_art_) LoadArt();
  if (visible()) ::InvalidateRect(hwnd_, nullptr, FALSE);
}

void TrayPopup::LoadArt() {
  loaded_art_ = state_.art_path;
  art_.reset();
  if (state_.art_path.empty() || ::GetFileAttributesW(state_.art_path.c_str()) == INVALID_FILE_ATTRIBUTES) return;
  // Copy into a small bitmap right away: GDI+ keeps the file open otherwise.
  Gdiplus::Bitmap source(state_.art_path.c_str());
  if (source.GetLastStatus() != Gdiplus::Ok) return;
  constexpr int px = 144;
  auto copy = std::make_unique<Gdiplus::Bitmap>(px, px, PixelFormat32bppPARGB);
  Gdiplus::Graphics g(copy.get());
  g.SetInterpolationMode(Gdiplus::InterpolationModeHighQualityBicubic);
  // Center crop to a square.
  const UINT w = source.GetWidth(), h = source.GetHeight();
  const UINT side = std::min(w, h);
  g.DrawImage(&source, Gdiplus::Rect(0, 0, px, px), static_cast<INT>((w - side) / 2), static_cast<INT>((h - side) / 2),
              static_cast<INT>(side), static_cast<INT>(side), Gdiplus::UnitPixel);
  art_ = std::move(copy);
}

void TrayPopup::Close() {
  if (hwnd_) ::ShowWindow(hwnd_, SW_HIDE);
}

TrayPopup::Part TrayPopup::HitTest(POINT p) const {
  for (int i = 0; i < kPartCount; ++i) {
    if (Inside(parts_[i], p)) return static_cast<Part>(i);
  }
  return kNone;
}

void TrayPopup::Press(Part part) {
  switch (part) {
    case kPrevious:
      on_action_("previous");
      break;
    case kToggle:
      // Flip right away; Dart confirms with the real state a moment later.
      state_.playing = !state_.playing;
      ::InvalidateRect(hwnd_, nullptr, FALSE);
      on_action_("toggle");
      break;
    case kNext:
      on_action_("next");
      break;
    case kOpen:
      Close();
      on_action_("open");
      break;
    case kQuit:
      Close();
      on_action_("quit");
      break;
    default:
      break;
  }
}

void TrayPopup::Paint(HDC hdc) {
  using namespace Gdiplus;
  Bitmap buffer(size_.cx, size_.cy, PixelFormat32bppPARGB);
  Graphics g(&buffer);
  g.SetSmoothingMode(SmoothingModeAntiAlias);
  // Grayscale: ClearType fringes turn blue on a drawn-then-copied buffer.
  g.SetTextRenderingHint(TextRenderingHintAntiAliasGridFit);
  g.SetPixelOffsetMode(PixelOffsetModeHalf);
  g.Clear(kBackground);

  const float sc = static_cast<float>(scale_);
  FontFamily text_family(L"Segoe UI Variable Text");
  const FontFamily& family = text_family.GetLastStatus() == Ok ? text_family : *FontFamily::GenericSansSerif();
  FontFamily semibold_family(L"Segoe UI Semibold");
  Font title_font(semibold_family.GetLastStatus() == Ok ? &semibold_family : &family, 14 * sc, FontStyleRegular,
                  UnitPixel);
  Font small_font(&family, 12.5f * sc, FontStyleRegular, UnitPixel);
  Font row_font(&family, 13.5f * sc, FontStyleRegular, UnitPixel);
  auto icons = IconFamily();

  StringFormat one_line;
  one_line.SetFormatFlags(StringFormatFlagsNoWrap);
  one_line.SetTrimming(StringTrimmingEllipsisCharacter);
  one_line.SetLineAlignment(StringAlignmentCenter);
  StringFormat centered;
  centered.SetAlignment(StringAlignmentCenter);
  centered.SetLineAlignment(StringAlignmentCenter);

  SolidBrush text(kText), muted(kMuted);

  // Cover (or a music note on a soft square) and the song.
  {
    GraphicsPath clip;
    AddRoundRect(clip, ToF(cover_), 8 * sc);
    if (art_) {
      g.SetClip(&clip);
      g.DrawImage(art_.get(), ToF(cover_));
      g.ResetClip();
    } else {
      SolidBrush soft(kHover);
      g.FillPath(&soft, &clip);
      if (icons) {
        Font glyph(icons.get(), 18 * sc, FontStyleRegular, UnitPixel);
        g.DrawString(kGlyphMusic, -1, &glyph, ToF(cover_), &centered, &muted);
      }
    }
    const float left = static_cast<float>(cover_.right) + 12 * sc;
    const float width = size_.cx - left - kPad * sc;
    const float top = static_cast<float>(cover_.top);
    const std::wstring title = state_.has_track ? state_.title : L"Prism";
    if (state_.has_track && !state_.artist.empty()) {
      g.DrawString(title.c_str(), -1, &title_font, RectF(left, top + 4 * sc, width, 20 * sc), &one_line, &text);
      g.DrawString(state_.artist.c_str(), -1, &small_font, RectF(left, top + 25 * sc, width, 18 * sc), &one_line,
                   &muted);
    } else {
      g.DrawString(title.c_str(), -1, &title_font, RectF(left, top, width, kCover * sc), &one_line, &text);
    }
    if (state_.playing) {
      // The one accent: a small amber light while music plays.
      SolidBrush led(kLed);
      const float r = 3 * sc;
      g.FillEllipse(&led, size_.cx - kPad * sc - r * 2, top + 4 * sc, r * 2, r * 2);
    }
  }

  // Playback buttons, drawn as filled shapes (icon fonts only have outlines).
  enum class Shape { kPrevious, kPlay, kPause, kNext };
  auto shape = [&](Shape kind, RectF r, Brush* brush) {
    const float cx = r.X + r.Width / 2, cy = r.Y + r.Height / 2;
    Pen round(brush, 2.2f * sc);
    round.SetLineJoin(LineJoinRound);
    auto triangle = [&](float tip_x, float base_x, float half_h) {
      GraphicsPath p;
      PointF pts[3] = {PointF(base_x, cy - half_h), PointF(tip_x, cy), PointF(base_x, cy + half_h)};
      p.AddPolygon(pts, 3);
      g.FillPath(brush, &p);
      g.DrawPath(&round, &p);  // the round pen softens the corners
    };
    auto bar = [&](float x, float w, float half_h) {
      GraphicsPath p;
      AddRoundRect(p, RectF(x, cy - half_h, w, half_h * 2), w / 2);
      g.FillPath(brush, &p);
    };
    const float u = 5.5f * sc;
    switch (kind) {
      case Shape::kPlay:
        // A little right of center: a triangle looks centered that way.
        triangle(cx + u * 1.25f, cx - u * 0.75f, u * 1.15f);
        break;
      case Shape::kPause:
        bar(cx - u * 0.95f, u * 0.62f, u * 1.15f);
        bar(cx + u * 0.33f, u * 0.62f, u * 1.15f);
        break;
      case Shape::kPrevious:
        bar(cx - u * 1.0f, u * 0.4f, u * 0.95f);
        triangle(cx - u * 0.45f, cx + u * 0.9f, u * 0.9f);
        break;
      case Shape::kNext:
        bar(cx + u * 0.6f, u * 0.4f, u * 0.95f);
        triangle(cx + u * 0.45f, cx - u * 0.9f, u * 0.9f);
        break;
    }
  };
  auto button = [&](Part part, Shape kind) {
    const RectF r = ToF(parts_[part]);
    if (part == kToggle) {
      // The main button: a filled light circle, like the app's play button.
      SolidBrush fill(down_ == part ? Color(255, 205, 205, 205) : hover_ == part ? Color(255, 255, 255, 255)
                                                                                    : Color(255, 236, 236, 236));
      g.FillEllipse(&fill, r);
      SolidBrush dark(Color(255, 20, 20, 22));
      shape(kind, r, &dark);
      return;
    }
    if (hover_ == part || down_ == part) {
      SolidBrush fill(down_ == part ? kPressed : kHover);
      g.FillEllipse(&fill, r);
    }
    SolidBrush ink(hover_ == part ? kText : Color(200, 245, 245, 245));
    shape(kind, r, &ink);
  };
  button(kPrevious, Shape::kPrevious);
  button(kToggle, state_.playing ? Shape::kPause : Shape::kPlay);
  button(kNext, Shape::kNext);

  // Divider.
  {
    const float y = static_cast<float>(parts_[kOpen].top) - 6 * sc - 1 * sc;
    Pen line(kLine, 1 * sc);
    g.DrawLine(&line, kPad * sc, y, size_.cx - kPad * sc, y);
  }

  // Rows.
  auto row = [&](Part part, const wchar_t* glyph, const std::wstring& label) {
    const RectF r = ToF(parts_[part]);
    if (hover_ == part || down_ == part) {
      GraphicsPath bg;
      AddRoundRect(bg, r, 6 * sc);
      SolidBrush fill(down_ == part ? kPressed : kHover);
      g.FillPath(&fill, &bg);
    }
    const float icon_left = r.X + 10 * sc;
    if (icons) {
      Font f(icons.get(), 14 * sc, FontStyleRegular, UnitPixel);
      g.DrawString(glyph, -1, &f, RectF(icon_left, r.Y, 20 * sc, r.Height), &centered, &muted);
    }
    g.DrawString(label.c_str(), -1, &row_font, RectF(icon_left + 30 * sc, r.Y, r.Width - 50 * sc, r.Height),
                 &one_line, &text);
  };
  row(kOpen, kGlyphOpen, state_.show_label);
  row(kQuit, kGlyphQuit, state_.quit_label);

  Graphics screen(hdc);
  screen.DrawImage(&buffer, 0, 0);
}

LRESULT CALLBACK TrayPopup::WndProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  if (message == WM_NCCREATE) {
    auto* create = reinterpret_cast<CREATESTRUCTW*>(lparam);
    ::SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(create->lpCreateParams));
  }
  auto* self = reinterpret_cast<TrayPopup*>(::GetWindowLongPtrW(hwnd, GWLP_USERDATA));
  if (self && self->hwnd_ == hwnd) return self->Handle(message, wparam, lparam);
  return ::DefWindowProcW(hwnd, message, wparam, lparam);
}

LRESULT TrayPopup::Handle(UINT message, WPARAM wparam, LPARAM lparam) {
  switch (message) {
    case WM_PAINT: {
      PAINTSTRUCT ps;
      HDC hdc = ::BeginPaint(hwnd_, &ps);
      Paint(hdc);
      ::EndPaint(hwnd_, &ps);
      return 0;
    }
    case WM_ERASEBKGND:
      return 1;
    case WM_ACTIVATE:
      if (LOWORD(wparam) == WA_INACTIVE) Close();
      return 0;
    case WM_KEYDOWN:
      if (wparam == VK_ESCAPE) Close();
      return 0;
    case WM_MOUSEMOVE: {
      if (!tracking_) {
        TRACKMOUSEEVENT tme{sizeof(tme), TME_LEAVE, hwnd_, 0};
        ::TrackMouseEvent(&tme);
        tracking_ = true;
      }
      const Part part = HitTest({GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)});
      if (part != hover_) {
        hover_ = part;
        ::SetCursor(::LoadCursorW(nullptr, part == kNone ? IDC_ARROW : IDC_HAND));
        ::InvalidateRect(hwnd_, nullptr, FALSE);
      }
      return 0;
    }
    case WM_MOUSELEAVE:
      tracking_ = false;
      hover_ = down_ = kNone;
      ::InvalidateRect(hwnd_, nullptr, FALSE);
      return 0;
    case WM_LBUTTONDOWN:
      down_ = HitTest({GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)});
      ::InvalidateRect(hwnd_, nullptr, FALSE);
      return 0;
    case WM_LBUTTONUP: {
      const Part part = HitTest({GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)});
      const Part pressed = down_;
      down_ = kNone;
      ::InvalidateRect(hwnd_, nullptr, FALSE);
      if (part != kNone && part == pressed) Press(part);
      return 0;
    }
    case WM_SETCURSOR:
      if (LOWORD(lparam) == HTCLIENT) {
        ::SetCursor(::LoadCursorW(nullptr, hover_ == kNone ? IDC_ARROW : IDC_HAND));
        return TRUE;
      }
      break;
    default:
      break;
  }
  return ::DefWindowProcW(hwnd_, message, wparam, lparam);
}
