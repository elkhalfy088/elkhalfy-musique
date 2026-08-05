import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';

class SongTile extends StatelessWidget {
  final SongModel song;
  final bool isPlaying;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool showAlbumArt;

  const SongTile({
    Key? key,
    required this.song,
    this.isPlaying = false,
    this.isSelected = false,
    required this.onTap,
    this.onLongPress,
    this.showAlbumArt = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final isFav = musicProvider.isFavorite(song.id);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isPlaying
              ? AppTheme.primaryColor.withOpacity(0.12)
              : isSelected
                  ? AppTheme.primaryColor.withOpacity(0.08)
                  : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: isPlaying
              ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            // Album Art
            if (showAlbumArt) ...[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppTheme.surfaceColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: QueryArtworkWidget(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    artworkFit: BoxFit.cover,
                    artworkBorder: BorderRadius.circular(10),
                    nullArtworkWidget: _defaultArtwork(),
                    keepOldArtwork: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPlaying ? AppTheme.primaryColor : AppTheme.textPrimary,
                      fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${song.artist} • ${song.formattedDuration}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Playing indicator
            if (isPlaying)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _PlayingAnimation(),
              ),
            // Options
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textTertiary, size: 20),
              color: AppTheme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) => _handleMenuAction(context, value),
              itemBuilder: (_) => [
                _menuItem('play_next', Icons.skip_next_rounded, 'Play Next'),
                _menuItem('add_to_queue', Icons.queue_music_rounded, 'Add to Queue'),
                _menuItem(
                  'favorite',
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  isFav ? 'Remove Favorite' : 'Add to Favorites',
                ),
                _menuItem('add_to_playlist', Icons.playlist_add_rounded, 'Add to Playlist'),
                _menuItem('hide', Icons.visibility_off_rounded, 'Hide Song'),
                _menuItem('info', Icons.info_outline_rounded, 'Song Info'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultArtwork() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF9B59B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final musicProvider = context.read<MusicProvider>();
    final playerProvider = context.read<PlayerProvider>();
    switch (action) {
      case 'favorite':
        musicProvider.toggleFavorite(song.id);
        break;
      case 'hide':
        musicProvider.hideSong(song.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${song.title} hidden'),
            backgroundColor: AppTheme.cardColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        break;
      case 'info':
        _showSongInfo(context);
        break;
      case 'add_to_playlist':
        _showAddToPlaylist(context, musicProvider);
        break;
    }
  }

  void _showSongInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Song Info',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const Divider(color: AppTheme.dividerColor),
            _infoRow('Title', song.title),
            _infoRow('Artist', song.artist),
            _infoRow('Album', song.album),
            _infoRow('Duration', song.formattedDuration),
            _infoRow('Size', song.formattedSize),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylist(BuildContext context, MusicProvider musicProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add to Playlist',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const Divider(color: AppTheme.dividerColor),
            if (musicProvider.playlists.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No playlists yet. Create one in the Library tab.',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
              )
            else
              ...musicProvider.playlists.map((pl) => ListTile(
                    leading: const Icon(Icons.playlist_play_rounded, color: AppTheme.primaryColor),
                    title: Text(pl.name, style: const TextStyle(color: AppTheme.textPrimary)),
                    subtitle: Text('${pl.songIds.length} songs',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    onTap: () {
                      musicProvider.addSongToPlaylist(pl.id, song.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added to ${pl.name}'),
                          backgroundColor: AppTheme.cardColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PlayingAnimation extends StatefulWidget {
  @override
  State<_PlayingAnimation> createState() => _PlayingAnimationState();
}

class _PlayingAnimationState extends State<_PlayingAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 100),
      )..repeat(reverse: true),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 4, end: 18).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) => Container(
              width: 4,
              height: _animations[i].value,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
