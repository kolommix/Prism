import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../library/domain/track.dart';
import '../../player/application/player_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/domain/app_settings.dart';
import '../../together/application/together_controller.dart';
import '../data/cover_lookup.dart';
import '../data/discord_ipc.dart';
import '../../../l10n/l10n.dart';

/// The app id in use: your own if set, else the one built into Prism.
String discordIdOf(AppSettings s) => s.discordClientId.trim().isNotEmpty ? s.discordClientId.trim() : prismDiscordClientId;

class _DiscordStatusNotifier extends Notifier<DiscordStatus> {
  @override
  DiscordStatus build() => const DiscordStatus(DiscordLink.off);
  void set(DiscordStatus s) => state = s;
}

/// Connected? As who? For the settings page.
final discordStatusProvider = NotifierProvider<_DiscordStatusNotifier, DiscordStatus>(_DiscordStatusNotifier.new);

/// Links for the status: the song's own page when it has one, else a search.
List<(String, String)> discordButtons(Track t, CoverInfo? info, String title, String artist) {
  final out = <(String, String)>[];
  if (t.uri.startsWith('https://www.youtube.com')) {
    out.add((l10n.watchOnYoutube, t.uri));
  } else if (t.uri.startsWith('https://soundcloud.com')) {
    out.add((l10n.openOnSoundcloud, t.uri.split('#').first));
  } else {
    final q = Uri.encodeQueryComponent(isUnknownArtist(artist) ? title : '$artist $title');
    out.add((l10n.findOnYoutube, 'https://www.youtube.com/results?search_query=$q'));
  }
  final link = info?.linkUrl;
  if (link != null && link.isNotEmpty) out.add((info!.linkLabel, link));
  return out;
}

/// Discord "Listening to …" status (Windows): clean song name, album art, the
/// real progress bar, link buttons, and who you listen with. Updates on song
/// changes, play/pause and seeks.
final discordPresenceProvider = Provider<void>((ref) {
  if (!Platform.isWindows) return;
  final presence = DiscordPresence(
    onStatus: (s) {
      if (ref.mounted) ref.read(discordStatusProvider.notifier).set(s);
    },
  );
  ref.onDispose(presence.stop);
  final ready = presence.start();
  final covers = CoverLookup();
  ref.onDispose(covers.close);

  void sendFor(Track t, CoverInfo? info, String id) {
    final st = ref.read(engineStateProvider).value;
    final together = ref.read(togetherProvider);
    final title = cleanSongTitle(info?.title ?? t.title);
    final artist = t.artist.isNotEmpty || t.albumArtist.isNotEmpty ? t.displayArtist : (info?.artist ?? t.displayArtist);
    final album = t.album.isNotEmpty ? t.album : (info?.album ?? '');
    final cover = t.artworkPath != null && t.artworkPath!.startsWith('https://') ? t.artworkPath : info?.coverUrl;
    final buttons = discordButtons(t, info, title, artist);
    presence.update(
      id,
      activityFrame(
        title: title,
        artist: artist,
        album: album,
        playing: st?.playing ?? false,
        position: st?.position ?? Duration.zero,
        duration: st?.duration ?? t.duration,
        nowMs: DateTime.now().millisecondsSinceEpoch,
        pid: pid,
        coverUrl: cover,
        linkUrl: buttons.first.$2,
        buttons: buttons,
        party: together.connected && together.code != null
            ? (together.code!, together.people.length + 1, math.max(together.people.length + 1, 8))
            : null,
      ),
    );
  }

  Future<void> push() async {
    await ready;
    if (!ref.mounted) return;
    final s = ref.read(settingsProvider);
    final id = discordIdOf(s);
    if (!s.discordPresence) {
      ref.read(discordStatusProvider.notifier).set(const DiscordStatus(DiscordLink.off));
      return;
    }
    if (id.isEmpty) {
      ref.read(discordStatusProvider.notifier).set(const DiscordStatus(DiscordLink.needsId));
      return;
    }
    final t = ref.read(currentTrackProvider);
    if (t == null) {
      presence.update(id, null);
      return;
    }
    final wantCover = s.discordCovers && !(t.artworkPath?.startsWith('https://') ?? false);
    final known = wantCover ? covers.cached(t) : null;
    if (wantCover && known == null && !covers.isSettled(t)) {
      // A quick find goes out with the song in one update; a slow one follows.
      final finding = covers.find(t);
      final quick = await finding.timeout(const Duration(milliseconds: 600), onTimeout: () => null);
      if (!ref.mounted || ref.read(currentTrackProvider)?.id != t.id) return;
      sendFor(t, quick, id);
      if (quick != null) return;
      final found = await finding;
      // Still the same song and still on: show it with its cover now.
      if (found != null && ref.mounted && ref.read(currentTrackProvider)?.id == t.id && ref.read(settingsProvider).discordPresence) {
        sendFor(t, found, id);
      }
      return;
    }
    sendFor(t, known, id);
  }

  // A song change fires several of the listeners below at once (song, play
  // state, position): one update for all of them.
  Timer? soon;
  ref.onDispose(() => soon?.cancel());
  void schedule() {
    soon?.cancel();
    soon = Timer(const Duration(milliseconds: 80), () => unawaited(push()));
  }

  // Seeks: the progress bar on Discord has to jump too.
  var lastPos = Duration.zero;
  var lastAt = DateTime.now();
  ref.listen(engineStateProvider, (_, next) {
    final st = next.value;
    if (st == null) return;
    final now = DateTime.now();
    final expected = st.playing ? lastPos + now.difference(lastAt) : lastPos;
    final jumped = (st.position - expected).abs() > const Duration(seconds: 3);
    lastPos = st.position;
    lastAt = now;
    if (jumped) schedule();
  });
  ref.listen(currentTrackProvider, (_, _) => schedule());
  ref.listen(isPlayingProvider, (_, _) => schedule());
  ref.listen(togetherProvider.select((s) => (s.connected, s.people.length)), (_, _) => schedule());
  ref.listen(settingsProvider.select((s) => (s.discordPresence, discordIdOf(s), s.discordCovers)), (old, v) {
    if (!v.$1) {
      if (old != null && old.$2.isNotEmpty) ready.then((_) => presence.update(old.$2, null));
      ref.read(discordStatusProvider.notifier).set(const DiscordStatus(DiscordLink.off));
    } else {
      schedule();
    }
  });
  schedule();
});

/// Windows mini player: a small always-on-top window with just the
/// essentials. The full app stays alive underneath (state is kept).
class MiniModeController extends Notifier<bool> {
  Rect? _saved;

  @override
  bool build() => false;

  Future<void> enter() async {
    if (!Platform.isWindows || state) return;
    _saved = await windowManager.getBounds();
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setMinimumSize(const Size(320, 104));
    await windowManager.setSize(const Size(380, 112));
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setAlignment(Alignment.bottomRight);
    state = true;
  }

  Future<void> exit() async {
    if (!state) return;
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
    await windowManager.setMinimumSize(const Size(420, 640));
    final r = _saved;
    if (r != null) await windowManager.setBounds(r);
    state = false;
  }

  Future<void> toggle() => state ? exit() : enter();
}

final miniModeProvider = NotifierProvider<MiniModeController, bool>(MiniModeController.new);
