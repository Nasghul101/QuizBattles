import assert from "node:assert/strict";
import { test } from "node:test";

import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

const projectId = "demo-quizbattles";
const authHost = process.env.AUTH_EMULATOR_HOST || "127.0.0.1:9099";
const functionsHost = process.env.FUNCTIONS_EMULATOR_HOST || "127.0.0.1:5001";
const authUrl = `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`;
const functionUrl = `http://${functionsHost}/${projectId}/us-central1/processMatchStatistics`;

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

function answers(results) {
  return { answered: true, results: results.map((was_correct) => ({ was_correct })) };
}

async function seedMatch(matchId, players, uids, rounds, { friends }) {
  await Promise.all(uids.map((uid, i) => db.doc(`users/${uid}`).set(emptyProfile(uid, players[i]))));
  if (friends) {
    await db.doc(`friendships/${[...uids].sort().join("_")}`).set({ participant_uids: [...uids].sort() });
  }
  await db.doc(`matches/${matchId}`).set({
    match_id: matchId,
    players,
    participant_uids: uids,
    status: "active",
    stats_processed: false,
    rounds_data: rounds.map(({ category, results }) => ({
      category,
      player_answers: {
        [players[0]]: answers(results[0]),
        [players[1]]: answers(results[1])
      }
    }))
  });
}

test("rejects missing/invalid tokens and non-participants without changing data", async () => {
  const first = await signUp("first");
  const second = await signUp("second");
  const outsider = await signUp("outsider");
  await seedMatch(
    "match-auth",
    ["FirstPlayer", "SecondPlayer"],
    [first.uid, second.uid],
    [{ category: "History", results: [[true, true, true], [true, false, false]] }],
    { friends: false }
  );

  assert.equal((await callFunction({ match_id: "match-auth" })).status, 401);
  assert.equal((await callFunction({ match_id: "match-auth" }, "not-a-token")).status, 401);
  assert.equal((await callFunction({ match_id: "match-auth" }, outsider.token)).status, 403);
  assert.equal((await callFunction({}, first.token)).status, 400);
  assert.equal((await callFunction({ match_id: "missing-match" }, first.token)).status, 404);

  assert.equal((await db.doc("matches/match-auth").get()).data().stats_processed, false);
  assert.equal((await db.doc("matches/match-auth").get()).data().status, "active");
  assert.equal((await db.doc(`users/${first.uid}`).get()).data().total_games, 0);
});

test("a win updates both profiles and the match exactly once", async () => {
  const winner = await signUp("winner");
  const loser = await signUp("loser");
  await seedMatch(
    "match-win",
    ["WinnerOne", "LoserOne"],
    [winner.uid, loser.uid],
    [
      { category: "History", results: [[true, false, false], [true, true, false]] },
      { category: "History", results: [[false, false], [false, true]] },
      { category: "Science", results: [[true, true, true], [false, false, false]] }
    ],
    { friends: true }
  );
  await db.doc(`users/${winner.uid}`).update({
    category_stats: {
      History: { correct_answers: 2, total_answers: 4 },
      Science: { correct_answers: 1, total_answers: 2 }
    }
  });
  await db.doc(`users/${loser.uid}`).update({
    category_stats: {
      History: { correct_answers: 1, total_answers: 2 },
      Science: { correct_answers: 2, total_answers: 4 }
    }
  });

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
    History: { correct_answers: 3, total_answers: 9 },
    Science: { correct_answers: 4, total_answers: 5 }
  });
  assert.equal(loserProfile.total_games, 1);
  assert.equal(loserProfile.losses, 1);
  assert.equal(loserProfile.current_streak, 0);
  assert.deepEqual(loserProfile.category_stats, {
    History: { correct_answers: 4, total_answers: 7 },
    Science: { correct_answers: 2, total_answers: 7 }
  });
  const completedMatch = (await db.doc("matches/match-win").get()).data();
  assert.equal(completedMatch.stats_processed, true);
  assert.equal(completedMatch.status, "finished");
});

test("a draw increments answer counts for both players without awarding a match win", async () => {
  const first = await signUp("draw-a");
  const second = await signUp("draw-b");
  await seedMatch(
    "match-draw",
    ["DrawOne", "DrawTwo"],
    [first.uid, second.uid],
    [
      { category: "History", results: [[true, true, false], [true, false, true]] },
      { category: "Science", results: [[true, false], [true, false]] }
    ],
    { friends: false }
  );

  const response = await callFunction({ match_id: "match-draw" }, first.token);
  assert.equal(response.status, 200);

  const firstProfile = (await db.doc(`users/${first.uid}`).get()).data();
  const secondProfile = (await db.doc(`users/${second.uid}`).get()).data();
  for (const profile of [firstProfile, secondProfile]) {
    assert.equal(profile.total_games, 1);
    assert.equal(profile.wins, 0);
    assert.equal(profile.losses, 0);
    assert.deepEqual(profile.friend_wins, {});
    assert.deepEqual(profile.category_stats, {
      History: { correct_answers: 2, total_answers: 3 },
      Science: { correct_answers: 1, total_answers: 2 }
    });
  }
  const completedMatch = (await db.doc("matches/match-draw").get()).data();
  assert.equal(completedMatch.stats_processed, true);
  assert.equal(completedMatch.status, "finished");
});

test("concurrent requests process statistics once", async () => {
  const first = await signUp("race-a");
  const second = await signUp("race-b");
  await seedMatch(
    "match-race",
    ["RaceOne", "RaceTwo"],
    [first.uid, second.uid],
    [{ category: "History", results: [[false], [true, true, true]] }],
    { friends: false }
  );

  const responses = await Promise.all([
    callFunction({ match_id: "match-race" }, first.token),
    callFunction({ match_id: "match-race" }, second.token)
  ]);
  assert.deepEqual(responses.map((response) => response.status), [200, 200]);

  const profile = (await db.doc(`users/${second.uid}`).get()).data();
  assert.equal(profile.total_games, 1);
  assert.equal(profile.wins, 1);
});
