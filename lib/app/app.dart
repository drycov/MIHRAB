import 'package:flutter/material.dart';
import '../application/reminder_coordinator.dart';
import '../application/schedule.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/settings.dart';
import '../features/prayers/prayers_screen.dart';
import '../features/settings/settings_screen.dart';
import 'theme.dart';
import '../features/qibla/qibla_screen.dart';
import '../features/calendar/calendar_screen.dart';

class MihrabApp extends ConsumerWidget {
  const MihrabApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'MIHRAB', debugShowCheckedModeBanner: false,
    theme: MihrabTheme.build(Brightness.light),
    darkTheme: MihrabTheme.build(Brightness.dark),
    themeMode: ref.watch(settingsProvider.select((s) => s.light)) ? ThemeMode.light : ThemeMode.dark,
    home: const AppShell(),
  );
}
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}
class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  String? reminderError;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) refreshReminders(); });
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshReminders();
  }
  Future<void> refreshReminders() async {
    try {
      await ref.read(reminderCoordinatorProvider).refresh();
      if (mounted && reminderError != null) setState(() => reminderError = null);
    } catch (_) {
      if (mounted) setState(() => reminderError = 'Не удалось обновить уведомления. Проверьте настройки.');
    }
  }
  int index = 0;
  @override
  Widget build(BuildContext context) {
    ref.listen(localDayProvider, (previous, next) { if (previous != next) refreshReminders(); });
    return Scaffold(
    appBar: AppBar(title: const Text('MIHRAB', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w600))),
    body: SafeArea(child: Column(children: [
      if (reminderError != null) ListTile(title: Text(reminderError!), trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: refreshReminders)),
      Expanded(child: switch (index) {0 => const PrayersScreen(), 1 => const QiblaScreen(), 2 => const CalendarScreen(), _ => const SettingsScreen()}),
    ])),
    bottomNavigationBar: NavigationBar(selectedIndex: index,
      onDestinationSelected: (value) => setState(() => index = value),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.access_time), label: 'Намаз'),
        NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Кибла'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Календарь'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Настройки'),
      ]),
  );
  }
}
