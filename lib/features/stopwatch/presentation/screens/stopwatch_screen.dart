import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';
import '../controllers/stopwatch_controller.dart';

class StopwatchScreen extends ConsumerWidget {
  const StopwatchScreen({super.key});

  String _formatTime(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final centiseconds = ((duration.inMilliseconds % 1000) ~/ 10)
        .toString()
        .padLeft(2, '0');

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds.$centiseconds';
    }
    return '$minutes:$seconds.$centiseconds';
  }

  String _formatDuration(Duration duration) {
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final centiseconds = ((duration.inMilliseconds % 1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds.$centiseconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stopwatchControllerProvider);
    final controller = ref.read(stopwatchControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate splits
    final List<Duration> splits = [];
    for (int i = 0; i < state.laps.length; i++) {
      if (i == 0) {
        splits.add(state.laps[0]);
      } else {
        splits.add(state.laps[i] - state.laps[i - 1]);
      }
    }

    int fastestIdx = -1;
    int slowestIdx = -1;
    if (splits.length >= 2) {
      Duration minDuration = splits[0];
      Duration maxDuration = splits[0];
      fastestIdx = 0;
      slowestIdx = 0;

      for (int i = 1; i < splits.length; i++) {
        if (splits[i] < minDuration) {
          minDuration = splits[i];
          fastestIdx = i;
        }
        if (splits[i] > maxDuration) {
          maxDuration = splits[i];
          slowestIdx = i;
        }
      }
    }

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
                      'Stopwatch',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      onPressed: () => context.go('/settings'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Time Display Panel
              Expanded(
                flex: 4,
                child: Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white.withOpacity(0.01) : Colors.black.withOpacity(0.01),
                      border: Border.all(
                        color: state.isRunning
                            ? const Color(0xFFFF8500).withOpacity(0.2)
                            : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                        width: 1.5,
                      ),
                      boxShadow: state.isRunning
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFF8500).withOpacity(isDark ? 0.04 : 0.08),
                                blurRadius: 40,
                                spreadRadius: 5,
                              )
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: state.isRunning
                              ? const Color(0xFFFF8500)
                              : (isDark ? Colors.white30 : Colors.black26),
                          size: 32,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _formatTime(state.elapsedTime),
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w200,
                            color: isDark ? Colors.white : Colors.black87,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.isRunning ? 'RUNNING' : 'PAUSED',
                          style: TextStyle(
                            fontSize: 11,
                            color: state.isRunning
                                ? const Color(0xFFFF8500).withOpacity(0.8)
                                : (isDark ? Colors.white24 : Colors.black26),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Lap Records list
              Expanded(
                flex: 5,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassDecoration(opacity: 0.03, isDark: isDark),
                  child: state.laps.isEmpty
                      ? Center(
                          child: Text(
                            'No laps recorded yet',
                            style: TextStyle(
                              color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.38),
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: state.laps.length,
                          itemBuilder: (context, idx) {
                            // Display in reverse chronological order
                            final displayIdx = state.laps.length - 1 - idx;
                            final lapTime = state.laps[displayIdx];
                            final split = splits[displayIdx];

                            Color? itemColor;
                            String tag = '';
                            if (displayIdx == fastestIdx) {
                              itemColor = isDark ? const Color(0xFF00F5D4) : const Color(0xFF0088CC);
                              tag = 'Fastest';
                            } else if (displayIdx == slowestIdx) {
                              itemColor = isDark ? const Color(0xFFFF0055) : const Color(0xFFD6004F);
                              tag = 'Slowest';
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Lap ${displayIdx + 1}',
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (tag.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: itemColor!.withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            tag,
                                            style: TextStyle(
                                              color: itemColor,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    _formatDuration(split),
                                    style: TextStyle(
                                      color: itemColor ?? (isDark ? Colors.white : Colors.black87),
                                      fontWeight: itemColor != null
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatTime(lapTime),
                                    style: TextStyle(
                                      color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4),
                                      fontSize: 13,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Control buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    // Lap / Reset button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.elapsedTime == Duration.zero
                            ? null
                            : () {
                                if (state.isRunning) {
                                  controller.lap();
                                } else {
                                  controller.reset();
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                          side: BorderSide(
                            color: state.elapsedTime == Duration.zero
                                ? (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04))
                                : (isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          state.isRunning ? 'Lap' : 'Reset',
                          style: TextStyle(
                            fontSize: 16,
                            color: state.elapsedTime == Duration.zero
                                ? (isDark ? Colors.white30 : Colors.black26)
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Start / Pause button
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: state.isRunning
                                ? [
                                    const Color(0xFFFF5E00),
                                    const Color(0xFFFF0055)
                                  ]
                                : (isDark
                                    ? [
                                        const Color(0xFF00BBF9),
                                        const Color(0xFF00F5D4)
                                      ]
                                    : [
                                        const Color(0xFF0284C7),
                                        const Color(0xFF0D9488)
                                      ]),
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
}
