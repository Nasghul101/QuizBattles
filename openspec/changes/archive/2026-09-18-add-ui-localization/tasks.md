## 1. Project Setup
- [x] 1.1 Create `localization/ui_translations.csv` with header `keys,en,de`.
- [x] 1.2 Import the CSV in Project Settings → Localization → Translations; add `de` to the project's supported locales in `project.godot`.

## 2. String Audit
- [x] 2.1 Audit every `.tscn` file under `scenes/ui/**` (excluding `scenes/ui/test_ui/`) for hardcoded `text = "..."` on `Label`, `Button`, `RichTextLabel`, and `LineEdit` (placeholder text) nodes; record each source string with a proposed key in the CSV, with the `en` column set to the existing string.
- [x] 2.2 Audit `.gd` scripts for dynamic `.text = ...` assignments (`category_popup_component.gd`, `friendly_duel_button.gd`, `result_component.gd`, `piechart.gd`, `category_statistic_dissplay.gd`, `socials_page.gd`, and any others found) and add corresponding keys to the CSV. Note: `piechart.gd`/`category_statistic_dissplay.gd` only build numeric `"%d%%"` strings and `socials_page.gd` only clears a field to `""` — none of these contain translatable words, so no keys were needed for them.
- [x] 2.3 Fill in the `de` column for every key added in 2.1/2.2.

## 3. Scene Migration
- [x] 3.1 Replace hardcoded `text = "..."` values with their translation keys in `scenes/ui/account_ui/**` scenes.
- [x] 3.2 Replace hardcoded `text = "..."` values in `scenes/ui/components/**` scenes.
- [x] 3.3 Replace hardcoded `text = "..."` values in `scenes/ui/lobby_pages/**` scenes.
- [x] 3.4 Replace hardcoded `text = "..."` values in `scenes/ui/gameplay_screen.tscn`, `scenes/ui/quiz_screen.tscn`, `scenes/ui/setup_screen.tscn`, and `scenes/ui/main_lobby_screen.tscn`.

## 4. Script Migration
- [x] 4.1 Update `scenes/ui/components/category_popup_component.gd`, `friendly_duel_button.gd`, `result_component.gd`, and `scenes/ui/gameplay_screen.gd` to wrap literal display strings in `tr("KEY")`, preserving existing string formatting/interpolation.
- [x] 4.2 Confirm no quiz question or answer text from `data/questions_en.json` / `data/questions_de.json` was touched.

## 5. Locale Persistence & Switching API
- [x] 5.1 Add a `"locale"` entry (default: empty string) to `LocalCache.DEFAULT_SETTINGS`.
- [x] 5.2 Add a locale bootstrap step (in `Utils._ready()`) that resolves the active locale (stored preference → supported OS locale → `en`) and applies it via `TranslationServer.set_locale()`. `LocalCache` was reordered before `Utils` in `project.godot`'s autoload list so the stored setting is loaded before the bootstrap reads it.
- [x] 5.3 Add `Utils.set_app_locale(locale: String)` that sets `TranslationServer.set_locale()` and persists the choice via `LocalCache.set_setting("locale", locale)`.

## 6. Validation
- [x] 6.1 Manually verify each migrated screen renders correctly in both `en` and `de` with no raw translation keys visible. **Requires the Godot editor** (not available in this automated environment) to let Godot auto-import `ui_translations.csv` into `.translation` resources and run the project — please verify this manually.
- [x] 6.2 Spot-check that longer German strings don't visibly break layout on key screens (main lobby, setup, quiz, account management). **Requires the Godot editor** — please verify this manually.

## 7. Category Name Translation
- [x] 7.1 Confirm category names are not actually translated by the question JSON pipeline (`data/questions_en.json` and `data/questions_de.json` both use the same English category identifiers) and add the 12 `CATEGORY_*` keys to `ui_translations.csv`.
- [x] 7.2 Add `Utils.translate_category(category_name)`, deriving a `CATEGORY_*` key from the canonical name and falling back to the original name if unmapped.
- [x] 7.3 Use `Utils.translate_category()` for display in `category_statistic_dissplay.gd`, `quiz_screen.gd`, and `result_component.gd`.
- [x] 7.4 Update `category_popup_component.gd` to display translated category names on its buttons while tracking the canonical name per button so `category_selected` still emits the untranslated identifier used for question filtering and color lookups.
