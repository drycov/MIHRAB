import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/settings.dart';
import '../../infrastructure/adhan_audio.dart';

class AdhanScreen extends ConsumerStatefulWidget {
  const AdhanScreen({super.key});
  @override
  ConsumerState<AdhanScreen> createState() => _AdhanScreenState();
}
class _AdhanScreenState extends ConsumerState<AdhanScreen> {
  late final AdhanAudio audio;
  bool busy = false;
  String? status;

  @override
  void initState() {
    super.initState();
    audio = AdhanAudio(ref.read(preferencesProvider));
  }
  @override
  void dispose() {
    unawaited(audio.dispose());
    super.dispose();
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() {busy = true;status = null;});
    try { await action(); }
    catch (_) { if (mounted) setState(() => status = 'Не удалось выполнить операцию с аудио. Проверьте формат и файл.'); }
    finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Записи азана')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Выберите собственные записи MP3, WAV или M4A. До 15 МБ на запись. Файлы сохраняются в приватном каталоге приложения.'),
      if (!audio.supported) const ListTile(title: Text('Импорт доступен только на Android и iOS')),
      for (final profile in AdhanProfile.values) Card(child: Padding(
        padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start,children:[
          Text(profile.label,style: Theme.of(context).textTheme.titleLarge),
          Text(audio.name(profile) ?? 'Запись не выбрана'),
          const SizedBox(height:8),
          Wrap(spacing:8,runSpacing:8,children:[
            OutlinedButton.icon(onPressed:busy || !audio.supported ? null : () => run(() async {await audio.import(profile);}),icon:const Icon(Icons.folder_open),label:const Text('Выбрать')),
            FilledButton.tonalIcon(onPressed:busy || audio.name(profile)==null ? null : () => run(()=>audio.play(profile)),icon:const Icon(Icons.play_arrow),label:const Text('Слушать')),
            OutlinedButton.icon(onPressed:busy || !audio.supported ? null : () => run(audio.stop),icon:const Icon(Icons.stop),label:const Text('Стоп')),
            TextButton(onPressed:busy || audio.name(profile)==null ? null : () => run(()=>audio.remove(profile)),child:const Text('Удалить')),
          ]),
        ]),
      )),
      if(busy) const LinearProgressIndicator(),
      if(status!=null) Text(status!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
      const Text('На Android можно выбрать профиль «Локальный азан» в настройках уведомлений. После импорта или удаления записи перепланируйте уведомления. Доставка звука зависит от Android и настроек канала; полное воспроизведение не гарантируется.'),
    ])),
  );
}
