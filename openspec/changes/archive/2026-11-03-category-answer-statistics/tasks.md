## 1. Match Statistics

- [x] 1.1 Replace round/match-win category updates in `functions/index.js` with per-player aggregation of each round's stored answer results into `correct_answers` and `total_answers`; keep overall scoring and the existing idempotent transaction unchanged, and verify draws, repeated categories, incorrect results, and timeout results are handled by the focused function tests.
- [x] 1.2 Update `tests/firebase/match_statistics_function.test.mjs` fixtures and assertions for the new counters, including independent player results and draw behavior; run `npm run test:functions` and verify the function still processes a match only once.

## 2. Account Statistics UI

- [x] 2.1 Update the account screen and category statistic component to read and display `correct_answers` and `total_answers`, calculate integer accuracy with a zero-total guard, and replace win-oriented internal labels/setters where appropriate; verify examples such as 12/20 display 60% and empty categories display 0%.
- [x] 2.2 Replace the category labels with localized “Answered Correctly,” “Total Answers,” and “Accuracy” strings in `localization/ui_translations.csv`; verify each label in English, German, and Traditional Chinese on the account management screen.

## 3. Integration Verification (user testing not automated)

- [x] 3.1 Run the focused Cloud Function emulator tests and verify the account screen shows answer-based counts after a completed match, including when the overall match is a draw; confirm no code or task deletes database data, since clearing the current data is user-managed.
