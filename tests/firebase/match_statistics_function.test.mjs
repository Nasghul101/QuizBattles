import assert from "node:assert/strict";
import { test } from "node:test";

import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

const projectId = "demo-quizbattles";
const authUrl = "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key";
const functionUrl = `http://127.0.0.1:5001/${projectId}/us-central1/processMatchStatistics`;

initializeApp({ projectId });
const db = getFirestore();

async function signUp(label) {
  const response = await fetch(authUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      email: `${label}-${Date.now()}@example.invalid`,
      password: "Test-password-123!",
      returnSecureToken: true
    })
  });
  assert.equal(response.status, 200);
  const body = await response.json();
  return { uid: body.localId, token: body.idToken };
}

function callFunction(body, token) {
  return fetch(functionUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {})
    },
    body: JSON.stringify(body)
  });
}

function emptyProfile(uid, username) {
  return {
    uid,
    username,
    username_normalized: username.toLowerCase(),
    avatar_path: "res://assets/avatars/default.png",
    wins: 0,
    losses: 0,
    total_games: 0,
    current_streak: 0,
    friend_wins: {},
    category_stats: {}
  };
}

function answers(correctCount) {
  return { answered: true, results: Array.from({ length: 3 }, (_, i) => ({ was_correct: i < correctCount })) };
}

async function seedMatch(matchId, players, uids, scores, { friends }) {
  await Promise.all(uids.map((uid, i) => db.doc(`users/${uid}`).set(emptyProfile(uid, players[i]))));
  if (friends) {
    await db.doc(`friendships/${[...uids].sort().join("_")}`).set({ participant_uids: [...uids].sort() });
  }
  await db.doc(`matches/${matchId}`).set({
    match_id: matchId,
    players,
    participant_uids: uids,
    status: "finished",
    stats_processed: false,
    rounds_data: ["History", "Science"].map((category) => ({
      category,
      player_answers: { [players[0]]: answers(scores[0]), [players[1]]: answers(scores[1]) }
    }))
  });
}

test("rejects missing/invalid tokens and non-participants without changing data", async () => {
  const first = await signUp("first");
  const second = await signUp("second");
  const outsider = await signUp("outsider");
  await seedMatch("match-auth", ["FirstPlayer", "SecondPlayer"], [first.uid, second.uid], [3, 1], { friends: false });

  assert.equal((await callFunction({ match_id: "match-auth" })).status, 401);
  assert.equal((await callFunction({ match_id: "match-auth" }, "not-a-token")).status, 401);
  assert.equal((await callFunction({ match_id: "match-auth" }, outsider.token)).status, 403);
  assert.equal((await callFunction({}, first.token)).status, 400);
  assert.equal((await callFunction({ match_id: "missing-match" }, first.token)).status, 404);

  assert.equal((await db.doc("matches/match-auth").get()).data().stats_processed, false);
  assert.equal((await db.doc(`users/${first.uid}`).get()).data().total_games, 0);
});

test("a win updates both profiles and the match exactly once", async () => {
  const winner = await signUp("winner");
  const loser = await signUp("loser");
  await seedMatch("match-win", ["WinnerOne", "LoserOne"], [winner.uid, loser.uid], [3, 1], { friends: true });

  const first = await callFunction({ match_id: "match-win" }, loser.token);
  assert.equal(first.status, 200);
  assert.deepEqual(await first.json(), { processed: true, already_processed: false });

  const duplicate = await callFunction({ match_id: "match-win" }, winner.token);
  assert.equal(duplicate.status, 200);
  assert.deepEqual(await duplicate.json(), { processed: false, already_processed: true });

  const winnerProfile = (await db.doc(`users/${winner.uid}`).get()).data();
  const loserProfile = (await db.doc(`users/${loser.uid}`).get()).data();
  assert.equal(winnerProfile.total_games, 1);
  assert.equal(winnerProfile.wins, 1);
  assert.equal(winnerProfile.current_streak, 1);
  assert.deepEqual(winnerProfile.friend_wins, { LoserOne: 1 });
  assert.deepEqual(winnerProfile.category_stats, {
    History: { played: 1, wins: 1 },
    Science: { played: 1, wins: 1 }
  });
  assert.equal(loserProfile.total_games, 1);
  assert.equal(loserProfile.losses, 1);
  assert.equal(loserProfile.current_streak, 0);
  assert.deepEqual(loserProfile.category_stats.History, { played: 1, wins: 0 });
  assert.equal((await db.doc("matches/match-win").get()).data().stats_processed, true);
});

test("a draw only increments games and category participation", async () => {
  const first = await signUp("draw-a");
  const second = await signUp("draw-b");
  await seedMatch("match-draw", ["DrawOne", "DrawTwo"], [first.uid, second.uid], [2, 2], { friends: false });

  const response = await callFunction({ match_id: "match-draw" }, first.token);
  assert.equal(response.status, 200);

  for (const uid of [first.uid, second.uid]) {
    const profile = (await db.doc(`users/${uid}`).get()).data();
    assert.equal(profile.total_games, 1);
    assert.equal(profile.wins, 0);
    assert.equal(profile.losses, 0);
    assert.deepEqual(profile.friend_wins, {});
    assert.deepEqual(profile.category_stats.Science, { played: 1, wins: 0 });
  }
  assert.equal((await db.doc("matches/match-draw").get()).data().stats_processed, true);
});

test("concurrent requests process statistics once", async () => {
  const first = await signUp("race-a");
  const second = await signUp("race-b");
  await seedMatch("match-race", ["RaceOne", "RaceTwo"], [first.uid, second.uid], [1, 3], { friends: false });

  const responses = await Promise.all([
    callFunction({ match_id: "match-race" }, first.token),
    callFunction({ match_id: "match-race" }, second.token)
  ]);
  assert.deepEqual(responses.map((response) => response.status), [200, 200]);

  const profile = (await db.doc(`users/${second.uid}`).get()).data();
  assert.equal(profile.total_games, 1);
  assert.equal(profile.wins, 1);
});
