import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/services/providers.dart';
import 'core/services/database_service.dart';
import 'core/services/alarm_service.dart';
import 'core/services/router_service.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Hive Database
  final dbService = DatabaseService();
  await dbService.init();

  // Initialize Native Alarm Service
  final alarmService = AlarmService();
  await alarmService.init();

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
        alarmServiceProvider.overrideWithValue(alarmService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsControllerProvider);

    return MaterialApp.router(
      title: 'TimeOrbit',
      debugShowCheckedModeBanner: false,
      // Apply dark AMOLED theme if enabled in user preferences
      theme: settings.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        return AlarmAppWrapper(child: child!);
      },
    );
  }
}

/// A global wrapper that listens to active native alarm rings
/// and handles routing to the full-screen mission solver page.
class AlarmAppWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AlarmAppWrapper({super.key, required this.child});

  @override
  ConsumerState<AlarmAppWrapper> createState() => _AlarmAppWrapperState();
}

class _AlarmAppWrapperState extends ConsumerState<AlarmAppWrapper> {
  StreamSubscription? _ringSubscription;

  @override
  void initState() {
    super.initState();
    final alarmService = ref.read(alarmServiceProvider);

    // Listen to ringing event stream from native alarm plugin
    _ringSubscription = alarmService.ringStream?.listen((alarmSettings) {
      if (mounted) {
        // Reroute to Active Alarm Ring screen
        ref
            .read(routerProvider)
            .goNamed(
              'ring',
              pathParameters: {'alarmId': alarmSettings.id.toString()},
            );
      }
    });

    _checkActiveRingingAlarm();
  }

  Future<void> _checkActiveRingingAlarm() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final alarmService = ref.read(alarmServiceProvider);
      final ringingId = await alarmService.getActiveRingingAlarmId();
      if (ringingId != null && mounted) {
        ref
            .read(routerProvider)
            .goNamed('ring', pathParameters: {'alarmId': ringingId.toString()});
      }
    });
  }

  @override
  void dispose() {
    _ringSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
