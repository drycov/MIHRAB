import 'package:flutter/material.dart';
import '../../l10n/mihrab_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/settings.dart';
import '../dua/dua_screen.dart';
import '../../domain/bookmark.dart';
import '../bookmarks/bookmark_button.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../tasbih/tasbih_screen.dart';
import '../../domain/quran.dart';
import 'quran_audio_screen.dart';
import 'quran_offline_screen.dart';
import '../../infrastructure/quran_repository.dart';
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  final repo = QuranRepository(ref.watch(preferencesProvider));
  ref.onDispose(repo.close);
  return repo;
});

final quranCatalogProvider = FutureProvider.autoDispose<List<Surah>>(
  (ref) => ref.watch(quranRepositoryProvider).catalog(),
);

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});
  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  String query = '';

  void open(Surah surah, {int verse = 1}) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SurahScreen(surah: surah, initialVerse: verse),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(quranCatalogProvider);
    final prefs = ref.watch(preferencesProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? MihrabTokens.gold : MihrabTokens.emerald;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Коран')),
        actions: [
          IconButton(
            tooltip: context.tr('Избранное'),
            icon: Icon(Icons.bookmarks_outlined, color: accent),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BookmarksScreen()),
            ),
          ),
          IconButton(
            tooltip: context.tr('Тасбих'),
            icon: Icon(Icons.touch_app, color: accent),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const TasbihScreen()),
            ),
          ),
          IconButton(
            tooltip: context.tr('Дуа и азкары'),
            icon: Icon(Icons.auto_stories, color: accent),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DuaScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Название или номер суры',
                ),
                onChanged: (v) =>
                    setState(() => query = v.trim().toLowerCase()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IslamicCard(
                padding: EdgeInsets.zero,
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(
                    Icons.download_for_offline_outlined,
                    color: accent,
                  ),
                  title: Text(context.tr('Офлайн-библиотека')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const QuranOfflineScreen(),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: catalog.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Не удалось загрузить каталог. Проверьте интернет.',
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(quranCatalogProvider),
                        child: Text(context.tr('Повторить')),
                      ),
                    ],
                  ),
                ),
                data: (surahs) {
                  final last = prefs.getInt('quran_last_surah') ?? 0;
                  final filtered = surahs
                      .where(
                        (s) =>
                            query.isEmpty ||
                            s.number.toString() == query ||
                            s.name.contains(query) ||
                            s.transliteration.toLowerCase().contains(query),
                      )
                      .toList();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      if (last >= 1 && last <= 114 && query.isEmpty)
                        IslamicCard(
                          highlighted: true,
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            leading: const Icon(
                              Icons.history,
                              color: MihrabTokens.gold,
                            ),
                            title: const Text(
                              'Продолжить чтение',
                              style: TextStyle(color: MihrabTokens.paper),
                            ),
                            subtitle: Text(
                              surahs[last - 1].transliteration,
                              style: TextStyle(
                                color: MihrabTokens.goldSoft
                                    .withValues(alpha: 0.9),
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: MihrabTokens.gold,
                            ),
                            onTap: () => open(
                              surahs[last - 1],
                              verse: prefs.getInt('quran_last_verse') ?? 1,
                            ),
                          ),
                        ),
                      for (final s in filtered)
                        IslamicCard(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: dark
                                  ? MihrabTokens.emeraldSoft
                                  : MihrabTokens.cream,
                              foregroundColor: accent,
                              child: Text(
                                '${s.number}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            title: Text(
                              s.transliteration,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${s.name} · ${s.count} аятов',
                              textDirection: TextDirection.rtl,
                            ),
                            trailing: BookmarkButton(
                              bookmark: Bookmark(
                                kind: BookmarkKind.surah,
                                reference: s.number.toString(),
                                title: s.transliteration,
                              ),
                            ),
                            onTap: () => open(s),
                          ),
                        ),
                      if (filtered.isEmpty)
                        const IslamicCard(
                          child: Text('Суры не найдены'),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SurahScreen extends ConsumerStatefulWidget {
  const SurahScreen({
    super.key,
    required this.surah,
    this.initialVerse = 1,
    this.initialTranslation,
  });
  final Surah surah;
  final int initialVerse;
  final QuranTranslation? initialTranslation;
  @override
  ConsumerState<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends ConsumerState<SurahScreen> {
  late QuranTranslation translation;
  late Future<List<Ayah>> future;
  late int verse;
  double fontSize = 28;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(preferencesProvider).getString('quran_translation');
    translation = widget.initialTranslation ??
        QuranTranslation.values.firstWhere(
          (t) => t.id == saved,
          orElse: () => QuranTranslation.russian,
        );
    verse = widget.initialVerse.clamp(1, widget.surah.count).toInt();
    future = ref.read(quranRepositoryProvider).verses(widget.surah, translation);
  }

  Future<void> remember() async {
    final prefs = ref.read(preferencesProvider);
    final a = await prefs.setInt('quran_last_surah', widget.surah.number);
    final b = await prefs.setInt('quran_last_verse', verse);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            a && b ? 'Позиция сохранена' : 'Не удалось сохранить позицию',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? MihrabTokens.gold : MihrabTokens.emerald;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.surah.transliteration),
        actions: [
          IconButton(
            tooltip: context.tr('Слушать аят'),
            icon: Icon(Icons.headphones, color: accent),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => QuranAudioScreen(
                  surah: widget.surah,
                  initialVerse: verse,
                ),
              ),
            ),
          ),
          BookmarkButton(
            bookmark: Bookmark(
              kind: BookmarkKind.ayah,
              reference: '${widget.surah.number}:$verse',
              title: '${widget.surah.transliteration} · $verse',
            ),
          ),
          IconButton(
            tooltip: context.tr('Сохранить позицию'),
            onPressed: remember,
            icon: Icon(Icons.bookmark_add_outlined, color: accent),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: IslamicCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                margin: EdgeInsets.zero,
                child: DropdownButton<QuranTranslation>(
                  isExpanded: true,
                  value: translation,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final t in QuranTranslation.values)
                      DropdownMenuItem(value: t, child: Text(t.label)),
                  ],
                  onChanged: (t) {
                    if (t == null) return;
                    setState(() {
                      translation = t;
                      future = ref
                          .read(quranRepositoryProvider)
                          .verses(widget.surah, t);
                    });
                    ref
                        .read(preferencesProvider)
                        .setString('quran_translation', t.id);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Text(
                    'Размер',
                    style: TextStyle(
                      color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: fontSize,
                      min: 20,
                      max: 44,
                      activeColor: accent,
                      onChanged: (v) => setState(() => fontSize = v),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Ayah>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: TextButton(
                        onPressed: () => setState(
                          () => future = ref
                              .read(quranRepositoryProvider)
                              .verses(
                                widget.surah,
                                translation,
                                refresh: true,
                              ),
                        ),
                        child: const Text('Ошибка загрузки. Повторить'),
                      ),
                    );
                  }
                  final ayah = snapshot.data![verse - 1];
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    children: [
                      Text(
                        widget.surah.name,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: dark
                                  ? MihrabTokens.goldSoft
                                  : MihrabTokens.emerald,
                            ),
                      ),
                      const IslamicDivider(padding: 20),
                      SelectableText(
                        ayah.arabic,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: fontSize,
                          height: 2,
                          color: dark
                              ? MihrabTokens.cream
                              : MihrabTokens.ink,
                        ),
                      ),
                      const IslamicDivider(padding: 20),
                      SelectableText(
                        ayah.translation,
                        style: const TextStyle(fontSize: 18, height: 1.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Аят ${widget.surah.number}:$verse · ${translation.label}',
                        style: TextStyle(
                          color: dark
                              ? MihrabTokens.goldSoft
                              : MihrabTokens.muted,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: dark
                        ? MihrabTokens.gold.withValues(alpha: 0.12)
                        : MihrabTokens.emerald.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: context.tr('Предыдущий аят'),
                    onPressed:
                        verse > 1 ? () => setState(() => verse--) : null,
                    icon: Icon(Icons.chevron_left, color: accent),
                  ),
                  DropdownButton<int>(
                    value: verse,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (var i = 1; i <= widget.surah.count; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text('$i / ${widget.surah.count}'),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => verse = v);
                    },
                  ),
                  IconButton(
                    tooltip: context.tr('Следующий аят'),
                    onPressed: verse < widget.surah.count
                        ? () => setState(() => verse++)
                        : null,
                    icon: Icon(Icons.chevron_right, color: accent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
