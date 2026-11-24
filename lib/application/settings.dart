import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/prayer_schedule.dart';

final preferencesProvider = Provider<SharedPreferences>((ref) => throw StateError('Preferences not initialized'));
final settingsProvider = NotifierProvider<SettingsController, Settings>(SettingsController.new);

class Settings {
  const Settings({required this.cityIndex, required this.hanafi, required this.light});
  final int cityIndex;
  final bool hanafi, light;
  City get city => City.all[cityIndex];
  Settings copyWith({int? cityIndex, bool? hanafi, bool? light}) => Settings(
    cityIndex: cityIndex ?? this.cityIndex, hanafi: hanafi ?? this.hanafi, light: light ?? this.light,
  );
}

class SettingsController extends Notifier<Settings> {
  @override
  Settings build() {
    final prefs = ref.watch(preferencesProvider);
    return Settings(
      cityIndex: (prefs.getInt('city') ?? 0).clamp(0, City.all.length - 1).toInt(),
      hanafi: prefs.getBool('hanafi') ?? true,
      light: prefs.getBool('light') ?? false,
    );
  }
  Future<void> city(int value) async {
    if (value < 0 || value >= City.all.length) return;
    if (!await ref.read(preferencesProvider).setInt('city', value)) throw StateError('City save failed');
    state = state.copyWith(cityIndex: value);
  }
  Future<void> hanafi(bool value) async {
    if (!await ref.read(preferencesProvider).setBool('hanafi', value)) throw StateError('Madhab save failed');
    state = state.copyWith(hanafi: value);
  }
  Future<void> light(bool value) async {
    state = state.copyWith(light: value);
    await ref.read(preferencesProvider).setBool('light', value);
  }
}
