import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_tile.dart';
import 'library_screen.dart';
import 'settings_screen.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  late AnimationController _fabController;

  final List<Widget> _screens = const [
    _SongsTab(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MusicProvider>().loadSongs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: AppTheme.dividerColor, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.music_note_rounded, Icons.music_note_outlined, 'Songs'),
              _navItem(1, Icons.library_music_rounded, Icons.library_music_outlined, 'Library'),
              _navItem(2, Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData activeIcon, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongsTab extends StatefulWidget {
  const _SongsTab({Key? key}) : super(key: key);

  @override
  State<_SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<_SongsTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MusicProvider, PlayerProvider>(
      builder: (ctx, music, player, _) {
        return NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              snap: true,
              backgroundColor: AppTheme.bgColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: _isSearching
                    ? null
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Elkhalfy',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1,
                            ),
                          ),
                          const Text(
                            'Musique 🎵',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded,
                      color: AppTheme.textPrimary),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        music.search('');
                      }
                    });
                  },
                ),
                PopupMenuButton<SortOrder>(
                  icon: const Icon(Icons.sort_rounded, color: AppTheme.textPrimary),
                  color: AppTheme.cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: music.setSortOrder,
                  itemBuilder: (_) => [
                    _sortMenuItem(SortOrder.titleAsc, 'Title (A-Z)', music.sortOrder),
                    _sortMenuItem(SortOrder.titleDesc, 'Title (Z-A)', music.sortOrder),
                    _sortMenuItem(SortOrder.artistAsc, 'Artist', music.sortOrder),
                    _sortMenuItem(SortOrder.dateAdded, 'Recently Added', music.sortOrder),
                    _sortMenuItem(SortOrder.duration, 'Duration', music.sortOrder),
                  ],
                ),
              ],
            ),
          ],
          body: Column(
            children: [
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search songs, artists...',
                      hintStyle: const TextStyle(color: AppTheme.textTertiary),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textTertiary),
                      filled: true,
                      fillColor: AppTheme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: music.search,
                  ),
                ),
              // Stats Row
              if (!_isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _statChip(
                        '${music.visibleSongs.length} Songs',
                        Icons.music_note_rounded,
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _playAll(music, player),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text('Play All',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _shuffleAll(music, player),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shuffle_rounded,
                                  color: AppTheme.textSecondary, size: 18),
                              SizedBox(width: 4),
                              Text('Shuffle',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Songs List
              Expanded(
                child: _buildSongsList(music, player),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSongsList(MusicProvider music, PlayerProvider player) {
    if (music.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Loading your music...', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    if (music.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 52),
            const SizedBox(height: 16),
            Text(music.errorMessage!,
                style: const TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => music.loadSongs(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final songs = music.visibleSongs;

    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.music_off_rounded, color: AppTheme.textTertiary, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('No songs found',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Make sure you have music files on your device',
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: songs.length,
        itemBuilder: (ctx, i) {
          final song = songs[i];
          final isPlaying = player.currentSong?.id == song.id;
          return AnimationConfiguration.staggeredList(
            position: i,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: SongTile(
                  song: song,
                  isPlaying: isPlaying,
                  onTap: () => _playSong(ctx, song, songs, player),
                  onLongPress: () => _showSongOptions(ctx, song, music),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _playSong(BuildContext ctx, SongModel song, List<SongModel> songs, PlayerProvider player) {
    player.playSong(song, songs);
    Navigator.push(
      ctx,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PlayerScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  void _playAll(MusicProvider music, PlayerProvider player) {
    final songs = music.visibleSongs;
    if (songs.isEmpty) return;
    player.playQueue(songs, 0);
  }

  void _shuffleAll(MusicProvider music, PlayerProvider player) async {
    final songs = music.visibleSongs;
    if (songs.isEmpty) return;
    final shuffled = List<SongModel>.from(songs)..shuffle();
    player.playQueue(shuffled, 0);
    if (!player.isShuffleEnabled) player.toggleShuffle();
  }

  void _showSongOptions(BuildContext ctx, SongModel song, MusicProvider music) {
    // Already handled in SongTile
  }

  PopupMenuItem<SortOrder> _sortMenuItem(SortOrder order, String label, SortOrder current) {
    final isSelected = current == order;
    return PopupMenuItem<SortOrder>(
      value: order,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              )),
        ],
      ),
    );
  }

  Widget _statChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
