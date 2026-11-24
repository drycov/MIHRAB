# MIHRAB — Design System & UI Implementation Guide

Use this document when generating or editing Flutter UI for the MIHRAB app.
Follow it strictly so every screen stays visually consistent.

---

## 1. Brand & mood

- **Product:** Islamic prayer companion (namaz times, Qibla, Hijri calendar, Quran, Ramadan, tasbih, dua).
- **Mood:** Calm mosque interior — deep emerald, warm gold, parchment cream. Quiet, respectful, not flashy.
- **Language:** Russian UI labels; Arabic for prayer names, Quran, dua (always `TextDirection.rtl` for Arabic).
- **Avoid:** Neon colors, heavy Material purple defaults, playful cartoons, dense clutter, harsh shadows.

---

## 2. Color tokens (`lib/app/theme.dart` → `MihrabTokens`)

| Token | Value | Use |
|-------|--------|-----|
| `background` | `#071F1B` | Dark scaffold |
| `emerald` | `#0E342B` | Primary dark surfaces, active cards |
| `emeraldDeep` | `#062018` | Gradients, shadows |
| `emeraldSoft` | `#164A3C` | Gradient tops, soft fills |
| `gold` | `#D4B06A` | Accents, active icons, CTAs in dark |
| `goldSoft` | `#E8D5A3` | Secondary gold text |
| `cream` | `#F6F1E6` | Light scaffold |
| `creamMuted` | `#E8E0D0` | Light secondary surfaces |
| `ink` | `#1A2E28` | Light mode primary text |
| `muted` | `#6B7F78` | Secondary labels |

**Rules**
- Dark mode primary accent = gold; light mode primary accent = emerald.
- Borders: gold @ 0.08–0.12 alpha (dark) or emerald @ 0.07–0.08 (light).
- Active / highlighted blocks: solid `emerald` + gold border ~0.4 alpha.
- Never introduce new brand colors without extending `MihrabTokens`.

**Spacing / radius**
- `space` 20, `spaceSm` 12, `spaceLg` 28
- `radius` 20, `radiusSm` 12, `radiusLg` 28
- Title letter-spacing: ~3–4 (`letterTitle`); section labels ~1.6–2.0

---

## 3. Shared components (`lib/shared/islamic_ornaments.dart`)

Always prefer these over one-off containers:

| Widget | Role |
|--------|------|
| `IslamicStar` | 8-point geometric star ornament |
| `IslamicDivider` | Horizontal rule with central star |
| `IslamicSectionTitle` | Uppercase section label with tracking |
| `IslamicCard` | Standard surface card; `highlighted: true` for emerald hero rows |
| `MihrabFrame` | Arch-top gradient hero (countdown, Qibla, Ramadan day) |

Import:
```dart
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';
```

---

## 4. Layout patterns

### Screen padding
```dart
ListView(
  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28), // or 20 horizontal
  children: [...],
)
```

### AppBar
- Centered title when it is a root tab; otherwise default back + title.
- Title style: `letterSpacing: MihrabTokens.letterTitle`, weight 600.
- Action icons: gold (dark) / emerald (light).

### Hero block
Use `MihrabFrame` for the main focal metric (next prayer, Qibla dial, fasting countdown):
- Small gold star or crescent at top
- Uppercase micro-label (letterSpacing ≥ 2)
- Large white primary number/name
- Arabic line in `goldSoft`, RTL
- Thin gold separator line
- Secondary time/meta in gold

### Lists
- Prefer `IslamicCard` rows over bare `ListTile` on white scaffold.
- Active row: `highlighted: true` or emerald fill + gold border.
- Leading: circular icon badge (40×40), gold border when active.
- Trailing times: `FontFeature.tabularFigures()`, letterSpacing ~0.6–0.8.

### Forms / settings
- Group controls inside `IslamicCard(padding: EdgeInsets.zero)` with internal `Divider`s.
- Interactive tiles need a local Material above any opaque decoration. IslamicCard provides a transparent, rounded, clipped Material inside its decorated surface; retain it when editing the component.
- Section headers: `IslamicSectionTitle('...')`.
- Primary CTA: `FilledButton` with
  - dark: `backgroundColor: gold`, `foregroundColor: background`
  - light: `backgroundColor: emerald`, `foregroundColor: cream`
  - `BorderRadius.circular(MihrabTokens.radius)`, vertical padding 14.

### Search fields
- Standard `TextField` with `prefixIcon: Icon(Icons.search)`.
- Keep decoration light; rely on theme, not custom purple fills.

### Arabic text
```dart
Text(
  arabic,
  textDirection: TextDirection.rtl,
  textAlign: TextAlign.right, // or center for titles
  style: TextStyle(height: 1.6–2.0, fontSize: …),
)
```

---

## 5. Screen-specific notes

| Screen | Hero | Notes |
|--------|------|--------|
| Prayers | `CountdownCard` / `MihrabFrame` | Prayer tiles with circular icons; source footnote centered |
| Qibla | `MihrabFrame` + custom compass | Gold rings, N highlighted, Kaaba tick |
| Calendar | Hijri title + grid | Today = gold border; selected = emerald fill |
| Ramadan | `MihrabFrame` day progress | Table rows as `IslamicCard`; today highlighted |
| Quran | List of surahs | CircleAvatar numbers; keep reading quiet |
| Tasbih | Large circular counter | Gold/emerald progress ring; Arabic dhikr above |
| Dua | Search + chips + cards | Detail: large RTL Arabic, progress bar, counter |
| Bookmarks | Search + filters | Cards/list tiles with popup actions |
| Settings | Grouped `IslamicCard`s | Section titles; footer wordmark MIHRAB |
| Onboarding | Mosque icon in ring | 3 steps; basmala; gold progress |

---

## 6. Theme API

```dart
MihrabTheme.build(Brightness.light)
MihrabTheme.build(Brightness.dark)
```

- `useMaterial3: true`
- Card theme: elevation 0, radius 20, subtle border
- NavigationBar: indicator gold/emerald soft fill; selected icon/label accented
- Switch: selected thumb gold, track emeraldSoft

Do not call `ThemeData` from scratch on a screen — extend or use tokens.

---

## 7. Rules for ChatGPT / codegen

1. **Always import** `theme.dart` and `islamic_ornaments.dart` for new UI.
2. **No hard-coded** `Colors.green`, `Colors.amber`, `Color(0xFF…)` outside `MihrabTokens`.
3. **Reuse** `IslamicCard`, `MihrabFrame`, `IslamicDivider`, `IslamicSectionTitle` before inventing new shells.
4. **Arabic** → always `textDirection: TextDirection.rtl`.
5. **Times** → `FontFeature.tabularFigures()`.
6. **Primary buttons** follow dark=gold / light=emerald mapping above.
7. **Padding** stick to 16–20 horizontal, bottom ≥ 24–28 for scroll lists.
8. **Do not** strip existing Riverpod / navigation logic when restyling.
9. **Keep** accessibility: tooltips on icon buttons, Semantics on tasbih counter.
10. When unsure, match `prayers_screen.dart` + `settings_screen.dart` as reference implementations.

---

## 8. Minimal template for a new screen

```dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';

class ExampleScreen extends ConsumerWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TITLE',
          style: TextStyle(
            letterSpacing: MihrabTokens.letterTitle,
            fontWeight: FontWeight.w600,
            color: dark ? MihrabTokens.goldSoft : MihrabTokens.ink,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const IslamicSectionTitle('Секция'),
          IslamicCard(
            child: Text('Content', style: theme.textTheme.bodyLarge),
          ),
          const IslamicDivider(),
          // …
        ],
      ),
    );
  }
}
```

---

## 9. Out of scope for pure UI tasks

- Prayer calculation, notification scheduling, Quran network layer — do not rewrite unless asked.
- Changing city list, calculation method, or religious copy without explicit request.
