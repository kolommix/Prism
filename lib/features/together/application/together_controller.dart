import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/application/library_providers.dart';
import '../../library/domain/track.dart';
import '../../online/application/online_providers.dart';
import '../../online/domain/external_track.dart';
import '../../online/services/youtube/youtube_module.dart';
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
    this.who = const [],
    this.overInternet = false,
    this.error = false,
    this.control = true,
    this.myStatus = PersonStatus.listening,
    this.notice,
    this.noticeId = 0,
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

  /// The same people with how it goes for each.
  final List<SessionPerson> who;

  /// Friends outside this network can join.
  final bool overInternet;

  /// Guests may control the music (host: the switch; guest: what the host allows).
  final bool control;

  /// Guest: how it goes here (sent to the host, shown to everyone).
  final PersonStatus myStatus;

  /// Something to tell the user once (a snackbar), new each time [noticeId] changes.
  final String? notice;
  final int noticeId;

  TogetherState copyWith({
    int? guests,
    String? status,
    String? missingSong,
    bool clearMissing = false,
    String? hostName,
    List<String>? people,
    List<SessionPerson>? who,
    bool? control,
    PersonStatus? myStatus,
    String? notice,
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
        who: who ?? this.who,
        overInternet: overInternet,
        control: control ?? this.control,
        myStatus: myStatus ?? this.myStatus,
        notice: notice ?? this.notice,
        noticeId: notice == null ? noticeId : noticeId + 1,
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
/// position on every jump and every 5 s. Every song goes with its YouTube
/// upload when the host knows it (imported and streamed songs), and when a
/// friend is missing a song the host looks it up once, so everyone plays the
/// very same upload. Friends may play, pause, skip, seek and add songs
/// ([TogetherState.control], on by default).
/// Guest: finds the session (same network first, then the internet), matches
/// songs in the local library, plays the host's YouTube upload or searches
/// for missing ones, keeps the position within [maxDrift], mirrors play/pause,
/// and sends its own play/pause/skip/seek/"play next" to the host.
class TogetherController extends Notifier<TogetherState> {
  ListenTogetherRelay? _relay;
  NearbyBeacon? _beacon;
  final _links = <TogetherLink>[];
  final _subs = <StreamSubscription<Object?>>[];
  Timer? _heartbeat;
  int _epoch = 0;

  static const _port = 47800;

  /// Who is listening: guest id -> (name, last heard, status).
  final _guests = <String, (String, DateTime, PersonStatus)>{};

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

  /// The message friends get: the code with a line on what to do with it.
  String inviteText() => l10n.togetherInviteText(state.code ?? '');

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
      control: settings.togetherGuestControl,
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

  /// Host: friends may control the music, or only the host.
  void setGuestControl(bool on) {
    try {
      ref.read(settingsProvider.notifier).update((s) => s.copyWith(togetherGuestControl: on));
    } on Object {
      // Not saved (no settings store): this session still follows the switch.
    }
    if (state.role != TogetherRole.host) return;
    state = state.copyWith(control: on);
    _broadcast(forceQueue: true);
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

  /// Anyone with the code can send these: types are checked, text kept small.
  static String? _guestId(Object? raw) => raw is String && raw.isNotEmpty && raw.length <= 64 ? raw : null;

  void _onHostMessage(TogetherLink from, Map<String, dynamic> m) {
    switch (m['t']) {
      case 'ping':
        final id = _guestId(m['id']) ?? 'guest';
        final rawName = m['name'];
        final isNew = !_guests.containsKey(id);
        if (isNew && _guests.length >= 50) return;
        final name = rawName is String && rawName.trim().isNotEmpty
            ? (rawName.length > 40 ? rawName.substring(0, 40) : rawName)
            : l10n.friend;
        final status = PersonStatus.parse(m['st']);
        final before = _guests[id];
        _guests[id] = (name, DateTime.now(), status);
        from.send({'t': 'pong', 'at': m['at'], 'id': id, 'host': DateTime.now().millisecondsSinceEpoch});
        if (isNew || before?.$1 != name || before?.$3 != status) {
          _guestsChanged();
          if (isNew) _broadcast(forceQueue: true);
        }
        if (status != PersonStatus.listening) unawaited(_lookUpForGuests());
      case 'need':
        _broadcast(forceQueue: true);
      case 'bye':
        if (_guests.remove(m['id']) != null) _guestsChanged();
      case 'cmd':
        unawaited(_onCommand(from, m));
    }
  }

  // ---- what friends ask for

  Future<void> _onCommand(TogetherLink from, Map<String, dynamic> m) async {
    final id = _guestId(m['id']);
    final guest = id == null ? null : _guests[id];
    final command = TogetherCommand.parse(m['op']);
    if (guest == null || command == null) return;
    if (!state.control) {
      from.send({'t': 'denied', 'id': id});
      return;
    }
    final p = _player;
    switch (command) {
      case TogetherCommand.play:
        await p.play();
      case TogetherCommand.pause:
        await p.pause();
      case TogetherCommand.seek:
        final pos = m['pos'];
        if (pos is int && pos >= 0) await p.seek(Duration(milliseconds: pos));
      case TogetherCommand.next:
        await p.skipNext();
      case TogetherCommand.previous:
        await p.skipPrevious();
      case TogetherCommand.jump:
        final i = m['i'];
        final (start, end) = sharedWindow(p.queue.index, p.queue.tracks.length);
        if (i is int && start + i >= start && start + i < end) await p.jumpTo(start + i);
      case TogetherCommand.playNext || TogetherCommand.add || TogetherCommand.playNow:
        final refs = [
          for (final r in (m['refs'] as List? ?? const []).take(maxCommandSongs))
            if (r is Map<String, dynamic>) TrackRef.fromJson(r),
        ];
        final tracks = await _tracksFor(refs);
        if (tracks.isEmpty) {
          from.send({'t': 'denied', 'id': id, 'why': 'missing'});
          return;
        }
        if (command == TogetherCommand.add) {
          await p.addToQueue(tracks);
        } else {
          final wasEmpty = p.queue.isEmpty;
          await p.playNext(tracks.take(command == TogetherCommand.playNow ? 1 : tracks.length).toList());
          if (command == TogetherCommand.playNow && !wasEmpty) await p.skipNext();
        }
    }
    state = state.copyWith(notice: l10n.togetherChangedBy(guest.$1));
    _broadcast(forceQueue: true);
  }

  /// Songs a friend sent: from this library, else their YouTube upload, else
  /// a search on the online services that are on.
  Future<List<Track>> _tracksFor(List<TrackRef> refs) async {
    if (refs.isEmpty) return const [];
    final matcher = TrackMatcher(await ref.read(libraryRepositoryProvider).watchTracks().first);
    final out = <Track>[];
    for (final r in refs) {
      final t = matcher.match(r) ?? await _online(r);
      if (t != null) out.add(t);
    }
    return out;
  }

  /// The song on an online service: its YouTube upload when given (and
  /// YouTube playback is on), else a search. Null when nothing fits.
  Future<Track?> _online(TrackRef r) async {
    try {
      final hub = ref.read(onlineHubProvider);
      final yt = r.yt;
      if (yt != null && hub.playable.any((m) => m.playableSourceId == youtubeSourceId)) {
        return await ref.read(remoteTrackStoreProvider).ensure(Track(
              id: 0,
              sourceId: youtubeSourceId,
              uri: 'https://www.youtube.com/watch?v=$yt',
              title: r.title,
              artist: r.artist,
              durationMs: r.durationMs,
            ));
      }
      if (hub.playable.isEmpty) return null;
      final result = await ref.read(matchServiceProvider).match(_external(r));
      final track = result.track;
      return track == null ? null : await ref.read(remoteTrackStoreProvider).ensure(track);
    } on Object {
      return null;
    }
  }

  static ExternalTrack _external(TrackRef r) => ExternalTrack(
        service: OnlineService.file,
        title: r.title,
        artists: isUnknownArtist(r.artist) ? const [] : [r.artist],
        durationMs: r.durationMs,
      );

  // ---- finding songs for friends

  /// YouTube uploads the host found for its own songs (shared uri -> id).
  final _ytFor = <String, String?>{};
  bool _lookingUp = false;

  /// A friend is missing a song: the host looks up the current and the next
  /// two songs once (if YouTube is on here), and sends the uploads it found,
  /// so every friend plays the same one.
  Future<void> _lookUpForGuests() async {
    if (_lookingUp || state.role != TogetherRole.host) return;
    _lookingUp = true;
    try {
      final hub = ref.read(onlineHubProvider);
      if (!hub.playable.any((m) => m.playableSourceId == youtubeSourceId)) return;
      final q = _player.queue;
      var found = false;
      for (var i = q.index; i >= 0 && i < q.tracks.length && i <= q.index + 2; i++) {
        final t = q.tracks[i];
        final key = TrackRef.sharedUri(t);
        if (_ytFor.containsKey(key) || youtubeIdOfTrack(t) != null) continue;
        _ytFor[key] = null; // once per song, also when nothing is found
        final result = await ref.read(matchServiceProvider).match(_external(TrackRef.of(t)));
        final match = result.track;
        if (match != null && match.sourceId == youtubeSourceId) {
          _ytFor[key] = youtubeIdOfTrack(match);
          found = true;
        }
      }
      if (found) _broadcast(forceQueue: true);
    } on Object {
      // No online services, or they failed: friends search themselves.
    } finally {
      _lookingUp = false;
    }
  }

  void _forgetSilentGuests() {
    final limit = DateTime.now().subtract(const Duration(seconds: 28));
    final before = _guests.length;
    _guests.removeWhere((_, g) => g.$2.isBefore(limit));
    if (_guests.length != before) _guestsChanged();
  }

  List<SessionPerson> get _who => [for (final g in _guests.values) SessionPerson(g.$1, g.$3)];

  void _guestsChanged() {
    final who = _who;
    final names = [for (final w in who) w.name];
    state = state.copyWith(
      guests: names.length,
      people: names,
      who: who,
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
    final refs = [
      for (final t in q.tracks.sublist(start, end)) TrackRef.shared(t, yt: _ytFor[TrackRef.sharedUri(t)]),
    ];
    final key = '$start|${refs.map((r) => '${r.uri}#${r.yt ?? ''}').join('|')}';
    final changed = key != _lastQueueKey;
    if (changed) {
      _lastQueueKey = key;
      _queueVersion++;
    }
    final who = _who;
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
      people: [for (final w in who) w.name],
      who: who,
      control: state.control,
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
    // From now on this player's buttons, media keys and "play next" go to the host.
    _player.remote = _GuestRemote(this);
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
    link.send({'t': 'ping', 'at': _pingSent, 'id': _me, 'name': _myName, 'st': state.myStatus.name});
  }

  void _setMyStatus(PersonStatus s) {
    if (state.myStatus == s) return;
    state = state.copyWith(myStatus: s);
    final link = _links.firstOrNull;
    if (link != null) _sendPing(link); // everyone sees it now, not in 8 s
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
      case 'denied' when m['id'] == _me:
        final host = state.hostName ?? l10n.friend;
        state = state.copyWith(
          notice: m['why'] == 'missing' ? l10n.togetherHostCantFind(host) : l10n.togetherOnlyHostControls(host),
        );
        // Back to where the host is (an optimistic local change is undone).
        final latest = _latestState;
        if (latest != null) {
          _pendingState ??= latest;
          unawaited(_drainStates());
        }
      case 'ended':
        _endSession(l10n.theHostEndedTheSession);
    }
  }

  // ---- the guest's own buttons

  /// The host lets guests control the music.
  bool get _controlAllowed => state.control;

  /// Sends a command to the host. False when there is no host to send to.
  bool _command(TogetherCommand op, [Map<String, Object> extra = const {}]) {
    final link = _links.firstOrNull;
    if (link == null || state.role != TogetherRole.guest) return false;
    if (!state.control) {
      state = state.copyWith(notice: l10n.togetherOnlyHostControls(state.hostName ?? l10n.friend));
      return true;
    }
    link.send({'t': 'cmd', 'id': _me, 'op': op.name, ...extra});
    return true;
  }

  List<Map<String, Object>> _refs(Iterable<Track> tracks) =>
      [for (final t in tracks.take(maxCommandSongs)) TrackRef.shared(t).toJson()];

  /// Shared-queue index of each song in this player's queue.
  List<int> _localToShared = const [];

  List<TrackRef> _queue = const [];
  int _haveVersion = -1;
  SharedState? _pendingState;
  bool _applying = false;

  /// Looks again for the song that is missing (YouTube was just turned on).
  void findMissingOnline() {
    _foundOnline.removeWhere((_, t) => t == null);
    final latest = _latestState;
    if (latest == null || state.role != TogetherRole.guest) return;
    _pendingState ??= latest;
    unawaited(_drainStates());
  }

  SharedState? _latestState;

  void _onState(SharedState s) {
    _latestState = s;
    if (s.queue.isNotEmpty) {
      _queue = s.queue;
      _haveVersion = s.queueVersion;
    } else if (s.queueVersion != _haveVersion && _links.isNotEmpty) {
      _links.first.send({'t': 'need'}); // missed one
    }
    final whoChanged = s.who.isNotEmpty
        ? !_samePeople(s.who, state.who)
        : s.people.length != state.people.length;
    if (s.hostName != state.hostName || whoChanged || s.control != state.control) {
      state = state.copyWith(
        hostName: s.hostName,
        people: s.people,
        who: s.who.isNotEmpty ? s.who : [for (final p in s.people) SessionPerson(p, PersonStatus.listening)],
        guests: s.people.length,
        control: s.control,
      );
    }
    if (_queue.isEmpty) return;
    _pendingState = s;
    unawaited(_drainStates());
  }

  static bool _samePeople(List<SessionPerson> a, List<SessionPerson> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].name != b[i].name || a[i].status != b[i].status) return false;
    }
    return true;
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
    final toShared = <int>[];
    var localIndex = -1;
    for (var i = 0; i < _queue.length; i++) {
      final r = _queue[i];
      final t = matcher.match(r) ?? _foundOnline[_key(r)];
      if (t == null) continue;
      if (i == s.index) localIndex = matched.length;
      matched.add(t);
      toShared.add(i);
    }
    if (localIndex < 0) {
      final missing = s.index >= 0 && s.index < _queue.length ? _queue[s.index] : null;
      final label = missing == null ? null : '${missing.title} – ${missing.artist}';
      if (missing != null) unawaited(_findOnline(missing, s));
      final searching = _searching.isNotEmpty;
      _setMyStatus(searching ? PersonStatus.finding : PersonStatus.missing);
      state = state.copyWith(
        status: searching ? l10n.lookingForTheSongOnline : l10n.theHostIsPlayingASong,
        missingSong: label,
      );
      await _player.local.pause();
      return;
    }
    _localToShared = toShared;
    // Find the next songs now, so the session doesn't stop when they come up.
    for (var i = s.index + 1; i < _queue.length && i <= s.index + 3; i++) {
      if (i >= 0 && matcher.match(_queue[i]) == null) unawaited(_findOnline(_queue[i], s));
    }
    final expected = s.expectedPosition(guestNowMs: DateTime.now().millisecondsSinceEpoch, clockOffsetMs: _clockOffset);
    final local = _player.local;
    if (_player.queue.current?.id != matched[localIndex].id) {
      await local.playTracks(matched, startIndex: localIndex, shuffle: false);
      await local.seek(expected);
    } else {
      // Same song: songs added or moved around it don't restart it.
      if (!_sameQueue(matched)) await local.setQueue(matched, localIndex);
      if (needsSeek(_player.state.position, expected)) await local.seek(expected);
    }
    if ((_player.tuning.speed - s.speed).abs() > 0.01) await _player.setSpeed(s.speed);
    if (s.playing && !_player.state.playing) await local.play();
    if (!s.playing && _player.state.playing) await local.pause();
    _setMyStatus(PersonStatus.listening);
    if (state.missingSong != null || state.status != l10n.followingTheHost) {
      state = state.copyWith(status: l10n.followingTheHost, clearMissing: true);
    }
  }

  /// This player's queue holds exactly [tracks] (a song the host added shows
  /// up here too, without restarting the one that plays).
  bool _sameQueue(List<Track> tracks) {
    final q = _player.queue.tracks;
    if (q.length != tracks.length) return false;
    for (var i = 0; i < q.length; i++) {
      if (q[i].id != tracks[i].id) return false;
    }
    return true;
  }

  /// The same song from the host can come with or without its YouTube id.
  static String _key(TrackRef r) => r.yt ?? r.uri;

  /// A song this library doesn't have: the host's YouTube upload, or a search
  /// on the online services that are on.
  Future<void> _findOnline(TrackRef r, SharedState latest) async {
    final key = _key(r);
    if (_foundOnline.containsKey(key) || !_searching.add(key)) return;
    try {
      _foundOnline[key] = await _online(r);
    } finally {
      _searching.remove(key);
    }
    if (_foundOnline[key] != null && state.role == TogetherRole.guest) {
      _pendingState ??= latest;
      unawaited(_drainStates());
    } else if (state.role == TogetherRole.guest && _searching.isEmpty && state.missingSong != null) {
      _setMyStatus(PersonStatus.missing);
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
    try {
      if (_player.remote is _GuestRemote) _player.remote = null;
    } on Object {
      // The player is gone already (app closing).
    }
    _guests.clear();
    _ytFor.clear();
    _lastQueueKey = '';
    _queue = const [];
    _localToShared = const [];
    _haveVersion = -1;
    _pendingState = null;
    _foundOnline.clear();
  }
}

/// A guest's play, pause, skip, seek and "play next": to the host. Play,
/// pause and seek also happen here at once, so the buttons feel instant; the
/// host's answer keeps everyone in step.
class _GuestRemote implements PlayerRemote {
  _GuestRemote(this._c);
  final TogetherController _c;

  LocalPlayer get _local => _c._player.local;

  @override
  bool play() {
    final sent = _c._command(TogetherCommand.play);
    if (sent && _c._controlAllowed) unawaited(_local.play());
    return sent;
  }

  @override
  bool pause() {
    final sent = _c._command(TogetherCommand.pause);
    if (sent && _c._controlAllowed) unawaited(_local.pause());
    return sent;
  }

  @override
  bool seek(Duration position) {
    final sent = _c._command(TogetherCommand.seek, {'pos': position.inMilliseconds});
    if (sent && _c._controlAllowed) unawaited(_local.seek(position));
    return sent;
  }

  @override
  bool skipNext() => _c._command(TogetherCommand.next);

  @override
  bool skipPrevious() => _c._command(TogetherCommand.previous);

  @override
  bool jumpTo(int index) {
    final map = _c._localToShared;
    if (index < 0 || index >= map.length) return false;
    return _c._command(TogetherCommand.jump, {'i': map[index]});
  }

  @override
  bool playTracks(List<Track> tracks, int startIndex) {
    if (startIndex < 0 || startIndex >= tracks.length) return false;
    return _c._command(TogetherCommand.playNow, {'refs': _c._refs([tracks[startIndex]])});
  }

  @override
  bool playNext(List<Track> tracks) => _c._command(TogetherCommand.playNext, {'refs': _c._refs(tracks)});

  @override
  bool addToQueue(List<Track> tracks) => _c._command(TogetherCommand.add, {'refs': _c._refs(tracks)});
}

/// Finds a join code in pasted text (a friend's message), for the sheet.
String? findJoinCode(String? text) {
  if (text == null) return null;
  final m = RegExp(r'\b[A-Z2-9]{5}(?:-[0-9A-F]{8})?\b').firstMatch(text.trim());
  final code = m?.group(0);
  return code != null && parseJoinCode(code) != null ? code : null;
}

/// A code in a Prism invite (the "Copy invite" message), for the "join?"
/// question when Prism comes to the front. Plain text without "Prism" in it
/// is not taken: a random 5-letter word in the clipboard asks nothing.
String? findInviteCode(String? text) {
  if (text == null || !text.contains('Prism') || text.length > 400) return null;
  return findJoinCode(text);
}

final togetherProvider = NotifierProvider<TogetherController, TogetherState>(TogetherController.new);
