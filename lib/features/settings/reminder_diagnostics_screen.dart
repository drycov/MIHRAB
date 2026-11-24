import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/reminder_coordinator.dart';
import '../../application/reminder_preferences.dart';
import '../../application/settings.dart';
import '../../domain/reminders.dart';

class ReminderDiagnosticsScreen extends ConsumerStatefulWidget {
  const ReminderDiagnosticsScreen({super.key});
  @override
  ConsumerState<ReminderDiagnosticsScreen> createState() => _ReminderDiagnosticsScreenState();
}

class _ReminderDiagnosticsScreenState extends ConsumerState<ReminderDiagnosticsScreen>
    with WidgetsBindingObserver {
  bool busy = true;
  String? error;
  String? result;
  Map<String, String> rows = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) load(); });
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !busy) load();
  }
  String stamp(String? raw) {
    final date = DateTime.tryParse(raw ?? '')?.toLocal();
    if (date == null) return 'Нет данных';
    final local = date.toIso8601String();
    return local.substring(0,16).replaceFirst('T',' ');
  }
  Future<void> load({bool replan = false}) async {
    if (!mounted) return;
    setState(() { busy = true; error = null; });
    try {
      final service = ref.read(notificationsProvider);
      final prefs = ref.read(preferencesProvider);
      final coordinator = ref.read(reminderCoordinatorProvider);
      if (replan) result = await coordinator.refresh();
      await prefs.reload();
      final config = ReminderPreferences.read(prefs);
      final data = <String,String>{
        'Платформа': service.supported ? (service.isAndroid ? 'Android' : 'iOS') : 'Не поддерживается',
        'Выбрано намазов': (config?.enabled.length ?? 0).toString(),
        'Предварительное напоминание': '${config?.lead ?? 0} мин.',
        'Предпочтительный режим': config?.exact == true ? 'Точный' : 'Обычный',
        'Последнее обновление': stamp(prefs.getString('reminder_last_success')),
        'Последняя фоновая синхронизация': stamp(prefs.getString('reminder_last_background_success')),
        'Регистрация фоновой задачи': service.isAndroid ? (prefs.getBool('reminder_background_registered') == true ? 'Запрос регистрации успешен' : 'Не подтверждена') : 'Недоступна',
      };
      if (service.supported) {
        await service.initialize();
        final pending = await service.plugin.pendingNotificationRequests();
        data['Ожидающие уведомления MIHRAB'] = pending.where((p) => ReminderPlanner.ownsId(p.id)).length.toString();
        if (service.isAndroid) {
          data['Разрешение уведомлений'] = switch (await service.androidNotificationsEnabled()) {
            true => 'Разрешено', false => 'Запрещено', null => 'Не удалось определить',
          };
          data['Доступ к Exact Alarm'] = await service.canScheduleExact() ? 'Разрешён' : 'Недоступен';
        } else {
          data['Разрешение уведомлений'] = 'Проверьте в настройках iOS';
        }
      }
      if (mounted) setState(() => rows = data);
    } catch (_) {
      if (mounted) setState(() => error = 'Не удалось получить состояние уведомлений. Повторите проверку.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Диагностика уведомлений')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      if (busy) const LinearProgressIndicator(),
      if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      for (final row in rows.entries) ListTile(title: Text(row.key), subtitle: Text(row.value)),
      if (result != null) Text(result!),
      OutlinedButton.icon(onPressed: busy ? null : () => load(), icon: const Icon(Icons.refresh), label: const Text('Проверить состояние')),
      FilledButton.icon(onPressed: busy ? null : () => load(replan: true), icon: const Icon(Icons.schedule), label: const Text('Перепланировать')),
      const SizedBox(height: 12),
      const Text('Число ожидающих уведомлений берётся из плагина и не гарантирует доставку системой. WorkManager может запускаться с задержкой.'),
    ]),
  );
}
