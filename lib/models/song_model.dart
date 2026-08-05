import 'package:equatable/equatable.dart';

class SongModel extends Equatable {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String uri;
  final int duration;
  final int? albumId;
  final String? albumArtUri;
  final int size;
  final int dateAdded;

  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.uri,
    required this.duration,
    this.albumId,
    this.albumArtUri,
    required this.size,
    required this.dateAdded,
  });

  String get formattedDuration {
    final minutes = (duration ~/ 1000) ~/ 60;
    final seconds = (duration ~/ 1000) % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedSize {
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  SongModel copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    String? uri,
    int? duration,
    int? albumId,
    String? albumArtUri,
    int? size,
    int? dateAdded,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      uri: uri ?? this.uri,
      duration: duration ?? this.duration,
      albumId: albumId ?? this.albumId,
      albumArtUri: albumArtUri ?? this.albumArtUri,
      size: size ?? this.size,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'uri': uri,
      'duration': duration,
      'albumId': albumId,
      'albumArtUri': albumArtUri,
      'size': size,
      'dateAdded': dateAdded,
    };
  }

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id'] as int,
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String,
      uri: map['uri'] as String,
      duration: map['duration'] as int,
      albumId: map['albumId'] as int?,
      albumArtUri: map['albumArtUri'] as String?,
      size: map['size'] as int,
      dateAdded: map['dateAdded'] as int,
    );
  }

  @override
  List<Object?> get props => [id, uri];
}

class PlaylistModel extends Equatable {
  final String id;
  final String name;
  final List<int> songIds;
  final DateTime createdAt;
  final String? coverUri;

  const PlaylistModel({
    required this.id,
    required this.name,
    required this.songIds,
    required this.createdAt,
    this.coverUri,
  });

  PlaylistModel copyWith({
    String? id,
    String? name,
    List<int>? songIds,
    DateTime? createdAt,
    String? coverUri,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt ?? this.createdAt,
      coverUri: coverUri ?? this.coverUri,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'songIds': songIds,
      'createdAt': createdAt.toIso8601String(),
      'coverUri': coverUri,
    };
  }

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map['id'] as String,
      name: map['name'] as String,
      songIds: List<int>.from(map['songIds'] as List),
      createdAt: DateTime.parse(map['createdAt'] as String),
      coverUri: map['coverUri'] as String?,
    );
  }

  @override
  List<Object?> get props => [id];
}

enum RepeatMode { none, one, all }
enum SortOrder { titleAsc, titleDesc, artistAsc, dateAdded, duration }
