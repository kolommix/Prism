import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/player_providers.dart';
import 'widgets/waveform_seek_bar.dart';
import '../../../l10n/l10n.dart';

/// Lets the user pick a sleep timer duration (or cancel the running one).
Future<void> showSleepTimerSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final timer = ref.read(sleepTimerProvider);
          final state = ref.watch(sleepTimerStateProvider).value;
          void pick(Duration d) {
            timer.start(d);
            Navigator.pop(context);
          }

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(l10n.sleepTimer, style: Theme.of(context).textTheme.titleLarge),
                  subtitle: state?.isActive ?? false
                      ? StreamBuilder(
                          stream: Stream.periodic(const Duration(seconds: 1)),
                          builder: (context, _) => Text(
                            state!.endOfTrack
                                ? l10n.stopsAfterThisSong
                                : l10n.stopsIn(formatDuration(state.remaining(DateTime.now()))),
                          ),
                        )
                      : Text(l10n.musicFadesOutAndPauses),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in const [5, 15, 30, 45, 60, 90])
                      ActionChip(label: Text(l10n.minutesValue(m)), onPressed: () => pick(Duration(minutes: m))),
                    ActionChip(
                      label: Text(l10n.endOfSong),
                      onPressed: () {
                        timer.startEndOfTrack();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (state?.isActive ?? false)
                  TextButton.icon(
                    onPressed: () {
                      timer.cancel();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.timer_off_rounded),
                    label: Text(l10n.turnOff),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
