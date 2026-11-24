import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/settings.dart';
import '../../infrastructure/adhan_audio.dart';
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';

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
    setState(() {
      busy = true;
      status = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(
          () => status =
              'Не удалось выполнить операцию с аудио. Проверьте формат и файл.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? MihrabTokens.gold : MihrabTokens.emerald;

    return Scaffold(
      appBar: AppBar(title: const Text('ЗАПИСИ АЗАНА')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            if (!audio.supported)
              const IslamicCard(
                child: Text('Импорт доступен только на Android и iOS'),
              ),
            for (final profile in AdhanProfile.values)
              IslamicCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      audio.name(profile) ?? 'Запись не выбрана',
                      style: TextStyle(
                        color: dark
                            ? MihrabTokens.goldSoft
                            : MihrabTokens.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: busy || !audio.supported
                              ? null
                              : () => run(() async {
                                    await audio.import(profile);
                                  }),
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Выбрать'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: busy || audio.name(profile) == null
                              ? null
                              : () => run(() => audio.play(profile)),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Слушать'),
                        ),
                        if (!kIsWeb &&
                            defaultTargetPlatform == TargetPlatform.android)
                          OutlinedButton.icon(
                            onPressed: busy || audio.name(profile) == null
                                ? null
                                : () => run(() => audio.playNative(profile)),
                            icon: const Icon(Icons.play_circle),
                            label: const Text('Фоновое'),
                          ),
                        OutlinedButton.icon(
                          onPressed: busy || !audio.supported
                              ? null
                              : () => run(audio.stop),
                          icon: const Icon(Icons.stop),
                          label: const Text('Стоп'),
                        ),
                        TextButton(
                          onPressed: busy || audio.name(profile) == null
                              ? null
                              : () => run(() => audio.remove(profile)),
                          child: Text(
                            'Удалить',
                            style: TextStyle(color: accent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (busy) const LinearProgressIndicator(minHeight: 2),
            if (status != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  status!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
