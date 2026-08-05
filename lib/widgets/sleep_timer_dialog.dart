import 'package:flutter/material.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';

class SleepTimerDialog extends StatefulWidget {
  final PlayerProvider player;

  const SleepTimerDialog({Key? key, required this.player}) : super(key: key);

  @override
  State<SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<SleepTimerDialog> {
  int _selectedMinutes = 15;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _useSpecificTime = false;

  final List<int> _presets = [5, 10, 15, 20, 30, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    final isActive = widget.player.sleepTimerActive;
    final remaining = widget.player.remainingSleepTime;

    return Dialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.timer_rounded, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text('Sleep Timer',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 20),

            if (isActive && remaining != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Timer Active',
                              style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                          Text(
                            'Stops in ${_formatDuration(remaining)}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.player.cancelSleepTimer();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Mode Toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _useSpecificTime = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_useSpecificTime ? AppTheme.primaryColor : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('Duration',
                            style: TextStyle(
                              color: !_useSpecificTime ? Colors.white : AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _useSpecificTime = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _useSpecificTime ? AppTheme.primaryColor : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('Specific Time',
                            style: TextStyle(
                              color: _useSpecificTime ? Colors.white : AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (!_useSpecificTime) ...[
              const Text('Stop after:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.map((m) {
                  final selected = _selectedMinutes == m;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMinutes = m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppTheme.primaryColor : AppTheme.dividerColor,
                        ),
                      ),
                      child: Text(
                        m >= 60 ? '${m ~/ 60}h${m % 60 > 0 ? ' ${m % 60}m' : ''}' : '${m}m',
                        style: TextStyle(
                          color: selected ? Colors.white : AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              const Text('Stop at:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppTheme.primaryColor,
                          surface: AppTheme.cardColor,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (time != null) setState(() => _selectedTime = time);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time_rounded, color: AppTheme.primaryColor, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime.format(context),
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.dividerColor),
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Set Timer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startTimer() {
    if (_useSpecificTime) {
      final now = DateTime.now();
      final target = DateTime(now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute);
      widget.player.setSleepTimeAt(target);
    } else {
      widget.player.setSleepTimer(Duration(minutes: _selectedMinutes));
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_useSpecificTime
            ? 'Timer set for ${_selectedTime.format(context)}'
            : 'Music stops in $_selectedMinutes minutes'),
        backgroundColor: AppTheme.cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }
}
