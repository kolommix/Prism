import 'dart:math' as math;

import '../../library/data/search_text.dart';
import '../../library/domain/track.dart';
import '../domain/external_track.dart';
import '../domain/matching.dart';
import '../domain/online_error.dart';
import '../services/music_service_module.dart';
import '../services/soundcloud/soundcloud_module.dart';
import '../services/youtube/youtube_module.dart';
import '../../../l10n/l10n.dart';

class MatchResult {
  const MatchResult({this.track, required this.score, this.source, this.note});

  static const none = MatchResult(score: MatchScore.zero);

  /// Null when nothing reached [MatchScorer.acceptThreshold].
  final Track? track;
  final MatchScore score;

  /// `local`, `direct`, `youtube`, `soundcloud`.
  final String? source;
  final String? note;

  bool get matched => track != null;
}

class ScoredCandidate {
  const ScoredCandidate(this.track, this.score);
  final Track track;
  final MatchScore score;
}

/// Finds a playable track for an imported song:
///
/// 1. the exact local file (M3U paths),
/// 2. the local library (title search, scored) – wins when it's at least
///    "medium", or close to the best online result,
/// 3. the linked video/track itself for YouTube / SoundCloud imports,
/// 4. search on each playable service (YouTube, then SoundCloud) with
///    "artist title", stopping early on a "high" match.
///
/// Online errors propagate as [OnlineException] so the import can pause and
/// resume later; a failing service never hides local matches.
class MatchService {
  MatchService({required this.localSearch, required this.localByUri, required this.playable});

  final Future<List<Track>> Function(String query) localSearch;
  final Future<Track?> Function(String uri) localByUri;
  final List<MusicServiceModule> Function() playable;

  /// Local wins ties within this margin ("local file first").
  static const localPreference = 0.1;

  Future<MatchResult> match(ExternalTrack wanted) async {
    final url = wanted.url;
    if (url != null && wanted.service == OnlineService.file && !url.contains('://')) {
      final exact = await localByUri(url);
      if (exact != null) {
        return MatchResult(
          track: exact,
          score: const MatchScore(value: 1, title: 1, artist: 1, duration: 1),
          source: 'local',
          note: l10n.sameFile,
        );
      }
    }

    final local = MatchScorer.best(wanted, await _localCandidates(wanted));
    if (local != null && local.score.value >= 0.7) {
      return MatchResult(track: local.track, score: local.score, source: 'local', note: local.score.note);
    }

    final services = playable();
    final direct = _direct(wanted, services);
    if (direct != null) {
      if (local != null && local.score.value >= MatchScorer.acceptThreshold) {
        // A decent local copy still beats streaming.
        return MatchResult(track: local.track, score: local.score, source: 'local', note: local.score.note);
      }
      return MatchResult(
        track: direct,
        score: const MatchScore(value: 1, title: 1, artist: 1, duration: 1),
        source: 'direct',
        note: l10n.linkedVideo,
      );
    }

    ({Track track, MatchScore score})? online;
    String? onlineSource;
    OnlineException? lastError;
    for (final m in services) {
      try {
        final found = await m.search(MatchScorer.queryFor(wanted), limit: 8);
        final best = MatchScorer.best(wanted, found);
        if (best != null && (online == null || best.score.value > online.score.value)) {
          online = best;
          onlineSource = m.playableSourceId;
        }
        if (online != null && online.score.confidence == MatchConfidence.high) break;
      } on OnlineException catch (e) {
        // Transient problems pause the import (retry later); a broken
        // service is skipped so the others still get a chance.
        if (e.isTransient) rethrow;
        lastError = e;
      }
    }

    final localScore = local?.score.value ?? 0;
    final onlineScore = online?.score.value ?? 0;
    if (local != null && localScore >= MatchScorer.acceptThreshold && localScore >= onlineScore - localPreference) {
      return MatchResult(track: local.track, score: local.score, source: 'local', note: local.score.note);
    }
    if (online != null && onlineScore >= MatchScorer.acceptThreshold) {
      return MatchResult(track: online.track, score: online.score, source: onlineSource, note: online.score.note);
    }
    final note = services.isEmpty
        ? l10n.notInYourLibraryTurnOn
        : lastError?.message;
    return MatchResult(
      score: math.max(localScore, onlineScore) > 0 ? (online ?? local)!.score : MatchScore.zero,
      note: note,
    );
  }

  /// Candidates for the "fix match" sheet: local + every playable service,
  /// best first. Service errors are returned per service, not thrown.
  Future<(List<ScoredCandidate>, Map<String, String>)> candidates(ExternalTrack wanted, String query) async {
    final out = <ScoredCandidate>[];
    final errors = <String, String>{};
    final q = query.trim().isEmpty ? MatchScorer.queryFor(wanted) : query;
    for (final t in await localSearch(q)) {
      out.add(ScoredCandidate(t, MatchScorer.score(wanted, t)));
    }
    await Future.wait([
      for (final m in playable())
        m
            .search(q, limit: 10)
            .then((found) {
              for (final t in found) {
                out.add(ScoredCandidate(t, MatchScorer.score(wanted, t)));
              }
            })
            .catchError((Object e) {
              errors[m.service.label] = describeOnlineError(e);
            }),
    ]);
    out.sort((a, b) => b.score.value.compareTo(a.score.value));
    return (out, errors);
  }

  Future<List<Track>> _localCandidates(ExternalTrack w) async {
    final title = cleanTitle(w.title);
    if (title.isEmpty) return const [];
    final seen = <int>{};
    final out = <Track>[];
    void add(List<Track> list) {
      for (final t in list) {
        if (seen.add(t.id)) out.add(t);
      }
    }

    add(await localSearch(title));
    if (out.isEmpty) {
      // Tolerate small differences: search by the two longest title words.
      final words = title.split(' ').where((x) => x.length >= 3).toList()..sort((a, b) => b.length.compareTo(a.length));
      if (words.isNotEmpty) add(await localSearch(words.take(2).join(' ')));
      if (out.isEmpty && w.artists.isNotEmpty) add(await localSearch(normalizeForSearch(w.artists.first)));
    }
    return out;
  }

  /// The imported YouTube video / SoundCloud track itself, when playable.
  Track? _direct(ExternalTrack w, List<MusicServiceModule> services) {
    final id = w.externalId;
    if (id == null || w.url == null) return null;
    final sourceId = switch (w.service) {
      OnlineService.youtube => youtubeSourceId,
      OnlineService.soundcloud => soundcloudSourceId,
      _ => null,
    };
    if (sourceId == null || !services.any((m) => m.playableSourceId == sourceId)) return null;
    return Track(
      id: 0,
      sourceId: sourceId,
      uri: sourceId == soundcloudSourceId ? '${w.url}#sc=$id' : 'https://www.youtube.com/watch?v=$id',
      title: sourceId == youtubeSourceId && w.artists.isNotEmpty ? '${w.artist} - ${w.title}' : w.title,
      artist: w.artist,
      album: w.album,
      durationMs: w.durationMs,
      artworkPath: w.artworkUrl,
    );
  }
}
