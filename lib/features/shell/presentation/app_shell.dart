import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/prism_theme_extensions.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/led_dot.dart';
import '../../background/presentation/prism_background.dart';
import '../../player/application/player_providers.dart';
import '../../player/presentation/desktop_player_bar.dart';
import '../../player/presentation/mini_player.dart';
import '../../player/presentation/now_playing_panel.dart';
import '../../together/application/together_controller.dart';
import '../../together/presentation/together_sheet.dart';
import 'prism_logo.dart';
import '../../../l10n/l10n.dart';

/// Breakpoints for the responsive layout.
abstract final class Breakpoints {
  /// Below this: phone layout (bottom nav + mini-player).
  static const sidebar = 760.0;

  /// From this width the now-playing panel is shown next to the content.
  static const nowPlayingPanel = 1180.0;
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

List<_Destination> get _destinations => [
  _Destination(l10n.xLibrary, Icons.library_music_outlined, Icons.library_music_rounded),
  _Destination(l10n.search, Icons.search_rounded, Icons.manage_search_rounded),
  _Destination(l10n.playlists2, Icons.queue_music_outlined, Icons.queue_music_rounded),
  _Destination(l10n.stats, Icons.insights_outlined, Icons.insights_rounded),
  _Destination(l10n.settings, Icons.tune_outlined, Icons.tune_rounded),
];

/// Top-level scaffold that adapts to the window size.
///
/// * **Phone**: content + glass mini-player + glass bottom navigation.
/// * **Desktop/tablet**: sidebar | content | (optional) now-playing panel,
///   with a full-width player bar at the bottom.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell, required this.children});

  final StatefulNavigationShell shell;

  /// One navigator per branch (kept alive).
  final List<Widget> children;

  void _go(int index) => shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final art = ref.watch(currentTrackProvider.select((t) => t?.artworkPath));
    final hasTrack = ref.watch(currentTrackProvider.select((t) => t != null));
    final content = _FadingBranches(index: shell.currentIndex, children: children);

    return PrismBackground(
      artworkPath: art,
      intensity: 0.35,
      child: width < Breakpoints.sidebar
          ? _PhoneLayout(content: content, index: shell.currentIndex, onSelect: _go, hasTrack: hasTrack)
          : _WideLayout(
              content: content,
              index: shell.currentIndex,
              onSelect: _go,
              hasTrack: hasTrack,
              showPanel: width >= Breakpoints.nowPlayingPanel,
            ),
    );
  }
}

class _PhoneLayout extends StatelessWidget {
  const _PhoneLayout({required this.content, required this.index, required this.onSelect, required this.hasTrack});

  final Widget content;
  final int index;
  final ValueChanged<int> onSelect;
  final bool hasTrack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: content,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mini-player slides in the first time something plays.
            AnimatedSize(
              duration: context.motion.d(PrismMotion.medium),
              curve: Curves.easeOutCubic,
              child: hasTrack
                  ? const Padding(padding: EdgeInsets.only(bottom: 6), child: MiniPlayer())
                  : const SizedBox(width: double.infinity),
            ),
            GlassPanel(
              backdrop: true, // list content scrolls under the nav bar
              borderRadius: BorderRadius.vertical(top: Radius.circular(context.shape.radius)),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                height: 68,
                selectedIndex: index,
                onDestinationSelected: onSelect,
                labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                animationDuration: context.motion.d(PrismMotion.long),
                destinations: [
                  for (final d in _destinations)
                    NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.content,
    required this.index,
    required this.onSelect,
    required this.hasTrack,
    required this.showPanel,
  });

  final Widget content;
  final int index;
  final ValueChanged<int> onSelect;
  final bool hasTrack;
  final bool showPanel;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    // On Windows the top padding is the app's own title bar strip: keep the
    // panels below it, and don't let the pages inside add it once more.
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.fromLTRB(10, top > 0 ? top : 10, 10, 10),
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Sidebar(index: index, onSelect: onSelect),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassPanel(borderRadius: context.shape.large, border: false, child: content),
                    ),
                    AnimatedSwitcher(
                      duration: motion.d(PrismMotion.long),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, a) => SizeTransition(
                        sizeFactor: a,
                        axis: Axis.horizontal,
                        alignment: AlignmentDirectional.centerStart,
                        child: FadeTransition(opacity: a, child: child),
                      ),
                      child: showPanel && hasTrack
                          ? const Padding(
                              key: ValueKey('panel'),
                              padding: EdgeInsets.only(left: 10),
                              child: SizedBox(width: 340, child: NowPlayingPanel()),
                            )
                          : const SizedBox.shrink(key: ValueKey('none')),
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: motion.d(PrismMotion.medium),
                curve: Curves.easeOutCubic,
                child: hasTrack
                    ? const Padding(padding: EdgeInsets.only(top: 10), child: DesktopPlayerBar())
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  /// Height of one item incl. its gap; the selection pill slides by this.
  static const _itemExtent = 44.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 980;
    return GlassPanel(
      borderRadius: context.shape.large,
      border: false,
      child: AnimatedContainer(
        duration: context.motion.d(PrismMotion.medium),
        curve: Curves.easeOutCubic,
        width: compact ? 76 : 220,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(compact ? 0 : 8, 0, compact ? 0 : 8, 24),
              child: Align(
                alignment: compact ? Alignment.center : Alignment.centerLeft,
                child: PrismLogo(showName: !compact),
              ),
            ),
            SizedBox(
              height: _itemExtent * _destinations.length,
              child: Stack(
                children: [
                  // One pill that glides to the selected item.
                  AnimatedPositioned(
                    duration: context.motion.d(PrismMotion.long),
                    curve: PrismMotion.curve,
                    top: index * _itemExtent + 2,
                    left: 0,
                    right: 0,
                    height: _itemExtent - 4,
                    // One surface step up with a hairline: quiet, the LED marks it.
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      for (var i = 0; i < _destinations.length; i++)
                        _SidebarItem(
                          destination: _destinations[i],
                          selected: i == index,
                          compact: compact,
                          height: _itemExtent,
                          onTap: () => onSelect(i),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            _TogetherEntry(compact: compact),
          ],
        ),
      ),
    );
  }
}

/// Listen together, always one click away; shows the session while it runs.
class _TogetherEntry extends ConsumerWidget {
  const _TogetherEntry({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(togetherProvider);
    final scheme = Theme.of(context).colorScheme;
    final label = !s.connected
        ? l10n.listenTogether
        : (s.role == TogetherRole.host
              ? (s.guests == 0 ? l10n.code(s.code ?? '') : l10n.nListening(s.guests + 1))
              : l10n.xWith(s.hostName ?? l10n.aFriend));
    return Tooltip(
      message: compact ? label : '',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => showTogetherSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                s.connected ? Icons.groups_rounded : Icons.group_add_outlined,
                size: 20,
                color: s.connected ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
              if (!compact) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: s.connected ? scheme.onSurface : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                LedDot(on: s.connected),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.compact,
    required this.height,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final bool compact;
  final double height;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final motion = context.motion;
    final d = widget.destination;
    final fg = widget.selected || _hover ? scheme.onSurface : scheme.onSurfaceVariant;
    return SizedBox(
      height: widget.height,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Tooltip(
              message: widget.compact ? d.label : '',
              child: AnimatedContainer(
                duration: motion.d(PrismMotion.short),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  // Hover tint only; the selection is the sliding pill below.
                  color: !widget.selected && _hover ? scheme.onSurface.withValues(alpha: 0.04) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: fg),
                  duration: motion.d(PrismMotion.medium),
                  curve: PrismMotion.curve,
                  builder: (context, color, _) => Row(
                    mainAxisAlignment: widget.compact ? MainAxisAlignment.center : MainAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: motion.d(PrismMotion.short),
                        child: Icon(
                          widget.selected ? d.selectedIcon : d.icon,
                          key: ValueKey(widget.selected),
                          size: 20,
                          color: color,
                        ),
                      ),
                      if (!widget.compact) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            d.label,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                        LedDot(on: widget.selected),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps every branch navigator alive and switches with a *fade-through*:
/// the old page fades out during the first 40 % of the transition, the new
/// one fades (and settles) in afterwards. Pages have transparent backgrounds,
/// so a plain cross-fade would show both on top of each other.
///
/// [TickerMode] must sit *inside* the fade: it mutes animations of the hidden
/// page, and wrapping the fade itself would freeze the outgoing page at full
/// opacity (that was the "pages overlap" bug).
class _FadingBranches extends StatelessWidget {
  const _FadingBranches({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  static const _out = Interval(0, 0.4, curve: Curves.easeIn);
  static const _in = Interval(0.4, 1, curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final duration = context.motion.d(PrismMotion.medium);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          IgnorePointer(
            ignoring: i != index,
            child: AnimatedOpacity(
              opacity: i == index ? 1 : 0,
              duration: duration,
              curve: i == index ? _in : _out,
              child: AnimatedScale(
                scale: i == index ? 1 : 0.985,
                duration: duration,
                curve: i == index ? _in : _out,
                child: TickerMode(enabled: i == index, child: children[i]),
              ),
            ),
          ),
      ],
    );
  }
}
