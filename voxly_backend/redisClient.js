import { createClient } from "redis";
import { REDIS_URL } from "./config.js";

const redisClient = createClient({ url: REDIS_URL });

redisClient.on("connect", () => console.log("Подключено к Redis"));
redisClient.on("error", (err) => console.error("Ошибка Redis:", err));

(async () => {
  await redisClient.connect();
})();

export default redisClient;
