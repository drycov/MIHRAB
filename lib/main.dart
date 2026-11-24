import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'domain/prayer_schedule.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  final preferences = await SharedPreferences.getInstance();
  runApp(MihrabApp(preferences: preferences));
}

const gold = Color(0xFFD9BD85);
const emerald = Color(0xFF103D32);

class MihrabApp extends StatefulWidget {
  const MihrabApp({super.key, required this.preferences});
  final SharedPreferences preferences;
  @override
  State<MihrabApp> createState() => _MihrabAppState();
}

class _MihrabAppState extends State<MihrabApp> {
  late int cityIndex;
  late bool hanafi;
  late ThemeMode mode;
  int tab = 0;
  int dayOffset = 0;
  late Timer timer;
  DateTime now = DateTime.now();
  @override
  void initState() {
    super.initState();
    cityIndex = (widget.preferences.getInt('city') ?? 0).clamp(0, City.all.length - 1).toInt();
    hanafi = widget.preferences.getBool('hanafi') ?? true;
    mode = widget.preferences.getBool('light') == true ? ThemeMode.light : ThemeMode.dark;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }
  @override
  void dispose() { timer.cancel(); super.dispose(); }

  String time(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  String remaining(Duration d) {
    final seconds = d.inSeconds < 0 ? 0 : d.inSeconds;
    return [seconds ~/ 3600, seconds ~/ 60 % 60, seconds % 60]
        .map((n) => n.toString().padLeft(2, '0')).join(':');
  }

  @override
  Widget build(BuildContext context) {
    final city = City.all[cityIndex];
    final local = tz.TZDateTime.from(now, tz.getLocation(city.zone));
    final date = DateTime(local.year, local.month, local.day + dayOffset);
    final next = PrayerSchedule.next(city, now, hanafi: hanafi);
    final slots = PrayerSchedule.forDay(city, date, hanafi: hanafi);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MIHRAB',
      themeMode: mode,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: emerald)),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark), scaffoldBackgroundColor: const Color(0xFF071F1B)),
      home: Scaffold(
        appBar: AppBar(title: const Text('MIHRAB', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w600))),
        body: SafeArea(child: tab == 0 ? ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(children: [const Icon(Icons.location_on_outlined), const SizedBox(width: 8), Expanded(child: Text(city.name)), Text(time(local))]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(color: emerald, borderRadius: BorderRadius.vertical(top: Radius.elliptical(160, 85), bottom: Radius.circular(24))),
              child: Column(children: [
                const Text('Следующий намаз', style: TextStyle(color: gold)),
                const SizedBox(height: 12),
                Text(next.kind.label, style: const TextStyle(color: Colors.white, fontSize: 28)),
                Text(next.kind.arabic, style: const TextStyle(color: gold, fontSize: 22)),
                const SizedBox(height: 12),
                Text(remaining(next.time.difference(now)), style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w600)),
                Text('Начало в ${time(next.time)}', style: const TextStyle(color: gold)),
              ]),
            ),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(onPressed: () => setState(() => dayOffset--), icon: const Icon(Icons.chevron_left)),
              Text('${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}'),
              IconButton(onPressed: () => setState(() => dayOffset++), icon: const Icon(Icons.chevron_right)),
            ]),
            if (dayOffset != 0) TextButton(onPressed: () => setState(() => dayOffset = 0), child: const Text('Сегодня')),
            for (final slot in slots)
              Card(
                color: dayOffset == 0 && slot.time == next.time ? emerald : null,
                child: ListTile(
                  textColor: dayOffset == 0 && slot.time == next.time ? Colors.white : null,
                  iconColor: dayOffset == 0 && slot.time == next.time ? gold : null,
                  leading: Icon(slot.kind == PrayerKind.isha ? Icons.nightlight_outlined : Icons.wb_sunny_outlined),
                  title: Text(slot.kind.label),
                  subtitle: Text(slot.kind.arabic),
                  trailing: Text(time(slot.time), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
            const SizedBox(height: 12),
            const Text('Расчёт MWL. Не официальное расписание ДУМК. Сверяйте время с местной мечетью.', textAlign: TextAlign.center),
          ],
        ) : ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Город'),
          DropdownButton<int>(isExpanded: true, value: cityIndex, items: [
            for (var i = 0; i < City.all.length; i++) DropdownMenuItem(value: i, child: Text(City.all[i].name)),
          ], onChanged: (v) { if (v == null) return; setState(() { cityIndex = v; dayOffset = 0; }); widget.preferences.setInt('city', v); }),
          SwitchListTile(title: const Text('Ханафитский Аср'), value: hanafi, onChanged: (v) { setState(() => hanafi = v); widget.preferences.setBool('hanafi', v); }),
          SwitchListTile(title: const Text('Светлая тема'), value: mode == ThemeMode.light, onChanged: (v) { setState(() => mode = v ? ThemeMode.light : ThemeMode.dark); widget.preferences.setBool('light', v); }),
          const ListTile(title: Text('Метод расчёта'), subtitle: Text('Muslim World League (MWL)')),
        ])),
        bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [
          NavigationDestination(icon: Icon(Icons.access_time), label: 'Намаз'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Настройки'),
        ]),
      ),
    );
  }
}
