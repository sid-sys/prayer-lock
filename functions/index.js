const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

// The key lives in Firebase Secret Manager. It is never written in code.
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

const LEVELS = ["distant", "struggling", "okay", "close", "very close"];
const FEELINGS = [
  "Grateful", "Anxious", "Tired", "Hopeful",
  "Sad", "Stressed", "Peaceful", "Lost",
];

exports.generatePrayer = onCall(
  { secrets: [OPENAI_API_KEY], region: "us-central1", maxInstances: 10 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in first.");
    }
    const rel = Number(request.data.relationship);
    const feeling = String(request.data.feeling || "");
    if (!(rel >= 1 && rel <= 5) || !FEELINGS.includes(feeling)) {
      throw new HttpsError("invalid-argument", "Bad input.");
    }

    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${OPENAI_API_KEY.value()}`,
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        max_tokens: 150,
        temperature: 0.8,
        messages: [
          {
            role: "system",
            content:
              "You write short Christian prayers (3 to 5 sentences, under 70 words) " +
              "for a person to read out loud. Use simple words, warm tone, first person. " +
              "End with Amen. Output only the prayer.",
          },
          {
            role: "user",
            content: `My relationship with God today feels ${LEVELS[rel - 1]}. I feel ${feeling.toLowerCase()}.`,
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
