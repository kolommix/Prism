import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';

/// What a hotkey does.
enum HotkeyAction {
  playPause,
  next,
  previous,
  volumeUp,
  volumeDown,
  mute,
  seekForward,
  seekBack,
  lyricsWindow,
  showPrism;

  String get label => switch (this) {
        playPause => l10n.hotkeyPlayPause,
        next => l10n.hotkeyNext,
        previous => l10n.hotkeyPrevious,
        volumeUp => l10n.hotkeyVolumeUp,
        volumeDown => l10n.hotkeyVolumeDown,
        mute => l10n.hotkeyMute,
        seekForward => l10n.hotkeySeekForward,
        seekBack => l10n.hotkeySeekBack,
        lyricsWindow => l10n.hotkeyLyricsWindow,
        showPrism => l10n.hotkeyShowPrism,
      };

  /// Keeps going while the keys are held.
  bool get repeats => this == volumeUp || this == volumeDown || this == seekForward || this == seekBack;

  static HotkeyAction? byName(String name) => values.where((a) => a.name == name).firstOrNull;
}

/// A key with modifiers, as Windows' RegisterHotKey wants it.
class HotkeyCombo {
  const HotkeyCombo(this.vk, {this.ctrl = false, this.alt = false, this.shift = false, this.win = false});

  /// Windows virtual-key code.
  final int vk;
  final bool ctrl, alt, shift, win;

  /// RegisterHotKey modifier bits: 1 Alt, 2 Ctrl, 4 Shift, 8 Win.
  int get mods => (alt ? 1 : 0) | (ctrl ? 2 : 0) | (shift ? 4 : 0) | (win ? 8 : 0);

  /// A plain key alone would take that key away from every other app.
  bool get valid => mods != 0 || (vk >= 0x70 && vk <= 0x87);

  String get label => [
        if (ctrl) 'Ctrl',
        if (alt) 'Alt',
        if (shift) 'Shift',
        if (win) 'Win',
        vkLabel(vk),
      ].join(' + ');

  String encode() => '$mods:$vk';

  static HotkeyCombo? decode(String? s) {
    final parts = s?.split(':');
    if (parts == null || parts.length != 2) return null;
    final mods = int.tryParse(parts[0]), vk = int.tryParse(parts[1]);
    if (mods == null || vk == null || vk <= 0) return null;
    return HotkeyCombo(vk, alt: mods & 1 != 0, ctrl: mods & 2 != 0, shift: mods & 4 != 0, win: mods & 8 != 0);
  }

  @override
  bool operator ==(Object other) => other is HotkeyCombo && other.vk == vk && other.mods == mods;

  @override
  int get hashCode => Object.hash(vk, mods);
}

/// Ctrl + Alt + a key: easy to reach. Not Ctrl + Alt + Space or M: other apps
/// (graphics and keyboard tools) often hold those.
final Map<HotkeyAction, HotkeyCombo> defaultHotkeys = {
  HotkeyAction.playPause: const HotkeyCombo(0x50, ctrl: true, alt: true), // P
  HotkeyAction.next: const HotkeyCombo(0x27, ctrl: true, alt: true), // →
  HotkeyAction.previous: const HotkeyCombo(0x25, ctrl: true, alt: true), // ←
  HotkeyAction.volumeUp: const HotkeyCombo(0x26, ctrl: true, alt: true), // ↑
  HotkeyAction.volumeDown: const HotkeyCombo(0x28, ctrl: true, alt: true), // ↓
  HotkeyAction.mute: const HotkeyCombo(0x23, ctrl: true, alt: true), // End
  HotkeyAction.seekForward: const HotkeyCombo(0x27, ctrl: true, alt: true, shift: true),
  HotkeyAction.seekBack: const HotkeyCombo(0x25, ctrl: true, alt: true, shift: true),
  HotkeyAction.lyricsWindow: const HotkeyCombo(0x4C, ctrl: true, alt: true), // L
  HotkeyAction.showPrism: const HotkeyCombo(0x4F, ctrl: true, alt: true), // O
};

String vkLabel(int vk) {
  if (vk >= 0x41 && vk <= 0x5A) return String.fromCharCode(vk);
  if (vk >= 0x30 && vk <= 0x39) return String.fromCharCode(vk);
  if (vk >= 0x70 && vk <= 0x87) return 'F${vk - 0x6F}';
  if (vk >= 0x60 && vk <= 0x69) return 'Num ${vk - 0x60}';
  return switch (vk) {
    0x20 => l10n.keySpace,
    0x25 => '←',
    0x26 => '↑',
    0x27 => '→',
    0x28 => '↓',
    0x21 => 'PgUp',
    0x22 => 'PgDn',
    0x23 => 'End',
    0x24 => 'Home',
    0x2D => 'Ins',
    0x2E => 'Del',
    0x13 => 'Pause',
    0x91 => 'ScrLk',
    0x6A => 'Num *',
    0x6B => 'Num +',
    0x6D => 'Num -',
    0x6E => 'Num .',
    0x6F => 'Num /',
    0xBA => ';',
    0xBB => '=',
    0xBC => ',',
    0xBD => '-',
    0xBE => '.',
    0xBF => '/',
    0xC0 => '`',
    0xDB => '[',
    0xDC => r'\',
    0xDD => ']',
    0xDE => "'",
    _ => '#$vk',
  };
}

/// Windows virtual-key code of a key by its place on the keyboard (so the
/// Russian layout gives the same keys), or null for keys hotkeys don't take.
int? vkForPhysicalKey(PhysicalKeyboardKey k) {
  const letters = [
    PhysicalKeyboardKey.keyA, PhysicalKeyboardKey.keyB, PhysicalKeyboardKey.keyC, PhysicalKeyboardKey.keyD, //
    PhysicalKeyboardKey.keyE, PhysicalKeyboardKey.keyF, PhysicalKeyboardKey.keyG, PhysicalKeyboardKey.keyH,
    PhysicalKeyboardKey.keyI, PhysicalKeyboardKey.keyJ, PhysicalKeyboardKey.keyK, PhysicalKeyboardKey.keyL,
    PhysicalKeyboardKey.keyM, PhysicalKeyboardKey.keyN, PhysicalKeyboardKey.keyO, PhysicalKeyboardKey.keyP,
    PhysicalKeyboardKey.keyQ, PhysicalKeyboardKey.keyR, PhysicalKeyboardKey.keyS, PhysicalKeyboardKey.keyT,
    PhysicalKeyboardKey.keyU, PhysicalKeyboardKey.keyV, PhysicalKeyboardKey.keyW, PhysicalKeyboardKey.keyX,
    PhysicalKeyboardKey.keyY, PhysicalKeyboardKey.keyZ,
  ];
  final li = letters.indexOf(k);
  if (li >= 0) return 0x41 + li;
  const digits = [
    PhysicalKeyboardKey.digit0, PhysicalKeyboardKey.digit1, PhysicalKeyboardKey.digit2, PhysicalKeyboardKey.digit3, //
    PhysicalKeyboardKey.digit4, PhysicalKeyboardKey.digit5, PhysicalKeyboardKey.digit6, PhysicalKeyboardKey.digit7,
    PhysicalKeyboardKey.digit8, PhysicalKeyboardKey.digit9,
  ];
  final di = digits.indexOf(k);
  if (di >= 0) return 0x30 + di;
  const fkeys = [
    PhysicalKeyboardKey.f1, PhysicalKeyboardKey.f2, PhysicalKeyboardKey.f3, PhysicalKeyboardKey.f4, //
    PhysicalKeyboardKey.f5, PhysicalKeyboardKey.f6, PhysicalKeyboardKey.f7, PhysicalKeyboardKey.f8,
    PhysicalKeyboardKey.f9, PhysicalKeyboardKey.f10, PhysicalKeyboardKey.f11, PhysicalKeyboardKey.f12,
    PhysicalKeyboardKey.f13, PhysicalKeyboardKey.f14, PhysicalKeyboardKey.f15, PhysicalKeyboardKey.f16,
    PhysicalKeyboardKey.f17, PhysicalKeyboardKey.f18, PhysicalKeyboardKey.f19, PhysicalKeyboardKey.f20,
    PhysicalKeyboardKey.f21, PhysicalKeyboardKey.f22, PhysicalKeyboardKey.f23, PhysicalKeyboardKey.f24,
  ];
  final fi = fkeys.indexOf(k);
  if (fi >= 0) return 0x70 + fi;
  const numpad = [
    PhysicalKeyboardKey.numpad0, PhysicalKeyboardKey.numpad1, PhysicalKeyboardKey.numpad2, //
    PhysicalKeyboardKey.numpad3, PhysicalKeyboardKey.numpad4, PhysicalKeyboardKey.numpad5,
    PhysicalKeyboardKey.numpad6, PhysicalKeyboardKey.numpad7, PhysicalKeyboardKey.numpad8,
    PhysicalKeyboardKey.numpad9,
  ];
  final ni = numpad.indexOf(k);
  if (ni >= 0) return 0x60 + ni;
  final other = <PhysicalKeyboardKey, int>{
    PhysicalKeyboardKey.space: 0x20,
    PhysicalKeyboardKey.arrowLeft: 0x25,
    PhysicalKeyboardKey.arrowUp: 0x26,
    PhysicalKeyboardKey.arrowRight: 0x27,
    PhysicalKeyboardKey.arrowDown: 0x28,
    PhysicalKeyboardKey.pageUp: 0x21,
    PhysicalKeyboardKey.pageDown: 0x22,
    PhysicalKeyboardKey.end: 0x23,
    PhysicalKeyboardKey.home: 0x24,
    PhysicalKeyboardKey.insert: 0x2D,
    PhysicalKeyboardKey.delete: 0x2E,
    PhysicalKeyboardKey.pause: 0x13,
    PhysicalKeyboardKey.scrollLock: 0x91,
    PhysicalKeyboardKey.numpadMultiply: 0x6A,
    PhysicalKeyboardKey.numpadAdd: 0x6B,
    PhysicalKeyboardKey.numpadSubtract: 0x6D,
    PhysicalKeyboardKey.numpadDecimal: 0x6E,
    PhysicalKeyboardKey.numpadDivide: 0x6F,
    PhysicalKeyboardKey.semicolon: 0xBA,
    PhysicalKeyboardKey.equal: 0xBB,
    PhysicalKeyboardKey.comma: 0xBC,
    PhysicalKeyboardKey.minus: 0xBD,
    PhysicalKeyboardKey.period: 0xBE,
    PhysicalKeyboardKey.slash: 0xBF,
    PhysicalKeyboardKey.backquote: 0xC0,
    PhysicalKeyboardKey.bracketLeft: 0xDB,
    PhysicalKeyboardKey.backslash: 0xDC,
    PhysicalKeyboardKey.bracketRight: 0xDD,
    PhysicalKeyboardKey.quote: 0xDE,
  };
  return other[k];
}
