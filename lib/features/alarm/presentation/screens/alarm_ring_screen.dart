import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/providers.dart';
import '../../../../core/services/sensor_service.dart';
import '../../domain/entities/alarm_entity.dart';
import '../../domain/entities/mission_entity.dart';
import '../controllers/alarm_controller.dart';
import '../../../timer/presentation/controllers/timer_controller.dart';
import '../../../sleep/presentation/controllers/sleep_log_controller.dart';

class AlarmRingScreen extends ConsumerStatefulWidget {
  final int alarmId;

  const AlarmRingScreen({super.key, required this.alarmId});

  @override
  ConsumerState<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends ConsumerState<AlarmRingScreen> {
  AlarmEntity? _alarm;
  bool _initialized = false;
  SensorService? _sensorService;

  // Math Mission state
  int _currentMathProblemIndex = 0;
  late String _mathQuestion;
  late int _mathAnswer;
  final TextEditingController _mathController = TextEditingController();

  // Shake Mission state
  int _shakeCount = 0;

  // Captcha Mission state
  late String _captchaText;
  final TextEditingController _captchaController = TextEditingController();

  // Memory Mission state
  List<String> _memoryItems = [];
  List<bool> _memoryCardRevealed = [];
  List<bool> _memoryCardMatched = [];
  int _memoryFirstSelectedIndex = -1;
  bool _memoryCheckingMatch = false;

  @override
  void initState() {
    super.initState();
    _mathQuestion = '';
    _mathAnswer = 0;
    _captchaText = '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sensorService = ref.read(sensorServiceProvider);
    if (!_initialized) {
      final alarms = ref.read(alarmControllerProvider);
      try {
        _alarm = alarms.firstWhere((a) => a.id == widget.alarmId);
      } catch (e) {
        // Fallback if alarm object not found in list (e.g. quick nap or temp alarm)
        _alarm = AlarmEntity(
          id: widget.alarmId,
          dateTime: DateTime.now(),
          label: widget.alarmId == 999999 ? 'Timer Completed' : 'Alarm Triggered',
        );
      }

      // Initialize mission states
      if (_alarm != null) {
        if (_alarm!.mission.type == MissionType.math) {
          _generateMathProblem();
        } else if (_alarm!.mission.type == MissionType.shake) {
          _sensorService?.startShakeDetection(
            onShakeDetected: _onShakeIncrement,
            threshold: 12.0,
          );
        } else if (_alarm!.mission.type == MissionType.captcha) {
          _generateCaptcha();
        } else if (_alarm!.mission.type == MissionType.memory) {
          _generateMemoryMatch();
        }
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    // Make sure we stop shake detection if active
    _sensorService?.stopShakeDetection();
    _mathController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  // --- MATH MISSION HELPERS ---
  void _generateMathProblem() {
    final difficulty = _alarm?.mission.difficulty ?? 1;
    final rand = math.Random();
    int a = 0, b = 0, c = 0;

    if (difficulty == 1) {
      // Easy: Single-digit addition/subtraction
      a = rand.nextInt(9) + 1;
      b = rand.nextInt(9) + 1;
      final op = rand.nextBool() ? '+' : '-';
      if (op == '+') {
        _mathQuestion = '$a + $b';
        _mathAnswer = a + b;
      } else {
        // Ensure positive result
        if (a < b) {
          final temp = a;
          a = b;
          b = temp;
        }
        _mathQuestion = '$a - $b';
        _mathAnswer = a - b;
      }
    } else if (difficulty == 2) {
      // Medium: Double-digit addition/subtraction or single-digit multiplication
      final isMult = rand.nextBool();
      if (isMult) {
        a = rand.nextInt(9) + 2;
        b = rand.nextInt(9) + 2;
        _mathQuestion = '$a × $b';
        _mathAnswer = a * b;
      } else {
        a = rand.nextInt(89) + 10;
        b = rand.nextInt(89) + 10;
        final op = rand.nextBool() ? '+' : '-';
        if (op == '+') {
          _mathQuestion = '$a + $b';
          _mathAnswer = a + b;
        } else {
          if (a < b) {
            final temp = a;
            a = b;
            b = temp;
          }
          _mathQuestion = '$a - $b';
          _mathAnswer = a - b;
        }
      }
    } else {
      // Hard: Complex three-term equations
      a = rand.nextInt(12) + 2;
      b = rand.nextInt(12) + 2;
      c = rand.nextInt(40) + 10;
      final multFirst = rand.nextBool();
      if (multFirst) {
        _mathQuestion = '($a × $b) + $c';
        _mathAnswer = (a * b) + c;
      } else {
        _mathQuestion = '$c - ($a × $b)';
        _mathAnswer = c - (a * b);
      }
    }
    _mathController.clear();
    setState(() {});
  }

  void _submitMathAnswer() {
    final ans = int.tryParse(_mathController.text.trim());
    if (ans == _mathAnswer) {
      final target = _alarm?.mission.targetCount ?? 3;
      if (_currentMathProblemIndex + 1 >= target) {
        _dismissAlarm();
      } else {
        setState(() {
          _currentMathProblemIndex++;
          _generateMathProblem();
        });
      }
    } else {
      // Wrong answer feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect. Try again!'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFFFF0055),
        ),
      );
    }
  }

  // --- SHAKE MISSION HELPERS ---
  void _onShakeIncrement() {
    if (!mounted) return;
    setState(() {
      _shakeCount++;
      final target = _alarm?.mission.targetCount ?? 20;
      if (_shakeCount >= target) {
        _sensorService?.stopShakeDetection();
        _dismissAlarm();
      }
    });
  }

  // --- CAPTCHA MISSION HELPERS ---
  void _generateCaptcha() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // removed confusing chars O, 0, I, 1
    final rand = math.Random();
    final length = (_alarm?.mission.difficulty ?? 1) == 1 ? 5 : 7;
    _captchaText = List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
    _captchaController.clear();
    setState(() {});
  }

  void _submitCaptcha() {
    if (_captchaController.text.trim().toUpperCase() == _captchaText) {
      _dismissAlarm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Captcha does not match. Try again!'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFFFF0055),
        ),
      );
      _generateCaptcha();
    }
  }

  // --- MEMORY MISSION HELPERS ---
  void _generateMemoryMatch() {
    final difficulty = _alarm?.mission.difficulty ?? 1;
    int numPairs = difficulty == 1 ? 2 : (difficulty == 2 ? 3 : 4);
    const symbols = ['🦊', '🦉', '🦁', '🦖', '🦄', '🐬', '🐝', '🐨'];
    final selectedSymbols = symbols.sublist(0, numPairs);
    _memoryItems = [...selectedSymbols, ...selectedSymbols];
    _memoryItems.shuffle(math.Random());
    _memoryCardRevealed = List.filled(_memoryItems.length, false);
    _memoryCardMatched = List.filled(_memoryItems.length, false);
    _memoryFirstSelectedIndex = -1;
    _memoryCheckingMatch = false;
    setState(() {});
  }

  void _onMemoryCardTap(int index) {
    if (_memoryCheckingMatch || _memoryCardRevealed[index] || _memoryCardMatched[index]) {
      return;
    }

    setState(() {
      _memoryCardRevealed[index] = true;
    });

    if (_memoryFirstSelectedIndex == -1) {
      _memoryFirstSelectedIndex = index;
    } else {
      _memoryCheckingMatch = true;
      final firstIdx = _memoryFirstSelectedIndex;
      _memoryFirstSelectedIndex = -1;

      if (_memoryItems[firstIdx] == _memoryItems[index]) {
        setState(() {
          _memoryCardMatched[firstIdx] = true;
          _memoryCardMatched[index] = true;
          _memoryCheckingMatch = false;
        });

        if (_memoryCardMatched.every((m) => m)) {
          _dismissAlarm();
        }
      } else {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _memoryCardRevealed[firstIdx] = false;
              _memoryCardRevealed[index] = false;
              _memoryCheckingMatch = false;
            });
          }
        });
      }
    }
  }

  // --- DISMISS & SNOOZE ACTIONS ---
  Future<void> _dismissAlarm() async {
    if (widget.alarmId == 999999) {
      await ref.read(alarmServiceProvider).cancelAlarm(widget.alarmId);
      ref.read(timerControllerProvider.notifier).dismissTimer();
      if (mounted) {
        context.go('/timer');
      }
      return;
    }

    if (_alarm != null) {
      // If it's a repeating alarm, calculate the next trigger time and reschedule it
      if (_alarm!.isRepeating) {
        final nextOccurrence = DateTime.now().add(const Duration(seconds: 1)); // Placeholder, recalculated on save
        final updatedAlarm = _alarm!.copyWith(
          dateTime: nextOccurrence,
          isEnabled: true,
          currentSnoozeCount: 0,
        );
        // Rescheduling will occur automatically on controller save
        await ref.read(alarmControllerProvider.notifier).updateAlarm(updatedAlarm);
      } else {
        // Disable non-repeating alarm
        final updatedAlarm = _alarm!.copyWith(isEnabled: false, currentSnoozeCount: 0);
        await ref.read(alarmControllerProvider.notifier).updateAlarm(updatedAlarm);
      }
    }
    
    // Stop native ringing audio
    await ref.read(alarmServiceProvider).cancelAlarm(widget.alarmId);
    
    if (mounted) {
      _showSleepJournalRatingSheet();
    }
  }

  void _showSleepJournalRatingSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF070708) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5);

    showModalBottomSheet(
      context: context,
      isDismissible: false, // Force rating check-in
      enableDrag: false,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Good Morning! ☀️',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: titleColor),
              ),
              const SizedBox(height: 8),
              Text(
                'How are you feeling right now?',
                style: TextStyle(fontSize: 14, color: subtitleColor),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildEmojiButton(context, '🤩', 'Refreshed', 4, isDark),
                  _buildEmojiButton(context, '🙂', 'Good', 3, isDark),
                  _buildEmojiButton(context, '🥱', 'Tired', 2, isDark),
                  _buildEmojiButton(context, '😫', 'Exhausted', 1, isDark),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmojiButton(BuildContext context, String emoji, String label, int rating, bool isDark) {
    final btnBgColor = isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03);
    final btnBorderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final labelColor = isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () async {
            await ref.read(sleepLogControllerProvider.notifier).logWakeUpQuality(rating);
            if (context.mounted) {
              Navigator.pop(context); // Pop sheet
              context.go('/'); // Return to dashboard
            }
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: btnBgColor,
              shape: BoxShape.circle,
              border: Border.all(color: btnBorderColor),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 32)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _snoozeAlarm() async {
    if (_alarm != null) {
      if (_alarm!.currentSnoozeCount >= _alarm!.maxSnoozeCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Max snooze limit reached! You must solve the mission.'),
            backgroundColor: Color(0xFFFF0055),
          ),
        );
        return;
      }

      await ref.read(alarmControllerProvider.notifier).snoozeAlarm(_alarm!);
      await ref.read(alarmServiceProvider).cancelAlarm(widget.alarmId);
      
      if (mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_alarm == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final mission = _alarm!.mission;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5);
    final buttonTextColor = isDark ? Colors.white70 : Colors.black87;
    final buttonBorderColor = isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.12);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getBackgroundGradient(context),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Pulse Glowing Icon
                _buildGlowingAlarmIcon(),
                const SizedBox(height: 24),
                // Alarm Title/Label
                Text(
                  _alarm!.label,
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.alarmId == 999999 ? 'Timer Finished' : 'Alarm is Ringing',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),

                // Challenge Card (Conditional on Mission type)
                _buildChallengeWidget(mission, isDark),

                const Spacer(),

                // Snooze & Direct Stop buttons
                Row(
                  children: [
                    if (widget.alarmId != 999999) ...[
                      // Allow snooze only if limit not reached
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _alarm!.currentSnoozeCount < _alarm!.maxSnoozeCount
                              ? _snoozeAlarm
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: buttonTextColor,
                            side: BorderSide(color: buttonBorderColor),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Snooze (${_alarm!.maxSnoozeCount - _alarm!.currentSnoozeCount} left)',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    // Stop button: if no mission, triggers stop directly. Else, disabled/hidden or prompts to solve
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.activeAlarmGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ElevatedButton(
                          onPressed: mission.type == MissionType.none ? _dismissAlarm : null,
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
                            mission.type == MissionType.none ? 'Dismiss' : 'Solve Mission to Stop',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlowingAlarmIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFF0055).withOpacity(0.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0055).withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: const Icon(
        Icons.alarm,
        size: 50,
        color: Color(0xFFFF0055),
      ),
    );
  }

  Widget _buildChallengeWidget(MissionEntity mission, bool isDark) {
    final titleColor = isDark ? Colors.white : Colors.black87;
    final accentColor = isDark ? const Color(0xFF00F5D4) : const Color(0xFF7B2CBF);
    final buttonTextColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.38);
    final borderColor = isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.23);

    switch (mission.type) {
      case MissionType.math:
        final target = mission.targetCount;
        return Container(
          decoration: AppTheme.glassDecoration(opacity: 0.1, isDark: isDark),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Math Challenge (${_currentMathProblemIndex + 1}/$target)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
              ),
              const SizedBox(height: 20),
              Text(
                _mathQuestion,
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: accentColor),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _mathController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Enter answer',
                  hintStyle: TextStyle(color: hintColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor, width: 2),
                  ),
                ),
                onSubmitted: (_) => _submitMathAnswer(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitMathAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: buttonTextColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Verify Answer'),
              ),
            ],
          ),
        );

      case MissionType.shake:
        final target = mission.targetCount;
        final progress = (_shakeCount / target).clamp(0.0, 1.0);
        return Container(
          decoration: AppTheme.glassDecoration(opacity: 0.1, isDark: isDark),
          padding: const EdgeInsets.all(24),
          width: double.infinity,
          child: Column(
            children: [
              Text(
                'Physical Challenge: Shake It!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
              ),
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_shakeCount',
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      Text(
                        '/ $target shakes',
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Icon(
                Icons.vibration,
                size: 32,
                color: accentColor,
              ),
              const SizedBox(height: 8),
              Text(
                'Shake the phone energetically to stop the alarm.',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

      case MissionType.captcha:
        final capBoxColor = isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.05);
        final capBorderColor = isDark ? Colors.white24 : Colors.black12;

        return Container(
          decoration: AppTheme.glassDecoration(opacity: 0.1, isDark: isDark),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Captcha Typing Challenge',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
              ),
              const SizedBox(height: 20),
              // Simulated styled Captcha box
              Container(
                decoration: BoxDecoration(
                  color: capBoxColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: capBorderColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  _captchaText,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                    color: accentColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _captchaController,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Type letters exactly',
                  hintStyle: TextStyle(color: hintColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor, width: 2),
                  ),
                ),
                onSubmitted: (_) => _submitCaptcha(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitCaptcha,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: buttonTextColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit Captcha'),
              ),
            ],
          ),
        );

      case MissionType.memory:
        if (_memoryItems.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return Container(
          decoration: AppTheme.glassDecoration(opacity: 0.1, isDark: isDark),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Memory Challenge: Match the Pairs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _memoryItems.length <= 4 ? 2 : 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: _memoryItems.length,
                itemBuilder: (context, idx) {
                  final revealed = _memoryCardRevealed[idx] || _memoryCardMatched[idx];
                  final cardBg = revealed
                      ? accentColor.withOpacity(0.15)
                      : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03));
                  final cardBorder = revealed ? accentColor : (isDark ? Colors.white24 : Colors.black12);

                  return GestureDetector(
                    onTap: () => _onMemoryCardTap(idx),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cardBorder,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        revealed ? _memoryItems[idx] : '❓',
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );

      default:
        // No mission: return blank or info text
        return Container(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No wake-up mission set. Have a wonderful morning!',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        );
    }
  }
}

