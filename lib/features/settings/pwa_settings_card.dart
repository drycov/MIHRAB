import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';
import '../../l10n/mihrab_strings.dart';
import '../../infrastructure/pwa_bridge.dart';

class PwaSettingsCard extends StatefulWidget {
  const PwaSettingsCard({super.key});

  @override
  State<PwaSettingsCard> createState() => _PwaSettingsCardState();
}

class _PwaSettingsCardState extends State<PwaSettingsCard> {
  Map<String, dynamic> status = const {};
  Timer? timer;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    status = pwaStatus();
    timer = Timer.periodic(const Duration(seconds: 2), (_) => refresh());
  }

  void refresh() {
    if (mounted) setState(() => status = pwaStatus());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> install() async {
    if (status['installable'] == true) {
      await installPwa();
      refresh();
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Установить MIHRAB')),
        content: Text(context.tr('Откройте меню браузера и выберите установку приложения. В Safari: Поделиться → На экран «Домой».')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> check() async {
    setState(() => busy = true);
    final success = await checkPwaUpdate();
    if (!mounted) return;
    setState(() {
      busy = false;
      status = pwaStatus();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.tr(success ? 'Проверка обновлений завершена' : 'Проверка обновлений недоступна')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? MihrabTokens.gold : MihrabTokens.emerald;
    return IslamicCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        ListTile(
          leading: Icon(status['online'] == false ? Icons.cloud_off : Icons.cloud_queue, color: accent),
          title: Text(context.tr(status['online'] == false ? 'Нет подключения к сети' : status['online'] == true ? 'Подключение к сети' : 'Статус сети неизвестен')),
          subtitle: Text(context.tr(status['offlineReady'] == true ? 'Автономный кеш активен' : 'Автономный кеш не подтверждён')),
        ),
        const Divider(height: 1),
        ListTile(
          leading: Icon(Icons.install_mobile, color: accent),
          title: Text(context.tr(status['installed'] == true ? 'MIHRAB установлен' : 'Установить MIHRAB')),
          onTap: status['installed'] == true ? null : install,
        ),
        const Divider(height: 1),
        ListTile(
          leading: Icon(Icons.system_update, color: accent),
          title: Text(context.tr('Проверить обновления')),
          subtitle: status['updateAvailable'] == true
              ? Text(context.tr('Доступно обновление. Закройте все окна MIHRAB и откройте приложение снова.'))
              : null,
          onTap: busy ? null : check,
        ),
      ]),
    );
  }
}
