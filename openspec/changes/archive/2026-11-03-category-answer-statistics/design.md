## Context

See [proposal.md](./proposal.md) for motivation. Match rounds already store a canonical category and separate per-player result arrays containing `was_correct`. The existing Cloud Function processes match statistics atomically once and marks the match as processed; category counts can use that same transaction and idempotency boundary.

The account statistic component currently derives its percentage from the two displayed counts and uses the existing CSV translation resource for its labels.

## Goals / Non-Goals

**Goals:**
- Derive per-category totals from each player's stored results, independent of the overall match winner.
- Preserve the current once-per-match atomic statistics update.
- Present answer counts and an accuracy percentage with localized labels.

**Non-Goals:**
- Update profile statistics during each answer selection.
- Change overall match scoring, wins, losses, draws, or streaks.
- Migrate or backfill legacy category counters.

## Decisions

1. **Aggregate results and finish the match in the existing statistics transaction.** For each round and player, add the number of stored results to that round category's `total_answers`, and add one to `correct_answers` for each result whose `was_correct` value is true. The same transaction marks the match finished and sets `stats_processed`, so match completion cannot be left active after its statistics have been applied. If a client loads an already-processed match that is still marked active, gameplay repairs the status and shows the finish popup. Updating counters on every tap was considered, but it would split statistics persistence from the current atomic match-completion flow and require separate duplicate-answer protection.

2. **Use `correct_answers` and `total_answers` as the category-stat fields.** These names describe the measured data directly and avoid carrying forward the previous match-win meaning. Legacy `played` and `wins` values will not be converted; the user plans to clear existing database data before using the new metric.

3. **Count every stored result in the denominator, including timer expirations.** The current timeout flow records an incorrect result, and the user confirmed that timeouts count. Only results explicitly marked correct increment the numerator.

4. **Update the display terminology and keep it localized.** Show “Answered Correctly,” “Total Answers,” and “Accuracy” through the existing `ui_translations.csv` pipeline. Continue using the canonical category name for data lookup; calculate the integer percentage from the two counts and show 0% when there are no total answers.

## Risks / Trade-offs

- [Risk] If legacy profile data is not cleared, its `played` / `wins` counters do not represent answer counts. → No compatibility mapping is planned; the rollout assumes the existing data is cleared as the user intends.
- [Trade-off] Profile statistics remain unchanged during an active match and update only after match completion. → This preserves the existing transactional, idempotent update boundary selected for this change.
- [Risk] A future timeout implementation might stop recording an incorrect result. → The denominator is defined by stored result records, so timeout behavior and answer-statistics tests should remain aligned.

## Migration Plan

No automatic migration or historical backfill is included. The user will clear the current database data before relying on the new category-stat fields. New and subsequently updated profiles use `correct_answers` and `total_answers`. Rollback is a code revert; it cannot restore data the user has cleared.
