## Why

Category statistics currently count rounds as `played` and award a category `win` whenever a player wins the overall match, regardless of their answers in that category. This makes the displayed category win rate misleading; tracking actual answers will show players how accurately they answer questions in each category.

## What Changes

- Replace category match/round counts with per-player `correct_answers` and `total_answers` counts, derived from each stored answer result and its round category.
- Aggregate answer counts for both players once when a match completes, including draws; count every recorded result in the total and only correct results in the correct count.
- Update the category statistics display to label the counters “Answered Correctly” and “Total Answers,” with the rate based on correct answers divided by total answers.
- Use the existing localization system for the updated category-stat labels.
- No historical backfill is planned because the user intends to clear the existing database data before using the new counters.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `local-user-database`: Change category statistics from match/round win counts to answer-level correct and total counts, aggregated at match completion.
- `account-management-screen`: Display answer-level category totals and the corresponding accuracy rate.

## Impact

- `functions/index.js`: Match-completion statistics aggregation and Firestore category-stat schema.
- `scenes/ui/account_ui/account_management_screen.gd` and `scenes/ui/components/category_statistic_dissplay.gd` / `.tscn`: Category statistic values, labels, and rate calculation.
- `localization/ui_translations.csv`: Localized labels for correct and total answers.
- Existing `rounds_data[*].player_answers[*].results` already stores per-question `was_correct` values; the category is stored on the containing round. Statistics remain applied once at match completion through the existing idempotent Cloud Function flow.
- Timed-out questions are currently saved as incorrect results; per the user's decision, each such recorded result counts toward `total_answers`.
- Existing database data will be cleared by the user; no migration or backfill is included in this change.
