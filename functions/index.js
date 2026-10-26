const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

// The key lives in Firebase Secret Manager. It is never written in code.
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

// Each account may ask for this many prayers per day (UTC day).
// This keeps the AI cost safe, even if someone tries to abuse the function.
const DAILY_LIMIT = 30;

const LEVELS = ["distant", "struggling", "okay", "close", "very close"];
const FEELINGS = [
  "Grateful", "Anxious", "Tired", "Hopeful",
  "Sad", "Stressed", "Peaceful", "Lost",
];

const STYLE = {
  morning:
    "A morning prayer to Jesus: gratitude for the new day and surrender. Humbly ask God for the strength " +
    "to follow Him and to love people today.",
  night:
    "A night prayer to Jesus: thanks for the day and forgiveness. Humbly ask God for the strength " +
    "to forgive, to let go of worries and to rest in Him.",
  gate:
    "A short prayer to pause before using the phone. Humbly admit weakness and beg God for the strength " +
    "to put Him first, to say no to distractions and to use time wisely.",
};

/** Count one prayer for this account today. Returns false if the limit is used up. */
async function takeOne(uid) {
  const db = getFirestore();
  const day = new Date().toISOString().slice(0, 10);
  const ref = db.collection("usage").doc(`${uid}_${day}`);
  return db.runTransaction(async (t) => {
    const snap = await t.get(ref);
    const used = snap.exists ? snap.data().count || 0 : 0;
    if (used >= DAILY_LIMIT) return false;
    t.set(
      ref,
      { uid, day, count: used + 1, updatedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );
    return true;
  });
}

exports.generatePrayer = onCall(
  { secrets: [OPENAI_API_KEY], region: "us-central1", maxInstances: 10 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in first.");
    }
    const rel = Number(request.data.relationship);
    const feeling = String(request.data.feeling || "");
    const kind = STYLE[request.data.kind] ? request.data.kind : "gate";
    if (!(rel >= 1 && rel <= 5) || (feeling && !FEELINGS.includes(feeling))) {
      throw new HttpsError("invalid-argument", "Bad input.");
    }

    // Daily limit per account.
    const allowed = await takeOne(request.auth.uid);
    if (!allowed) {
      throw new HttpsError(
        "resource-exhausted",
        "You have reached today's prayer limit. Please try again tomorrow."
      );
    }

    const feelText = feeling
      ? `I feel ${feeling.toLowerCase()}.`
      : "I prefer not to say how I feel.";

    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${OPENAI_API_KEY.value()}`,
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        max_tokens: 220,
        temperature: 0.8,
        messages: [
          {
            role: "system",
            content:
              "You write short Christian prayers (4 to 6 sentences, under 90 words) " +
              "for a person to read out loud. Use simple words, warm tone, first person. " +
              STYLE[kind] +
              " Include at least one sentence that asks God for strength. End with Amen. Output only the prayer.",
          },
          {
            role: "user",
            content: `My relationship with God today feels ${LEVELS[rel - 1]}. ${feelText}`,
          },
        ],
      }),
    });

    if (!res.ok) {
      throw new HttpsError("internal", "Prayer service failed.");
    }
    const json = await res.json();
    const prayer = json.choices?.[0]?.message?.content?.trim();
    if (!prayer) throw new HttpsError("internal", "Empty prayer.");
    return { prayer };
  }
);
