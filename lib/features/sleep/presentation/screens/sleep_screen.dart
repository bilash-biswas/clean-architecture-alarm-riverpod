import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/sleep_controller.dart';
import '../controllers/sleep_log_controller.dart';
import '../../../alarm/presentation/controllers/alarm_controller.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';

class SleepScreen extends ConsumerWidget {
  const SleepScreen({super.key});

  // Helper to format remaining timer: mm:ss
  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Calculate Bedtime suggestions based on optimal 90-minute sleep cycles
  List<Map<String, dynamic>> _calculateBedtimes(DateTime wakeTime, bool isDark) {
    // 14 minutes is average time needed to fall asleep
    final fallAsleepWindow = const Duration(minutes: 14);
    
    return [
      {
        'cycles': 6,
        'duration': '9.0 hrs',
        'time': wakeTime.subtract(const Duration(hours: 9)).subtract(fallAsleepWindow),
        'tag': 'Ideal',
        'color': isDark ? const Color(0xFF00F5D4) : const Color(0xFF0D9488),
      },
      {
        'cycles': 5,
        'duration': '7.5 hrs',
        'time': wakeTime.subtract(const Duration(hours: 7, minutes: 30)).subtract(fallAsleepWindow),
        'tag': 'Recommended',
        'color': isDark ? const Color(0xFF00BBF9) : const Color(0xFF0284C7),
      },
      {
        'cycles': 4,
        'duration': '6.0 hrs',
        'time': wakeTime.subtract(const Duration(hours: 6)).subtract(fallAsleepWindow),
        'tag': 'Minimum',
        'color': isDark ? const Color(0xFFFF8500) : const Color(0xFFEA580C),
      },
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sleepState = ref.watch(sleepControllerProvider);
    final sleepController = ref.read(sleepControllerProvider.notifier);
    
    final sleepLogController = ref.read(sleepLogControllerProvider.notifier);

    final alarms = ref.watch(alarmControllerProvider);

    // Calculate next wake time from active alarms
    final now = DateTime.now();
    DateTime? nextWakeTime;
    final activeAlarms = alarms.where((a) => a.isEnabled).toList();
    
    for (var alarm in activeAlarms) {
      if (alarm.dateTime.isAfter(now)) {
        if (nextWakeTime == null || alarm.dateTime.isBefore(nextWakeTime)) {
          nextWakeTime = alarm.dateTime;
        }
      }
    }

    // Default target wake time if no alarm is scheduled
    final bool hasActiveAlarm = nextWakeTime != null;
    nextWakeTime ??= DateTime(now.year, now.month, now.day, 7, 0).add(
      now.hour >= 7 ? const Duration(days: 1) : Duration.zero,
    );

    final bedtimeSuggestions = _calculateBedtimes(nextWakeTime, isDark);

    final List<Map<String, String>> soundPresets = [
      {
        'name': 'Rain & Thunder',
        'icon': '⛈️',
        'path': AppConstants.ambientRainAudioPath,
      },
      {
        'name': 'Deep Ocean',
        'icon': '🌊',
        'path': AppConstants.ambientOceanAudioPath,
      },
      {
        'name': 'Campfire Spark',
        'icon': '🔥',
        'path': AppConstants.ambientCampfireAudioPath,
      },
    ];

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
                      'Sleep Sound Aid',
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

              // Scrollable Dashboard Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 90),
                  children: [
                    const SizedBox(height: 8),

                    // Countdown Timer display
                    Center(
                      child: _buildTimerWheel(context, sleepState, sleepController),
                    ),
                    const SizedBox(height: 24),

                    // Playback Volume and Controls
                    _buildPlaybackControls(context, sleepState, sleepController),
                    const SizedBox(height: 24),

                    // Bedtime Suggestions (Sleep Cycle planner)
                    _buildBedtimePlannerPanel(context, nextWakeTime, hasActiveAlarm, bedtimeSuggestions),
                    const SizedBox(height: 24),

                    // Weekly Sleep Analytics Chart
                    _buildAnalyticsPanel(context, sleepLogController),
                    const SizedBox(height: 24),

                    // Sounds Preset Selection list
                    Text(
                      'Ambient Sounds',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: soundPresets.map((preset) {
                        final isSelected = sleepState.selectedSound == preset['path'];
                        return _buildSoundListTile(context, preset, isSelected, sleepController);
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Navigation Bar
              const BottomNavBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerWheel(BuildContext context, SleepState state, SleepController controller) {
    final hasTimer = state.remainingTimer != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.white.withOpacity(0.01) : Colors.black.withOpacity(0.01),
        border: Border.all(
          color: hasTimer ? (isDark ? const Color(0xFF00BBF9) : const Color(0xFF0284C7)).withOpacity(0.2) : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.spa_outlined,
            color: hasTimer ? (isDark ? const Color(0xFF00BBF9) : const Color(0xFF0284C7)) : (isDark ? Colors.white24 : Colors.black26),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            _formatDuration(state.remainingTimer),
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w100,
              color: hasTimer ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white30 : Colors.black26),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasTimer ? 'Fading out soon' : 'Set a Sleep Timer',
            style: TextStyle(
              fontSize: 10,
              color: hasTimer ? (isDark ? const Color(0xFF00BBF9) : const Color(0xFF0284C7)).withOpacity(0.7) : (isDark ? Colors.white24 : Colors.black26),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!hasTimer) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPresetButton(context, '15m', const Duration(minutes: 15), controller),
                const SizedBox(width: 8),
                _buildPresetButton(context, '30m', const Duration(minutes: 30), controller),
                const SizedBox(width: 8),
                _buildPresetButton(context, '60m', const Duration(minutes: 60), controller),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: controller.stopTimer,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0055).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF0055).withOpacity(0.2)),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFFFF0055), fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetButton(BuildContext context, String label, Duration duration, SleepController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => controller.startTimer(duration),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
        ),
        child: Text(
          label,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 10),
        ),
      ),
    );
  }

  Widget _buildPlaybackControls(BuildContext context, SleepState state, SleepController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final volumeIconColor = isDark ? Colors.white30 : Colors.black26;
    final playBtnBg = state.isPlaying ? null : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03));
    final playIconColor = state.isPlaying ? Colors.white : (isDark ? Colors.white : Colors.black87);

    return Container(
      decoration: AppTheme.glassDecoration(opacity: 0.03, isDark: isDark),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.volume_down_outlined, color: volumeIconColor, size: 18),
              Expanded(
                child: Slider(
                  value: state.volume,
                  activeColor: isDark ? const Color(0xFF00BBF9) : const Color(0xFF0284C7),
                  inactiveColor: isDark ? Colors.white10 : Colors.black12,
                  onChanged: controller.setVolume,
                ),
              ),
              Icon(Icons.volume_up_outlined, color: volumeIconColor, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: controller.togglePlay,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: state.isPlaying
                    ? LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF00BBF9), const Color(0xFF00F5D4)]
                            : [const Color(0xFF0284C7), const Color(0xFF0D9488)])
                    : null,
                color: playBtnBg,
              ),
              child: Icon(
                state.isPlaying ? Icons.pause : Icons.play_arrow,
                color: playIconColor,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBedtimePlannerPanel(BuildContext context, DateTime wakeTime, bool hasActiveAlarm, List<Map<String, dynamic>> suggestions) {
    final timeStr = DateFormat('hh:mm a').format(wakeTime);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5);
    final accentColor = isDark ? const Color(0xFF00F5D4) : const Color(0xFF7B2CBF);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(opacity: 0.03, isDark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bedtime Sleep Cycles Planner',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
              ),
              Icon(
                hasActiveAlarm ? Icons.alarm_on : Icons.alarm_off,
                size: 16,
                color: hasActiveAlarm ? accentColor : (isDark ? Colors.white24 : Colors.black26),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hasActiveAlarm
                ? 'Based on your upcoming alarm scheduled at $timeStr:'
                : 'To wake up feeling fully refreshed at $timeStr:',
            style: TextStyle(color: subtitleColor, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: suggestions.map((s) {
              final formattedBedtime = DateFormat('h:mm a').format(s['time'] as DateTime);
              final isIdeal = s['tag'] == 'Ideal';
              final columnBg = isIdeal ? (s['color'] as Color).withOpacity(0.08) : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03));
              final columnBorder = isIdeal ? (s['color'] as Color).withOpacity(0.3) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06));

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: columnBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: columnBorder,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        formattedBedtime,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s['duration'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (s['color'] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s['tag'] as String,
                          style: TextStyle(
                            color: s['color'] as Color,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsPanel(BuildContext context, SleepLogController logController) {
    final stats = logController.getLast7DaysStats();
    final avgLabel = logController.getAverageMoodLabel();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final avgColor = isDark ? const Color(0xFF00F5D4) : const Color(0xFF7B2CBF);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(opacity: 0.03, isDark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Sleep Analytics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
              ),
              Text(
                'Avg: $avgLabel',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: avgColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Custom painted/designed Bar Chart columns
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: stats.map((day) {
              final rating = day['rating'] as int;
              
              double heightFraction = 0.08; // default minimum height
              Color barColor = isDark ? Colors.white10 : Colors.black12;
              if (rating == 4) {
                heightFraction = 1.0;
                barColor = isDark ? const Color(0xFF00F5D4) : const Color(0xFF0D9488);
              } else if (rating == 3) {
                heightFraction = 0.75;
                barColor = isDark ? const Color(0xFF00BBF9) : const Color(0xFF0284C7);
              } else if (rating == 2) {
                heightFraction = 0.5;
                barColor = isDark ? const Color(0xFFFF8500) : const Color(0xFFEA580C);
              } else if (rating == 1) {
                heightFraction = 0.25;
                barColor = isDark ? const Color(0xFFFF0055) : const Color(0xFFD6004F);
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Background slot outline
                      Container(
                        height: 80,
                        width: 14,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      // Colored bar
                      Container(
                        height: 80 * heightFraction,
                        width: 14,
                        decoration: BoxDecoration(
                          color: barColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: rating > 0
                              ? [
                                  BoxShadow(
                                    color: barColor.withOpacity(0.2),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  )
                                ]
                              : [],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    day['dayName'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: rating > 0 ? (isDark ? Colors.white70 : Colors.black87) : (isDark ? Colors.white24 : Colors.black26),
                      fontWeight: rating > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rating > 0 ? day['emoji'] as String : '•',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundListTile(BuildContext context, Map<String, String> preset, bool isSelected, SleepController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? const Color(0xFF00BBF9) : const Color(0xFF0284C7);

    final tileBgColor = isSelected ? activeColor.withOpacity(0.05) : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02));
    final tileBorderColor = isSelected ? activeColor.withOpacity(0.2) : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04));
    final titleColor = isSelected ? activeColor : (isDark ? Colors.white : Colors.black87);
    final trailingIconColor = isSelected ? activeColor : (isDark ? Colors.white24 : Colors.black26);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: tileBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tileBorderColor,
        ),
      ),
      child: ListTile(
        leading: Text(preset['icon'] ?? '🎵', style: const TextStyle(fontSize: 22)),
        title: Text(
          preset['name'] ?? '',
          style: TextStyle(
            color: titleColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.volume_up, color: activeColor, size: 20)
            : Icon(Icons.play_arrow_outlined, color: trailingIconColor, size: 20),
        onTap: () => controller.selectSound(preset['path'] ?? ''),
      ),
    );
  }
}

