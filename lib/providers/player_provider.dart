import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayerHandler _audioHandler;

  List<SongModel> _queue = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _bufferedPosition = Duration.zero;
  RepeatMode _repeatMode = RepeatMode.none;
  bool _isShuffleEnabled = false;
  Timer? _sleepTimer;
  DateTime? _sleepTime;
  Duration? _sleepDuration;
  bool _sleepTimerActive = false;
  double _volume = 1.0;
  double _speed = 1.0;

  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _queueSub;

  PlayerProvider(this._audioHandler) {
    _init();
  }

  void _init() {
    _playerStateSub = _audioHandler.playbackState.listen((state) {
      _isPlaying = state.playing;
      _position = state.position;
      _bufferedPosition = state.bufferedPosition;
      notifyListeners();
    });

    _positionSub = _audioHandler.positionDataStream.listen((data) {
      _position = data.position;
      _duration = data.duration;
      _bufferedPosition = data.bufferedPosition;
      notifyListeners();
    });

    _queueSub = _audioHandler.mediaItem.listen((item) {
      if (item != null) {
        _currentIndex = _queue.indexWhere((s) => s.uri == item.id);
      }
      notifyListeners();
    });
  }

  SongModel? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _queue.length
          ? _queue[_currentIndex]
          : null;
  List<SongModel> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  Duration get bufferedPosition => _bufferedPosition;
  RepeatMode get repeatMode => _repeatMode;
  bool get isShuffleEnabled => _isShuffleEnabled;
  bool get sleepTimerActive => _sleepTimerActive;
  DateTime? get sleepTime => _sleepTime;
  Duration? get sleepDuration => _sleepDuration;
  double get volume => _volume;
  double get speed => _speed;

  double get progressPercent {
    if (_duration.inMilliseconds == 0) return 0.0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  Future<void> playQueue(List<SongModel> songs, int startIndex) async {
    _queue = songs;
    _currentIndex = startIndex;
    notifyListeners();

    final mediaItems = songs
        .map((s) => MediaItem(
              id: s.uri,
              title: s.title,
              artist: s.artist,
              album: s.album,
              duration: Duration(milliseconds: s.duration),
              artUri: s.albumArtUri != null ? Uri.parse(s.albumArtUri!) : null,
              extras: {'songId': s.id},
            ))
        .toList();

    await _audioHandler.addQueueItems(mediaItems);
    await _audioHandler.skipToQueueItem(startIndex);
    await _audioHandler.play();
  }

  Future<void> playSong(SongModel song, List<SongModel> allSongs) async {
    final idx = allSongs.indexWhere((s) => s.id == song.id);
    await playQueue(allSongs, idx >= 0 ? idx : 0);
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioHandler.pause();
    } else {
      await _audioHandler.play();
    }
  }

  Future<void> seekTo(Duration position) async {
    await _audioHandler.seek(position);
  }

  Future<void> seekToPercent(double percent) async {
    final ms = (_duration.inMilliseconds * percent).toInt();
    await seekTo(Duration(milliseconds: ms));
  }

  Future<void> skipToNext() async {
    await _audioHandler.skipToNext();
  }

  Future<void> skipToPrevious() async {
    if (_position.inSeconds > 3) {
      await seekTo(Duration.zero);
    } else {
      await _audioHandler.skipToPrevious();
    }
  }

  Future<void> skipTo(int index) async {
    await _audioHandler.skipToQueueItem(index);
  }

  Future<void> toggleRepeat() async {
    switch (_repeatMode) {
      case RepeatMode.none:
        _repeatMode = RepeatMode.all;
        await _audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        await _audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.none;
        await _audioHandler.setRepeatMode(AudioServiceRepeatMode.none);
        break;
    }
    notifyListeners();
  }

  Future<void> toggleShuffle() async {
    _isShuffleEnabled = !_isShuffleEnabled;
    await _audioHandler.setShuffleMode(
      _isShuffleEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    );
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _audioHandler.player.setVolume(_volume);
    notifyListeners();
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.5, 2.0);
    await _audioHandler.player.setSpeed(_speed);
    notifyListeners();
  }

  // Sleep Timer
  void setSleepTimer(Duration duration) {
    _cancelSleepTimer();
    _sleepDuration = duration;
    _sleepTime = DateTime.now().add(duration);
    _sleepTimerActive = true;
    _sleepTimer = Timer(duration, () {
      _audioHandler.pause();
      _cancelSleepTimer();
      notifyListeners();
    });
    notifyListeners();
  }

  void setSleepTimeAt(DateTime time) {
    _cancelSleepTimer();
    final now = DateTime.now();
    var target = time;
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }
    final duration = target.difference(now);
    _sleepTime = target;
    _sleepDuration = duration;
    _sleepTimerActive = true;
    _sleepTimer = Timer(duration, () {
      _audioHandler.pause();
      _cancelSleepTimer();
      notifyListeners();
    });
    notifyListeners();
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerActive = false;
    _sleepTime = null;
    _sleepDuration = null;
  }

  void cancelSleepTimer() {
    _cancelSleepTimer();
    notifyListeners();
  }

  Duration? get remainingSleepTime {
    if (_sleepTime == null) return null;
    final remaining = _sleepTime!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _queueSub?.cancel();
    _sleepTimer?.cancel();
    super.dispose();
  }
}
