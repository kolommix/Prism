import 'package:freezed_annotation/freezed_annotation.dart';

part 'smart_playlist.freezed.dart';
part 'smart_playlist.g.dart';

/// One condition of a smart playlist. All rules of a playlist must match.
@Freezed(unionKey: 'rule')
sealed class SmartRule with _$SmartRule {
  /// Played at least [minPlays] times (optionally only counting the last
  /// [days] days); sorts by play count.
  const factory SmartRule.mostPlayed({@Default(1) int minPlays, int? days}) = MostPlayedRule;

  /// Added to the library in the last [days] days.
  const factory SmartRule.recentlyAdded({@Default(30) int days}) = RecentlyAddedRule;

  /// Genre contains [genre] (case-insensitive).
  const factory SmartRule.genre({required String genre}) = GenreRule;

  /// Year between [from] and [to] (inclusive, either may be open).
  const factory SmartRule.year({int? from, int? to}) = YearRule;

  /// Not played in the last [days] days (or never).
  const factory SmartRule.notPlayedFor({@Default(90) int days}) = NotPlayedForRule;

  factory SmartRule.fromJson(Map<String, dynamic> json) => _$SmartRuleFromJson(json);
}

enum SmartSort { plays, recentlyAdded, title, random }

@freezed
abstract class SmartPlaylist with _$SmartPlaylist {
  const factory SmartPlaylist({
    /// Database id; built-ins use negative ids.
    @Default(0) int id,
    required String name,
    @Default([]) List<SmartRule> rules,
    @Default(SmartSort.plays) SmartSort sort,
    @Default(100) int limit,
  }) = _SmartPlaylist;

  factory SmartPlaylist.fromJson(Map<String, dynamic> json) => _$SmartPlaylistFromJson(json);
}

/// Shown to everyone, cannot be deleted.
const builtInSmartPlaylists = [
  SmartPlaylist(id: -1, name: 'Most played', rules: [SmartRule.mostPlayed(minPlays: 2)], sort: SmartSort.plays, limit: 100),
  SmartPlaylist(id: -2, name: 'Recently added', rules: [SmartRule.recentlyAdded(days: 30)], sort: SmartSort.recentlyAdded),
  SmartPlaylist(id: -3, name: 'Forgotten gems', rules: [SmartRule.mostPlayed(minPlays: 3), SmartRule.notPlayedFor(days: 60)]),
];

/// SQL + bound values for a smart playlist (pure → unit tested).
class SmartQuery {
  const SmartQuery(this.sql, this.args);
  final String sql;
  final List<Object> args;
}

/// Builds one SELECT over `tracks` with play statistics joined in.
/// Dates are unix seconds (drift's default storage).
SmartQuery buildSmartQuery(SmartPlaylist p, DateTime now) {
  final where = <String>[];
  final args = <Object>[];
  int secsAgo(int days) => now.subtract(Duration(days: days)).millisecondsSinceEpoch ~/ 1000;
  var playsWindow = '';
  for (final r in p.rules) {
    switch (r) {
      case MostPlayedRule(:final minPlays, :final days):
        if (days != null) {
          playsWindow = ' AND p.played_at >= ?';
        }
        where.add('COALESCE(s.plays, 0) >= ?');
        args.add(minPlays);
      case RecentlyAddedRule(:final days):
        where.add('t.added_at >= ?');
        args.add(secsAgo(days));
      case GenreRule(:final genre):
        where.add('LOWER(t.genre) LIKE ?');
        args.add('%${genre.toLowerCase()}%');
      case YearRule(:final from, :final to):
        if (from != null) {
          where.add('t.year >= ?');
          args.add(from);
        }
        if (to != null) {
          where.add('t.year <= ?');
          args.add(to);
        }
      case NotPlayedForRule(:final days):
        where.add('(s.last_played IS NULL OR s.last_played < ?)');
        args.add(secsAgo(days));
    }
  }
  // The play-count window (if any) is bound first, so prepend its value.
  final windowArgs = <Object>[];
  if (playsWindow.isNotEmpty) {
    final days = p.rules.whereType<MostPlayedRule>().first.days!;
    windowArgs.add(secsAgo(days));
  }
  final order = switch (p.sort) {
    SmartSort.plays => 'plays DESC, s.last_played DESC',
    SmartSort.recentlyAdded => 't.added_at DESC',
    SmartSort.title => 't.title COLLATE NOCASE',
    SmartSort.random => 'RANDOM()',
  };
  final sql = 'SELECT t.*, COALESCE(s.plays, 0) AS plays FROM tracks t '
      'LEFT JOIN (SELECT p.track_id, COUNT(*) AS plays, MAX(p.played_at) AS last_played '
      'FROM plays p WHERE 1=1$playsWindow GROUP BY p.track_id) s ON s.track_id = t.id'
      '${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'} '
      'ORDER BY $order LIMIT ?';
  return SmartQuery(sql, [...windowArgs, ...args, p.limit.clamp(1, 5000)]);
}
