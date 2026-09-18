## Context
The game currently has zero localization infrastructure: every `Label`/`Button`/etc. `text` value is written directly in English inside `.tscn` files, and several scripts build display strings inline (e.g. `"Round: " + str(count)`). Quiz question and answer content already has an independent, working translation pipeline (`data/questions_en.json`, `data/questions_de.json`, `tools/translate_questions.py`). Category names are a separate case: both JSON files use the *same* English category identifiers (`"General Knowledge"`, `"Science"`, etc.) as canonical keys, so that pipeline does not translate them — they are in scope for this change, displayed via `Utils.translate_category()` while the canonical English identifier keeps flowing through color lookups (`Utils.resolve_category_color()`) and question filtering unchanged.

Godot 4's built-in localization system supports CSV-based translations out of the box: a CSV with a `keys` column plus one column per locale is imported as a set of `Translation` resources, and any `Control`-derived node auto-applies `tr()` to its `text` (and similar) properties when `auto_translate_mode` is enabled (the default). This matches the CSV approach recommended by the referenced guide and needs no extra Godot plugins.

## Goals / Non-Goals
- Goals:
  - Establish a single CSV translation source for all static/dynamic UI text.
  - Support English (`en`) and German (`de`) initially, matching the languages already present in the question data.
  - Make locale selection persistent (via `LocalCache`) and switchable at runtime without an app restart.
  - Keep the migration mechanical and low-risk: swap literal strings for translation keys, no behavior changes.
- Non-Goals:
  - No new settings/language-switcher UI screen (locale API only; UI hookup is a future change).
  - No localization of quiz question text or answer options (already handled elsewhere).
  - No localization of the dev-only scenes under `scenes/ui/test_ui/`.
  - No gettext/.po workflow, no pluralization support, no RTL handling (not needed for en/de).

## Decisions
- **Decision: CSV translations over gettext.** CSV is simpler to maintain for a small/medium string set and is explicitly what was requested. File lives at `localization/ui_translations.csv` with columns `keys,en,de`.
- **Decision: Key naming convention.** Keys are `SCREAMING_SNAKE_CASE`, prefixed by an abbreviated screen/component name, e.g. `SETUP_SCREEN_START_BUTTON`, `NOTIFICATION_ACCEPT_BUTTON`, `RESULT_ROUND_LABEL`. Dynamic strings that embed values (e.g. `"Round: " + str(count)`) become format-style keys used with `tr("FRIENDLY_DUEL_ROUND_COUNT") % count` (or `.format()`), keeping the key stable regardless of the interpolated value.
- **Decision: Rely on Godot's automatic Control translation for `.tscn` text.** Since `auto_translate_mode` defaults to enabled and is inherited from the (also-default-enabled) viewport setting, replacing a node's `text` property value with a translation key string in the `.tscn` file is sufficient — no per-node script changes are needed purely for static scene text.
- **Decision: `.gd` scripts must call `tr()` explicitly.** Scripts that build `.text` at runtime are not covered by the scene-level auto-translation and must wrap their key in `tr(...)` explicitly, e.g. `round_count.text = tr("FRIENDLY_DUEL_ROUND_COUNT") % count`.
- **Decision: Locale persistence via `LocalCache`.** A new `"locale"` entry is added to the cache's `settings` dictionary (empty string = "no explicit preference yet"), read/written through the existing `get_setting`/`set_setting` API — consistent with how `music_volume`/`sfx_volume`/`notifications_enabled` are already handled.
- **Decision: Locale bootstrap order.** On startup: (1) use `LocalCache` stored locale if non-empty and supported, (2) else use `OS.get_locale_language()` if it matches a supported locale, (3) else fall back to `en`. This runs once, early (e.g. in `Utils._ready()` or a small dedicated autoload), before any scene renders.
- **Decision: Runtime switch API.** A single function (e.g. `Utils.set_app_locale(locale: String)`) calls `TranslationServer.set_locale()` and `LocalCache.set_setting("locale", locale)`. Godot automatically re-translates all currently visible auto-translated Control text; scripts that built dynamic text via `tr()` must be re-invoked by whatever refresh logic each screen already uses (no new observer pattern is introduced in this change).
- **Decision: Category names are translated via a derived key, not stored as separate CSV identifiers.** `Utils.translate_category(category_name)` derives a `CATEGORY_*` key from the canonical name (`"General Knowledge"` → `CATEGORY_GENERAL_KNOWLEDGE`) and falls back to the original name if no matching key exists (e.g. a category added later without a translation). Code that needs the canonical name for matching/coloring (e.g. `category_popup_component.gd`'s category-selection buttons) keeps a separate mapping from button to canonical name so the translated `button.text` is never mistaken for the identifier.

## Risks / Trade-offs
- **Risk: Large mechanical diff across ~26 scene files.** Mitigated by doing the migration screen-by-screen (see tasks.md) and validating each screen visually in both locales before moving on.
- **Risk: Missed dynamic strings in scripts silently show raw keys.** Mitigated by an explicit audit task and a manual pass in both locales (tasks.md section 4).
- **Risk: German text length breaking mobile layouts (~35% longer on average).** Out of scope to fully solve in this change; flagged as a manual verification step, not a blocking requirement, since UI layout work is a separate concern from wiring up localization.

## Migration Plan
1. Add CSV + project settings registration (no visible behavior change yet — keys not yet referenced).
2. Migrate scenes and scripts screen-by-screen, verifying each still displays correct English text (since `en` values match current text) before moving to the next.
3. Add locale persistence + bootstrap + switch API last, since it only becomes useful once keys exist.
4. No rollback complexity: reverting is deleting the CSV/localization settings and restoring literal strings, since no data storage format changes.

## Open Questions
None — scope, locales, and UI placement were confirmed with the requester before drafting this proposal.
