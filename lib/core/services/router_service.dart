import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/alarm/presentation/screens/alarm_list_screen.dart';
import '../../features/alarm/presentation/screens/alarm_form_screen.dart';
import '../../features/alarm/presentation/screens/alarm_ring_screen.dart';
import '../../features/sleep/presentation/screens/sleep_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/timer/presentation/screens/timer_screen.dart';
import '../../features/stopwatch/presentation/screens/stopwatch_screen.dart';
import '../../features/world_clock/presentation/screens/world_clock_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const AlarmListScreen(),
      ),
      GoRoute(
        path: '/add-alarm',
        name: 'add-alarm',
        builder: (context, state) => const AlarmFormScreen(),
      ),
      GoRoute(
        path: '/edit-alarm/:alarmId',
        name: 'edit-alarm',
        builder: (context, state) {
          final idString = state.pathParameters['alarmId'];
          final alarmId = int.tryParse(idString ?? '');
          return AlarmFormScreen(alarmId: alarmId);
        },
      ),
      GoRoute(
        path: '/ring/:alarmId',
        name: 'ring',
        builder: (context, state) {
          final idString = state.pathParameters['alarmId'];
          final alarmId = int.tryParse(idString ?? '') ?? 0;
          return AlarmRingScreen(alarmId: alarmId);
        },
      ),
      GoRoute(
        path: '/sleep',
        name: 'sleep',
        builder: (context, state) => const SleepScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/timer',
        name: 'timer',
        builder: (context, state) => const TimerScreen(),
      ),
      GoRoute(
        path: '/stopwatch',
        name: 'stopwatch',
        builder: (context, state) => const StopwatchScreen(),
      ),
      GoRoute(
        path: '/world-clock',
        name: 'world-clock',
        builder: (context, state) => const WorldClockScreen(),
      ),
    ],
  );
});

