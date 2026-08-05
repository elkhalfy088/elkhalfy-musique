import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart'
    hide PlaylistModel, SongModel;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

class MusicProvider extends ChangeNotifier {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _allSongs = [];
  List<SongModel> _filteredSongs = [];
  List<int> _hiddenSongIds = [];
  List<PlaylistModel> _playlists = [];
  List<int> _favoriteSongIds = [];
  SortOrder _sortOrder = SortOrder.titleAsc;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<SongModel> get allSongs => _filteredSongs;
  List<SongModel> get visibleSongs => _filteredSongs.where((s) => !_hiddenSongIds.contains(s.id)).toList();
  List<SongModel> get hiddenSongs => _allSongs.where((s) => _hiddenSongIds.contains(s.id)).toList();
  List<PlaylistModel> get playlists => _playlists;
  List<int> get favoriteSongIds => _favoriteSongIds;
  SortOrder get sortOrder => _sortOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isFavorite(int songId) => _favoriteSongIds.contains(songId);
  bool isHidden(int songId) => _hiddenSongIds.contains(songId);

  MusicProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _hiddenSongIds = prefs.getStringList('hidden_songs')?.map(int.parse).toList() ?? [];
    _favoriteSongIds = prefs.getStringList('favorite_songs')?.map(int.parse).toList() ?? [];
    final playlistsJson = prefs.getStringList('playlists') ?? [];
    _playlists = playlistsJson
        .map((j) => PlaylistModel.fromMap(jsonDecode(j) as Map<String, dynamic>))
        .toList();
    final sortStr = prefs.getString('sort_order') ?? 'titleAsc';
    _sortOrder = SortOrder.values.firstWhere(
      (e) => e.name == sortStr,
      orElse: () => SortOrder.titleAsc,
    );
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('hidden_songs', _hiddenSongIds.map((e) => e.toString()).toList());
    await prefs.setStringList('favorite_songs', _favoriteSongIds.map((e) => e.toString()).toList());
    await prefs.setStringList(
        'playlists', _playlists.map((p) => jsonEncode(p.toMap())).toList());
    await prefs.setString('sort_order', _sortOrder.name);
  }

  Future<bool> requestPermission() async {
    return await _audioQuery.permissionsRequest();
  }

  Future<void> loadSongs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hasPermission = await _audioQuery.permissionsStatus();
      if (!hasPermission) {
        final granted = await _audioQuery.permissionsRequest();
        if (!granted) {
          _errorMessage = 'Storage permission denied';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      _allSongs = songs
          .where((s) => s.duration != null && s.duration! > 10000)
          .map((s) => SongModel(
                id: s.id,
                title: s.title,
                artist: s.artist ?? 'Unknown Artist',
                album: s.album ?? 'Unknown Album',
                uri: s.uri ?? '',
                duration: s.duration ?? 0,
                albumId: s.albumId,
                size: s.size,
                dateAdded: s.dateAdded ?? 0,
              ))
          .toList();

      _applyFilters();
    } catch (e) {
      _errorMessage = 'Failed to load songs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    var songs = List<SongModel>.from(_allSongs);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      songs = songs.where((s) =>
          s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.album.toLowerCase().contains(q)).toList();
    }

    switch (_sortOrder) {
      case SortOrder.titleAsc:
        songs.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOrder.titleDesc:
        songs.sort((a, b) => b.title.compareTo(a.title));
        break;
      case SortOrder.artistAsc:
        songs.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      case SortOrder.dateAdded:
        songs.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case SortOrder.duration:
        songs.sort((a, b) => b.duration.compareTo(a.duration));
        break;
    }

    _filteredSongs = songs;
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setSortOrder(SortOrder order) {
    _sortOrder = order;
    _savePreferences();
    _applyFilters();
  }

  void toggleFavorite(int songId) {
    if (_favoriteSongIds.contains(songId)) {
      _favoriteSongIds.remove(songId);
    } else {
      _favoriteSongIds.add(songId);
    }
    _savePreferences();
    notifyListeners();
  }

  void hideSong(int songId) {
    if (!_hiddenSongIds.contains(songId)) {
      _hiddenSongIds.add(songId);
      _savePreferences();
      notifyListeners();
    }
  }

  void unhideSong(int songId) {
    _hiddenSongIds.remove(songId);
    _savePreferences();
    notifyListeners();
  }

  List<SongModel> get favoriteSongs =>
      _allSongs.where((s) => _favoriteSongIds.contains(s.id)).toList();

  void createPlaylist(String name) {
    final playlist = PlaylistModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songIds: [],
      createdAt: DateTime.now(),
    );
    _playlists.add(playlist);
    _savePreferences();
    notifyListeners();
  }

  void deletePlaylist(String playlistId) {
    _playlists.removeWhere((p) => p.id == playlistId);
    _savePreferences();
    notifyListeners();
  }

  void addSongToPlaylist(String playlistId, int songId) {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx != -1 && !_playlists[idx].songIds.contains(songId)) {
      _playlists[idx] = _playlists[idx].copyWith(
        songIds: [..._playlists[idx].songIds, songId],
      );
      _savePreferences();
      notifyListeners();
    }
  }

  void removeSongFromPlaylist(String playlistId, int songId) {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final updated = _playlists[idx].songIds.where((id) => id != songId).toList();
      _playlists[idx] = _playlists[idx].copyWith(songIds: updated);
      _savePreferences();
      notifyListeners();
    }
  }

  List<SongModel> getPlaylistSongs(String playlistId) {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId,
        orElse: () => PlaylistModel(id: '', name: '', songIds: [], createdAt: DateTime.now()));
    return _allSongs.where((s) => playlist.songIds.contains(s.id)).toList();
  }

  List<String> get albums {
    final set = <String>{};
    for (final s in _allSongs) {
      set.add(s.album);
    }
    return set.toList()..sort();
  }

  List<String> get artists {
    final set = <String>{};
    for (final s in _allSongs) {
      set.add(s.artist);
    }
    return set.toList()..sort();
  }

  List<SongModel> getSongsByAlbum(String album) =>
      _allSongs.where((s) => s.album == album).toList();

  List<SongModel> getSongsByArtist(String artist) =>
      _allSongs.where((s) => s.artist == artist).toList();
}
