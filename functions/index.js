"use strict";

const { initializeApp, getApps } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const RANDOM_SEARCH_TTL_MS = 24 * 60 * 60 * 1000;
const RANDOM_SEARCH_SCAN_LIMIT = 100;
const RANDOM_MATCH_ROUNDS = 5;
const RANDOM_MATCH_QUESTIONS = 3;
const FEEDBACK_MIN_INTERVAL_MS = 30000;
const FEEDBACK_DAILY_LIMIT = 50;

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

function updateCategoryAnswerStats(profiles, match, players) {
  for (const round of match.rounds_data) {
    const category = round?.category;
    if (typeof category !== "string" || category === "") {
      continue;
    }

    for (let playerIndex = 0; playerIndex < players.length; playerIndex += 1) {
      const results = round.player_answers?.[players[playerIndex]]?.results;
      if (!Array.isArray(results) || results.length === 0) {
        continue;
      }

      const profile = profiles[playerIndex];
      const existingStats = profile.category_stats[category];
      const stats = Number.isInteger(existingStats?.correct_answers) &&
        Number.isInteger(existingStats?.total_answers)
        ? existingStats
        : { correct_answers: 0, total_answers: 0 };

      for (const result of results) {
        stats.total_answers += 1;
        if (result?.was_correct === true) {
          stats.correct_answers += 1;
        }
      }
      profile.category_stats[category] = stats;
    }
  }
}

// Applies a finished match to both profiles and marks the match finished and processed atomically.
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

    updateCategoryAnswerStats(profiles, match, players);

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
      if (friendshipSnapshot.exists) {
        const loserName = players[loserIndex];
        winner.friend_wins[loserName] = (winner.friend_wins[loserName] || 0) + 1;
      }
    }

    transaction.update(refs[0], profiles[0]);
    transaction.update(refs[1], profiles[1]);
    transaction.update(matchRef, { status: "finished", stats_processed: true });
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

exports.sendFeedback = onRequest(async (request, response) => {
  try {
    if (request.method !== "POST") {
      throw new StatisticsError(405, "Use POST.");
    }
    const uid = await authenticate(request);
    const body = request.body || {};
    const feedbackType = body.feedback_type;
    const feedback = typeof body.feedback === "string" ? body.feedback.trim() : "";
    if (!Number.isInteger(feedbackType) || feedbackType < 0 || feedbackType > 3) {
      throw new StatisticsError(400, "feedback_type must be 0-3.");
    }
    if (feedback === "" || feedback.length > 5000) {
      throw new StatisticsError(400, "A feedback text is required.");
    }
    const answers = Array.isArray(body.answers) ? body.answers.slice(0, 4).map(String) : [];
    const db = getFirestore();
    const limitRef = db.collection("feedback_limits").doc(uid);
    const feedbackRef = db.collection("feedback").doc();
    const now = Date.now();

    await db.runTransaction(async (transaction) => {
      const limit = (await transaction.get(limitRef)).data() || {};
      const day = new Date(now).toISOString().slice(0, 10);
      const dailyCount = limit.day === day ? limit.count || 0 : 0;
      if (now - (limit.last_sent_ms || 0) < FEEDBACK_MIN_INTERVAL_MS) {
        throw new StatisticsError(429, "Please wait before sending more feedback.");
      }
      if (dailyCount >= FEEDBACK_DAILY_LIMIT) {
        throw new StatisticsError(429, "Daily feedback limit reached.");
      }
      transaction.set(limitRef, { day, count: dailyCount + 1, last_sent_ms: now });
      transaction.set(feedbackRef, {
        uid,
        question: String(body.question ?? "").slice(0, 1000),
        answers: answers.map((answer) => answer.slice(0, 500)),
        correct_answer: String(body.correct_answer ?? "").slice(0, 500),
        player_answer: String(body.player_answer ?? "").slice(0, 500),
        feedback_type: feedbackType,
        feedback,
        created_at: FieldValue.serverTimestamp(),
      });
    });
    response.status(200).json({ sent: true });
  } catch (error) {
    if (error instanceof StatisticsError) {
      response.status(error.status).json({ error: error.message });
      return;
    }
    console.error(error);
    response.status(500).json({ error: "Feedback could not be sent." });
  }
});

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

function buildRandomMatch(inviter, invitee) {
  const matchId = `match_${Math.floor(Date.now() / 1000)}_${Math.floor(Math.random() * 1000000)}`;
  const rounds = [];
  for (let i = 1; i <= RANDOM_MATCH_ROUNDS; i += 1) {
    rounds.push({
      round_number: i,
      category: "",
      category_chooser: i % 2 === 1 ? inviter.username : invitee.username,
      questions: [],
      player_answers: {
        [inviter.username]: { answered: false, results: [] },
        [invitee.username]: { answered: false, results: [] },
      },
    });
  }
  return {
    match_id: matchId,
    players: [inviter.username, invitee.username],
    participant_uids: [inviter.uid, invitee.uid],
    inviter: inviter.username,
    mode: "random",
    config: { rounds: RANDOM_MATCH_ROUNDS, questions: RANDOM_MATCH_QUESTIONS },
    current_turn: inviter.username,
    current_round: 1,
    status: "active",
    dismissed_by: [],
    stats_processed: false,
    rounds_data: rounds,
    created_at: Date.now() / 1000,
  };
}

// Pairs the caller with the oldest unexpired search of another player, or stores a search.
// The caller pressed last, so the caller becomes the inviter and plays first.
async function findRandomOpponent(db, callerUid) {
  const searches = db.collection("random_searches");
  const ownRef = searches.doc(callerUid);

  return db.runTransaction(async (transaction) => {
    const now = Date.now();
    const cutoff = now - RANDOM_SEARCH_TTL_MS;

    const callerSnap = await transaction.get(db.collection("users").doc(callerUid));
    const username = callerSnap.data()?.username;
    if (typeof username !== "string" || username === "") {
      throw new StatisticsError(400, "The caller has no profile.");
    }

    const ownSnap = await transaction.get(ownRef);
    if (ownSnap.exists && ownSnap.data().created_at > cutoff) {
      return { status: "searching" };
    }

    const callerMatches = await transaction.get(
      db.collection("matches").where("participant_uids", "array-contains", callerUid),
    );
    const currentOpponents = new Set();
    for (const matchDoc of callerMatches.docs) {
      if (matchDoc.data().status === "active") {
        matchDoc.data().participant_uids.forEach((uid) => currentOpponents.add(uid));
      }
    }

    const waiting = await transaction.get(
      searches.where("created_at", ">", cutoff).orderBy("created_at").limit(RANDOM_SEARCH_SCAN_LIMIT),
    );
    const opponentDoc = waiting.docs.find((doc) => doc.id !== callerUid && !currentOpponents.has(doc.id));

    if (!opponentDoc) {
      transaction.set(ownRef, { uid: callerUid, username, created_at: now });
      return { status: "searching" };
    }

    const opponent = { uid: opponentDoc.id, username: opponentDoc.data().username };
    const match = buildRandomMatch({ uid: callerUid, username }, opponent);
    transaction.delete(opponentDoc.ref);
    if (ownSnap.exists) {
      transaction.delete(ownRef);
    }
    transaction.set(db.collection("matches").doc(match.match_id), match);
    return { status: "matched", match_id: match.match_id };
  });
}

exports.findRandomOpponent = onRequest(async (request, response) => {
  try {
    if (request.method !== "POST") {
      throw new StatisticsError(405, "Use POST.");
    }
    const callerUid = await authenticate(request);
    response.status(200).json(await findRandomOpponent(getFirestore(), callerUid));
  } catch (error) {
    if (error instanceof StatisticsError) {
      response.status(error.status).json({ error: error.message });
      return;
    }
    console.error(error);
    response.status(500).json({ error: "Opponent search failed." });
  }
});

exports.expireRandomSearches = onSchedule("every 60 minutes", async () => {
  const db = getFirestore();
  const cutoff = Date.now() - RANDOM_SEARCH_TTL_MS;
  const expired = await db.collection("random_searches").where("created_at", "<=", cutoff).get();
  const batch = db.batch();
  expired.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
});
