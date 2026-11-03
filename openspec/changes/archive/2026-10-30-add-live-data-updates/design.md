## Context

`UserDatabase` (Firestore REST via godot-firebase) offers one-shot reads only. The addon's `FirestoreListener` is an RTDB mirror workaround, not real Firestore realtime, and the project has no RTDB. The user rejected hosting polling inside `UserDatabase` and suggested client-side polling every 5 s.

## Goals / Non-Goals

- Goals: affected players' open screens update without navigating; no backend/rules changes; `UserDatabase` unchanged.
- Non-Goals: sub-second push; offline sync; changing the notification data model.

## Decisions

- **Separate autoload `LiveUpdateService`** that calls existing `UserDatabase.get_notifications/get_friends/get_all_matches_for_player`, keeping `UserDatabase` a data layer. Alternative (polling inside UserDatabase) rejected by the user.
- **Poll via a Timer node (5 s)**, guarded by an in-flight flag; exponential backoff up to 30 s on failures.
- **Diff by stable key**: notifications by `id`, friends by username, matches by `match_id` plus a hash of the match dictionary. Baseline poll is silent.
- **Signals on GlobalSignalBus** (`notifications_changed`, `friends_changed`, `matches_changed`). Not reusing `notification_received`, because `UserDatabase._on_notification_received_global` persists notifications and would create duplicates.
- **Screens re-render from signals**: lobby appends components for `added` and frees `removed`, others refetch their list once. Connections made in `_ready`, dropped in `_exit_tree`.
- **Alternatives**: RTDB stream + client/Cloud Function ping (true push, new infra); per-user revision doc (1 read per poll, requires all writers to bump). Both are possible follow-ups.

## Risks / Trade-offs

- Latency up to ~5 s, not literally one frame; the frame-level update applies after detection.
- Read cost ≈ 3 queries / 5 s / active client; mitigated by pausing in background and signed out.
- Concurrent refreshes (signal plus screen's own load) may double-render; screens must be idempotent by id.
