import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/l10n.dart';
import '../domain/online_error.dart';
import '../services/yandex/yandex_module.dart';

/// Guide kept up to date by the community project behind the unofficial API.
final _guide = Uri.parse('https://ym.marshal.dev/en/main/token.html');

/// Asks for the user's own Yandex Music token and checks it. True = connected.
Future<bool> showYandexTokenDialog(BuildContext context, YandexModule module) async {
  final ok = await showDialog<bool>(context: context, builder: (_) => _TokenDialog(module: module));
  return ok ?? false;
}

class _TokenDialog extends StatefulWidget {
  const _TokenDialog({required this.module});
  final YandexModule module;

  @override
  State<_TokenDialog> createState() => _TokenDialogState();
}

class _TokenDialogState extends State<_TokenDialog> {
  final _c = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_c.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.module.setToken(_c.text);
      if (mounted) Navigator.pop(context, true);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = describeOnlineError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l10n.yandexTokenTitle),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.yandexTokenSteps, style: text.bodyMedium),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(l10n.yandexOpenGuide),
              onPressed: () => launchUrl(_guide, mode: LaunchMode.externalApplication),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _c,
              obscureText: true,
              enabled: !_busy,
              decoration: InputDecoration(labelText: l10n.yandexToken),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            Text(l10n.yandexTokenPrivate, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: text.bodySmall?.copyWith(color: scheme.error)),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        FilledButton(onPressed: _busy ? null : _save, child: Text(l10n.connect)),
      ],
    );
  }
}
