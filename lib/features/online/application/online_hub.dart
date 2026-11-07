import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/sources/track_source.dart';
import '../../library/domain/track.dart';
import '../data/oauth.dart';
import '../data/online_config.dart';
import '../data/online_http.dart';
import '../data/stream_cache.dart';
import '../data/stream_proxy.dart';
import '../domain/external_track.dart';
import '../domain/online_error.dart';
import '../services/link_only/link_modules.dart';
import '../services/music_service_module.dart';
import '../services/public_links/public_readers.dart';
import '../services/soundcloud/soundcloud_module.dart';
import '../services/spotify/spotify_module.dart';
import '../services/youtube/data_api_backend.dart';
import '../services/youtube/explode_backend.dart';
import '../services/youtube/youtube_backend.dart';
import '../services/youtube/youtube_module.dart';
import '../../../l10n/l10n.dart';

import '../services/yandex/yandex_module.dart';
/// Feature flags (Settings → Online services). Every service can be switched
/// off on its own; the "personal use only" parts are off by default.
class OnlineFlags {
  const OnlineFlags({
    this.spotify = true,
    this.youtube = true,
    this.youtubeExtractor = false,
    this.soundcloud = true,
    this.deezerLinks = true,
    this.yandex = false,
    this.appleMusicLinks = false,
    this.offlineCache = false,
    this.cacheLimitMb = 2048,
  });

  factory OnlineFlags.fromJson(Map<String, dynamic> j) {
    const d = OnlineFlags();
    bool b(String k, bool def) => j[k] is bool ? j[k] as bool : def;
    return OnlineFlags(
      spotify: b('spotify', d.spotify),
      youtube: b('youtube', d.youtube),
      youtubeExtractor: b('youtubeExtractor', d.youtubeExtractor),
      soundcloud: b('soundcloud', d.soundcloud),
      deezerLinks: b('deezerLinks', d.deezerLinks),
      yandex: b('yandex', d.yandex),
      appleMusicLinks: b('appleMusicLinks', d.appleMusicLinks),
      offlineCache: b('offlineCache', d.offlineCache),
      cacheLimitMb: (j['cacheLimitMb'] as num?)?.toInt().clamp(256, 51200) ?? d.cacheLimitMb,
    );
  }

  final bool spotify;
  final bool youtube;

  /// youtube_explode: search/playlists without an API key + playback +
  /// offline copies. Personal use only (against YouTube's Terms).
  final bool youtubeExtractor;
  final bool soundcloud;
  final bool deezerLinks;

  /// Yandex Music import: no official API, so off until someone wants it.
  final bool yandex;

  /// Reads public Apple Music web pages (best effort, personal use).
  final bool appleMusicLinks;

  /// Keep a copy of streamed songs after playing them.
  final bool offlineCache;
  final int cacheLimitMb;

  Map<String, Object> toJson() => {
    'spotify': spotify,
    'youtube': youtube,
    'youtubeExtractor': youtubeExtractor,
    'soundcloud': soundcloud,
    'deezerLinks': deezerLinks,
    'yandex': yandex,
    'appleMusicLinks': appleMusicLinks,
    'offlineCache': offlineCache,
    'cacheLimitMb': cacheLimitMb,
  };

  bool enabled(OnlineService s) => switch (s) {
    OnlineService.spotify => spotify,
    OnlineService.youtube => youtube,
    OnlineService.soundcloud => soundcloud,
    OnlineService.deezer => deezerLinks,
    OnlineService.yandex => yandex,
    OnlineService.appleMusic => appleMusicLinks,
    OnlineService.file => true,
  };

  OnlineFlags copyWith({
    bool? spotify,
    bool? youtube,
    bool? youtubeExtractor,
    bool? soundcloud,
    bool? deezerLinks,
    bool? yandex,
    bool? appleMusicLinks,
    bool? offlineCache,
    int? cacheLimitMb,
  }) => OnlineFlags(
    spotify: spotify ?? this.spotify,
    youtube: youtube ?? this.youtube,
    youtubeExtractor: youtubeExtractor ?? this.youtubeExtractor,
    soundcloud: soundcloud ?? this.soundcloud,
    deezerLinks: deezerLinks ?? this.deezerLinks,
    yandex: yandex ?? this.yandex,
    appleMusicLinks: appleMusicLinks ?? this.appleMusicLinks,
    offlineCache: offlineCache ?? this.offlineCache,
    cacheLimitMb: cacheLimitMb ?? this.cacheLimitMb,
  );

  OnlineFlags withService(OnlineService s, bool on) => switch (s) {
    OnlineService.spotify => copyWith(spotify: on),
    OnlineService.youtube => copyWith(youtube: on),
    OnlineService.soundcloud => copyWith(soundcloud: on),
    OnlineService.deezer => copyWith(deezerLinks: on),
    OnlineService.yandex => copyWith(yandex: on),
    OnlineService.appleMusic => copyWith(appleMusicLinks: on),
    OnlineService.file => this,
  };
}

enum ModuleState { off, notConfigured, ready, failed }

class ModuleStatus {
  const ModuleStatus(this.state, [this.message]);
  final ModuleState state;
  final String? message;
}

/// Owns the online modules. Each one is built inside its own try/catch from
/// the config file + flags; a module that throws while being built (or later)
/// only marks *itself* as failed. Rebuilt when flags or the config change.
class OnlineHub {
  OnlineHub({
    required this.configLoader,
    required this.prefs,
    required this.tokens,
    required this.http,
    required this.launch,
    required this.cache,
    StreamProxy? proxy,
  }) : proxy = proxy ?? StreamProxy();

  /// Loopback proxy for streams that need chunked range requests (YouTube).
  final StreamProxy proxy;

  final OnlineConfigLoader configLoader;
  final SharedPreferencesAsync prefs;
  final TokenStore tokens;
  final OnlineHttp http;
  final BrowserLauncher launch;
  final StreamCache cache;

  static const _flagsKey = 'online.flags';

  OnlineConfig config = const OnlineConfig();
  OnlineFlags flags = const OnlineFlags();
  final _modules = <OnlineService, MusicServiceModule>{};
  final _status = <OnlineService, ModuleStatus>{};
  final _revisions = StreamController<int>.broadcast();
  int _revision = 0;

  /// Bumps whenever modules, flags or accounts change (UI listens).
  Stream<int> get revisions => _revisions.stream;
  int get revision => _revision;
  void notify() => _revisions.add(++_revision);

  Future<void> init() async {
    try {
      final raw = await prefs.getString(_flagsKey);
      if (raw != null) flags = OnlineFlags.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object catch (e) {
      debugPrint('Online flags unreadable, using defaults: $e');
    }
    config = await configLoader.load();
    _build();
  }

  Future<void> setFlags(OnlineFlags f) async {
    flags = f;
    await prefs.setString(_flagsKey, jsonEncode(f.toJson()));
    _build();
  }

  Future<void> reloadConfig() async {
    config = await configLoader.load();
    _build();
  }

  ModuleStatus status(OnlineService s) => _status[s] ?? const ModuleStatus(ModuleState.off);

  /// Ready module or null (off / not configured / failed).
  MusicServiceModule? module(OnlineService s) => _modules[s];

  Iterable<MusicServiceModule> get modules => _modules.values;

  /// What opens a pasted link. A public link needs no key, login or switch: a
  /// person pasting it is asking for it. Only reads names, plays nothing.
  /// Throws [OnlineException] when the service can't be read at all yet.
  MusicServiceModule linkReader(OnlineService s) => switch (s) {
        OnlineService.spotify => SpotifyLinkReader(SpotifyPublicReader(http), _modules[s]),
        OnlineService.youtube => _modules[s] ?? YoutubePublicReader(http),
        OnlineService.deezer => _modules[s] ?? DeezerModule(http),
        OnlineService.appleMusic => _modules[s] ?? AppleMusicModule(http),
        OnlineService.yandex => _modules[s] ?? YandexModule(http, tokens),
        // Its pages hold almost nothing without a key, and that key is not ours to take.
        OnlineService.soundcloud => _modules[s] ?? (throw OnlineException(OnlineErrorKind.notConfigured, service: s)),
        OnlineService.file => throw OnlineException(OnlineErrorKind.unsupported, service: s),
      };

  /// Modules that can search *and* play (used by matching and search).
  List<MusicServiceModule> get playable => [
    for (final s in const [OnlineService.youtube, OnlineService.soundcloud])
      if (_modules[s] case final m?
          when m.features.contains(ModuleFeature.stream) && m.features.contains(ModuleFeature.search))
        m,
  ];

  List<MusicServiceModule> get searchable => [
    for (final m in _modules.values)
      if (m.features.contains(ModuleFeature.search)) m,
  ];

  void _build() {
    for (final m in _modules.values) {
      try {
        m.dispose();
      } on Object {
        // ignore
      }
    }
    _modules.clear();
    _status.clear();
    cache.limitBytes = flags.cacheLimitMb * 1024 * 1024;
    if (config.error != null) debugPrint(config.error);
    for (final s in OnlineService.values) {
      if (s == OnlineService.file) continue;
      if (!flags.enabled(s)) {
        _status[s] = const ModuleStatus(ModuleState.off);
        continue;
      }
      try {
        final m = _create(s);
        if (m == null) continue; // _create set notConfigured
        _modules[s] = m;
        _status[s] = ModuleStatus(ModuleState.ready, m.setupHint);
      } on Object catch (e) {
        debugPrint('Online module ${s.name} failed to start: $e');
        _status[s] = ModuleStatus(ModuleState.failed, describeOnlineError(e));
      }
    }
    notify();
  }

  MusicServiceModule? _create(OnlineService s) {
    void missing(String what) => _status[s] = ModuleStatus(
      ModuleState.notConfigured,
      l10n.isMissingIn(what, config.path ?? 'online_config.json', config.error == null ? '' : ' ${config.error}'),
    );
    switch (s) {
      case OnlineService.spotify:
        if (!config.hasSpotify) {
          missing('spotify.clientId');
          return null;
        }
        return SpotifyModule(
          clientId: config.spotifyClientId,
          port: config.spotifyRedirectPort,
          store: tokens,
          http: http,
          launch: launch,
        );
      case OnlineService.youtube:
        final YoutubeBackend? extractor = flags.youtubeExtractor ? ExplodeBackend() : null;
        final YoutubeBackend? catalog = config.hasYoutubeApi
            ? DataApiBackend.withKey(config.youtubeApiKey, http)
            : extractor;
        if (catalog == null && !config.hasGoogleLogin) {
          missing(l10n.youtubeApikeyOrTurnOnThe);
          return null;
        }
        return YoutubeModule.create(
          catalog: catalog,
          streamer: extractor,
          proxy: extractor == null ? null : proxy,
          googleClientId: config.googleClientId,
          googleClientSecret: config.googleClientSecret,
          store: tokens,
          http: http,
          launch: launch,
        );
      case OnlineService.soundcloud:
        if (!config.hasSoundcloud) {
          missing('soundcloud.clientId');
          return null;
        }
        return SoundcloudModule(
          clientId: config.soundcloudClientId,
          clientSecret: config.soundcloudClientSecret,
          port: config.soundcloudRedirectPort,
          store: tokens,
          http: http,
          launch: launch,
        );
      case OnlineService.deezer:
        return DeezerModule(http);
      case OnlineService.appleMusic:
        return AppleMusicModule(http);
      case OnlineService.yandex:
        return YandexModule(http, tokens);
      case OnlineService.file:
        return null;
    }
  }

  /// One [TrackSource] per streaming service, registered at startup even
  /// when the service is off – so old queue items fail with a clear message
  /// ("YouTube is turned off") instead of "no source registered".
  List<TrackSource> trackSources() => [
    RemoteTrackSource(this, OnlineService.youtube, youtubeSourceId),
    RemoteTrackSource(this, OnlineService.soundcloud, soundcloudSourceId),
  ];
}

/// Plays tracks of one online service: offline copy first, then the
/// module's stream URL. Optionally saves a copy after a successful resolve.
class RemoteTrackSource extends TrackSource {
  RemoteTrackSource(this._hub, this.service, this.sourceId);

  final OnlineHub _hub;
  final OnlineService service;
  final String sourceId;

  @override
  String get id => sourceId;
  @override
  String get displayName => service.label;
  @override
  Set<TrackSourceCapability> get capabilities => const {
    TrackSourceCapability.search,
    TrackSourceCapability.requiresNetwork,
  };

  MusicServiceModule _module() {
    final m = _hub.module(service);
    if (m == null) {
      final st = _hub.status(service);
      throw OnlineException(
        st.state == ModuleState.notConfigured ? OnlineErrorKind.notConfigured : OnlineErrorKind.disabled,
        service: service,
        message: st.state == ModuleState.failed ? st.message : null,
      );
    }
    return m;
  }

  @override
  Future<Uri> resolvePlaybackUri(Track track) async {
    final cached = await _hub.cache.fileFor(track);
    if (cached != null) return Uri.file(cached.path);
    final m = _module();
    final uri = await m.streamUri(track);
    if (_hub.flags.offlineCache && m.features.contains(ModuleFeature.stream) && track.id > 0) {
      try {
        _hub.cache.download(track, m);
      } on Object {
        // Offline copy is a bonus; never block playback.
      }
    }
    return uri;
  }

  @override
  Future<Map<String, String>> playbackHeaders(Track track) async {
    if (await _hub.cache.fileFor(track) != null) return const {};
    return _module().streamHeaders(track);
  }

  @override
  Future<List<Track>> search(String query, {int limit = 50}) => _module().search(query, limit: limit);
}
