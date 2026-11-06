import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../player/application/player_providers.dart';
import '../../../l10n/l10n.dart';

/// Keeps the Android home-screen widget (PrismWidgetProvider.kt) in sync
/// with the current song and play state. No-op on other platforms.
final androidWidgetSyncProvider = Provider<void>((ref) {
  if (!Platform.isAndroid) return;
  Future<void> push() async {
    final t = ref.read(currentTrackProvider);
    try {
      await HomeWidget.saveWidgetData<String>('title', t?.title ?? 'Prism');
      await HomeWidget.saveWidgetData<String>('artist', t?.displayArtist ?? l10n.nothingPlaying);
      await HomeWidget.saveWidgetData<bool>('playing', ref.read(isPlayingProvider));
      // The widget reads a local file; streamed covers are URLs.
      final art = t?.artworkPath;
      await HomeWidget.saveWidgetData<String>('art', art != null && art.startsWith('http') ? null : art);
      await HomeWidget.updateWidget(androidName: 'PrismWidgetProvider');
    } on Object {
      // No widget placed / plugin unavailable: nothing to update.
    }
  }

  ref.listen(currentTrackProvider, (_, _) => unawaited(push()));
  ref.listen(isPlayingProvider, (_, _) => unawaited(push()));
  unawaited(push());
});
