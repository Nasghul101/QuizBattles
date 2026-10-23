import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { after, before, beforeEach, test } from "node:test";

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment
} from "@firebase/rules-unit-testing";
import {
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc
} from "firebase/firestore";

const projectId = "demo-quizbattles";
let testEnvironment;

before(async () => {
  testEnvironment = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules: await readFile(new URL("../../firestore.rules", import.meta.url), "utf8")
    }
  });
});

beforeEach(async () => {
  await testEnvironment.clearFirestore();
});

after(async () => {
  await testEnvironment.cleanup();
});

function profile(uid, username) {
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

async function seedUser(uid, username) {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `users/${uid}`), profile(uid, username));
  });
}

function authenticatedDb(uid) {
  return testEnvironment.authenticatedContext(uid).firestore();
}

test("public profiles are readable, but private fields and client statistics are denied", async () => {
  await seedUser("profile-owner", "ProfileOwner");
  const anonymousDb = testEnvironment.unauthenticatedContext().firestore();
  const ownerDb = authenticatedDb("profile-owner");

  await assertSucceeds(getDoc(doc(anonymousDb, "users/profile-owner")));
  await assertFails(setDoc(doc(ownerDb, "users/profile-owner"), {
    ...profile("profile-owner", "ProfileOwner"),
    email: "private@example.com"
  }));
  await assertSucceeds(updateDoc(doc(ownerDb, "users/profile-owner"), {
    avatar_path: "res://assets/avatars/updated.png"
  }));
  await assertFails(updateDoc(doc(ownerDb, "users/profile-owner"), { wins: 1 }));
  await assertFails(deleteDoc(doc(ownerDb, "users/profile-owner")));
});

test("username claims are unique and required to create a default profile", async () => {
  const ownerDb = authenticatedDb("new-owner");
  const claim = {
    uid: "new-owner",
    username: "UniqueName",
    username_normalized: "uniquename"
  };

  await assertFails(setDoc(doc(ownerDb, "users/new-owner"), profile("new-owner", "UniqueName")));
  await assertSucceeds(setDoc(doc(ownerDb, "usernames/uniquename"), claim));
  await assertSucceeds(setDoc(doc(ownerDb, "users/new-owner"), profile("new-owner", "UniqueName")));
  await assertFails(setDoc(doc(authenticatedDb("second-owner"), "usernames/uniquename"), {
    ...claim,
    uid: "second-owner"
  }));
  await assertFails(updateDoc(doc(ownerDb, "usernames/uniquename"), { uid: "second-owner" }));
});

test("notifications are recipient-scoped and recipients can only change read state", async () => {
  await seedUser("notification-recipient", "Recipient");
  const notification = {
    recipient_uid: "notification-recipient",
    sender_uid: "notification-sender",
    message: "A friend request",
    action_data: { sender_uid: "notification-sender" },
    has_actions: true,
    is_read: false,
    created_at: Timestamp.now()
  };
  const senderDb = authenticatedDb("notification-sender");
  const recipientDb = authenticatedDb("notification-recipient");
  const outsiderDb = authenticatedDb("notification-outsider");
  const notificationRef = doc(senderDb, "notifications/request-1");

  await assertSucceeds(setDoc(notificationRef, notification));
  await assertSucceeds(getDoc(doc(recipientDb, "notifications/request-1")));
  await assertFails(getDoc(doc(outsiderDb, "notifications/request-1")));
  await assertFails(updateDoc(doc(senderDb, "notifications/request-1"), { is_read: true }));
  await assertSucceeds(updateDoc(doc(recipientDb, "notifications/request-1"), { is_read: true }));
  await assertFails(updateDoc(doc(recipientDb, "notifications/request-1"), {
    message: "Changed by recipient",
    is_read: true
  }));
});

test("friendships use a canonical sorted pair and are visible only to participants", async () => {
  await seedUser("friend-a", "FriendA");
  await seedUser("friend-b", "FriendB");
  const participantDb = authenticatedDb("friend-a");
  const otherParticipantDb = authenticatedDb("friend-b");
  const outsiderDb = authenticatedDb("friend-outsider");
  const friendship = {
    participant_uids: ["friend-a", "friend-b"],
    created_at: Timestamp.now()
  };

  await assertSucceeds(setDoc(doc(participantDb, "friendships/friend-a_friend-b"), friendship));
  await assertSucceeds(getDoc(doc(otherParticipantDb, "friendships/friend-a_friend-b")));
  await assertFails(getDoc(doc(outsiderDb, "friendships/friend-a_friend-b")));
  await assertFails(setDoc(doc(participantDb, "friendships/friend-b_friend-a"), {
    ...friendship,
    participant_uids: ["friend-b", "friend-a"]
  }));
  await assertFails(updateDoc(doc(participantDb, "friendships/friend-a_friend-b"), {
    participant_uids: ["friend-a", "friend-outsider"]
  }));
  await assertSucceeds(deleteDoc(doc(otherParticipantDb, "friendships/friend-a_friend-b")));
});

test("matches are restricted to participants and clients cannot process statistics", async () => {
  await seedUser("match-a", "MatchA");
  await seedUser("match-b", "MatchB");
  const participantDb = authenticatedDb("match-a");
  const outsiderDb = authenticatedDb("match-outsider");
  const match = {
    match_id: "match-1",
    participant_uids: ["match-a", "match-b"],
    status: "waiting",
    stats_processed: false
  };
  const matchRef = doc(participantDb, "matches/match-1");

  await assertSucceeds(setDoc(matchRef, match));
  await assertSucceeds(getDoc(matchRef));
  await assertFails(getDoc(doc(outsiderDb, "matches/match-1")));
  await assertFails(setDoc(doc(outsiderDb, "matches/match-2"), {
    ...match,
    match_id: "match-2"
  }));
  await assertSucceeds(updateDoc(matchRef, { status: "in_progress" }));
  await assertFails(updateDoc(matchRef, { stats_processed: true }));
  await assertFails(updateDoc(matchRef, { participant_uids: ["match-a", "match-outsider"] }));
});
