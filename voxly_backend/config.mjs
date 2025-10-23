import dotenv from "dotenv";

dotenv.config();

const requiredEnv = [
  "PORT",
  "REDIS_URL",
  "LIVEKIT_URL",
  "LIVEKIT_API_KEY",
  "LIVEKIT_API_SECRET",
  "OPENROUTER_API_KEY",
];

const missingEnv = requiredEnv.filter((key) => !process.env[key]);

if (missingEnv.length > 0) {
  console.error(
    `\nОшибка запуска: Отсутствуют необходимые переменные окружения: ${missingEnv.join(
      ", "
    )}\n` +
      `Убедитесь, что они заданы в GitHub Secrets ИЛИ в вашем локальном .env файле.\n`
  );
  process.exit(1);
}

export const PORT = process.env.PORT;
export const REDIS_URL = process.env.REDIS_URL;
export const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
export const LIVEKIT_URL = process.env.LIVEKIT_URL;
export const LIVEKIT_API_KEY = process.env.LIVEKIT_API_KEY;
export const LIVEKIT_API_SECRET = process.env.LIVEKIT_API_SECRET;
