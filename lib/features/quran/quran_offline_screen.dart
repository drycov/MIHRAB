import 'package:flutter/material.dart';
import '../../l10n/mihrab_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/quran.dart';
import '../../domain/quran_search.dart';
import '../../infrastructure/quran_disk.dart';
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';
import 'quran_screen.dart';

class QuranOfflineScreen extends ConsumerStatefulWidget {
  const QuranOfflineScreen({super.key});
  @override
  ConsumerState<QuranOfflineScreen> createState() =>
      _QuranOfflineScreenState();
}

class _QuranOfflineScreenState extends ConsumerState<QuranOfflineScreen> {
  QuranTranslation translation = QuranTranslation.russian;
  bool busy = false, cancel = false;
  int downloaded = 0, bytes = 0;
  String? status;
  List<QuranSearchHit> hits = [];
  String query = '';

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final repo = ref.read(quranRepositoryProvider);
    final catalog = repo.cachedCatalog() ?? [];
    final count =
        catalog.where((s) => repo.cachedVerses(s, translation) != null).length;
    final size = await QuranDisk.size();
    if (mounted) {
      setState(() {
        downloaded = count;
        bytes = size;
      });
    }
  }

  Future<void> run(Future<void> Function() fn) async {
    if (busy) return;
    setState(() {
      busy = true;
      cancel = false;
      status = null;
    });
    try {
      await fn();
    } catch (_) {
      if (mounted) {
        setState(
          () => status =
              'Операция не завершена. Проверьте сеть и свободное место.',
        );
      }
    } finally {
      if (mounted) {
        try {
          await refresh();
        } catch (_) {}
        if (mounted) setState(() => busy = false);
      }
    }
  }

  Future<void> download() async {
    final repo = ref.read(quranRepositoryProvider);
    final selected = translation;
    final catalog = await repo.catalog();
    for (final surah in catalog) {
      if (cancel || !mounted) return;
      await repo.verses(surah, selected);
      if (repo.cachedVerses(surah, selected) == null) {
        throw StateError('Cache incomplete');
      }
      if (mounted) setState(() => downloaded = catalog.take(surah.number).length);
    }
    if (mounted) setState(() => status = 'Все 114 сур сохранены.');
  }

  void search() {
    final repo = ref.read(quranRepositoryProvider);
    final all = <QuranSearchHit>[];
    for (final surah in repo.cachedCatalog() ?? <Surah>[]) {
      for (final ayah in repo.cachedVerses(surah, translation) ?? <Ayah>[]) {
        all.add(QuranSearchHit(surah, ayah));
      }
    }
    setState(() => hits = searchQuran(all, query));
  }

  Future<bool> confirm(String title) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Удалить'),
            ),
          ],
        ),
      ) ??
      false;

  @override
  void dispose() {
    cancel = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? MihrabTokens.gold : MihrabTokens.emerald;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Офлайн-библиотека'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            const IslamicSectionTitle('Перевод'),
            IslamicCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: DropdownButton<QuranTranslation>(
                isExpanded: true,
                value: translation,
                underline: const SizedBox.shrink(),
                items: [
                  for (final t in QuranTranslation.values)
                    DropdownMenuItem(value: t, child: Text(t.label)),
                ],
                onChanged: busy
                    ? null
                    : (t) {
                        if (t != null) {
                          setState(() {
                            translation = t;
                            hits = [];
                            downloaded = 0;
                          });
                          refresh();
                        }
                      },
              ),
            ),
            IslamicCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Сохранено сур: $downloaded / 114',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: downloaded / 114,
                      minHeight: 5,
                      backgroundColor: dark
                          ? MihrabTokens.emeraldSoft
                          : MihrabTokens.creamMuted,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: busy ? null : () => run(download),
              icon: const Icon(Icons.download),
              label: const Text('Загрузить весь текст'),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor:
                    dark ? MihrabTokens.background : MihrabTokens.cream,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MihrabTokens.radius),
                ),
              ),
            ),
            if (busy)
              TextButton(
                onPressed: () => setState(() => cancel = true),
                child: Text(
                  cancel
                      ? 'Остановка после текущей суры'
                      : 'Остановить загрузку',
                ),
              ),
            if (status != null) Text(status!),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (await confirm(
                            'Удалить выбранный перевод и арабский кеш этой редакции?',
                          ) &&
                          mounted) {
                        await run(
                          () => ref
                              .read(quranRepositoryProvider)
                              .removeTranslation(translation),
                        );
                        if (mounted) setState(() => hits = []);
                      }
                    },
              child: const Text('Удалить текст выбранной редакции'),
            ),
            if (QuranDisk.supported) ...[
              const IslamicSectionTitle('Аудио'),
              IslamicCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Аудио: ${(bytes / 1048576).toStringAsFixed(1)} / 256 МиБ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (bytes / QuranDisk.limit)
                            .clamp(0.0, 1.0)
                            .toDouble(),
                        minHeight: 5,
                        backgroundColor: dark
                            ? MihrabTokens.emeraldSoft
                            : MihrabTokens.creamMuted,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Аяты скачиваются отдельно в аудиоплеере.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: dark
                                ? MihrabTokens.goldSoft
                                : MihrabTokens.muted,
                          ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        if (await confirm(
                              'Удалить все скачанные аудиозаписи?',
                            ) &&
                            mounted) {
                          await run(QuranDisk.clear);
                        }
                      },
                child: const Text('Очистить аудио'),
              ),
            ],
            const IslamicSectionTitle('Поиск офлайн'),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Поиск по сохранённым аятам',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => query = v,
              onSubmitted: (_) {
                if (!busy) search();
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: busy ? null : search,
              child: const Text('Найти офлайн'),
            ),
            const SizedBox(height: 8),
            Text(
              'Поиск только по скачанным сурам выбранной редакции, до 200 результатов.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
                  ),
            ),
            for (final hit in hits)
              IslamicCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  title: Text(
                    '${hit.surah.transliteration} · ${hit.ayah.number}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    hit.ayah.translation,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SurahScreen(
                        surah: hit.surah,
                        initialVerse: hit.ayah.number,
                        initialTranslation: translation,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
