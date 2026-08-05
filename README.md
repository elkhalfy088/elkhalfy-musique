# Elkhalfy Musique 🎵

A professional, feature-rich Flutter music player app for Android.

## Features

### 🎵 Music Playback
- Display all songs from device storage
- Background playback (continues even with screen off)
- Gapless playback
- Crossfade between songs
- Playback speed control (0.5x – 2.0x)
- Volume control
- Play queue management

### 🔐 Privacy & Security
- App Lock with 4-digit PIN
- Biometric authentication (fingerprint/face)
- Hide individual songs with PIN protection
- Secure PIN storage using FlutterSecureStorage

### ⏰ Sleep Timer
- Stop music after a set duration (5m, 10m, 15m, 30m, 60m, 90m)
- Stop music at a specific time (e.g., 6:00 AM)
- Cancel timer anytime

### 📚 Library Organization
- Favorites collection
- Custom playlists
- Albums view with grid layout
- Hidden songs vault
- Sort by: Title, Artist, Date Added, Duration

### 🎨 Beautiful Design
- Professional dark theme with purple gradient
- Smooth animations and transitions
- Rotating album art on player screen
- Mini player with progress indicator
- Playing animation indicator
- AMOLED mode support

### ⚙️ Advanced Settings
- Audio quality selection
- Crossfade duration
- Accent color themes
- Notification controls
- Headset button controls
- Library rescan

## Building the APK

### Requirements
- Flutter SDK 3.x
- Android Studio
- JDK 17+

### Steps

1. **Open in Android Studio:**
   - Open Android Studio
   - Click "Open" and select the `elkhalfy_musique` folder

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Build debug APK:**
   ```bash
   flutter build apk --debug
   ```

4. **Build release APK:**
   ```bash
   flutter build apk --release
   ```

5. The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

### Required Permissions
The app requires:
- `READ_EXTERNAL_STORAGE` / `READ_MEDIA_AUDIO` — to read music files
- `FOREGROUND_SERVICE` — for background playback
- `USE_BIOMETRIC` — for fingerprint authentication (optional)

## Project Structure

```
lib/
├── main.dart              # App entry point + audio service init
├── theme/
│   └── app_theme.dart     # Colors, gradients, typography
├── models/
│   └── song_model.dart    # SongModel, PlaylistModel, enums
├── services/
│   └── audio_handler.dart # AudioService background handler
├── providers/
│   ├── music_provider.dart    # Songs, playlists, favorites, hidden
│   ├── player_provider.dart   # Playback state & controls
│   └── settings_provider.dart # App settings & PIN management
├── screens/
│   ├── home_screen.dart       # Main screen with bottom nav
│   ├── player_screen.dart     # Full-screen player
│   ├── library_screen.dart    # Favorites, Playlists, Albums, Hidden
│   ├── settings_screen.dart   # All settings
│   └── lock_screen.dart       # PIN entry screen
└── widgets/
    ├── song_tile.dart          # Song list item
    ├── mini_player.dart        # Bottom mini player bar
    └── sleep_timer_dialog.dart # Sleep timer UI
```

## Packages Used

| Package | Purpose |
|---|---|
| `just_audio` | Audio playback engine |
| `audio_service` | Background playback + media notifications |
| `on_audio_query` | Read songs from device storage |
| `provider` | State management |
| `shared_preferences` | App settings persistence |
| `flutter_secure_storage` | Encrypted PIN storage |
| `local_auth` | Biometric authentication |
| `google_fonts` | Poppins font family |
| `flutter_staggered_animations` | List animations |
| `percent_indicator` | Progress indicators |
