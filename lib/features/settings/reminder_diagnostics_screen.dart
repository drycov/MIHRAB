import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/reminder_coordinator.dart';
import '../../application/reminder_preferences.dart';
import '../../application/settings.dart';
import '../../domain/reminders.dart';
import '../../domain/prayer_schedule.dart';

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
  bool? notificationAllowed;
  bool exactAllowed = false;
  bool android = false;
  bool supported = false;
  int selectedCount = 0;
  int pendingCount = 0;
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
  Future<void> load({bool replan = false, Future<String> Function()? action}) async {
    if (!mounted) return;
    setState(() { busy = true; error = null; });
    try {
      final service = ref.read(notificationsProvider);
      final prefs = ref.read(preferencesProvider);
      final coordinator = ref.read(reminderCoordinatorProvider);
      final actionResult = action != null ? await action() : (replan ? await coordinator.refresh() : null);
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
      bool? allowed;
      var exact = false;
      var pendingTotal = 0;
      if (service.supported) {
        await service.initialize();
        final pending = await service.plugin.pendingNotificationRequests();
        pendingTotal = pending.where((p) => ReminderPlanner.ownsId(p.id)).length;
        data['Ожидающие уведомления MIHRAB'] = pendingTotal.toString();
        if (service.isAndroid) {
          allowed = await service.androidNotificationsEnabled();
          exact = await service.canScheduleExact();
          data['Разрешение уведомлений'] = switch (allowed) {
            true => 'Разрешено', false => 'Запрещено', null => 'Не удалось определить',
          };
          data['Доступ к Exact Alarm'] = exact ? 'Разрешён' : 'Недоступен';
        } else {
          data['Разрешение уведомлений'] = 'Проверьте в настройках iOS';
        }
      }
      if (mounted) setState(() {
        rows = data; android = service.isAndroid; supported = service.supported;
        notificationAllowed = allowed; exactAllowed = exact;
        selectedCount = config?.enabled.length ?? 0; pendingCount = pendingTotal;
        if (actionResult != null) result = actionResult;
      });
    } catch (_) {
      if (mounted) setState(() => error = 'Не удалось выполнить операцию. Проверьте разрешения и повторите попытку.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> enableAll() => load(action: () async {
    final prefs = ref.read(preferencesProvider);
    final coordinator = ref.read(reminderCoordinatorProvider);
    await prefs.reload();
    final config = ReminderPreferences.read(prefs);
    return coordinator.apply(PrayerKind.values.where((p) => p.obligatory).toSet(),
      config?.lead ?? 0, config?.exact ?? false);
  });

  Future<void> grantNotifications() => load(action: () async {
    final service = ref.read(notificationsProvider);
    final coordinator = ref.read(reminderCoordinatorProvider);
    if (!await service.requestPermission()) {
      return 'Разрешите уведомления в системных настройках MIHRAB.';
    }
    return coordinator.refresh();
  });

  Future<void> grantExact() => load(action: () async {
    final service = ref.read(notificationsProvider);
    final coordinator = ref.read(reminderCoordinatorProvider);
    if (!await service.requestExactPermission()) return 'Точный режим недоступен. Используется приблизительный.';
    return coordinator.refresh();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Диагностика уведомлений')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      if (busy) const LinearProgressIndicator(),
      if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      if (supported) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Готовность уведомлений', style: Theme.of(context).textTheme.titleLarge),
          Text(notificationAllowed == false ? 'Уведомления запрещены системой' : selectedCount == 0 ? 'Выберите намазы для напоминаний' : pendingCount == 0 ? 'Нет ожидающих уведомлений' : 'Запланировано: $pendingCount'),
          if (notificationAllowed == false) FilledButton(onPressed: busy ? null : grantNotifications, child: const Text('Разрешить уведомления')),
          if (selectedCount == 0) OutlinedButton(onPressed: busy ? null : enableAll, child: const Text('Включить все пять намазов')),
          if (android && !exactAllowed) OutlinedButton(onPressed: busy ? null : grantExact, child: const Text('Разрешить точные уведомления')),
          if (android && notificationAllowed == false) const Text('Если запрос не появляется: Настройки Android → Приложения → MIHRAB → Уведомления.'),
        ]))),
      for (final row in rows.entries) ListTile(title: Text(row.key), subtitle: Text(row.value)),
      if (result != null) Text(result!),
      OutlinedButton.icon(onPressed: busy ? null : () => load(), icon: const Icon(Icons.refresh), label: const Text('Проверить состояние')),
      FilledButton.icon(onPressed: busy ? null : () => load(replan: true), icon: const Icon(Icons.schedule), label: const Text('Перепланировать')),
      const SizedBox(height: 12),
    ])),
  );
}
