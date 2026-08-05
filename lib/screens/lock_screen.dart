import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class LockScreen extends StatefulWidget {
  final bool isHiddenSongsLock;
  final VoidCallback? onUnlocked;

  const LockScreen({Key? key, this.isHiddenSongsLock = false, this.onUnlocked}) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  final List<String> _enteredPin = [];
  String _errorMessage = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 24)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      if (!widget.isHiddenSongsLock && settings.useBiometric) {
        _tryBiometric();
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    try {
      final canAuth = await _localAuth.canCheckBiometrics;
      if (!canAuth) return;
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock Elkhalfy Musique',
        options: const AuthenticationOptions(biometricOnly: false),
      );
      if (authenticated && mounted) {
        _handleUnlock();
      }
    } catch (_) {}
  }

  void _onKeyPress(String key) {
    if (key == '⌫') {
      if (_enteredPin.isNotEmpty) {
        setState(() {
          _enteredPin.removeLast();
          _errorMessage = '';
        });
      }
    } else {
      if (_enteredPin.length < 4) {
        setState(() {
          _enteredPin.add(key);
          _errorMessage = '';
        });
        if (_enteredPin.length == 4) {
          _checkPin();
        }
      }
    }
  }

  Future<void> _checkPin() async {
    final settings = context.read<SettingsProvider>();
    bool valid;
    if (widget.isHiddenSongsLock) {
      valid = await settings.verifyHiddenSongsPin(_enteredPin.join());
    } else {
      valid = await settings.verifyAppPin(_enteredPin.join());
    }

    if (valid) {
      _handleUnlock();
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN. Try again.';
        _enteredPin.clear();
      });
      _shakeController.forward(from: 0);
    }
  }

  void _handleUnlock() {
    if (widget.onUnlocked != null) {
      widget.onUnlocked!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Logo
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, Color(0xFF9B59B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 42),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.isHiddenSongsLock ? 'Hidden Songs' : 'Elkhalfy Musique',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your PIN to continue',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 48),
            // PIN dots
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    _shakeController.status == AnimationStatus.forward
                        ? _shakeAnimation.value * ((_shakeController.value * 10).toInt().isEven ? 1 : -1)
                        : 0,
                    0,
                  ),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: filled ? 22 : 18,
                    height: filled ? 22 : 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppTheme.primaryColor : Colors.transparent,
                      border: Border.all(
                        color: filled ? AppTheme.primaryColor : AppTheme.dividerColor,
                        width: 2,
                      ),
                      boxShadow: filled
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              AnimatedOpacity(
                opacity: _errorMessage.isNotEmpty ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const Spacer(),
            // Numpad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['', '0', '⌫'],
                  ])
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: row.map((key) {
                        if (key.isEmpty) {
                          return const SizedBox(width: 80, height: 80);
                        }
                        return _buildKey(key);
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Consumer<SettingsProvider>(
              builder: (ctx, settings, _) {
                if (!widget.isHiddenSongsLock && settings.useBiometric) {
                  return TextButton.icon(
                    onPressed: _tryBiometric,
                    icon: const Icon(Icons.fingerprint_rounded,
                        color: AppTheme.primaryColor),
                    label: const Text('Use Biometric',
                        style: TextStyle(color: AppTheme.primaryColor)),
                  );
                }
                return const SizedBox(height: 24);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String key) {
    final isDelete = key == '⌫';
    return GestureDetector(
      onTap: () => _onKeyPress(key),
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDelete ? Colors.transparent : AppTheme.cardColor,
          border: isDelete ? null : Border.all(color: AppTheme.dividerColor, width: 0.5),
        ),
        child: Center(
          child: isDelete
              ? const Icon(Icons.backspace_outlined, color: AppTheme.textSecondary, size: 24)
              : Text(
                  key,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                  ),
                ),
        ),
      ),
    );
  }
}
