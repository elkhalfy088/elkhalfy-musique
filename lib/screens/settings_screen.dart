import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import 'lock_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (ctx, settings, _) {
        return Scaffold(
          backgroundColor: AppTheme.bgColor,
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: AppTheme.bgColor,
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              // Profile Header
              _buildHeader(ctx, settings),
              const SizedBox(height: 8),

              // Security
              _buildSection('🔐 Security', [
                _buildSwitchTile(
                  title: 'App Lock',
                  subtitle: 'Require PIN to open app',
                  icon: Icons.lock_rounded,
                  value: settings.appLockEnabled,
                  onChanged: (v) {
                    if (v && !settings.hasAppPin) {
                      _showSetPinDialog(ctx, settings, isAppPin: true);
                    } else {
                      settings.setAppLockEnabled(v);
                    }
                  },
                ),
                if (settings.appLockEnabled) ...[
                  _buildActionTile(
                    title: 'Change App PIN',
                    subtitle: 'Update your app lock PIN',
                    icon: Icons.pin_rounded,
                    onTap: () => _showSetPinDialog(ctx, settings, isAppPin: true),
                  ),
                  _buildSwitchTile(
                    title: 'Biometric Authentication',
                    subtitle: 'Use fingerprint or face to unlock',
                    icon: Icons.fingerprint_rounded,
                    value: settings.useBiometric,
                    onChanged: settings.setUseBiometric,
                  ),
                  _buildActionTile(
                    title: 'Remove App Lock',
                    subtitle: 'Disable PIN lock',
                    icon: Icons.lock_open_rounded,
                    onTap: () => _confirmRemovePin(ctx, settings),
                    destructive: true,
                  ),
                ],
                _buildActionTile(
                  title: settings.hasHiddenSongsPin
                      ? 'Change Hidden Songs PIN'
                      : 'Set Hidden Songs PIN',
                  subtitle: 'Protect access to hidden songs',
                  icon: Icons.visibility_off_rounded,
                  onTap: () => _showSetPinDialog(ctx, settings, isAppPin: false),
                ),
                if (settings.hasHiddenSongsPin)
                  _buildActionTile(
                    title: 'Remove Hidden Songs PIN',
                    subtitle: 'Anyone can view hidden songs',
                    icon: Icons.no_encryption_rounded,
                    onTap: () {
                      settings.removeHiddenSongsPin();
                      _showSnack(ctx, 'Hidden songs PIN removed');
                    },
                    destructive: true,
                  ),
              ]),

              // Playback
              _buildSection('🎵 Playback', [
                _buildSwitchTile(
                  title: 'Gapless Playback',
                  subtitle: 'No gap between songs',
                  icon: Icons.queue_music_rounded,
                  value: settings.gaplessPlayback,
                  onChanged: settings.setGaplessPlayback,
                ),
                _buildSwitchTile(
                  title: 'Crossfade',
                  subtitle: 'Smooth transition between songs',
                  icon: Icons.swap_horiz_rounded,
                  value: settings.crossfadeEnabled,
                  onChanged: settings.setCrossfadeEnabled,
                ),
                if (settings.crossfadeEnabled)
                  _buildSliderTile(
                    title: 'Crossfade Duration',
                    subtitle: '${settings.crossfadeDuration.toStringAsFixed(1)}s',
                    icon: Icons.timer_rounded,
                    value: settings.crossfadeDuration,
                    min: 1.0,
                    max: 10.0,
                    onChanged: settings.setCrossfadeDuration,
                  ),
                _buildSwitchTile(
                  title: 'Headset Controls',
                  subtitle: 'Control playback with headset buttons',
                  icon: Icons.headset_rounded,
                  value: settings.headsetControl,
                  onChanged: settings.setHeadsetControl,
                ),
                _buildActionTile(
                  title: 'Audio Quality',
                  subtitle: _audioQualityLabel(settings.audioQuality),
                  icon: Icons.high_quality_rounded,
                  onTap: () => _showAudioQualityDialog(ctx, settings),
                ),
              ]),

              // Appearance
              _buildSection('🎨 Appearance', [
                _buildSwitchTile(
                  title: 'Show Album Art',
                  subtitle: 'Display cover art in song list',
                  icon: Icons.image_rounded,
                  value: settings.showAlbumArt,
                  onChanged: settings.setShowAlbumArt,
                ),
                _buildSwitchTile(
                  title: 'AMOLED Dark Mode',
                  subtitle: 'Pure black background (saves battery)',
                  icon: Icons.brightness_2_rounded,
                  value: settings.darkModeAmoled,
                  onChanged: settings.setDarkModeAmoled,
                ),
                _buildActionTile(
                  title: 'Accent Color',
                  subtitle: _accentColorLabel(settings.accentColor),
                  icon: Icons.color_lens_rounded,
                  onTap: () => _showAccentColorDialog(ctx, settings),
                ),
              ]),

              // Notifications
              _buildSection('🔔 Notifications', [
                _buildSwitchTile(
                  title: 'Media Notification',
                  subtitle: 'Show player controls in notification bar',
                  icon: Icons.notifications_rounded,
                  value: settings.notificationEnabled,
                  onChanged: settings.setNotificationEnabled,
                ),
              ]),

              // Library
              _buildSection('📚 Library', [
                _buildActionTile(
                  title: 'Rescan Library',
                  subtitle: 'Refresh music from storage',
                  icon: Icons.refresh_rounded,
                  onTap: () {
                    context.read<MusicProvider>().loadSongs();
                    _showSnack(ctx, 'Scanning library...');
                  },
                ),
              ]),

              // About
              _buildSection('ℹ️ About', [
                _buildInfoTile('App Name', 'Elkhalfy Musique', Icons.music_note_rounded),
                _buildInfoTile('Version', '1.0.0', Icons.info_outline_rounded),
                _buildInfoTile('Developer', 'Elkhalfy Dev', Icons.code_rounded),
                _buildActionTile(
                  title: 'Rate the App',
                  subtitle: 'Leave a review on Play Store',
                  icon: Icons.star_rounded,
                  onTap: () {},
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext ctx, SettingsProvider settings) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E35), Color(0xFF252545)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Center(
              child: Text('E',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  )),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Elkhalfy Musique',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 4),
                Text(
                  settings.appLockEnabled ? '🔒 App Lock Active' : '🎵 Ready to Play',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'v1.0.0',
                  style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerColor, width: 0.5),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: destructive
              ? Colors.red.withOpacity(0.1)
              : AppTheme.primaryColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: destructive ? Colors.redAccent : AppTheme.primaryColor, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              color: destructive ? Colors.redAccent : AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: destructive ? Colors.redAccent.withOpacity(0.5) : AppTheme.textTertiary, size: 20),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
                    Text(subtitle,
                        style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(value: value, min: min, max: max, onChanged: onChanged),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: Text(value, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
    );
  }

  void _showSetPinDialog(BuildContext ctx, SettingsProvider settings,
      {required bool isAppPin}) {
    final pin1Controller = TextEditingController();
    final pin2Controller = TextEditingController();
    String? error;

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setState) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isAppPin ? 'Set App PIN' : 'Set Hidden Songs PIN',
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pin1Controller,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, letterSpacing: 8),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Enter 4-digit PIN',
                  hintStyle: const TextStyle(color: AppTheme.textTertiary, letterSpacing: 0, fontSize: 14),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pin2Controller,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, letterSpacing: 8),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Confirm PIN',
                  hintStyle: const TextStyle(color: AppTheme.textTertiary, letterSpacing: 0, fontSize: 14),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '',
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx2),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (pin1Controller.text.length != 4) {
                  setState(() => error = 'PIN must be 4 digits');
                  return;
                }
                if (pin1Controller.text != pin2Controller.text) {
                  setState(() => error = 'PINs do not match');
                  return;
                }
                if (isAppPin) {
                  settings.setAppPin(pin1Controller.text);
                } else {
                  settings.setHiddenSongsPin(pin1Controller.text);
                }
                Navigator.pop(ctx2);
                _showSnack(ctx, 'PIN set successfully');
              },
              child: const Text('Set PIN'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemovePin(BuildContext ctx, SettingsProvider settings) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove App Lock?',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text('Anyone will be able to open the app without a PIN.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              settings.removeAppPin();
              Navigator.pop(ctx);
              _showSnack(ctx, 'App lock removed');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAudioQualityDialog(BuildContext ctx, SettingsProvider settings) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Audio Quality',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final q in [
              ('low', 'Low Quality', '64 kbps'),
              ('medium', 'Medium Quality', '128 kbps'),
              ('high', 'High Quality', '320 kbps'),
              ('lossless', 'Lossless', 'Original'),
            ])
              ListTile(
                leading: Radio<String>(
                  value: q.$1,
                  groupValue: settings.audioQuality,
                  onChanged: (v) {
                    if (v != null) {
                      settings.setAudioQuality(v);
                      Navigator.pop(ctx);
                    }
                  },
                  activeColor: AppTheme.primaryColor,
                ),
                title: Text(q.$2, style: const TextStyle(color: AppTheme.textPrimary)),
                subtitle: Text(q.$3, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
                onTap: () {
                  settings.setAudioQuality(q.$1);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAccentColorDialog(BuildContext ctx, SettingsProvider settings) {
    final colors = [
      ('purple', 'Purple', const Color(0xFF6C63FF)),
      ('blue', 'Blue', const Color(0xFF2196F3)),
      ('green', 'Green', const Color(0xFF4CAF50)),
      ('orange', 'Orange', const Color(0xFFFF9800)),
      ('pink', 'Pink', const Color(0xFFE91E63)),
      ('teal', 'Teal', const Color(0xFF009688)),
    ];

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Accent Color',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((c) {
            final isSelected = settings.accentColor == c.$1;
            return GestureDetector(
              onTap: () {
                settings.setAccentColor(c.$1);
                Navigator.pop(ctx);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: c.$3,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [BoxShadow(color: c.$3.withOpacity(0.5), blurRadius: 12)]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(c.$2,
                      style: TextStyle(
                          color: isSelected ? c.$3 : AppTheme.textTertiary, fontSize: 11)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _audioQualityLabel(String q) {
    switch (q) {
      case 'low': return 'Low (64 kbps)';
      case 'medium': return 'Medium (128 kbps)';
      case 'high': return 'High (320 kbps)';
      case 'lossless': return 'Lossless';
      default: return 'High (320 kbps)';
    }
  }

  String _accentColorLabel(String c) {
    switch (c) {
      case 'purple': return 'Purple';
      case 'blue': return 'Blue';
      case 'green': return 'Green';
      case 'orange': return 'Orange';
      case 'pink': return 'Pink';
      case 'teal': return 'Teal';
      default: return 'Purple';
    }
  }

  void _showSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
