import 'package:flutter/material.dart';
import '../../l10n/mihrab_strings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/tasbih.dart';
import '../../domain/tasbih.dart';
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';

class TasbihScreen extends ConsumerWidget {
  const TasbihScreen({super.key});

  Future<void> run(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить изменения')),
        );
      }
    }
  }

  Future<bool> confirm(BuildContext context, String title) async =>
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
              child: const Text('Подтвердить'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> configure(
    BuildContext context,
    WidgetRef ref,
    Dhikr d,
    int target,
  ) async {
    final current = ref.read(tasbihProvider);
    if (current.dhikr == d && current.target == target) return;
    if (current.count > 0 &&
        !current.complete &&
        !await confirm(
          context,
          'Начать новый счёт? Текущий прогресс будет сброшен.',
        )) {
      return;
    }
    if (!context.mounted) return;
    await run(context, () => ref.read(tasbihProvider.notifier).configure(d, target));
  }

  Future<void> custom(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: ref.read(tasbihProvider).target.toString(),
    );
    final goal = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final value = int.tryParse(controller.text);
          final valid = value != null && value >= 1 && value <= 9999;
          return AlertDialog(
            title: const Text('Произвольная цель'),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(labelText: 'От 1 до 9999'),
              onChanged: (_) => setLocal(() {}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: valid ? () => Navigator.pop(ctx, value) : null,
                child: const Text('Применить'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    if (goal != null && context.mounted) {
      await configure(context, ref, ref.read(tasbihProvider).dhikr, goal);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(tasbihProvider);
    final c = ref.read(tasbihProvider.notifier);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final accent = dark ? MihrabTokens.gold : MihrabTokens.emerald;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Тасбих')),
        actions: [
          IconButton(
            tooltip: 'История',
            icon: Icon(Icons.history, color: accent),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TasbihHistoryScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            IslamicCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButton<Dhikr>(
                isExpanded: true,
                value: s.dhikr,
                underline: const SizedBox.shrink(),
                items: [
                  for (final d in Dhikr.values)
                    DropdownMenuItem(value: d, child: Text(d.label)),
                ],
                onChanged: (d) {
                  if (d != null) configure(context, ref, d, s.target);
                },
              ),
            ),
            if (s.dhikr.arabic.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                s.dhikr.arabic,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: dark ? MihrabTokens.goldSoft : MihrabTokens.emerald,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final goal in [33, 99, 100])
                  ChoiceChip(
                    label: Text('$goal'),
                    selected: s.target == goal,
                    onSelected: (_) => configure(context, ref, s.dhikr, goal),
                  ),
                ActionChip(
                  label: Text(
                    [33, 99, 100].contains(s.target)
                        ? 'Своя цель'
                        : 'Цель: ${s.target}',
                  ),
                  onPressed: () => custom(context, ref),
                ),
              ],
            ),
            const IslamicDivider(padding: 24),
            Center(
              child: Semantics(
                button: true,
                label: 'Увеличить счётчик',
                value: '${s.count} из ${s.target}',
                child: SizedBox(
                  width: 228,
                  height: 228,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: s.count / s.target,
                          strokeWidth: 6,
                          backgroundColor: dark
                              ? MihrabTokens.emeraldSoft
                              : MihrabTokens.creamMuted,
                          color: accent,
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                            backgroundColor: dark ? MihrabTokens.gold : MihrabTokens.emerald,
                            foregroundColor: dark ? MihrabTokens.background : MihrabTokens.cream,
                          ),
                          onPressed: s.complete
                              ? null
                              : () => run(context, () async {
                                    final before = ref.read(tasbihProvider);
                                    await c.increment();
                                    if (!context.mounted) return;
                                    final after = ref.read(tasbihProvider);
                                    if (after.count != before.count &&
                                        after.haptic) {
                                      if (after.complete) {
                                        await HapticFeedback.mediumImpact();
                                      } else {
                                        await HapticFeedback.selectionClick();
                                      }
                                    }
                                  }),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${s.count}',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1,
                                  fontFeatures: [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              Text(
                                'из ${s.target}',
                                style: TextStyle(
                                  color: dark ? MihrabTokens.background : MihrabTokens.cream,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.complete ? 'Завершено' : 'Нажмите',
                                style: TextStyle(
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                  color: dark ? MihrabTokens.background : MihrabTokens.cream,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.tonalIcon(
              onPressed: s.count == 0
                  ? null
                  : () async {
                      if (s.complete ||
                          await confirm(context, 'Сбросить текущий счёт?')) {
                        if (context.mounted) await run(context, c.reset);
                      }
                    },
              icon: const Icon(Icons.restart_alt),
              label: Text(s.complete ? 'Новая сессия' : 'Сбросить'),
            ),
            IslamicCard(
              padding: EdgeInsets.zero,
              margin: const EdgeInsets.only(top: 12),
              child: SwitchListTile(
                title: const Text('Тактильный отклик'),
                value: s.haptic,
                onChanged: (v) => run(context, () => c.vibration(v)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Цели счёта настраиваются пользователем и сами по себе не являются религиозным предписанием.',
              textAlign: TextAlign.center,
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

class TasbihHistoryScreen extends ConsumerWidget {
  const TasbihHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(tasbihProvider).history;
    final helper = const TasbihScreen();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? MihrabTokens.gold : MihrabTokens.emerald;

    return Scaffold(
      appBar: AppBar(
        title: const Text('История тасбиха'),
        actions: [
          IconButton(
            tooltip: 'Очистить историю',
            icon: Icon(Icons.delete_outline, color: accent),
            onPressed: history.isEmpty
                ? null
                : () async {
                    if (await helper.confirm(
                          context,
                          'Удалить историю завершённых сессий?',
                        ) &&
                        context.mounted) {
                      await helper.run(
                        context,
                        ref.read(tasbihProvider.notifier).clearHistory,
                      );
                    }
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            IslamicCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Сессий: ${history.length}'),
                subtitle: Text(
                  'Повторений в сохранённых сессиях: ${history.fold<int>(0, (sum, s) => sum + s.target)}',
                ),
              ),
            ),
            if (history.isEmpty)
              const IslamicCard(
                child: Text('История пока пуста'),
              ),
            for (final item in history)
              IslamicCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: ListTile(
                  leading: Icon(Icons.check_circle_outline, color: accent),
                  title: Text(item.dhikr.label),
                  subtitle: Text(
                    MaterialLocalizations.of(context)
                        .formatMediumDate(item.completedAt.toLocal()),
                  ),
                  trailing: Text(
                    '${item.target}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Хранятся последние 100 завершённых сессий.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: dark ? MihrabTokens.goldSoft : MihrabTokens.muted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
