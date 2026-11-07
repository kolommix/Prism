import 'dart:convert';

import 'package:path/path.dart' as p;

import '../../../l10n/l10n.dart';
import '../../playlists/domain/playlist_share.dart';
import 'import_parsers.dart';
import 'link_parser.dart';
import 'online_error.dart';

/// File types the import screen takes.
const importFileExtensions = ['csv', 'tsv', 'txt', 'json', 'm3u', 'm3u8', shareExtension];

bool isImportFile(String path) {
  final ext = p.extension(path).toLowerCase().replaceFirst('.', '');
  return importFileExtensions.contains(ext);
}

/// What someone pasted, dropped or shared, understood.
sealed class ImportInput {
  const ImportInput();
}

/// A `liner://` shared playlist (also inside a message).
class SharedPlaylistInput extends ImportInput {
  const SharedPlaylistInput(this.text);
  final String text;
}

/// A link of a music service.
class ServiceLinkInput extends ImportInput {
  const ServiceLinkInput(this.link);
  final ParsedLink link;
}

/// A path of a playlist file.
class FileInput extends ImportInput {
  const FileInput(this.path);
  final String path;
}

/// Nothing Prism can read.
class UnknownInput extends ImportInput {
  const UnknownInput();
}

/// The one place that decides what a piece of text is.
ImportInput classifyImportText(String text) {
  final t = text.trim();
  if (t.isEmpty) return const UnknownInput();
  if (isSharedPlaylistText(t)) return SharedPlaylistInput(t);
  final link = findMusicLink(t);
  if (link != null) return ServiceLinkInput(link);
  // A single line that names a playlist file (a path from the command line).
  if (!t.contains('\n') && !t.contains('://') && isImportFile(t)) return FileInput(t);
  return const UnknownInput();
}

/// "Spotify playlist", "YouTube song"…
String describeLink(ParsedLink l) => '${l.service.label} ${switch (l.kind) {
      LinkKind.playlist => l10n.playlist,
      LinkKind.album => l10n.album2,
      LinkKind.track => l10n.song,
      LinkKind.likes => l10n.likes,
      LinkKind.shortLink => l10n.link,
    }}';

/// Something to import that came from outside this screen (share sheet, drag
/// and drop, the command line): either text or the content of a file.
class ImportRequest {
  const ImportRequest.text(String this.text)
      : fileName = null,
        fileText = null;
  const ImportRequest.file(String this.fileName, String this.fileText) : text = null;

  final String? text;
  final String? fileName;
  final String? fileText;
}

/// Most exports are UTF-8; old M3U files are often Windows-1252.
String decodeImportBytes(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return latin1.decode(bytes);
  }
}

/// What to offer next to an error.
enum ImportNextStep { none, tryAgain, chooseFile, advanced }

/// A friendly error: what happened, what to do about it, and a button for it.
class ImportProblem {
  const ImportProblem(this.message, this.step);
  final String message;
  final ImportNextStep step;
}

/// Turns any failure of an import into plain words with a concrete next step.
ImportProblem importProblemFor(Object error, {ParsedLink? link}) {
  final service = link?.service ?? (error is OnlineException ? error.service : null);
  final name = service?.label ?? l10n.theService;
  if (error is ImportFormatException) return ImportProblem(l10n.importErrorFile(error.message), ImportNextStep.chooseFile);
  if (error is ShareFormatException) return ImportProblem(l10n.importErrorFile(error.message), ImportNextStep.chooseFile);
  if (error is! OnlineException) return ImportProblem(l10n.importErrorUnknown, ImportNextStep.chooseFile);
  return switch (error.kind) {
    OnlineErrorKind.offline => ImportProblem(l10n.importErrorOffline, ImportNextStep.tryAgain),
    OnlineErrorKind.rateLimited => ImportProblem(l10n.importErrorSlowDown(name), ImportNextStep.tryAgain),
    OnlineErrorKind.server => ImportProblem(l10n.importErrorServer(name), ImportNextStep.tryAgain),
    OnlineErrorKind.notFound || OnlineErrorKind.forbidden when error.isRegionBlocked =>
      ImportProblem(l10n.importErrorRegion(name), ImportNextStep.chooseFile),
    OnlineErrorKind.notFound || OnlineErrorKind.forbidden =>
      ImportProblem(l10n.importErrorPrivate, ImportNextStep.chooseFile),
    OnlineErrorKind.auth => ImportProblem(l10n.importErrorAccount(name), ImportNextStep.advanced),
    OnlineErrorKind.notConfigured => ImportProblem(l10n.importErrorNeedsKey(name), ImportNextStep.advanced),
    OnlineErrorKind.disabled => ImportProblem(l10n.importErrorNeedsKey(name), ImportNextStep.advanced),
    OnlineErrorKind.unsupported ||
    OnlineErrorKind.badResponse =>
      ImportProblem(l10n.importErrorCantRead(name), ImportNextStep.chooseFile),
  };
}
