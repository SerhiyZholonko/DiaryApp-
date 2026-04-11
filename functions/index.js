// MARK: - DiaryApp Cloud Functions
// generateAIInsight: HTTPS-ендпоінт між iOS-клієнтом і Gemini API.
// Gemini API ключ зберігається в Google Cloud Secret Manager — клієнт його не бачить.
//
// Деплой:
//   cd functions && npm install
//   firebase functions:secrets:set GEMINI_API_KEY   ← вводиш ключ один раз
//   firebase deploy --only functions

const functions = require("firebase-functions/v1");
const admin     = require("firebase-admin");

admin.initializeApp();

// ─────────────────────────────────────────────
// sendDailyReminders
// Запускається щохвилини. Знаходить юзерів,
// у яких UTC-час нагадування збігається з поточним,
// і шле FCM push.
// ─────────────────────────────────────────────
exports.sendDailyReminders = functions.pubsub
  .schedule("every 1 minutes")
  .onRun(async () => {
    const now = new Date();
    const utcHour   = now.getUTCHours();
    const utcMinute = now.getUTCMinutes();

    const snapshot = await admin.firestore()
      .collection("users")
      .where("reminderEnabled", "==", true)
      .where("reminderHour",    "==", utcHour)
      .where("reminderMinute",  "==", utcMinute)
      .get();

    if (snapshot.empty) return null;

    const sends = snapshot.docs.map(async doc => {
      const { fcmToken, language } = doc.data();
      if (!fcmToken) return;

      // Атомарно інкрементуємо badgeCount і читаємо нове значення
      const newBadge = await admin.firestore().runTransaction(async t => {
        const snap = await t.get(doc.ref);
        const current = (snap.data().badgeCount ?? 0) + 1;
        t.update(doc.ref, { badgeCount: current });
        return current;
      });

      const isUk = language === "uk";
      const message = {
        token: fcmToken,
        notification: {
          title: isUk ? "Час записати свій день 📖" : "Time to write your day 📖",
          body:  isUk
            ? "Як пройшов твій день? Запиши свої думки у щоденнику."
            : "How was your day? Write your thoughts in the diary.",
        },
        apns: { payload: { aps: { sound: "default", badge: newBadge } } },
      };

      return admin.messaging().send(message)
        .catch(err => {
          console.error(`[FCM] failed for ${doc.id}:`, err.message);
          if (err.code === "messaging/registration-token-not-registered") {
            return doc.ref.update({ reminderEnabled: false });
          }
        });
    });

    await Promise.allSettled(sends);
    return null;
  });

const GEMINI_MODEL    = "gemini-2.5-flash";
const GEMINI_ENDPOINT = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;
const MAX_PROMPT_LEN  = 8000;

/**
 * HTTPS POST /generateAIInsight
 *
 * Headers:
 *   Authorization: Bearer <Firebase ID Token>
 *   Content-Type: application/json
 *
 * Body:   { "prompt": "..." }
 * Result: { "text": "..." }
 * Error:  { "error": "..." }
 */
exports.generateAIInsight = functions
  .runWith({ secrets: ["GEMINI_API_KEY"] })
  .https.onRequest(async (req, res) => {

    // CORS (на випадок веб-клієнта)
    res.set("Access-Control-Allow-Origin", "*");
    if (req.method === "OPTIONS") {
      res.set("Access-Control-Allow-Methods", "POST");
      res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    // 1. Перевірка Firebase ID Token
    const authHeader = req.headers["authorization"] ?? "";
    if (!authHeader.startsWith("Bearer ")) {
      res.status(401).json({ error: "Відсутній або невірний токен авторизації." });
      return;
    }
    const idToken = authHeader.slice(7);
    try {
      await admin.auth().verifyIdToken(idToken);
    } catch {
      res.status(401).json({ error: "Токен авторизації недійсний або протермінований." });
      return;
    }

    // 2. Валідація тіла запиту
    const prompt = req.body?.prompt;
    if (typeof prompt !== "string" || !prompt.trim()) {
      res.status(400).json({ error: "Поле prompt не може бути порожнім." });
      return;
    }
    if (prompt.length > MAX_PROMPT_LEN) {
      res.status(400).json({ error: "Запит занадто великий." });
      return;
    }

    // 3. Виклик Gemini
    const apiKey = process.env.GEMINI_API_KEY;
    let geminiRes;
    try {
      geminiRes = await fetch(`${GEMINI_ENDPOINT}?key=${apiKey}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            maxOutputTokens: 500,
            temperature: 0.8,
            thinkingConfig: { thinkingBudget: 0 },
          },
        }),
      });
    } catch (networkErr) {
      console.error("Network error →", networkErr);
      res.status(503).json({ error: "Помилка мережі при зверненні до Gemini." });
      return;
    }

    if (!geminiRes.ok) {
      console.error("Gemini HTTP error:", geminiRes.status);
      if (geminiRes.status === 429) {
        res.status(429).json({ error: "Перевищено ліміт запитів Gemini. Спробуйте пізніше." });
      } else {
        res.status(502).json({ error: `Gemini відповів з помилкою: ${geminiRes.status}` });
      }
      return;
    }

    // 4. Парсинг відповіді
    // Gemini 2.5 Flash повертає кілька parts: thinking (thought:true) + відповідь.
    // Беремо перший part де thought != true.
    const json = await geminiRes.json();
    const parts = json?.candidates?.[0]?.content?.parts ?? [];
    const answerPart = parts.find((p) => !p.thought) ?? parts[parts.length - 1];
    const text = answerPart?.text ?? "";
    if (!text) {
      res.status(502).json({ error: "Gemini повернув порожню відповідь." });
      return;
    }

    res.status(200).json({ text });
  });
