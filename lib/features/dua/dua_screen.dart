import 'package:material_ui/material_ui.dart';
import '../../l10n/mihrab_strings.dart';
import 'package:flutter/services.dart';
import '../../domain/dua.dart';
import '../../domain/bookmark.dart';
import '../bookmarks/bookmark_button.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../tasbih/tasbih_screen.dart';
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';

class DuaScreen extends StatefulWidget {
  const DuaScreen({super.key});
  @override
  State<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends State<DuaScreen> {
  DuaCategory? category;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered =
        duas
            .where(
              (d) =>
                  (category == null || d.category == category) &&
                  [
                    d.title,
                    d.meaning,
                    d.transliteration,
                    d.arabic,
                  ].any((s) => s.toLowerCase().contains(query)),
            )
            .toList();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? MihrabTokens.gold : MihrabTokens.emerald;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Дуа и азкары')),
        actions: [
          IconButton(
            tooltip: context.tr('Избранное'),
            icon: Icon(Icons.bookmarks_outlined, color: accent),
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BookmarksScreen(),
                  ),
                ),
          ),
          IconButton(
            tooltip: context.tr('Тасбих'),
            icon: Icon(Icons.touch_app, color: accent),
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const TasbihScreen()),
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
                  hintText: 'Поиск дуа и азкаров',
                ),
                onChanged:
                    (v) => setState(() => query = v.trim().toLowerCase()),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: ChoiceChip(
                      label: const Text('Все'),
                      selected: category == null,
                      onSelected: (_) => setState(() => category = null),
                    ),
                  ),
                  for (final c in DuaCategory.values)
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: ChoiceChip(
                        label: Text(c.label),
                        selected: category == c,
                        onSelected: (_) => setState(() => category = c),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  if (filtered.isEmpty)
                    const IslamicCard(child: Text('Ничего не найдено')),
                  for (final d in filtered)
                    IslamicCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        title: Text(
                          d.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${d.category.label} · ${d.repetitions} повторений',
                        ),
                        trailing: Icon(Icons.chevron_right, color: accent),
                        onTap:
                            () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => DuaDetailScreen(dua: d),
                              ),
                            ),
                      ),
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

class DuaDetailScreen extends StatefulWidget {
  const DuaDetailScreen({super.key, required this.dua});
  final Dua dua;
  @override
  State<DuaDetailScreen> createState() => _DuaDetailScreenState();
}

class _DuaDetailScreenState extends State<DuaDetailScreen> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    final d = widget.dua;
    final done = count >= d.repetitions;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final accent = dark ? MihrabTokens.gold : MihrabTokens.emerald;

    return Scaffold(
      appBar: AppBar(
        title: Text(d.title),
        actions: [
          BookmarkButton(
            bookmark: Bookmark(
              kind: BookmarkKind.dua,
              reference: d.id,
              title: d.title,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(
              d.category.label.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.6,
                color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
              ),
            ),
            const SizedBox(height: 20),
            SelectableText(
              d.arabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 30,
                height: 2,
                color: dark ? MihrabTokens.goldSoft : MihrabTokens.ink,
              ),
            ),
            const IslamicDivider(padding: 20),
            Text(
              d.transliteration,
              style: theme.textTheme.titleMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 12),
            const IslamicSectionTitle('Смысловой перевод'),
            SelectableText(
              d.meaning,
              style: const TextStyle(fontSize: 18, height: 1.6),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: count / d.repetitions,
                minHeight: 4,
                backgroundColor:
                    dark ? MihrabTokens.emeraldSoft : MihrabTokens.creamMuted,
                color: accent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$count / ${d.repetitions}',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: done ? null : () => setState(() => count++),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor:
                    dark ? MihrabTokens.background : MihrabTokens.cream,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MihrabTokens.radius),
                ),
              ),
              child: Text(done ? 'Завершено' : 'Отметить повторение'),
            ),
            TextButton(
              onPressed: count == 0 ? null : () => setState(() => count = 0),
              child: const Text('Сбросить счётчик'),
            ),
            const IslamicDivider(),
            Text('Источник: ${d.source}'),
            SelectableText(d.url),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: d.url));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ссылка скопирована')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Копировать ссылку'),
            ),
            Text(
              'Транслитерация приблизительная. Для правильного произношения сверяйтесь с арабским текстом.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
