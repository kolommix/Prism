import 'external_track.dart';
import '../../../l10n/l10n.dart';

/// What went wrong talking to a service. The UI shows [OnlineException.message]
/// as is, so every kind gets a plain-words default.
enum OnlineErrorKind {
  /// No network / DNS / connection refused / timeout.
  offline,

  /// HTTP 429 (or a quota error) even after waiting.
  rateLimited,

  /// Not logged in, or the token was revoked.
  auth,

  /// Logged in but the service refuses (private playlist, dev-mode limits…).
  forbidden,
  notFound,

  /// 5xx after retries.
  server,

  /// API key / client id missing from the local config file.
  notConfigured,

  /// The feature flag is off.
  disabled,

  /// The service doesn't offer this (e.g. official YouTube API can't stream).
  unsupported,

  /// Unexpected response (service changed its format).
  badResponse,
}

class OnlineException implements Exception {
  OnlineException(this.kind, {this.service, this._message, this.retryAfter, this.isRegionBlocked = false, this.internetWorks = false});

  final OnlineErrorKind kind;
  final OnlineService? service;
  final String? _message;

  /// For [OnlineErrorKind.rateLimited]: how long the service asked to wait.
  final Duration? retryAfter;

  /// The service refuses this country or network (HTTP 451).
  final bool isRegionBlocked;

  /// An [OnlineErrorKind.offline] error checked by NetworkCheck: the internet
  /// works, only this service can't be reached from here.
  final bool internetWorks;

  /// True when trying again later can help (matching pauses instead of failing).
  bool get isTransient =>
      kind == OnlineErrorKind.offline || kind == OnlineErrorKind.rateLimited || kind == OnlineErrorKind.server;

  String get message {
    if (_message != null) return _message;
    final name = service?.label ?? l10n.theService;
    return switch (kind) {
      OnlineErrorKind.offline =>
        l10n.youSeemToBeOfflineLocal,
      OnlineErrorKind.rateLimited => l10n.isLimitingRequestsRightNowTry(name),
      OnlineErrorKind.auth => l10n.yourLoginExpiredConnectTheAccount(name),
      OnlineErrorKind.forbidden => l10n.refusedTheRequest(name),
      OnlineErrorKind.notFound => l10n.notFoundOnDeletedPrivateOr(name),
      OnlineErrorKind.server => l10n.hasServerProblemsTryAgainLater(name),
      OnlineErrorKind.notConfigured => l10n.needsAnApiKeyInThe(name),
      OnlineErrorKind.disabled => l10n.isTurnedOffInSettingsOnline(name),
      OnlineErrorKind.unsupported => l10n.canNotDoThis(name),
      OnlineErrorKind.badResponse => l10n.sentSomethingUnexpectedItMayHave(name),
    };
  }

  @override
  String toString() => message;
}

/// Turns any error into a message for a snackbar / error row.
String describeOnlineError(Object e) => e is OnlineException ? e.message : l10n.somethingWentWrong(e);
