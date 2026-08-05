import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart'
    hide PlaylistModel, SongModel;
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/player_provider.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sleep_timer_dialog.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _showQueue = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _slideController.forward();

    final player = context.read<PlayerProvider>();
    if (player.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        body: Consumer<PlayerProvider>(
          builder: (ctx, player, _) {
            final song = player.currentSong;
            if (song == null) {
              return const Center(
                child: Text('No song playing', style: TextStyle(color: AppTheme.textSecondary)),
              );
            }

            if (player.isPlaying) {
              _rotationController.repeat();
            } else {
              _rotationController.stop();
            }

            return SlideTransition(
              position: _slideAnimation,
              child: Stack(
                children: [
                  // Background
                  _buildBackground(song),
                  // Content
                  SafeArea(
                    child: Column(
                      children: [
                        _buildAppBar(ctx, player),
                        Expanded(
                          child: _showQueue
                              ? _buildQueueView(ctx, player)
                              : _buildPlayerView(ctx, player, song),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackground(SongModel song) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Opacity(
        opacity: 0.08,
        child: QueryArtworkWidget(
          id: song.id,
          type: ArtworkType.AUDIO,
          artworkFit: BoxFit.cover,
          artworkWidth: double.infinity,
          artworkHeight: double.infinity,
          nullArtworkWidget: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext ctx, PlayerProvider player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            color: AppTheme.textPrimary,
            onPressed: () => Navigator.pop(ctx),
          ),
          Expanded(
            child: Column(
              children: [
                Text('NOW PLAYING',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      letterSpacing: 2,
                    )),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _showQueue ? Icons.music_note_rounded : Icons.queue_music_rounded,
              size: 24,
            ),
            color: AppTheme.textPrimary,
            onPressed: () => setState(() => _showQueue = !_showQueue),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerView(BuildContext ctx, PlayerProvider player, SongModel song) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Album Art
          _buildAlbumArt(song, player),
          const SizedBox(height: 32),
          // Song Info
          _buildSongInfo(ctx, song, player),
          const SizedBox(height: 28),
          // Progress Bar
          _buildProgressBar(player),
          const SizedBox(height: 24),
          // Controls
          _buildControls(player),
          const SizedBox(height: 24),
          // Extra Controls
          _buildExtraControls(ctx, player),
          const SizedBox(height: 24),
          // Volume
          _buildVolumeControl(player),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(SongModel song, PlayerProvider player) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: player.isPlaying ? 280 : 240,
      height: player.isPlaying ? 280 : 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(player.isPlaying ? 0.4 : 0.15),
            blurRadius: player.isPlaying ? 40 : 20,
            spreadRadius: player.isPlaying ? 8 : 2,
          ),
        ],
      ),
      child: RotationTransition(
        turns: _rotationController,
        child: Container(
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: ClipOval(
            child: QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              artworkFit: BoxFit.cover,
              artworkBorder: BorderRadius.zero,
              nullArtworkWidget: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, Color(0xFF9B59B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.music_note_rounded, color: Colors.white, size: 80),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(BuildContext ctx, SongModel song, PlayerProvider player) {
    final musicProvider = ctx.watch<MusicProvider>();
    final isFav = musicProvider.isFavorite(song.id);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(isFav),
              color: isFav ? AppTheme.secondaryColor : AppTheme.textSecondary,
              size: 28,
            ),
          ),
          onPressed: () => musicProvider.toggleFavorite(song.id),
        ),
      ],
    );
  }

  Widget _buildProgressBar(PlayerProvider player) {
    final pos = player.position;
    final dur = player.duration;

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: AppTheme.dividerColor,
            thumbColor: Colors.white,
            overlayColor: AppTheme.primaryColor.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: player.progressPercent,
            onChanged: (v) => player.seekToPercent(v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(pos),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text(_formatDuration(dur),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(PlayerProvider player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            color: player.isShuffleEnabled ? AppTheme.primaryColor : AppTheme.textTertiary,
            size: 24,
          ),
          onPressed: player.toggleShuffle,
        ),
        // Previous
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, color: AppTheme.textPrimary, size: 38),
          onPressed: player.skipToPrevious,
        ),
        // Play/Pause
        GestureDetector(
          onTap: player.togglePlayPause,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, Color(0xFF9B59B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Icon(
                  player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(player.isPlaying),
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ),
        // Next
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, color: AppTheme.textPrimary, size: 38),
          onPressed: player.skipToNext,
        ),
        // Repeat
        IconButton(
          icon: Icon(
            player.repeatMode == RepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: player.repeatMode != RepeatMode.none
                ? AppTheme.primaryColor
                : AppTheme.textTertiary,
            size: 24,
          ),
          onPressed: player.toggleRepeat,
        ),
      ],
    );
  }

  Widget _buildExtraControls(BuildContext ctx, PlayerProvider player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _extraButton(
          icon: Icons.timer_outlined,
          label: player.sleepTimerActive ? 'Sleep On' : 'Sleep',
          active: player.sleepTimerActive,
          onTap: () => _showSleepTimerDialog(ctx, player),
        ),
        _extraButton(
          icon: Icons.speed_rounded,
          label: '${player.speed}x',
          active: player.speed != 1.0,
          onTap: () => _showSpeedDialog(ctx, player),
        ),
        _extraButton(
          icon: Icons.equalizer_rounded,
          label: 'EQ',
          active: false,
          onTap: () {},
        ),
        _extraButton(
          icon: Icons.share_rounded,
          label: 'Share',
          active: false,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _extraButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.primaryColor.withOpacity(0.15)
                  : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: active
                  ? Border.all(color: AppTheme.primaryColor.withOpacity(0.4))
                  : Border.all(color: AppTheme.dividerColor),
            ),
            child: Icon(icon,
                color: active ? AppTheme.primaryColor : AppTheme.textSecondary, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                color: active ? AppTheme.primaryColor : AppTheme.textTertiary,
                fontSize: 11,
              )),
        ],
      ),
    );
  }

  Widget _buildVolumeControl(PlayerProvider player) {
    return Row(
      children: [
        const Icon(Icons.volume_down_rounded, color: AppTheme.textTertiary, size: 20),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: AppTheme.primaryColor.withOpacity(0.8),
              inactiveTrackColor: AppTheme.dividerColor,
              thumbColor: AppTheme.primaryColor,
              overlayColor: AppTheme.primaryColor.withOpacity(0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: player.volume,
              onChanged: player.setVolume,
            ),
          ),
        ),
        const Icon(Icons.volume_up_rounded, color: AppTheme.textTertiary, size: 20),
      ],
    );
  }

  Widget _buildQueueView(BuildContext ctx, PlayerProvider player) {
    final queue = player.queue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Queue',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              Text('${queue.length} songs',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: queue.length,
            itemBuilder: (_, i) {
              final s = queue[i];
              final isCurrent = i == player.currentIndex;
              return ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isCurrent
                        ? AppTheme.primaryColor.withOpacity(0.2)
                        : AppTheme.cardColor,
                  ),
                  child: Center(
                    child: isCurrent
                        ? const Icon(Icons.equalizer_rounded,
                            color: AppTheme.primaryColor, size: 20)
                        : Text('${i + 1}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                  ),
                ),
                title: Text(s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent ? AppTheme.primaryColor : AppTheme.textPrimary,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 14,
                    )),
                subtitle: Text(s.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                onTap: () => player.skipTo(i),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSleepTimerDialog(BuildContext ctx, PlayerProvider player) {
    showDialog(
      context: ctx,
      builder: (_) => SleepTimerDialog(player: player),
    );
  }

  void _showSpeedDialog(BuildContext ctx, PlayerProvider player) {
    showDialog(
      context: ctx,
      barrierColor: Colors.black54,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Playback Speed',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${player.speed.toStringAsFixed(1)}x',
                  style: const TextStyle(
                      color: AppTheme.primaryColor, fontSize: 32, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
                  final isSelected = (player.speed - s).abs() < 0.01;
                  return GestureDetector(
                    onTap: () {
                      player.setSpeed(s);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
                        ),
                      ),
                      child: Text('${s}x',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
