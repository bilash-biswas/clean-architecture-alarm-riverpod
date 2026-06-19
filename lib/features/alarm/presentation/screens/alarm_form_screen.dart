import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/alarm_entity.dart';
import '../../domain/entities/mission_entity.dart';
import '../controllers/alarm_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import 'package:just_audio/just_audio.dart';

class AlarmFormScreen extends ConsumerStatefulWidget {
  final int? alarmId;

  const AlarmFormScreen({super.key, this.alarmId});

  @override
  ConsumerState<AlarmFormScreen> createState() => _AlarmFormScreenState();
}

class _AlarmFormScreenState extends ConsumerState<AlarmFormScreen> {
  bool _isEdit = false;
  late TimeOfDay _selectedTime;
  late String _label;
  late List<int> _repeatDays;
  late int _snoozeDuration;
  late int _maxSnoozeCount;
  late String _audioPath;
  late double _volume;
  late bool _vibrate;
  late int _fadeDuration;
  late MissionType _missionType;
  late int _missionDifficulty;
  late int _missionTargetCount;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.alarmId != null;

    // Set standard defaults first, overwritten in didChangeDependencies if editing
    final now = DateTime.now();
    _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
    _label = 'Alarm';
    _repeatDays = [];
    _snoozeDuration = 5;
    _maxSnoozeCount = 3;
    _audioPath = 'assets/audio/alarm.wav';
    _volume = 0.8;
    _vibrate = true;
    _fadeDuration = 10;
    _missionType = MissionType.none;
    _missionDifficulty = 1;
    _missionTargetCount = 3;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isEdit) {
      final alarms = ref.read(alarmControllerProvider);
      try {
        final alarm = alarms.firstWhere((a) => a.id == widget.alarmId);
        _selectedTime = TimeOfDay(hour: alarm.dateTime.hour, minute: alarm.dateTime.minute);
        _label = alarm.label;
        _repeatDays = List<int>.from(alarm.repeatDays);
        _snoozeDuration = alarm.snoozeDurationMinutes;
        _maxSnoozeCount = alarm.maxSnoozeCount;
        _audioPath = alarm.audioPath;
        _volume = alarm.volume;
        _vibrate = alarm.vibrate;
        _fadeDuration = alarm.fadeDurationSeconds;
        _missionType = alarm.mission.type;
        _missionDifficulty = alarm.mission.difficulty;
        _missionTargetCount = alarm.mission.targetCount;
      } catch (e) {
        // Fallback
      }
    } else {
      // Pull defaults from SettingsController
      final settings = ref.read(settingsControllerProvider);
      _snoozeDuration = settings.defaultSnoozeDuration;
      _volume = settings.defaultAlarmVolume;
      _fadeDuration = settings.fadeInDuration;
    }
  }

  // Pick Time
  Future<void> _selectTime(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF9D4EDD),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E1E24),
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF7B2CBF),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
                ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Save Alarm
  Future<void> _saveAlarm() async {
    final now = DateTime.now();
    // Temporary date time for calculations
    var alarmDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final alarm = AlarmEntity(
      id: widget.alarmId ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      dateTime: alarmDateTime,
      label: _label.isEmpty ? 'Alarm' : _label,
      repeatDays: _repeatDays,
      isEnabled: true,
      snoozeDurationMinutes: _snoozeDuration,
      maxSnoozeCount: _maxSnoozeCount,
      audioPath: _audioPath,
      volume: _volume,
      vibrate: _vibrate,
      fadeDurationSeconds: _fadeDuration,
      mission: MissionEntity(
        type: _missionType,
        difficulty: _missionDifficulty,
        targetCount: _missionTargetCount,
      ),
    );

    try {
      if (_isEdit) {
        await ref.read(alarmControllerProvider.notifier).updateAlarm(alarm);
      } else {
        await ref.read(alarmControllerProvider.notifier).addAlarm(alarm);
      }
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF0055),
          ),
        );
      }
    }
  }

  // Delete Alarm
  Future<void> _deleteAlarm() async {
    if (widget.alarmId != null) {
      await ref.read(alarmControllerProvider.notifier).delete(widget.alarmId!);
      if (mounted) {
        context.go('/');
      }
    }
  }

  // Toggle Weekday Selection (1=Mon, 7=Sun)
  void _toggleDay(int day) {
    setState(() {
      if (_repeatDays.contains(day)) {
        _repeatDays.remove(day);
      } else {
        _repeatDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _isEdit ? 'Edit Alarm' : 'New Alarm';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleColor = isDark ? Colors.white : Colors.black87;
    final backIconColor = isDark ? Colors.white70 : Colors.black54;
    final saveIconColor = isDark ? const Color(0xFF00F5D4) : const Color(0xFF7B2CBF);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getBackgroundGradient(context)),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: backIconColor),
                      onPressed: () => context.go('/'),
                    ),
                    Text(
                      titleText,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: titleColor),
                    ),
                    IconButton(
                      icon: Icon(Icons.check, color: saveIconColor, size: 28),
                      onPressed: _saveAlarm,
                    ),
                  ],
                ),
              ),

              // Form body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large interactive time picker button
                      _buildTimePickerWidget(),
                      const SizedBox(height: 24),

                      // Label input
                      _buildLabelInput(),
                      const SizedBox(height: 16),

                      // Day selector
                      Text(
                        'Repeat Days',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDaySelector(),
                      const SizedBox(height: 24),

                      // Snooze Settings
                      _buildSnoozeCard(),
                      const SizedBox(height: 16),

                      // Mission Selector
                      _buildMissionCard(),
                      const SizedBox(height: 16),

                      // Settings & Sound Preferences
                      _buildSoundPreferencesCard(),
                      const SizedBox(height: 32),

                      // Delete Button (visible when editing)
                      if (_isEdit)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF0055).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFF0055).withOpacity(0.3)),
                          ),
                          child: TextButton.icon(
                            onPressed: _deleteAlarm,
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFFF0055)),
                            label: const Text('Delete Alarm', style: TextStyle(color: Color(0xFFFF0055), fontSize: 16)),
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerWidget() {
    final hour = _selectedTime.hour.toString().padLeft(2, '0');
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final clockTextColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white30 : Colors.black45;

    return GestureDetector(
      onTap: () => _selectTime(context),
      child: Center(
        child: Container(
          width: double.infinity,
          height: 160,
          decoration: AppTheme.glassDecoration(opacity: 0.08, isDark: isDark),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$hour:$minute',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w100,
                  color: clockTextColor,
                  letterSpacing: -2,
                  shadows: isDark
                      ? [
                          const Shadow(
                            color: Color(0xFF9D4EDD),
                            blurRadius: 25,
                          ),
                        ]
                      : null,
                ),
              ),
              Text(
                'Tap to change time',
                style: TextStyle(color: hintColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.38);

    return Container(
      decoration: AppTheme.glassDecoration(opacity: 0.05, isDark: isDark),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        initialValue: _label == 'Alarm' ? '' : _label,
        onChanged: (val) => _label = val,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          icon: const Icon(Icons.label_outline, color: Color(0xFF9D4EDD)),
          hintText: 'Enter alarm label (e.g. Gym)',
          hintStyle: TextStyle(color: hintColor),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayNum = index + 1;
        final isSelected = _repeatDays.contains(dayNum);
        final unselectedBg = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);
        final unselectedBorder = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06);
        final textColor = isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87);

        return GestureDetector(
          onTap: () => _toggleDay(dayNum),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? const Color(0xFF9D4EDD) : unselectedBg,
              border: Border.all(
                color: isSelected ? const Color(0xFFE0AAFF) : unselectedBorder,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF9D4EDD).withOpacity(0.4),
                        blurRadius: 10,
                      )
                    ]
                  : [],
            ),
            alignment: Alignment.center,
            child: Text(
              days[index],
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSnoozeCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.white70 : Colors.black87;
    final dropdownBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final dividerColor = isDark ? Colors.white10 : Colors.black12;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Snooze Configuration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Snooze Interval', style: TextStyle(color: labelColor)),
                DropdownButton<int>(
                  value: _snoozeDuration,
                  dropdownColor: dropdownBg,
                  style: TextStyle(color: titleColor, fontSize: 16),
                  underline: const SizedBox(),
                  onChanged: (val) {
                    if (val != null) setState(() => _snoozeDuration = val);
                  },
                  items: [3, 5, 10, 15, 20].map((int val) {
                    return DropdownMenuItem<int>(
                      value: val,
                      child: Text('$val Minutes'),
                    );
                  }).toList(),
                ),
              ],
            ),
            Divider(color: dividerColor),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Maximum Snoozes', style: TextStyle(color: labelColor)),
                DropdownButton<int>(
                  value: _maxSnoozeCount,
                  dropdownColor: dropdownBg,
                  style: TextStyle(color: titleColor, fontSize: 16),
                  underline: const SizedBox(),
                  onChanged: (val) {
                    if (val != null) setState(() => _maxSnoozeCount = val);
                  },
                  items: [1, 2, 3, 5, 10].map((int val) {
                    return DropdownMenuItem<int>(
                      value: val,
                      child: Text('$val times'),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.white70 : Colors.black87;
    final dropdownBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final dividerColor = isDark ? Colors.white10 : Colors.black12;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wake-up Mission',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
                ),
                DropdownButton<MissionType>(
                  value: _missionType,
                  dropdownColor: dropdownBg,
                  style: TextStyle(color: titleColor, fontSize: 16),
                  underline: const SizedBox(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _missionType = val;
                        // set smart defaults based on type
                        if (val == MissionType.math) {
                          _missionTargetCount = 3;
                        } else if (val == MissionType.shake) {
                          _missionTargetCount = 20;
                        } else if (val == MissionType.captcha) {
                          _missionTargetCount = 1;
                        } else if (val == MissionType.memory) {
                          _missionTargetCount = 3; // 3 pairs default
                        }
                      });
                    }
                  },
                  items: [
                    const DropdownMenuItem(value: MissionType.none, child: Text('None (Swipe to stop)')),
                    const DropdownMenuItem(value: MissionType.math, child: Text('Math Equations')),
                    const DropdownMenuItem(value: MissionType.shake, child: Text('Device Shake')),
                    const DropdownMenuItem(value: MissionType.captcha, child: Text('Captcha Text')),
                    const DropdownMenuItem(value: MissionType.memory, child: Text('Memory Match')),
                  ],
                ),
              ],
            ),
            if (_missionType != MissionType.none) ...[
              Divider(color: dividerColor),
              const SizedBox(height: 8),
              // Difficulty selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Difficulty', style: TextStyle(color: labelColor)),
                  Row(
                    children: List.generate(3, (idx) {
                      final difficultyVal = idx + 1;
                      final names = ['Easy', 'Medium', 'Hard'];
                      final isSel = _missionDifficulty == difficultyVal;
                      final chipBg = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ChoiceChip(
                          label: Text(names[idx]),
                          selected: isSel,
                          onSelected: (_) => setState(() => _missionDifficulty = difficultyVal),
                          selectedColor: const Color(0xFF9D4EDD),
                          backgroundColor: chipBg,
                          labelStyle: TextStyle(color: isSel ? Colors.white : labelColor, fontSize: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Target count slider
              _buildTargetSlider(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTargetSlider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : Colors.black87;
    final valueColor = isDark ? const Color(0xFF00F5D4) : const Color(0xFF7B2CBF);

    int maxVal = 10;
    double minVal = 1.0;
    int divisions = 9;
    String labelText = 'Equations';
    if (_missionType == MissionType.shake) {
      maxVal = 100;
      minVal = 10.0;
      divisions = 9;
      labelText = 'Shakes';
    } else if (_missionType == MissionType.captcha) {
      maxVal = 5;
      minVal = 1.0;
      divisions = 4;
      labelText = 'Captchas';
    } else if (_missionType == MissionType.memory) {
      maxVal = 6;
      minVal = 2.0;
      divisions = 4;
      labelText = 'Pairs';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Target Count', style: TextStyle(color: labelColor)),
            Text('$_missionTargetCount $labelText', style: TextStyle(color: valueColor, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: _missionTargetCount.toDouble().clamp(minVal, maxVal.toDouble()),
          min: minVal,
          max: maxVal.toDouble(),
          divisions: divisions,
          activeColor: const Color(0xFF9D4EDD),
          inactiveColor: isDark ? Colors.white10 : Colors.black12,
          onChanged: (val) => setState(() => _missionTargetCount = val.toInt()),
        ),
      ],
    );
  }

  Widget _buildSoundPreferencesCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.white70 : Colors.black87;
    final valueColor = isDark ? const Color(0xFF00F5D4) : const Color(0xFF7B2CBF);
    final dropdownBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final dividerColor = isDark ? Colors.white10 : Colors.black12;
    final volumeIconColor = isDark ? Colors.white30 : Colors.black26;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audio & Hardware Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
            ),
            const SizedBox(height: 16),
            // Ringtone display
            GestureDetector(
              onTap: _showRingtoneSelector,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ringtone', style: TextStyle(color: labelColor)),
                    Row(
                      children: [
                        Text(
                          _getRingtoneName(_audioPath),
                          style: TextStyle(color: valueColor, fontSize: 15),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios, color: isDark ? Colors.white24 : Colors.black26, size: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: dividerColor),
            // Volume control
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.volume_down_outlined, color: volumeIconColor, size: 20),
                Expanded(
                  child: Slider(
                    value: _volume,
                    activeColor: const Color(0xFF9D4EDD),
                    inactiveColor: isDark ? Colors.white10 : Colors.black12,
                    onChanged: (val) => setState(() => _volume = val),
                  ),
                ),
                Icon(Icons.volume_up_outlined, color: volumeIconColor, size: 20),
              ],
            ),
            Divider(color: dividerColor),
            // Vibrate toggle
            SwitchListTile(
              title: Text('Vibrate Device', style: TextStyle(color: labelColor, fontSize: 15)),
              value: _vibrate,
              activeColor: const Color(0xFF9D4EDD),
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _vibrate = val),
            ),
            Divider(color: dividerColor),
            // Fade-in duration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Volume Fade-In', style: TextStyle(color: labelColor)),
                DropdownButton<int>(
                  value: _fadeDuration,
                  dropdownColor: dropdownBg,
                  style: TextStyle(color: titleColor, fontSize: 16),
                  underline: const SizedBox(),
                  onChanged: (val) {
                    if (val != null) setState(() => _fadeDuration = val);
                  },
                  items: [0, 5, 10, 15, 30, 45].map((int val) {
                    return DropdownMenuItem<int>(
                      value: val,
                      child: Text(val == 0 ? 'Instant' : '$val Seconds'),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRingtoneName(String path) {
    if (path.contains('ambient_rain')) return 'Rain Breeze';
    if (path.contains('digital')) return 'Digital Beeps';
    if (path.contains('forest')) return 'Forest Chimes';
    return 'Default Beep';
  }

  void _showRingtoneSelector() {
    final ringtones = [
      {'name': 'Default Beep', 'path': 'assets/audio/alarm.wav'},
      {'name': 'Rain Breeze', 'path': 'assets/audio/ambient_rain.wav'},
      {'name': 'Digital Beeps', 'path': 'assets/audio/digital.wav'},
      {'name': 'Forest Chimes', 'path': 'assets/audio/forest.wav'},
    ];

    final previewPlayer = AudioPlayer();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeColor = isDark ? const Color(0xFF00F5D4) : const Color(0xFF7B2CBF);
            final titleColor = isDark ? Colors.white : Colors.black87;

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Alarm Tone',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: ringtones.map((tone) {
                      final isSelected = _audioPath == tone['path'];
                      final toneTextColor = isSelected ? activeColor : (isDark ? Colors.white : Colors.black87);
                      final iconColor = isSelected ? activeColor : (isDark ? Colors.white60 : Colors.black54);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          tone['name']!,
                          style: TextStyle(
                            color: toneTextColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        leading: Radio<String>(
                          value: tone['path']!,
                          groupValue: _audioPath,
                          activeColor: activeColor,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _audioPath = val;
                              });
                              setModalState(() {});
                            }
                          },
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.play_arrow_outlined,
                            color: iconColor,
                          ),
                          onPressed: () async {
                            try {
                              await previewPlayer.stop();
                              await previewPlayer.setAsset(tone['path']!);
                              await previewPlayer.play();
                            } catch (e) {
                              // error playing preview
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      previewPlayer.dispose();
    });
  }
}
