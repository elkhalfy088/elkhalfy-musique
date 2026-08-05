import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart'
    hide PlaylistModel, SongModel;
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';
import 'lock_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Library'),
        backgroundColor: AppTheme.bgColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textTertiary,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Favorites'),
                Tab(text: 'Playlists'),
                Tab(text: 'Albums'),
                Tab(text: 'Hidden'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FavoritesTab(),
          _PlaylistsTab(),
          _AlbumsTab(),
          _HiddenTab(),
        ],
      ),
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<MusicProvider, PlayerProvider>(
      builder: (ctx, music, player, _) {
        final songs = music.favoriteSongs;
        if (songs.isEmpty) {
          return _EmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'No Favorites Yet',
            subtitle: 'Tap the heart icon on any song to add it here',
          );
        }
        return Column(
          children: [
            _SectionHeader(
              title: '${songs.length} Favorites',
              onPlayAll: () => player.playQueue(songs, 0),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: songs.length,
                padding: const EdgeInsets.only(bottom: 16),
                itemBuilder: (_, i) {
                  final song = songs[i];
                  return SongTile(
                    song: song,
                    isPlaying: player.currentSong?.id == song.id,
                    onTap: () => player.playSong(song, songs),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (ctx, music, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _createPlaylistDialog(ctx, music),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New Playlist'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            if (music.playlists.isEmpty)
              Expanded(
                child: _EmptyState(
                  icon: Icons.playlist_play_rounded,
                  title: 'No Playlists',
                  subtitle: 'Create your first playlist to organize your music',
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: music.playlists.length,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemBuilder: (_, i) {
                    final pl = music.playlists[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.playlist_play_rounded,
                            color: Colors.white, size: 28),
                      ),
                      title: Text(pl.name,
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      subtitle: Text('${pl.songIds.length} songs',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert_rounded,
                            color: AppTheme.textTertiary),
                        onPressed: () => _showPlaylistOptions(ctx, pl.id, pl.name, music),
                      ),
                      onTap: () => _openPlaylist(ctx, pl.id, pl.name, music),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _createPlaylistDialog(BuildContext ctx, MusicProvider music) {
    final controller = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Playlist',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Playlist name...',
            hintStyle: const TextStyle(color: AppTheme.textTertiary),
            filled: true,
            fillColor: AppTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                music.createPlaylist(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(BuildContext ctx, String id, String name, MusicProvider music) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Delete Playlist',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                music.deletePlaylist(id);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openPlaylist(BuildContext ctx, String id, String name, MusicProvider music) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => _PlaylistDetailScreen(playlistId: id, playlistName: name),
      ),
    );
  }
}

class _PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;
  final String playlistName;

  const _PlaylistDetailScreen(
      {Key? key, required this.playlistId, required this.playlistName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<MusicProvider, PlayerProvider>(
      builder: (ctx, music, player, _) {
        final songs = music.getPlaylistSongs(playlistId);
        return Scaffold(
          backgroundColor: AppTheme.bgColor,
          appBar: AppBar(
            title: Text(playlistName),
            backgroundColor: AppTheme.bgColor,
          ),
          body: songs.isEmpty
              ? _EmptyState(
                  icon: Icons.music_note_rounded,
                  title: 'Empty Playlist',
                  subtitle: 'Add songs from the main list',
                )
              : ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (_, i) {
                    final song = songs[i];
                    return SongTile(
                      song: song,
                      isPlaying: player.currentSong?.id == song.id,
                      onTap: () => player.playSong(song, songs),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _AlbumsTab extends StatelessWidget {
  const _AlbumsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (ctx, music, _) {
        final albums = music.albums;
        if (albums.isEmpty) {
          return _EmptyState(
            icon: Icons.album_rounded,
            title: 'No Albums',
            subtitle: 'Albums will appear here',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: albums.length,
          itemBuilder: (_, i) {
            final album = albums[i];
            final songs = music.getSongsByAlbum(album);
            final firstSong = songs.isNotEmpty ? songs.first : null;
            return GestureDetector(
              onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => _AlbumDetailScreen(album: album, songs: songs),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.dividerColor, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: firstSong != null
                            ? QueryArtworkWidget(
                                id: firstSong.id,
                                type: ArtworkType.AUDIO,
                                artworkFit: BoxFit.cover,
                                artworkWidth: double.infinity,
                                artworkBorder: BorderRadius.zero,
                                nullArtworkWidget: _defaultAlbumArt(),
                              )
                            : _defaultAlbumArt(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(album,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text('${songs.length} songs',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _defaultAlbumArt() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF9B59B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.album_rounded, color: Colors.white60, size: 48),
      ),
    );
  }
}

class _AlbumDetailScreen extends StatelessWidget {
  final String album;
  final List<SongModel> songs;

  const _AlbumDetailScreen({Key? key, required this.album, required this.songs})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (ctx, player, _) => Scaffold(
        backgroundColor: AppTheme.bgColor,
        appBar: AppBar(title: Text(album), backgroundColor: AppTheme.bgColor),
        body: ListView.builder(
          itemCount: songs.length,
          itemBuilder: (_, i) {
            final song = songs[i];
            return SongTile(
              song: song,
              isPlaying: player.currentSong?.id == song.id,
              onTap: () => player.playSong(song, songs),
            );
          },
        ),
      ),
    );
  }
}

class _HiddenTab extends StatelessWidget {
  const _HiddenTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    if (settings.hasHiddenSongsPin) {
      return _HiddenSongsLocked();
    }

    return _HiddenSongsList();
  }
}

class _HiddenSongsLocked extends StatefulWidget {
  @override
  State<_HiddenSongsLocked> createState() => _HiddenSongsLockedState();
}

class _HiddenSongsLockedState extends State<_HiddenSongsLocked> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return _HiddenSongsList();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: const Icon(Icons.lock_rounded, color: AppTheme.primaryColor, size: 48),
          ),
          const SizedBox(height: 24),
          const Text('Hidden Songs',
              style: TextStyle(
                  color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Enter PIN to access hidden songs',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _unlock(context),
            icon: const Icon(Icons.lock_open_rounded),
            label: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  void _unlock(BuildContext ctx) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => LockScreen(
          isHiddenSongsLock: true,
          onUnlocked: () {
            Navigator.pop(ctx);
            setState(() => _unlocked = true);
          },
        ),
      ),
    );
  }
}

class _HiddenSongsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<MusicProvider, PlayerProvider>(
      builder: (ctx, music, player, _) {
        final songs = music.hiddenSongs;
        if (songs.isEmpty) {
          return _EmptyState(
            icon: Icons.visibility_off_rounded,
            title: 'No Hidden Songs',
            subtitle: 'Long press on a song and tap "Hide" to hide it here',
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppTheme.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${songs.length} hidden songs',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: songs.length,
                padding: const EdgeInsets.only(bottom: 16),
                itemBuilder: (_, i) {
                  final song = songs[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: QueryArtworkWidget(
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          artworkFit: BoxFit.cover,
                          artworkBorder: BorderRadius.zero,
                          nullArtworkWidget: Container(
                            color: AppTheme.surfaceColor,
                            child: const Icon(Icons.music_note_rounded,
                                color: AppTheme.textTertiary, size: 22),
                          ),
                        ),
                      ),
                    ),
                    title: Text(song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textPrimary)),
                    subtitle: Text(song.artist,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    trailing: TextButton.icon(
                      onPressed: () => music.unhideSong(song.id),
                      icon: const Icon(Icons.visibility_rounded, size: 16),
                      label: const Text('Unhide'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          textStyle:
                              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onPlayAll;

  const _SectionHeader({Key? key, required this.title, this.onPlayAll}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          if (onPlayAll != null)
            TextButton.icon(
              onPressed: onPlayAll,
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: const Text('Play All', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState(
      {Key? key, required this.icon, required this.title, required this.subtitle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.textTertiary, size: 48),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
