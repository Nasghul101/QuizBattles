import assert from "node:assert/strict";
import { beforeEach, test } from "node:test";

import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

const projectId = "demo-quizbattles";
const authHost = process.env.AUTH_EMULATOR_HOST || "127.0.0.1:9099";
const functionsHost = process.env.FUNCTIONS_EMULATOR_HOST || "127.0.0.1:5001";
const authUrl = `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`;
const functionUrl = `http://${functionsHost}/${projectId}/us-central1/findRandomOpponent`;
const DAY_MS = 24 * 60 * 60 * 1000;

initializeApp({ projectId });
const db = getFirestore();

async function signUpWithProfile(username) {
  const response = await fetch(authUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      email: `${username}-${Date.now()}-${Math.random()}@example.invalid`,
      password: "Test-password-123!",
      returnSecureToken: true
    })
  });
  assert.equal(response.status, 200);
  const body = await response.json();
  await db.doc(`users/${body.localId}`).set({ uid: body.localId, username });
  return { uid: body.localId, token: body.idToken, username };
}

async function search(player) {
  const response = await fetch(functionUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${player.token}` },
    body: "{}"
  });
  return { status: response.status, body: await response.json() };
}

async function matchesOf(player) {
  return (await db.collection("matches").where("participant_uids", "array-contains", player.uid).get()).size;
}

async function clearCollection(name) {
  const snapshot = await db.collection(name).get();
  await Promise.all(snapshot.docs.map((doc) => doc.ref.delete()));
}

beforeEach(async () => {
  await clearCollection("random_searches");
});

test("a request without a token is rejected", async () => {
  const response = await fetch(functionUrl, { method: "POST", body: "{}" });
  assert.equal(response.status, 401);
});

test("the first request stores a search, the second pairs and the last presser starts", async () => {
  const first = await signUpWithProfile("RandomFirst");
  const second = await signUpWithProfile("RandomSecond");

  const firstResult = await search(first);
  assert.equal(firstResult.body.status, "searching");
  assert.equal((await db.doc(`random_searches/${first.uid}`).get()).exists, true);

  const secondResult = await search(second);
  assert.equal(secondResult.body.status, "matched");

  const match = (await db.doc(`matches/${secondResult.body.match_id}`).get()).data();
  assert.equal(match.mode, "random");
  assert.deepEqual(match.config, { rounds: 5, questions: 3 });
  assert.equal(match.rounds_data.length, 5);
  assert.equal(match.current_turn, "RandomSecond");
  assert.equal(match.inviter, "RandomSecond");
  assert.deepEqual(match.participant_uids, [second.uid, first.uid]);
  assert.equal((await db.doc(`random_searches/${first.uid}`).get()).exists, false);
});

test("a repeated request keeps a single search", async () => {
  const player = await signUpWithProfile("RandomRepeat");
  await search(player);
  const again = await search(player);

  assert.equal(again.body.status, "searching");
  assert.equal((await db.doc(`random_searches/${player.uid}`).get()).exists, true);
  assert.equal(await matchesOf(player), 0);
});

test("an expired search is not paired and is replaced", async () => {
  const stale = await signUpWithProfile("RandomStale");
  const fresh = await signUpWithProfile("RandomFresh");
  await db.doc(`random_searches/${stale.uid}`).set({
    uid: stale.uid,
    username: stale.username,
    created_at: Date.now() - DAY_MS - 1000
  });

  const result = await search(fresh);
  assert.equal(result.body.status, "searching");
  assert.equal(await matchesOf(fresh), 0);
  assert.equal((await db.doc(`random_searches/${fresh.uid}`).get()).exists, true);
});

test("players with an active match are not paired with each other, but can pair with others or again after it ends", async () => {
  const a = await signUpWithProfile("RandomPairA");
  const b = await signUpWithProfile("RandomPairB");
  const c = await signUpWithProfile("RandomPairC");

  await search(a);
  const firstMatch = await search(b);
  assert.equal(firstMatch.body.status, "matched");

  // A and B have an active match: B's new search must not take A's search.
  await search(a);
  const blocked = await search(b);
  assert.equal(blocked.body.status, "searching");
  assert.equal(await matchesOf(a), 1);
  assert.equal((await db.doc(`random_searches/${a.uid}`).get()).exists, true);

  // C is not an opponent of A, so C takes A's waiting search.
  const withOther = await search(c);
  assert.equal(withOther.body.status, "matched");
  assert.equal(await matchesOf(a), 2);

  // Once the first match is over, A can take B's waiting search again.
  await db.doc(`matches/${firstMatch.body.match_id}`).update({ status: "finished" });
  const again = await search(a);
  assert.equal(again.body.status, "matched");
  assert.notEqual(again.body.match_id, firstMatch.body.match_id);
});
