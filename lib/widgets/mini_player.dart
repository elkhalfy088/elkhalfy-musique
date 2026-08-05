import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';
import '../theme/app_theme.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (ctx, player, _) {
        final song = player.currentSong;
        if (song == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => Navigator.push(
            ctx,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const PlayerScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1E35), Color(0xFF252540)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.dividerColor, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: player.progressPercent,
                    backgroundColor: AppTheme.dividerColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    minHeight: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Album Art
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppTheme.surfaceColor,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: QueryArtworkWidget(
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          artworkFit: BoxFit.cover,
                          artworkBorder: BorderRadius.zero,
                          keepOldArtwork: true,
                          nullArtworkWidget: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryColor, Color(0xFF9B59B6)],
                              ),
                            ),
                            child: const Icon(Icons.music_note_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Song info
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
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
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
                    // Controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, size: 26),
                          color: AppTheme.textPrimary,
                          onPressed: player.skipToPrevious,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: player.togglePlayPause,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryColor, Color(0xFF9B59B6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
                                child: Icon(
                                  player.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  key: ValueKey(player.isPlaying),
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, size: 26),
                          color: AppTheme.textPrimary,
                          onPressed: player.skipToNext,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
