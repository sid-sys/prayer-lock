const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

// The key lives in Firebase Secret Manager. It is never written in code.
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

const LEVELS = ["distant", "struggling", "okay", "close", "very close"];
const FEELINGS = [
  "Grateful", "Anxious", "Tired", "Hopeful",
  "Sad", "Stressed", "Peaceful", "Lost",
];

const STYLE = {
  morning:
    "A morning prayer to Jesus: gratitude for the new day, surrender, and guidance for today.",
  night:
    "A night prayer to Jesus: thanks for the day, forgiveness, releasing worries, and peaceful rest.",
  gate:
    "A short prayer to pause before using the phone: a moment with God, focus, and wise use of time.",
};

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
        max_tokens: 160,
        temperature: 0.8,
        messages: [
          {
            role: "system",
            content:
              "You write short Christian prayers (3 to 5 sentences, under 75 words) " +
              "for a person to read out loud. Use simple words, warm tone, first person. " +
              STYLE[kind] +
              " End with Amen. Output only the prayer.",
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
