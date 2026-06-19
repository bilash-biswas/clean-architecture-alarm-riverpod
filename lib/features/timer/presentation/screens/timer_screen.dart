import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';
import '../controllers/timer_controller.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  int _selectedHours = 0;
  int _selectedMinutes = 5;
  int _selectedSeconds = 0;

  // Controllers for ListWheelScrollViews
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _secondController;

  @override
  void initState() {
    super.initState();
    _hourController = FixedExtentScrollController(initialItem: _selectedHours);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinutes);
    _secondController = FixedExtentScrollController(initialItem: _selectedSeconds);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _updateControllerDuration() {
    final duration = Duration(
      hours: _selectedHours,
      minutes: _selectedMinutes,
      seconds: _selectedSeconds,
    );
    ref.read(timerControllerProvider.notifier).setDuration(duration);
  }

  void _selectPreset(Duration duration) {
    setState(() {
      _selectedHours = duration.inHours;
      _selectedMinutes = duration.inMinutes % 60;
      _selectedSeconds = duration.inSeconds % 60;

      // Animate wheels to position
      _hourController.animateToItem(_selectedHours,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      _minuteController.animateToItem(_selectedMinutes,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      _secondController.animateToItem(_selectedSeconds,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    });
    ref.read(timerControllerProvider.notifier).setDuration(duration);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timerControllerProvider);
    final controller = ref.read(timerControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Is the timer in a modified state (running or paused)?
    final isModified = state.isRunning || state.remainingTime != state.presetTime;

    // Calculate progress fraction
    final totalSecs = state.presetTime.inSeconds;
    final remainingSecs = state.remainingTime.inSeconds;
    final progress = totalSecs > 0 ? (remainingSecs / totalSecs).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getBackgroundGradient(context)),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Timer',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                      ),
                      onPressed: () => context.go('/settings'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Countdown display OR Duration picker
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: isModified
                        ? _buildCountdownRing(progress, state)
                        : _buildDurationPicker(),
                  ),
                ),
              ),

              // Quick preset shortcuts (only when not active)
              if (!isModified) ...[
                _buildPresetsPanel(),
                const SizedBox(height: 24),
              ],

              // Controls Panel
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    // Reset / Cancel button
                    if (isModified) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.reset,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                            side: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withOpacity(0.12)
                                  : Colors.black.withOpacity(0.12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],

                    // Start / Pause button
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: state.isRunning
                                ? [const Color(0xFFFF5E00), const Color(0xFFFF0055)]
                                : (isDark
                                    ? [const Color(0xFF00F5D4), const Color(0xFF00BBF9)]
                                    : [const Color(0xFF0D9488), const Color(0xFF0284C7)]),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (state.isRunning) {
                              controller.pause();
                            } else {
                              controller.start();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            state.isRunning ? 'Pause' : 'Start',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bottom Navigation Bar
              const BottomNavBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownRing(double progress, TimerState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? const Color(0xFF00F5D4) : const Color(0xFF7B2CBF);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 250,
          height: 250,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDuration(state.remainingTime),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w100,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              state.isRunning ? 'COUNTING DOWN' : 'PAUSED',
              style: TextStyle(
                fontSize: 10,
                color: state.isRunning ? accentColor.withOpacity(0.8) : (isDark ? Colors.white24 : Colors.black26),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(opacity: 0.03, isDark: isDark),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWheelColumn(
                label: 'hours',
                max: 24,
                controller: _hourController,
                onChanged: (val) {
                  setState(() => _selectedHours = val);
                  _updateControllerDuration();
                },
              ),
              _buildDividerColon(),
              _buildWheelColumn(
                label: 'min',
                max: 60,
                controller: _minuteController,
                onChanged: (val) {
                  setState(() => _selectedMinutes = val);
                  _updateControllerDuration();
                },
              ),
              _buildDividerColon(),
              _buildWheelColumn(
                label: 'sec',
                max: 60,
                controller: _secondController,
                onChanged: (val) {
                  setState(() => _selectedSeconds = val);
                  _updateControllerDuration();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWheelColumn({
    required String label,
    required int max,
    required FixedExtentScrollController controller,
    required ValueChanged<int> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pickerTextColor = isDark ? Colors.white : Colors.black87;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 120,
          width: 60,
          child: CupertinoTheme(
            data: CupertinoThemeData(
              brightness: isDark ? Brightness.dark : Brightness.light,
              textTheme: CupertinoTextThemeData(
                pickerTextStyle: TextStyle(color: pickerTextColor, fontSize: 22),
              ),
            ),
            child: CupertinoPicker(
              scrollController: controller,
              itemExtent: 40,
              onSelectedItemChanged: onChanged,
              looping: true,
              children: List.generate(
                max,
                (index) => Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 24,
                      color: pickerTextColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.4),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDividerColon() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Text(
        ':',
        style: TextStyle(
          color: isDark ? Colors.white30 : Colors.black38,
          fontSize: 28,
          fontWeight: FontWeight.w100,
        ),
      ),
    );
  }

  Widget _buildPresetsPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Presets',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPresetChip('1 Min', const Duration(minutes: 1)),
              const SizedBox(width: 8),
              _buildPresetChip('3 Min', const Duration(minutes: 3)),
              const SizedBox(width: 8),
              _buildPresetChip('5 Min', const Duration(minutes: 5)),
              const SizedBox(width: 8),
              _buildPresetChip('10 Min', const Duration(minutes: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, Duration duration) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03);
    final borderColor = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectPreset(duration),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

