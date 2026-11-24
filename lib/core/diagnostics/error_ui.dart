import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import 'error_log.dart';

/// Copies a report (one entry, or the whole log) for pasting to the developer.
Future<void> copyErrorReport({ErrorEntry? only, ScaffoldMessengerState? messenger}) async {
  await Clipboard.setData(ClipboardData(text: ErrorLog.instance.report(only: only)));
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(SnackBar(content: Text(l10n.errorCopied), duration: const Duration(seconds: 2)));
}

/// A message about something that failed, with a Copy button that copies the
/// full report (what failed, where, version, system). Records it in the log
/// too, unless [entry] already is.
SnackBar errorSnackBar(
  String text, {
  ErrorEntry? entry,
  Object? error,
  StackTrace? stack,
  String where = 'app',
  ScaffoldMessengerState? messenger,
  Duration duration = const Duration(seconds: 6),
}) {
  final e = entry ??
      (error != null
          ? ErrorLog.instance.record(error, stack, where: where, message: text)
          : ErrorLog.instance.failed(where, text));
  return SnackBar(
    content: Text(text),
    duration: duration,
    action: SnackBarAction(
      label: l10n.copy,
      onPressed: () => copyErrorReport(only: e, messenger: messenger),
    ),
  );
}

/// Shows [errorSnackBar] on the nearest messenger.
void showErrorSnack(
  BuildContext context,
  String text, {
  Object? error,
  StackTrace? stack,
  String where = 'app',
}) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) {
    ErrorLog.instance.failed(where, text);
    return;
  }
  m.showSnackBar(errorSnackBar(text, error: error, stack: stack, where: where, messenger: m));
}

/// An error shown inside a page (a list that couldn't load), with a small
/// copy button. Logged once when first shown.
class ErrorText extends StatefulWidget {
  const ErrorText(this.error, {super.key, this.text, this.stack, this.where = 'app', this.center = true});

  final Object error;

  /// What to show; the error itself when null.
  final String? text;
  final StackTrace? stack;
  final String where;
  final bool center;

  @override
  State<ErrorText> createState() => _ErrorTextState();
}

class _ErrorTextState extends State<ErrorText> {
  late final ErrorEntry _entry =
      ErrorLog.instance.record(widget.error, widget.stack, where: widget.where, message: widget.text ?? '${widget.error}');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            widget.text ?? '${widget.error}',
            style: TextStyle(color: scheme.error),
            textAlign: widget.center ? TextAlign.center : TextAlign.start,
          ),
        ),
        IconButton(
          tooltip: l10n.errorCopyTooltip,
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.copy_rounded, size: 16, color: scheme.onSurfaceVariant),
          onPressed: () => copyErrorReport(only: _entry, messenger: ScaffoldMessenger.maybeOf(context)),
        ),
      ],
    );
    return widget.center ? Center(child: Padding(padding: const EdgeInsets.all(16), child: row)) : row;
  }
}
