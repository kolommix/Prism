// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Track _$TrackFromJson(Map<String, dynamic> json) => _Track(
  id: (json['id'] as num).toInt(),
  sourceId: json['sourceId'] as String? ?? 'local',
  uri: json['uri'] as String,
  title: json['title'] as String,
  artist: json['artist'] as String? ?? '',
  album: json['album'] as String? ?? '',
  albumArtist: json['albumArtist'] as String? ?? '',
  genre: json['genre'] as String? ?? '',
  year: (json['year'] as num?)?.toInt(),
  trackNumber: (json['trackNumber'] as num?)?.toInt(),
  discNumber: (json['discNumber'] as num?)?.toInt(),
  durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
  artworkPath: json['artworkPath'] as String?,
  rgTrackGain: (json['rgTrackGain'] as num?)?.toDouble(),
  rgTrackPeak: (json['rgTrackPeak'] as num?)?.toDouble(),
  rgAlbumGain: (json['rgAlbumGain'] as num?)?.toDouble(),
  rgAlbumPeak: (json['rgAlbumPeak'] as num?)?.toDouble(),
  loudnessLufs: (json['loudnessLufs'] as num?)?.toDouble(),
  truePeakDb: (json['truePeakDb'] as num?)?.toDouble(),
);

Map<String, dynamic> _$TrackToJson(_Track instance) => <String, dynamic>{
  'id': instance.id,
  'sourceId': instance.sourceId,
  'uri': instance.uri,
  'title': instance.title,
  'artist': instance.artist,
  'album': instance.album,
  'albumArtist': instance.albumArtist,
  'genre': instance.genre,
  'year': instance.year,
  'trackNumber': instance.trackNumber,
  'discNumber': instance.discNumber,
  'durationMs': instance.durationMs,
  'artworkPath': instance.artworkPath,
  'rgTrackGain': instance.rgTrackGain,
  'rgTrackPeak': instance.rgTrackPeak,
  'rgAlbumGain': instance.rgAlbumGain,
  'rgAlbumPeak': instance.rgAlbumPeak,
  'loudnessLufs': instance.loudnessLufs,
  'truePeakDb': instance.truePeakDb,
};
