import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/settings.dart';
import '../features/prayers/prayers_screen.dart';
import '../features/settings/settings_screen.dart';
import 'theme.dart';
import '../features/qibla/qibla_screen.dart';

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
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}
class _AppShellState extends State<AppShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MIHRAB', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w600))),
    body: SafeArea(child: switch (index) {0 => const PrayersScreen(), 1 => const QiblaScreen(), _ => const SettingsScreen()}),
    bottomNavigationBar: NavigationBar(selectedIndex: index,
      onDestinationSelected: (value) => setState(() => index = value),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.access_time), label: 'Намаз'),
        NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Кибла'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Настройки'),
      ]),
  );
}
