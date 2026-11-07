import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../application/library_providers.dart';

/// The songs taken out of Prism, with a way back.
Future<void> showRemovedSongs(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => const _RemovedSongsSheet(),
    );

class _RemovedSongsSheet extends ConsumerWidget {
  const _RemovedSongsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final removed = ref.watch(removedTracksProvider).value ?? const [];
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text(l10n.removedSongs, style: text.titleLarge),
              subtitle: Text(l10n.removedSongsHelp),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: removed.length,
                itemBuilder: (_, i) {
                  final r = removed[i];
                  return ListTile(
                    title: Text(r.title.isEmpty ? r.uri : r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(r.uri, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: TextButton(
                      onPressed: () async {
                        await ref.read(libraryRepositoryProvider).restoreRemoved(r.uri);
                        await ref.read(scanControllerProvider.notifier).rescanAll();
                      },
                      child: Text(l10n.restoreAction),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
