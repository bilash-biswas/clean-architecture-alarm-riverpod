import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleColor = isDark ? Colors.white : Colors.black87;
    final bodyColor = isDark ? Colors.white70 : Colors.black87;
    final captionColor = isDark ? Colors.white30 : Colors.black54;
    final dividerColor = isDark ? Colors.white10 : Colors.black12;
    final dropdownBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final backIconColor = isDark ? Colors.white70 : Colors.black54;

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
                      'Settings',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: titleColor),
                    ),
                    const SizedBox(width: 48), // Spacer
                  ],
                ),
              ),

              // Settings Items List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    // Theme Preferences Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Appearance',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
                              ),
                            ),
                            SwitchListTile(
                              title: Text('AMOLED Dark Mode', style: TextStyle(color: bodyColor)),
                              subtitle: Text('Enables pure black background', style: TextStyle(color: captionColor, fontSize: 12)),
                              value: settings.isDarkMode,
                              activeColor: isDark ? const Color(0xFF9D4EDD) : const Color(0xFF7B2CBF),
                              onChanged: (_) => controller.toggleDarkMode(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Default Alarm Preferences Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alarm Defaults',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
                            ),
                            const SizedBox(height: 16),

                            // Default Snooze
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Default Snooze Duration', style: TextStyle(color: bodyColor)),
                                DropdownButton<int>(
                                  value: settings.defaultSnoozeDuration,
                                  dropdownColor: dropdownBg,
                                  style: TextStyle(color: titleColor, fontSize: 15),
                                  underline: const SizedBox(),
                                  onChanged: (val) {
                                    if (val != null) controller.setDefaultSnoozeDuration(val);
                                  },
                                  items: [3, 5, 10, 15].map((int val) {
                                    return DropdownMenuItem<int>(
                                      value: val,
                                      child: Text('$val Min'),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            Divider(color: dividerColor),

                            // Default Fade-in
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Default Volume Fade-In', style: TextStyle(color: bodyColor)),
                                DropdownButton<int>(
                                  value: settings.fadeInDuration,
                                  dropdownColor: dropdownBg,
                                  style: TextStyle(color: titleColor, fontSize: 15),
                                  underline: const SizedBox(),
                                  onChanged: (val) {
                                    if (val != null) controller.setFadeInDuration(val);
                                  },
                                  items: [0, 5, 10, 15, 30].map((int val) {
                                    return DropdownMenuItem<int>(
                                      value: val,
                                      child: Text(val == 0 ? 'Instant' : '$val Sec'),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            Divider(color: dividerColor),

                            // Default Volume Slider
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Default Alarm Volume', style: TextStyle(color: bodyColor)),
                                Row(
                                  children: [
                                    Icon(Icons.volume_down_outlined, color: captionColor, size: 18),
                                    Expanded(
                                      child: Slider(
                                        value: settings.defaultAlarmVolume,
                                        activeColor: isDark ? const Color(0xFF9D4EDD) : const Color(0xFF7B2CBF),
                                        inactiveColor: isDark ? Colors.white10 : Colors.black12,
                                        onChanged: controller.setDefaultAlarmVolume,
                                      ),
                                    ),
                                    Icon(Icons.volume_up_outlined, color: captionColor, size: 18),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // App Metadata Info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About TimeOrbit',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('App Version', style: TextStyle(color: bodyColor)),
                                Text('1.0.0', style: TextStyle(color: captionColor)),
                              ],
                            ),
                            Divider(color: dividerColor),
                            Text(
                              'Developed using clean architectures with Riverpod and Hive database.',
                              style: TextStyle(color: captionColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
