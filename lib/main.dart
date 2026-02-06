import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'models/prayer_time.dart';
import 'screens/home_screen.dart';
import 'services/silent_service.dart';

const String workTaskName = 'prayerSilentCheck';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Background task: load saved times and toggle silent mode if needed.
    final prayerTimes = await PrayerTime.loadAll();
    await SilentService.checkAndToggle(prayerTimes);
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the background worker.
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Register a periodic task. Android enforces a 15-minute minimum interval
  // for periodic work. The app will still check every minute while open.
  Workmanager().registerPeriodicTask(
    workTaskName,
    workTaskName,
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(minutes: 1),
  );

  runApp(const MasjidSilentModeApp());
}

class MasjidSilentModeApp extends StatelessWidget {
  const MasjidSilentModeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masjid Silent Mode',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
