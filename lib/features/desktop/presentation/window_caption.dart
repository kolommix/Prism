import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/theme/prism_theme_extensions.dart';
import '../../player/platform/windows_fullscreen.dart';
import '../../../l10n/l10n.dart';

/// Height of the in-app title bar on Windows.
const double captionHeight = 32;

/// Windows hides its own title bar, so the app is one surface up to the top
/// edge. This puts the space back: the strip at the top moves the window
/// (double-click maximizes) and has the three window buttons in the app's own
/// colors. Pages see it as top padding (like a phone's status bar), so app
/// bars and the shell stay clear of it. Gone in full screen.
class WindowCaption extends StatelessWidget {
  const WindowCaption({super.key, required this.child});

  final Widget child;

  static bool get enabled => Platform.isWindows;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return ValueListenableBuilder<bool>(
      valueListenable: WindowsFullScreen.active,
      builder: (context, full, _) {
        if (full) return child;
        final media = MediaQuery.of(context);
        return Stack(
          children: [
            MediaQuery(
              data: media.copyWith(padding: media.padding.copyWith(top: media.padding.top + captionHeight)),
              child: child,
            ),
            const Positioned(top: 0, left: 0, right: 0, height: captionHeight, child: _CaptionBar()),
          ],
        );
      },
    );
  }
}

class _CaptionBar extends StatefulWidget {
  const _CaptionBar();

  @override
  State<_CaptionBar> createState() => _CaptionBarState();
}

class _CaptionBarState extends State<_CaptionBar> with WindowListener {
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.isMaximized().then((m) {
      if (mounted) setState(() => _maximized = m);
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  @override
  Widget build(BuildContext context) {
    // The first frame can come before the window has a size.
    return LayoutBuilder(builder: (context, box) => box.maxWidth < 160 ? const SizedBox.shrink() : _bar());
  }

  Widget _bar() {
    return Row(
      children: [
        // Transparent: the app's background shows through, nothing is drawn here.
        const Expanded(child: DragToMoveArea(child: SizedBox.expand())),
        _CaptionButton(tooltip: l10n.windowMinimize, icon: Icons.remove_rounded, onPressed: windowManager.minimize),
        _CaptionButton(
          tooltip: _maximized ? l10n.windowRestore : l10n.windowMaximize,
          icon: _maximized ? Icons.filter_none_rounded : Icons.crop_square_rounded,
          iconSize: _maximized ? 12 : 14,
          onPressed: () => _maximized ? windowManager.unmaximize() : windowManager.maximize(),
        ),
        _CaptionButton(tooltip: l10n.close, icon: Icons.close_rounded, onPressed: windowManager.close, close: true),
      ],
    );
  }
}

class _CaptionButton extends StatefulWidget {
  const _CaptionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.iconSize = 16,
    this.close = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final double iconSize;

  /// Windows paints the close button red on hover; people look for that.
  final bool close;

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final on = Theme.of(context).colorScheme.onSurface;
    final Color fill;
    final Color fg;
    if (widget.close && (_hover || _down)) {
      fill = _down ? const Color(0xFFB0202A) : const Color(0xFFC42B1C);
      fg = Colors.white;
    } else {
      fill = on.withValues(alpha: _down ? 0.14 : (_hover ? 0.08 : 0));
      fg = on.withValues(alpha: _hover ? 0.95 : 0.7);
    }
    final button = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = _down = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTap: () {
          setState(() => _down = false);
          widget.onPressed();
        },
        child: AnimatedContainer(
          duration: context.motion.d(const Duration(milliseconds: 120)),
          curve: PrismMotion.curve,
          width: 46,
          height: captionHeight,
          color: fill,
          child: Icon(widget.icon, size: widget.iconSize, color: fg),
        ),
      ),
    );
    // The strip sits above the pages, outside any Overlay: a Tooltip there
    // has nowhere to show (it threw in debug builds). Hover names only where
    // an Overlay exists.
    if (Overlay.maybeOf(context) == null) {
      return Semantics(label: widget.tooltip, button: true, child: button);
    }
    return Tooltip(message: widget.tooltip, waitDuration: const Duration(milliseconds: 600), child: button);
  }
}
