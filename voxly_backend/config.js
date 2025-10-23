import dotenv from "dotenv";

dotenv.config();

export const PORT = process.env.PORT;
export const REDIS_URL = process.env.REDIS_URL;
export const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
export const LIVEKIT_URL = process.env.LIVEKIT_URL;
export const LIVEKIT_API_KEY = process.env.LIVEKIT_API_KEY;
export const LIVEKIT_API_SECRET = process.env.LIVEKIT_API_SECRET;
