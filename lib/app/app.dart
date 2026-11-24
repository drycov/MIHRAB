import 'package:flutter/material.dart';
import '../application/reminder_coordinator.dart';
import '../application/schedule.dart';
import '../application/widget_sync.dart';
import '../application/hijri_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/settings.dart';
import '../application/onboarding.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/prayers/prayers_screen.dart';
import '../features/settings/settings_screen.dart';
import 'theme.dart';
import '../features/qibla/qibla_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/ramadan/ramadan_screen.dart';
import '../features/quran/quran_screen.dart';

class MihrabApp extends ConsumerWidget {
  const MihrabApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'MIHRAB',
    debugShowCheckedModeBanner: false,
    theme: MihrabTheme.build(Brightness.light),
    darkTheme: MihrabTheme.build(Brightness.dark),
    themeMode: ref.watch(settingsProvider.select((s) => s.light))
        ? ThemeMode.light
        : ThemeMode.dark,
    home: ref.watch(onboardingProvider)
        ? const AppShell()
        : const OnboardingScreen(),
  );
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  String? reminderError;
  int index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) refreshReminders();
    });
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
    await ref.read(widgetSyncProvider).refresh();
    if (!mounted) return;
    try {
      await ref.read(reminderCoordinatorProvider).refresh();
      if (mounted && reminderError != null) {
        setState(() => reminderError = null);
      }
    } catch (_) {
      if (mounted) {
        setState(() =>
            reminderError = 'Не удалось обновить уведомления. Проверьте настройки.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(localDayProvider, (previous, next) {
      if (previous != next) refreshReminders();
    });
    ref.listen(hijriAdjustmentProvider, (previous, next) {
      if (previous != next) ref.read(widgetSyncProvider).refresh();
    });
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MIHRAB',
          style: TextStyle(
            letterSpacing: MihrabTokens.letterTitle,
            fontWeight: FontWeight.w600,
            color: dark ? MihrabTokens.goldSoft : MihrabTokens.ink,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Рамадан',
            icon: Icon(
              Icons.nightlight_round,
              color: dark ? MihrabTokens.gold : MihrabTokens.emerald,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RamadanScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (reminderError != null)
              Material(
                color: dark
                    ? MihrabTokens.emeraldSoft
                    : MihrabTokens.creamMuted,
                child: ListTile(
                  dense: true,
                  title: Text(
                    reminderError!,
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: refreshReminders,
                  ),
                ),
              ),
            Expanded(
              child: switch (index) {
                0 => const PrayersScreen(),
                1 => const QiblaScreen(),
                2 => const CalendarScreen(),
                3 => const QuranScreen(),
                _ => const SettingsScreen(),
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.access_time),
            selectedIcon: Icon(Icons.access_time_filled),
            label: 'Намаз',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Кибла',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Календарь',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Коран',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
