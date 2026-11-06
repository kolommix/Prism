import 'dart:convert';
import 'dart:io';
import '../../../l10n/l10n.dart';

/// API keys / client ids for online services, read from a local JSON file
/// that is never committed (`online_config.json`, see
/// `online_config.example.json` and the README). Nothing is hard-coded: a
/// service without its keys shows "not configured" and the rest still works.
class OnlineConfig {
  const OnlineConfig({
    this.spotifyClientId = '',
    this.spotifyRedirectPort = 43821,
    this.youtubeApiKey = '',
    this.googleClientId = '',
    this.googleClientSecret = '',
    this.soundcloudClientId = '',
    this.soundcloudClientSecret = '',
    this.soundcloudRedirectPort = 43822,
    this.acoustIdKey = '',
    this.path,
    this.error,
  });

  factory OnlineConfig.fromJson(Map<String, dynamic> j, {String? path}) {
    Map<String, dynamic> sec(String k) => j[k] is Map<String, dynamic> ? j[k] as Map<String, dynamic> : const {};
    String s(Map<String, dynamic> m, String k) => (m[k] as String? ?? '').trim();
    int port(Map<String, dynamic> m, int def) => (m['redirectPort'] as num?)?.toInt() ?? def;
    final sp = sec('spotify'), yt = sec('youtube'), sc = sec('soundcloud');
    return OnlineConfig(
      spotifyClientId: s(sp, 'clientId'),
      spotifyRedirectPort: port(sp, 43821),
      youtubeApiKey: s(yt, 'apiKey'),
      googleClientId: s(yt, 'oauthClientId'),
      googleClientSecret: s(yt, 'oauthClientSecret'),
      soundcloudClientId: s(sc, 'clientId'),
      soundcloudClientSecret: s(sc, 'clientSecret'),
      soundcloudRedirectPort: port(sc, 43822),
      acoustIdKey: s(sec('acoustid'), 'apiKey'),
      path: path,
    );
  }

  final String spotifyClientId;
  final int spotifyRedirectPort;
  final String youtubeApiKey;
  final String googleClientId;
  final String googleClientSecret;
  final String soundcloudClientId;
  final String soundcloudClientSecret;
  final int soundcloudRedirectPort;

  /// File the values came from (shown in Settings).
  final String? path;

  /// Set when the file exists but can't be read.
  final String? error;

  /// Optional: https://acoustid.org/new-application (with fpcalc.exe beside the app).
  final String acoustIdKey;
  bool get hasSpotify => spotifyClientId.isNotEmpty;
  bool get hasYoutubeApi => youtubeApiKey.isNotEmpty;
  bool get hasGoogleLogin => googleClientId.isNotEmpty;
  bool get hasSoundcloud => soundcloudClientId.isNotEmpty;

  /// Written by "Create config file" in Settings.
  static const template = '''
{
  "_readme": "Prism online services. Keep this file private (it is gitignored). See README → Online services.",
  "spotify": {
    "clientId": "",
    "redirectPort": 43821
  },
  "youtube": {
    "apiKey": "",
    "oauthClientId": "",
    "oauthClientSecret": ""
  },
  "soundcloud": {
    "clientId": "",
    "clientSecret": "",
    "redirectPort": 43822
  },
  "acoustid": {
    "apiKey": ""
  }
}
''';
}

/// Finds and reads the config file. Order: `PRISM_ONLINE_CONFIG` env var,
/// `<app support>/online_config.json`, then `online_config.json` next to the
/// executable (handy for a portable copy).
class OnlineConfigLoader {
  OnlineConfigLoader(this.supportDir);

  final Directory supportDir;

  File get defaultFile => File('${supportDir.path}${Platform.pathSeparator}online_config.json');

  List<File> get _candidates => [
    if (Platform.environment['PRISM_ONLINE_CONFIG'] case final env? when env.isNotEmpty) File(env),
    defaultFile,
    File('${File(Platform.resolvedExecutable).parent.path}${Platform.pathSeparator}online_config.json'),
  ];

  Future<OnlineConfig> load() async {
    for (final f in _candidates) {
      if (!await f.exists()) continue;
      try {
        final j = jsonDecode(await f.readAsString());
        if (j is! Map<String, dynamic>) throw FormatException(l10n.topLevelMustBeAnObject);
        return OnlineConfig.fromJson(j, path: f.path);
      } on Object catch (e) {
        return OnlineConfig(path: f.path, error: l10n.couldNotRead(f.path, e));
      }
    }
    return OnlineConfig(path: defaultFile.path);
  }

  /// Creates the template file if there is none yet; returns its path.
  Future<String> createTemplate() async {
    final f = defaultFile;
    if (!await f.exists()) {
      await f.parent.create(recursive: true);
      await f.writeAsString(OnlineConfig.template);
    }
    return f.path;
  }
}
