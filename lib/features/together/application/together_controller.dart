import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/application/library_providers.dart';
import '../../library/domain/track.dart';
import '../../online/application/online_providers.dart';
import '../../online/domain/external_track.dart';
import '../../player/application/player_controller.dart';
import '../../player/application/player_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../../tools/domain/track_matching.dart';
import '../data/nearby.dart';
import '../data/relay.dart';
import '../data/together_link.dart';
import '../domain/together_protocol.dart';
import '../../../l10n/l10n.dart';

enum TogetherRole { none, host, guest }

class TogetherState {
  const TogetherState({
    this.role = TogetherRole.none,
    this.code,
    this.guests = 0,
    this.connected = false,
    this.busy = false,
    this.status,
    this.missingSong,
    this.hostName,
    this.people = const [],
    this.overInternet = false,
    this.error = false,
  });

  final TogetherRole role;

  /// Join code to share (host) / joined room (guest).
  final String? code;
  final int guests;
  final bool connected;

  /// Connecting right now.
  final bool busy;
  final String? status;

  /// [status] is a problem, not news.
  final bool error;

  /// Guest: the host plays a song this library doesn't have.
  final String? missingSong;
  final String? hostName;

  /// Everyone in the session except the host.
  final List<String> people;

  /// Friends outside this network can join.
  final bool overInternet;

  TogetherState copyWith({
    int? guests,
    String? status,
    String? missingSong,
    bool clearMissing = false,
    String? hostName,
    List<String>? people,
  }) =>
      TogetherState(
        role: role,
        code: code,
        guests: guests ?? this.guests,
        connected: connected,
        busy: busy,
        status: status ?? this.status,
        error: error,
        missingSong: clearMissing ? null : (missingSong ?? this.missingSong),
        hostName: hostName ?? this.hostName,
        people: people ?? this.people,
        overInternet: overInternet,
      );
}

/// Public servers to try, in order (tests use a local one).
final cloudBrokersProvider = Provider<List<CloudBroker>>((ref) => cloudBrokers);

/// How long to wait between reconnect tries (tests make it short).
final togetherRetryDelayProvider = Provider<Duration>((ref) => const Duration(seconds: 3));

/// Sessions seen on this network. Lives while the sheet is open.
final nearbySessionsProvider = StreamProvider.autoDispose<List<NearbySession>>((ref) async* {
  final own = ref.watch(togetherProvider.select((s) => s.role == TogetherRole.host ? s.code : null));
  final scanner = await NearbyScanner.start(ignoreRoom: own);
  if (scanner == null) {
    yield const [];
    return;
  }
  ref.onDispose(scanner.stop);
  yield const [];
  yield* scanner.sessions;
});

/// Hosts or joins a listen-together session.
///
/// Host: one relay on this PC (friends on the same Wi-Fi connect directly and
/// find it through a [NearbyBeacon]) plus one internet link: your own relay if
/// set, else a free public server. Sends the queue when it changes and the
/// position on every jump and every 5 s.
/// Guest: finds the session (same network first, then the internet), matches
/// songs in the local library, falls back to an online service for missing
/// ones, keeps the position within [maxDrift], mirrors play/pause.
class TogetherController extends Notifier<TogetherState> {
  ListenTogetherRelay? _relay;
  NearbyBeacon? _beacon;
  final _links = <TogetherLink>[];
  final _subs = <StreamSubscription<Object?>>[];
  Timer? _heartbeat;
  int _epoch = 0;

  static const _port = 47800;

  /// Who is listening: guest id -> (name, last heard).
  final _guests = <String, (String, DateTime)>{};

  final _me = List.generate(10, (_) => math.Random().nextInt(36).toRadixString(36)).join();

  PlayerController get _player => ref.read(playerControllerProvider);

  String get _myName {
    // Never the computer's name: this goes to other people and, for code
    // sessions, through a public broker.
    final set = ref.read(settingsProvider).togetherName.trim();
    return set.isNotEmpty ? set : l10n.someone;
  }

  @override
  TogetherState build() {
    ref.onDispose(_teardown);
    return const TogetherState();
  }

  // ---------------------------------------------------------------- host

  Future<void> host() async {
    await leave();
    final epoch = _epoch;
    state = TogetherState(busy: true, status: l10n.starting);
    final settings = ref.read(settingsProvider);
    final relayUrl = settings.relayUrl.trim();
    var room = randomRoom();
    InternetAddress? lanIp;

    // Internet: your own relay, or else a public server (tried twice, they
    // can be slow to answer). The code tells guests which one.
    var internet = false;
    if (relayUrl.isNotEmpty) {
      Future<TogetherLink> connect() => RelayLink.connect(Uri.parse(relayUrl), room, 'host');
      try {
        final link = await connect();
        _addHostLink(link);
        _keepHostLink(link, connect);
        internet = true;
      } on Object {
        // Falls through to "same Wi-Fi only" below.
      }
    } else if (settings.togetherInternet) {
      final brokers = ref.read(cloudBrokersProvider);
      for (var i = 0; i < brokers.length * 2 && !internet; i++) {
        if (epoch != _epoch) return;
        final at = i % brokers.length;
        final candidate = randomRoomOn(at, brokers.length);
        Future<TogetherLink> connect() => CloudLink.connect(candidate, host: true, broker: brokers[at]);
        try {
          final link = await connect();
          room = candidate;
          _addHostLink(link);
          _keepHostLink(link, connect);
          internet = true;
        } on Object {
          continue;
        }
      }
    }

    // Same Wi-Fi: a small relay inside this app.
    try {
      _relay = await ListenTogetherRelay.start(port: _port);
      _addHostLink(await RelayLink.connect(Uri.parse('ws://127.0.0.1:$_port/'), room, 'host'));
      lanIp = await _lanAddress();
    } on Object {
      await _relay?.close();
      _relay = null;
    }
    if (epoch != _epoch) return; // left meanwhile
    if (_links.isEmpty) {
      _teardown();
      state = TogetherState(status: l10n.couldNotStartCheckYourNetwork, error: true);
      return;
    }

    _beacon = await NearbyBeacon.start(room: room, name: _myName, song: () => _player.queue.current?.title ?? '');
    final code = internet || lanIp == null ? room : lanCode(room, lanIp);
    state = TogetherState(
      role: TogetherRole.host,
      code: code,
      connected: true,
      overInternet: internet,
      status: l10n.waitingForFriends,
    );
    _subs
      ..add(_player.queueStream.listen((_) => _broadcast()))
      ..add(_player.stateStream.listen((s) => _broadcast(onlyIfJump: true)));
    _heartbeat = Timer.periodic(const Duration(seconds: 5), (_) {
      _forgetSilentGuests();
      _broadcast();
    });
    _broadcast();
  }

  /// A dropped connection comes back by itself, on the same server (that's
  /// where the guests are), for as long as the session runs.
  void _keepHostLink(TogetherLink link, Future<TogetherLink> Function() connect) {
    final epoch = _epoch;
    unawaited(link.done.whenComplete(() async {
      if (epoch != _epoch) return;
      _links.remove(link);
      while (epoch == _epoch) {
        await Future<void>.delayed(ref.read(togetherRetryDelayProvider));
        if (epoch != _epoch) return;
        try {
          final fresh = await connect();
          if (epoch != _epoch) {
            unawaited(fresh.close());
            return;
          }
          _addHostLink(fresh);
          _keepHostLink(fresh, connect);
          _broadcast(forceQueue: true);
          return;
        } on Object {
          continue;
        }
      }
    }));
  }

  void _addHostLink(TogetherLink link) {
    _links.add(link);
    _subs.add(link.messages.listen((m) => _onHostMessage(link, m)));
  }

  void _onHostMessage(TogetherLink from, Map<String, dynamic> m) {
    switch (m['t']) {
      case 'ping':
        final id = m['id'] as String? ?? 'guest';
        final isNew = !_guests.containsKey(id);
        _guests[id] = (m['name'] as String? ?? l10n.friend, DateTime.now());
        from.send({'t': 'pong', 'at': m['at'], 'id': id, 'host': DateTime.now().millisecondsSinceEpoch});
        if (isNew) {
          _guestsChanged();
          _broadcast(forceQueue: true);
        }
      case 'need':
        _broadcast(forceQueue: true);
      case 'bye':
        if (_guests.remove(m['id']) != null) _guestsChanged();
    }
  }

  void _forgetSilentGuests() {
    final limit = DateTime.now().subtract(const Duration(seconds: 28));
    final before = _guests.length;
    _guests.removeWhere((_, g) => g.$2.isBefore(limit));
    if (_guests.length != before) _guestsChanged();
  }

  void _guestsChanged() {
    final names = [for (final g in _guests.values) g.$1];
    state = state.copyWith(
      guests: names.length,
      people: names,
      status: names.isEmpty ? l10n.waitingForFriends : l10n.listeningTogether,
    );
    _broadcast();
  }

  Duration _lastSentPos = Duration.zero;
  bool _lastSentPlaying = false;
  int _lastSentAt = 0;
  String _lastQueueKey = '';
  int _queueVersion = 0;

  void _broadcast({bool onlyIfJump = false, bool forceQueue = false}) {
    if (_links.isEmpty || state.role != TogetherRole.host) return;
    final q = _player.queue;
    final s = _player.state;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (onlyIfJump) {
      // Only seeks and play/pause need an immediate message.
      final expected = _lastSentPos + Duration(milliseconds: _lastSentPlaying ? now - _lastSentAt : 0);
      if (s.playing == _lastSentPlaying && (s.position - expected).abs() < const Duration(seconds: 2)) return;
    }
    _lastSentPos = s.position;
    _lastSentPlaying = s.playing;
    _lastSentAt = now;
    final (start, end) = sharedWindow(q.index, q.tracks.length);
    final refs = [for (final t in q.tracks.sublist(start, end)) TrackRef.of(t)];
    final key = '$start|${refs.map((r) => r.uri).join('|')}';
    final changed = key != _lastQueueKey;
    if (changed) {
      _lastQueueKey = key;
      _queueVersion++;
    }
    final message = SharedState(
      // The queue only when it changed or someone needs it.
      queue: changed || forceQueue ? refs : const [],
      index: q.index - start,
      positionMs: s.position.inMilliseconds,
      playing: s.playing,
      speed: _player.tuning.speed,
      sentAtMs: now,
      queueVersion: _queueVersion,
      hostName: _myName,
      people: [for (final g in _guests.values) g.$1],
    ).toJson();
    for (final link in _links) {
      link.send(message);
    }
  }

  // --------------------------------------------------------------- guest

  Future<void> join(String code, {InternetAddress? direct}) async {
    await leave();
    final epoch = _epoch;
    final parsed = parseJoinCode(code);
    if (parsed == null) {
      state = TogetherState(status: l10n.thatCodeDoesNotLookRight, error: true);
      return;
    }
    final (room, ip) = parsed;
    final settings = ref.read(settingsProvider);
    state = TogetherState(busy: true, code: room, status: l10n.lookingFor(room));

    // Same network first (no server involved), then the internet.
    final nearby = ref.exists(nearbySessionsProvider) ? ref.read(nearbySessionsProvider).value : null;
    final seen = nearby?.where((n) => n.room == room).firstOrNull;
    final lan = direct ?? ip ?? seen?.address;
    final attempts = <Future<TogetherLink> Function()>[
      if (lan != null) () => RelayLink.connect(Uri.parse('ws://${lan.address}:$_port/'), room, 'guest'),
      if (settings.relayUrl.trim().isNotEmpty)
        () => RelayLink.connect(Uri.parse(settings.relayUrl.trim()), room, 'guest')
      else if (settings.togetherInternet)
        for (final b in _brokersFor(room)) () => CloudLink.connect(room, host: false, broker: b),
    ];
    for (final attempt in attempts) {
      if (epoch != _epoch) return;
      TogetherLink? link;
      try {
        link = await attempt();
        if (await _hostAnswers(link, room, attempt)) {
          if (epoch != _epoch) {
            await link.close();
            return;
          }
          return;
        }
        await link.close();
      } on Object {
        await link?.close();
      }
    }
    if (epoch != _epoch) return;
    state = TogetherState(
      status: attempts.isEmpty
          ? l10n.onlineSessionsAreOffSettingsListen
          : l10n.noSessionWithTheCodeCheck(room),
      error: true,
    );
  }

  /// The server in the code, a second try on it (they can be slow to answer),
  /// then the others in case the code came from another version.
  List<CloudBroker> _brokersFor(String room) {
    final all = ref.read(cloudBrokersProvider);
    if (all.isEmpty) return const [];
    final first = all[brokerOfRoom(room, all.length)];
    return [first, first, ...all.where((b) => !identical(b, first))];
  }

  /// Says hello and waits for the host; on an answer the session has begun.
  Future<bool> _hostAnswers(TogetherLink link, String room, Future<TogetherLink> Function() connect) async {
    final answered = Completer<bool>();
    final sub = link.messages.listen((m) {
      final t = m['t'];
      if ((t == 'pong' || t == 'state') && !answered.isCompleted) answered.complete(true);
    });
    final retry = Timer.periodic(const Duration(seconds: 1), (_) => _sendPing(link));
    _sendPing(link);
    final ok = await answered.future.timeout(const Duration(seconds: 4), onTimeout: () => false);
    retry.cancel();
    await sub.cancel();
    if (!ok) return false;
    _addGuestLink(link, connect);
    _lastHostHeard = DateTime.now();
    state = TogetherState(role: TogetherRole.guest, code: room, connected: true, status: l10n.followingTheHost);
    _heartbeat = Timer.periodic(const Duration(seconds: 8), (_) {
      final current = _links.firstOrNull;
      if (current != null) _sendPing(current);
      _checkHost();
    });
    _sendPing(link);
    link.send({'t': 'need'});
    return true;
  }

  /// Keeps a guest in the session through a dropped connection; [_checkHost]
  /// gives up after a minute without the host.
  void _addGuestLink(TogetherLink link, Future<TogetherLink> Function() connect) {
    final epoch = _epoch;
    _links.add(link);
    _subs.add(link.messages.listen(_onGuestMessage));
    unawaited(link.done.whenComplete(() async {
      if (epoch != _epoch || state.role != TogetherRole.guest) return;
      _links.remove(link);
      state = state.copyWith(status: l10n.reconnecting);
      while (epoch == _epoch) {
        await Future<void>.delayed(ref.read(togetherRetryDelayProvider));
        if (epoch != _epoch) return;
        try {
          final fresh = await connect();
          if (epoch != _epoch) {
            unawaited(fresh.close());
            return;
          }
          _addGuestLink(fresh, connect);
          _sendPing(fresh);
          fresh.send({'t': 'need'});
          state = state.copyWith(status: l10n.followingTheHost);
          return;
        } on Object {
          continue;
        }
      }
    }));
  }

  int _pingSent = 0;
  int _clockOffset = 0;
  DateTime _lastHostHeard = DateTime(0);

  void _sendPing(TogetherLink link) {
    _pingSent = DateTime.now().millisecondsSinceEpoch;
    link.send({'t': 'ping', 'at': _pingSent, 'id': _me, 'name': _myName});
  }

  void _checkHost() {
    final silence = DateTime.now().difference(_lastHostHeard);
    if (silence > const Duration(seconds: 60)) {
      _endSession(l10n.theHostIsGone);
    } else if (silence > const Duration(seconds: 20)) {
      state = state.copyWith(status: l10n.waitingForTheHost);
    }
  }

  void _endSession(String why) {
    _teardown();
    state = TogetherState(status: why);
  }

  void _onGuestMessage(Map<String, dynamic> m) {
    _lastHostHeard = DateTime.now();
    switch (m['t']) {
      case 'pong' when m['at'] == _pingSent && m['id'] == _me:
        _clockOffset = clockOffsetMs(
          sentMs: _pingSent,
          receivedMs: DateTime.now().millisecondsSinceEpoch,
          hostMs: m['host'] as int? ?? 0,
        );
      case 'state':
        _onState(SharedState.fromJson(m));
      case 'ended':
        _endSession(l10n.theHostEndedTheSession);
    }
  }

  List<TrackRef> _queue = const [];
  int _haveVersion = -1;
  SharedState? _pendingState;
  bool _applying = false;

  void _onState(SharedState s) {
    if (s.queue.isNotEmpty) {
      _queue = s.queue;
      _haveVersion = s.queueVersion;
    } else if (s.queueVersion != _haveVersion && _links.isNotEmpty) {
      _links.first.send({'t': 'need'}); // missed one
    }
    if (s.hostName.isNotEmpty || s.people.isNotEmpty) {
      state = state.copyWith(hostName: s.hostName, people: s.people, guests: s.people.length);
    }
    if (_queue.isEmpty) return;
    _pendingState = s;
    unawaited(_drainStates());
  }

  /// One at a time: applying takes a while, only the newest state matters.
  Future<void> _drainStates() async {
    if (_applying) return;
    _applying = true;
    try {
      while (_pendingState != null && state.role == TogetherRole.guest) {
        final s = _pendingState!;
        _pendingState = null;
        await _applyState(s);
      }
    } finally {
      _applying = false;
    }
  }

  /// Songs missing here but found online, by the host's uri.
  final _foundOnline = <String, Track?>{};
  final _searching = <String>{};

  Future<void> _applyState(SharedState s) async {
    final library = await ref.read(libraryRepositoryProvider).watchTracks().first;
    final matcher = TrackMatcher(library);
    final matched = <Track>[];
    var localIndex = -1;
    for (var i = 0; i < _queue.length; i++) {
      final t = matcher.match(_queue[i]) ?? _foundOnline[_queue[i].uri];
      if (t == null) continue;
      if (i == s.index) localIndex = matched.length;
      matched.add(t);
    }
    if (localIndex < 0) {
      final missing = s.index >= 0 && s.index < _queue.length ? _queue[s.index] : null;
      final label = missing == null ? null : '${missing.title} – ${missing.artist}';
      if (missing != null) unawaited(_findOnline(missing, s));
      state = state.copyWith(
        status: _searching.isNotEmpty ? l10n.lookingForTheSongOnline : l10n.theHostIsPlayingASong,
        missingSong: label,
      );
      await _player.pause();
      return;
    }
    final expected = s.expectedPosition(guestNowMs: DateTime.now().millisecondsSinceEpoch, clockOffsetMs: _clockOffset);
    if (_player.queue.current?.id != matched[localIndex].id) {
      await _player.playTracks(matched, startIndex: localIndex, shuffle: false);
      await _player.seek(expected);
    } else if (needsSeek(_player.state.position, expected)) {
      await _player.seek(expected);
    }
    if ((_player.tuning.speed - s.speed).abs() > 0.01) await _player.setSpeed(s.speed);
    if (s.playing && !_player.state.playing) await _player.play();
    if (!s.playing && _player.state.playing) await _player.pause();
    if (state.missingSong != null || state.status != l10n.followingTheHost) {
      state = state.copyWith(status: l10n.followingTheHost, clearMissing: true);
    }
  }

  /// A song this library doesn't have: try the online services that are on.
  Future<void> _findOnline(TrackRef r, SharedState latest) async {
    if (_foundOnline.containsKey(r.uri) || !_searching.add(r.uri)) return;
    try {
      final hub = ref.read(onlineHubProvider);
      if (hub.playable.isEmpty) {
        _foundOnline[r.uri] = null;
        return;
      }
      final result = await ref.read(matchServiceProvider).match(
            ExternalTrack(
              service: OnlineService.file,
              title: r.title,
              artists: isUnknownArtist(r.artist) ? const [] : [r.artist],
              durationMs: r.durationMs,
            ),
          );
      final track = result.track;
      _foundOnline[r.uri] = track == null ? null : await ref.read(remoteTrackStoreProvider).ensure(track);
    } on Object {
      _foundOnline[r.uri] = null;
    } finally {
      _searching.remove(r.uri);
    }
    if (_foundOnline[r.uri] != null && state.role == TogetherRole.guest) {
      _pendingState ??= latest;
      unawaited(_drainStates());
    } else if (state.role == TogetherRole.guest) {
      state = state.copyWith(status: l10n.theHostIsPlayingASong);
    }
  }

  // ---------------------------------------------------------------- shared

  Future<InternetAddress?> _lanAddress() async {
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    // Prefer typical home-network ranges.
    for (final i in interfaces) {
      for (final a in i.addresses) {
        if (a.address.startsWith('192.168.') || a.address.startsWith('10.') || a.address.startsWith('172.')) return a;
      }
    }
    return interfaces.expand((i) => i.addresses).where((a) => !a.isLoopback).firstOrNull;
  }

  Future<void> leave() async {
    if (state.role == TogetherRole.host) {
      for (final l in _links) {
        l.send({'t': 'ended'});
      }
    } else if (state.role == TogetherRole.guest) {
      for (final l in _links) {
        l.send({'t': 'bye', 'id': _me});
      }
    }
    _teardown();
    state = const TogetherState();
  }

  void _teardown() {
    _epoch++;
    _heartbeat?.cancel();
    _heartbeat = null;
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
    final links = _links.toList();
    _links.clear();
    for (final l in links) {
      unawaited(l.close().catchError((Object _) {}));
    }
    _beacon?.stop();
    _beacon = null;
    final relay = _relay;
    _relay = null;
    if (relay != null) unawaited(relay.close().catchError((Object _) {}));
    _guests.clear();
    _lastQueueKey = '';
    _queue = const [];
    _haveVersion = -1;
    _pendingState = null;
    _foundOnline.clear();
  }
}

/// Finds a join code in pasted text (a friend's message), for the sheet.
String? findJoinCode(String? text) {
  if (text == null) return null;
  final m = RegExp(r'\b[A-Z2-9]{5}(?:-[0-9A-F]{8})?\b').firstMatch(text.trim());
  final code = m?.group(0);
  return code != null && parseJoinCode(code) != null ? code : null;
}


final togetherProvider = NotifierProvider<TogetherController, TogetherState>(TogetherController.new);
