import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/alarm_entity.dart';
import '../../domain/entities/mission_entity.dart';
import '../controllers/alarm_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';

class AlarmListScreen extends ConsumerStatefulWidget {
  const AlarmListScreen({super.key});

  @override
  ConsumerState<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends ConsumerState<AlarmListScreen> {
  // Timer for ticking dashboard clock
  late Timer _tickerTimer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    try {
      // Request standard permissions in a batch first
      await [Permission.notification, Permission.scheduleExactAlarm].request();

      // Request system overlay permission separately, as it launches a native system settings intent on Android.
      if (Platform.isAndroid) {
        final isOverlayGranted = await Permission.systemAlertWindow.isGranted;
        if (!isOverlayGranted) {
          await Permission.systemAlertWindow.request();
        }
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  @override
  void dispose() {
    _tickerTimer.cancel();
    super.dispose();
  }

  // Calculate remaining time to next active alarm
  String _calculateTimeUntilNextAlarm(List<AlarmEntity> alarms) {
    final enabledAlarms = alarms.where((a) => a.isEnabled).toList();
    if (enabledAlarms.isEmpty) return 'No alarms active';

    final now = DateTime.now();
    DateTime? nextTime;

    for (var alarm in enabledAlarms) {
      if (alarm.dateTime.isAfter(now)) {
        if (nextTime == null || alarm.dateTime.isBefore(nextTime)) {
          nextTime = alarm.dateTime;
        }
      }
    }

    if (nextTime == null) return 'No active alarms';

    final diff = nextTime.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (hours == 0 && minutes == 0) {
      return 'Next alarm in less than a minute';
    }

    String timeStr = 'Next alarm in';
    if (hours > 0) {
      timeStr += ' $hours ${hours == 1 ? 'hour' : 'hours'}';
    }
    if (minutes > 0) {
      timeStr += ' $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }

    return timeStr;
  }

  // Create a Quick Nap Alarm
  Future<void> _scheduleQuickNap(int minutes) async {
    final now = DateTime.now();
    final napTime = now.add(Duration(minutes: minutes));

    final alarm = AlarmEntity(
      id: now.millisecondsSinceEpoch ~/ 1000,
      dateTime: napTime,
      label: '$minutes Min Power Nap',
      isEnabled: true,
      volume: 0.8,
      vibrate: true,
    );

    await ref.read(alarmControllerProvider.notifier).addAlarm(alarm);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$minutes min Quick Nap scheduled!',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF00F5D4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alarms = ref.watch(alarmControllerProvider);
    final alarmNotifier = ref.read(alarmControllerProvider.notifier);
    final nextAlarmText = _calculateTimeUntilNextAlarm(alarms);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final captionColor = isDark
        ? Colors.white.withOpacity(0.4)
        : Colors.black.withOpacity(0.4);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getBackgroundGradient(context),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TimeOrbit',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.settings_outlined,
                          color: subtitleColor,
                        ),
                        onPressed: () => context.go('/settings'),
                      ),
                    ],
                  ),
                ),

                // Glowing Digital Clock + Time remaining
                _buildClockPanel(nextAlarmText, isDark),
                const SizedBox(height: 24),

                // Quick Naps preset
                _buildQuickNapPanel(isDark),
                const SizedBox(height: 20),

                // Alarms list title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Alarms',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        '${alarms.length} scheduled',
                        style: TextStyle(fontSize: 13, color: captionColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Alarms List View / Empty State
                alarms.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: _buildEmptyState(isDark),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: alarms
                              .map(
                                (alarm) => _buildAlarmCard(
                                  alarm,
                                  alarmNotifier,
                                  isDark,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                // Safe padding at the bottom to ensure last element is scrollable above the bottom navigation bar and FAB
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        // 72 nav bar + 8 margin + 16 breathing room above the pill nav
        padding: const EdgeInsets.only(bottom: 4),
        child: FloatingActionButton(
          onPressed: () => context.go('/add-alarm'),
          backgroundColor: const Color(0xFF9D4EDD),
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          elevation: 10,
          child: const Icon(Icons.add, size: 40),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  Widget _buildClockPanel(String nextAlarmText, bool isDark) {
    final formatTime = DateFormat('hh:mm').format(_currentTime);
    final formatAmPm = DateFormat('a').format(_currentTime);
    final formatDate = DateFormat('EEE, d MMM').format(_currentTime);

    final clockColor = isDark ? Colors.white : Colors.black87;
    final dateColor = isDark
        ? Colors.white.withOpacity(0.5)
        : Colors.black.withOpacity(0.5);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 24),
      width: double.infinity,
      decoration: AppTheme.glassDecoration(opacity: 0.04, isDark: isDark),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatTime,
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w100,
                  color: clockColor,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatAmPm,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9D4EDD).withOpacity(0.8),
                ),
              ),
            ],
          ),
          Text(
            formatDate,
            style: TextStyle(
              fontSize: 16,
              color: dateColor,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          // Glow badge for next alarm
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF9D4EDD).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF9D4EDD).withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.alarm, color: Color(0xFF9D4EDD), size: 14),
                const SizedBox(width: 6),
                Text(
                  nextAlarmText,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFE0AAFF)
                        : const Color(0xFF7B2CBF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNapPanel(bool isDark) {
    final titleColor = isDark ? Colors.white70 : Colors.black87;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Nap',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildNapButton('15 Min', 15, isDark),
              const SizedBox(width: 12),
              _buildNapButton('30 Min', 30, isDark),
              const SizedBox(width: 12),
              _buildNapButton('45 Min', 45, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNapButton(String label, int minutes, bool isDark) {
    final bgColor = isDark
        ? Colors.white.withOpacity(0.03)
        : Colors.black.withOpacity(0.03);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Expanded(
      child: GestureDetector(
        onTap: () => _scheduleQuickNap(minutes),
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
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmCard(
    AlarmEntity alarm,
    AlarmController alarmNotifier,
    bool isDark,
  ) {
    final formatTime = DateFormat('hh:mm').format(alarm.dateTime);
    final formatAmPm = DateFormat('a').format(alarm.dateTime);

    final cardBgColor = isDark
        ? (alarm.isEnabled
              ? const Color(0xFF1E1E24).withOpacity(0.6)
              : const Color(0xFF121214).withOpacity(0.4))
        : (alarm.isEnabled
              ? Colors.white.withOpacity(0.8)
              : Colors.white.withOpacity(0.4));
    final cardBorderColor = isDark
        ? (alarm.isEnabled
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.04))
        : (alarm.isEnabled
              ? Colors.black.withOpacity(0.08)
              : Colors.black.withOpacity(0.04));

    final timeTextColor = alarm.isEnabled
        ? (isDark ? Colors.white : Colors.black87)
        : (isDark ? Colors.white30 : Colors.black26);
    final amPmColor = alarm.isEnabled
        ? (isDark ? const Color(0xFF00F5D4) : const Color(0xFF7B2CBF))
        : (isDark ? Colors.white30 : Colors.black26);
    final subtextColor = alarm.isEnabled
        ? (isDark ? Colors.white70 : Colors.black87)
        : (isDark ? Colors.white24 : Colors.black26);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorderColor, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.go('/edit-alarm/${alarm.id}'),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatTime,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: timeTextColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatAmPm,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: amPmColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${alarm.label}  •  ${alarm.repeatDaysText}',
                      style: TextStyle(fontSize: 13, color: subtextColor),
                    ),
                    if (alarm.mission.type != MissionType.none &&
                        alarm.isEnabled) ...[
                      const SizedBox(height: 8),
                      // Mini mission badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? const Color(0xFF00F5D4)
                                      : const Color(0xFF0D9488))
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          alarm.mission.type.name.toUpperCase(),
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF00F5D4)
                                : const Color(0xFF0D9488),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: alarm.isEnabled,
                activeColor: const Color(0xFF9D4EDD),
                activeTrackColor: isDark
                    ? const Color(0xFF3C096C)
                    : const Color(0xFFE0AAFF),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,
                onChanged: (val) => alarmNotifier.toggleAlarm(alarm.id, val),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final iconColor = isDark
        ? Colors.white.withOpacity(0.15)
        : Colors.black.withOpacity(0.15);
    final titleColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black87;
    final subtextColor = isDark
        ? Colors.white.withOpacity(0.3)
        : Colors.black54;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.alarm_off, size: 64, color: iconColor),
          const SizedBox(height: 16),
          Text(
            'No Alarms Set',
            style: TextStyle(
              fontSize: 18,
              color: titleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click the + button to schedule your first alarm',
            style: TextStyle(fontSize: 13, color: subtextColor),
          ),
        ],
      ),
    );
  }
}
