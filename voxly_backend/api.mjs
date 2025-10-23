import express from "express";
import { OPENROUTER_API_KEY } from "./config.mjs";

const apiRouter = express.Router();

async function handleGenerateHint(req, res) {
  const { prompt } = req.body;
  if (!prompt) {
    return res
      .status(400)
      .json({ error: "Отсутствует текст подсказки (prompt) в теле запроса." });
  }

  const model = "meituan/longcat-flash-chat:free";
  const openRouterUrl = "https://openrouter.ai/api/v1/chat/completions";

  try {
    const aiResponse = await fetch(openRouterUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${OPENROUTER_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: model,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    const data = await aiResponse.json();

    if (aiResponse.ok) {
      const hint = data.choices[0].message.content.toString().trim();
      res.json({ hint });
    } else {
      console.error("Ошибка API OpenRouter:", data);
      res.status(aiResponse.status).json({
        error: "Ошибка генерации подсказки AI.",
        details: data.error?.message || "Неизвестная ошибка.",
      });
    }
  } catch (error) {
    console.error("Ошибка подключения к OpenRouter:", error);
    res.status(500).json({ error: "Внутренняя ошибка сервера AI." });
  }
}

apiRouter.post("/generate-hint", handleGenerateHint);

export default apiRouter;
