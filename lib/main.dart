import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/music_provider.dart';
import 'providers/player_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'services/audio_handler.dart';
import 'theme/app_theme.dart';

late AudioPlayerHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI overlays
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.bgColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize audio service
  _audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.elkhalfy.musique.channel.audio',
      androidNotificationChannelName: 'Elkhalfy Musique',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/ic_notification',
      notificationColor: Color(0xFF6C63FF),
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider(_audioHandler)),
      ],
      child: const ElkhalfyMusiqueApp(),
    ),
  );
}

class ElkhalfyMusiqueApp extends StatelessWidget {
  const ElkhalfyMusiqueApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elkhalfy Musique',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppEntry(),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({Key? key}) : super(key: key);

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> with WidgetsBindingObserver {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Lock app when backgrounded if app lock is enabled
      // The settings provider handles the lock state
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _initialize() async {
    // Wait for settings to load
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const _SplashScreen();
    }

    return Consumer<SettingsProvider>(
      builder: (ctx, settings, _) {
        if (settings.isAppLocked && settings.hasAppPin) {
          return LockScreen(
            onUnlocked: () {
              settings.unlockApp();
            },
          );
        }
        return const HomeScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 52),
            ),
            const SizedBox(height: 24),
            const Text(
              'Elkhalfy',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
                letterSpacing: 4,
                fontWeight: FontWeight.w300,
              ),
            ),
            const Text(
              'MUSIQUE',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
