"use strict";

const { initializeApp, getApps } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const { onRequest } = require("firebase-functions/v2/https");

if (getApps().length === 0) {
  initializeApp();
}

class StatisticsError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

function countCorrectAnswers(match, username) {
  let score = 0;
  for (const round of match.rounds_data || []) {
    const results = round.player_answers?.[username]?.results || [];
    score += results.filter((result) => result?.was_correct === true).length;
  }
  return score;
}

function ensureProfileStats(profile) {
  return {
    wins: profile.wins || 0,
    losses: profile.losses || 0,
    total_games: profile.total_games || 0,
    current_streak: profile.current_streak || 0,
    friend_wins: { ...(profile.friend_wins || {}) },
    category_stats: structuredClone(profile.category_stats || {}),
  };
}

// Applies a finished match to both profiles and marks the match processed in one transaction.
// `match.players[i]` is the username of `match.participant_uids[i]`.
async function processMatchStatistics(db, matchId, callerUid) {
  const matchRef = db.collection("matches").doc(matchId);

  return db.runTransaction(async (transaction) => {
    const matchSnapshot = await transaction.get(matchRef);
    if (!matchSnapshot.exists) {
      throw new StatisticsError(404, "Match not found.");
    }

    const match = matchSnapshot.data();
    const uids = match.participant_uids;
    const players = match.players;
    if (
      !Array.isArray(uids) || uids.length !== 2 || uids[0] === uids[1] ||
      !Array.isArray(players) || players.length !== 2 || players[0] === players[1]
    ) {
      throw new StatisticsError(400, "Match has invalid participants.");
    }
    if (!uids.includes(callerUid)) {
      throw new StatisticsError(403, "Caller is not a participant of this match.");
    }
    if (!Array.isArray(match.rounds_data)) {
      throw new StatisticsError(400, "Match has no round data.");
    }
    if (match.stats_processed === true) {
      return { processed: false, already_processed: true };
    }

    const refs = uids.map((uid) => db.collection("users").doc(uid));
    const friendshipRef = db.collection("friendships").doc([...uids].sort().join("_"));
    const [profile1Snapshot, profile2Snapshot, friendshipSnapshot] = await Promise.all([
      transaction.get(refs[0]),
      transaction.get(refs[1]),
      transaction.get(friendshipRef),
    ]);
    if (!profile1Snapshot.exists || !profile2Snapshot.exists) {
      throw new StatisticsError(404, "A participant profile was not found.");
    }

    const profiles = [
      ensureProfileStats(profile1Snapshot.data()),
      ensureProfileStats(profile2Snapshot.data()),
    ];
    profiles.forEach((profile) => {
      profile.total_games += 1;
    });

    const categories = match.rounds_data
      .map((round) => round?.category)
      .filter((category) => typeof category === "string" && category !== "");
    for (const profile of profiles) {
      for (const category of categories) {
        const stats = profile.category_stats[category] || { played: 0, wins: 0 };
        profile.category_stats[category] = { played: stats.played + 1, wins: stats.wins };
      }
    }

    const score1 = countCorrectAnswers(match, players[0]);
    const score2 = countCorrectAnswers(match, players[1]);
    if (score1 !== score2) {
      const winnerIndex = score1 > score2 ? 0 : 1;
      const loserIndex = 1 - winnerIndex;
      const winner = profiles[winnerIndex];
      const loser = profiles[loserIndex];

      winner.wins += 1;
      winner.current_streak += 1;
      loser.losses += 1;
      loser.current_streak = 0;
      for (const category of categories) {
        winner.category_stats[category].wins += 1;
      }
      if (friendshipSnapshot.exists) {
        const loserName = players[loserIndex];
        winner.friend_wins[loserName] = (winner.friend_wins[loserName] || 0) + 1;
      }
    }

    transaction.update(refs[0], profiles[0]);
    transaction.update(refs[1], profiles[1]);
    transaction.update(matchRef, { stats_processed: true });
    return { processed: true, already_processed: false };
  });
}

async function authenticate(request) {
  const header = request.get("Authorization") || "";
  const token = /^Bearer (.+)$/.exec(header);
  if (!token) {
    throw new StatisticsError(401, "Missing Firebase ID token.");
  }
  try {
    return (await getAuth().verifyIdToken(token[1])).uid;
  } catch {
    throw new StatisticsError(401, "Invalid Firebase ID token.");
  }
}

exports.processMatchStatistics = onRequest(async (request, response) => {
  try {
    if (request.method !== "POST") {
      throw new StatisticsError(405, "Use POST.");
    }
    const callerUid = await authenticate(request);
    const matchId = request.body?.match_id;
    if (typeof matchId !== "string" || matchId === "" || matchId.includes("/")) {
      throw new StatisticsError(400, "A valid match_id is required.");
    }
    response.status(200).json(await processMatchStatistics(getFirestore(), matchId, callerUid));
  } catch (error) {
    if (error instanceof StatisticsError) {
      response.status(error.status).json({ error: error.message });
      return;
    }
    console.error(error);
    response.status(500).json({ error: "Statistics processing failed." });
  }
});
