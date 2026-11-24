import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../l10n/l10n.dart';
import '../../domain/external_track.dart';
import '../../domain/online_error.dart';

/// One audio-only format of a video.
class InnertubeFormat {
  const InnertubeFormat({
    required this.url,
    required this.itag,
    required this.mimeType,
    required this.bitrate,
    required this.length,
  });

  final Uri url;
  final int itag;
  final String mimeType;
  final int bitrate;

  /// Bytes (0 when YouTube didn't say).
  final int length;

  /// `mp4` (AAC, saved as .m4a) or `webm` (Opus).
  String get container => mimeType.startsWith('audio/mp4') ? 'mp4' : 'webm';
}

/// Asks YouTube's player API for a video's audio the way YouTube's own
/// visionOS app does.
///
/// Late 2026 YouTube serves the Android and web clients that
/// youtube_explode uses only the first megabyte of most music uploads, and
/// asks them to "sign in to confirm you're not a bot". The visionOS client
/// with a visitor id gets plain audio links that serve the whole file, with
/// no signature to decipher and no proof token (the client yt-dlp uses for
/// the same songs, see yt-dlp's `INNERTUBE_CLIENTS`). Measured 2026-11-25:
/// 6 of 6 music uploads the other clients were refused, each whole, in under
/// a second.
///
/// Works on every platform (Android has no yt-dlp). When YouTube changes this
/// again the caller falls back to the other clients and yt-dlp.
class InnertubeAudio {
  InnertubeAudio({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  static const _player = 'https://www.youtube.com/youtubei/v1/player?prettyPrint=false';
  static const _visitorUrl = 'https://www.youtube.com/youtubei/v1/visitor_id?prettyPrint=false';
  static const clientName = 'VISIONOS';
  static const clientVersion = '1.02';
  static const clientId = '101';
  static const userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15';

  /// A visitor id lasts for months; a fresh one is asked for after this long,
  /// or when YouTube refuses the one we have.
  static const visitorLifetime = Duration(hours: 6);

  String? _visitor;
  DateTime _visitorAt = DateTime(0);

  /// Every audio format with a plain link, best first: AAC before Opus
  /// (Prism can write tags into .m4a), then higher bitrate. Throws
  /// [OnlineException]: notFound when the video can't be played at all.
  Future<List<InnertubeFormat>> audioFormats(String videoId) async {
    var visitor = await _visitorId();
    for (var attempt = 0; ; attempt++) {
      final j = await _ask(videoId, visitor);
      final status = (j['playabilityStatus'] as Map?)?['status'] as String? ?? '';
      final reason = (j['playabilityStatus'] as Map?)?['reason'] as String? ?? status;
      if (status == 'OK') return _formats(j);
      final fresh = (j['responseContext'] as Map?)?['visitorData'] as String?;
      if (status == 'LOGIN_REQUIRED' && attempt == 0) {
        // The visitor id went stale (or there was none): take the one YouTube
        // just handed out, or ask for a new one, and try once more.
        _visitor = null;
        visitor = (fresh != null && fresh != visitor) ? fresh : await _visitorId();
        _remember(visitor);
        continue;
      }
      if (status == 'LOGIN_REQUIRED') {
        throw OnlineException(OnlineErrorKind.rateLimited, service: OnlineService.youtube, message: l10n.youtubeAsksToSlowDownToo);
      }
      throw OnlineException(OnlineErrorKind.notFound, service: OnlineService.youtube, message: l10n.thisYoutubeVideoIsUnavailableRemoved(reason));
    }
  }

  Future<Map<String, dynamic>> _ask(String videoId, String? visitor) async {
    final body = {
      'context': {
        'client': {
          'clientName': clientName,
          'clientVersion': clientVersion,
          'deviceMake': 'Apple',
          'deviceModel': 'RealityDevice17,1',
          'userAgent': userAgent,
          'osName': 'visionOS',
          'osVersion': '26.5.23O471',
          'hl': 'en',
          'timeZone': 'UTC',
          'utcOffsetMinutes': 0,
          'visitorData': ?visitor,
        },
      },
      'videoId': videoId,
      'contentCheckOk': true,
      'racyCheckOk': true,
    };
    final http.Response r;
    try {
      r = await _http
          .post(
            Uri.parse(_player),
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
              HttpHeaders.userAgentHeader: userAgent,
              'X-YouTube-Client-Name': clientId,
              'X-YouTube-Client-Version': clientVersion,
              'X-Goog-Visitor-Id': ?visitor,
              'Origin': 'https://www.youtube.com',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw OnlineException(OnlineErrorKind.offline, service: OnlineService.youtube, message: l10n.youtubeDidNotAnswerInTime);
    } on SocketException {
      throw OnlineException(OnlineErrorKind.offline, service: OnlineService.youtube);
    } on http.ClientException {
      throw OnlineException(OnlineErrorKind.offline, service: OnlineService.youtube);
    }
    if (r.statusCode == 429) throw OnlineException(OnlineErrorKind.rateLimited, service: OnlineService.youtube);
    if (r.statusCode != 200) {
      throw OnlineException(
        OnlineErrorKind.badResponse,
        service: OnlineService.youtube,
        message: l10n.youtubeExtractorFailedYoutubeMayHave('HTTP ${r.statusCode}'),
      );
    }
    try {
      return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      throw OnlineException(OnlineErrorKind.badResponse, service: OnlineService.youtube);
    }
  }

  static List<InnertubeFormat> _formats(Map<String, dynamic> j) {
    final list = ((j['streamingData'] as Map?)?['adaptiveFormats'] as List?) ?? const [];
    final out = <InnertubeFormat>[];
    for (final f in list.whereType<Map>()) {
      final mime = f['mimeType'] as String? ?? '';
      final url = f['url'] as String?;
      // Links that need deciphering are of no use without YouTube's player code.
      if (!mime.startsWith('audio/') || url == null) continue;
      // Dubbed / described audio tracks: only the original.
      final track = f['audioTrack'] as Map?;
      if (track != null && track['audioIsDefault'] == false) continue;
      out.add(InnertubeFormat(
        url: Uri.parse(url),
        itag: f['itag'] as int? ?? 0,
        mimeType: mime,
        bitrate: f['bitrate'] as int? ?? 0,
        length: int.tryParse('${f['contentLength'] ?? ''}') ?? 0,
      ));
    }
    out.sort((a, b) {
      final byKind = (a.container == 'mp4' ? 0 : 1).compareTo(b.container == 'mp4' ? 0 : 1);
      return byKind != 0 ? byKind : b.bitrate.compareTo(a.bitrate);
    });
    return out;
  }

  Future<String?> _visitorId() async {
    final v = _visitor;
    if (v != null && DateTime.now().difference(_visitorAt) < visitorLifetime) return v;
    try {
      final r = await _http
          .post(
            Uri.parse(_visitorUrl),
            headers: {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.userAgentHeader: userAgent},
            body: jsonEncode({
              'context': {
                'client': {'clientName': 'WEB', 'clientVersion': '2.20260101.00.00', 'hl': 'en'},
              },
            }),
          )
          .timeout(const Duration(seconds: 15));
      final id = ((jsonDecode(r.body) as Map)['responseContext'] as Map?)?['visitorData'] as String?;
      _remember(id);
      return id;
    } on Object {
      // The player answer carries one too: the first try goes without.
      return null;
    }
  }

  void _remember(String? id) {
    if (id == null || id.isEmpty) return;
    _visitor = id;
    _visitorAt = DateTime.now();
  }

  void close() => _http.close();
}
