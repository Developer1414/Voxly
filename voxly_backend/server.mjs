import express from "express";
import { Server as SocketIOServer } from "socket.io";
import { AccessToken } from "livekit-server-sdk";
import dotenv from "dotenv";
import cors from "cors";
import { createClient } from "redis";
import crypto from "crypto";
import { json } from "node:stream/consumers";

// --- 1. Конфигурация и проверка переменных окружения ---
dotenv.config();

const { PORT, REDIS_URL, LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET } =
  process.env;

// Валидация: убедимся, что все переменные заданы, иначе завершаем работу
const requiredEnv = [
  "PORT",
  "LIVEKIT_URL",
  "LIVEKIT_API_KEY",
  "LIVEKIT_API_SECRET",
];
const missingEnv = requiredEnv.filter((key) => !process.env[key]);

if (missingEnv.length > 0) {
  console.error(
    `Ошибка: Отсутствуют необходимые переменные окружения: ${missingEnv.join(
      ", "
    )}`
  );
  process.exit(1);
}

// --- 2. Инициализация сервисов ---
const app = express();
app.use(express.json());
app.use(cors());

const server = app.listen(PORT, () =>
  console.log(`HTTP сервер запущен на порту ${PORT}`)
);

const io = new SocketIOServer(server, {
  cors: {
    origin: "*", // В production лучше указать конкретный домен
    methods: ["GET", "POST"],
  },
});

// --- 3. Подключение к Redis ---
const redisClient = createClient({ url: REDIS_URL });

redisClient.on("connect", () => console.log("Подключено к Redis"));
redisClient.on("error", (err) => console.error("Ошибка Redis:", err));
// Оборачиваем connect в async IIFE, чтобы использовать await
(async () => {
  await redisClient.connect();
})();

// Ключи для хранения данных в Redis
const WAITING_USERS_KEY = "waiting_users"; // Список ID сокетов ожидающих пользователей
const USER_DATA_PREFIX = "user:"; // Префикс для хранения данных пользователя (userName)
const ROOM_DATA_PREFIX = "room:"; // Префикс для хранения данных о комнате
const USER_ROOM_PREFIX = "user_room:"; // Префикс для связи user_id -> room_name

// --- 4. Вспомогательные функции ---

/**
 * Создает токен доступа LiveKit для пользователя.
 * @param {string} roomName - Имя комнаты.
 * @param {string} userName - Имя пользователя.
 * @returns {string} - Сгенерированный JWT.
 */

async function createToken(roomName, userName) {
  const at = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, {
    identity: userName,
    ttl: "60m", // Токен действителен 60 минут
  });
  at.addGrant({
    roomJoin: true,
    room: roomName,
    canPublish: true,
    canSubscribe: true,
  });

  const token = await at.toJwt();

  // УЛУЧШЕНИЕ: Проверяем, что токен успешно сгенерирован как строка.
  if (typeof token !== "string" || token.length === 0) {
    console.error(
      "ОШИБКА ГЕНЕРАЦИИ ТОКЕНА LIVEKIT: Токен не является строкой. " +
        "Убедитесь, что ключи API в .env файле корректны и не содержат лишних пробелов."
    );
    throw new Error("Не удалось сгенерировать токен доступа LiveKit.");
  }

  return token;
}

/**
 * Очищает сессию пользователя: удаляет из очереди, закрывает активную комнату.
 * @param {string} socketId - ID сокета пользователя.
 */
async function cleanupUserSession(socketId) {
  try {
    // 1. Пытаемся удалить пользователя из списка ожидания
    const removedCount = await redisClient.lRem(WAITING_USERS_KEY, 1, socketId);
    if (removedCount > 0) {
      console.log(`Пользователь ${socketId} удален из очереди ожидания.`);
      await redisClient.del(`${USER_DATA_PREFIX}${socketId}`);
      return;
    }

    // 2. Если пользователя не было в очереди, ищем его активную комнату
    const roomName = await redisClient.get(`${USER_ROOM_PREFIX}${socketId}`);
    if (!roomName) return; // У пользователя нет активной комнаты

    const roomDataRaw = await redisClient.get(`${ROOM_DATA_PREFIX}${roomName}`);
    if (!roomDataRaw) return;

    const roomUsers = JSON.parse(roomDataRaw);
    const partnerSocketId = roomUsers.find((id) => id !== socketId);

    // 3. Уведомляем партнера о завершении чата
    if (partnerSocketId) {
      io.to(partnerSocketId).emit("ended", { reason: "partner_disconnected" });
      console.log(
        `Пользователь ${partnerSocketId} уведомлен о завершении комнаты ${roomName}`
      );
    }

    // 4. Удаляем всю информацию о комнате и пользователях из Redis
    await redisClient.del(`${ROOM_DATA_PREFIX}${roomName}`);
    await redisClient.del(`${USER_ROOM_PREFIX}${socketId}`);
    if (partnerSocketId) {
      await redisClient.del(`${USER_ROOM_PREFIX}${partnerSocketId}`);
      await redisClient.del(`${USER_DATA_PREFIX}${partnerSocketId}`);
    }
    await redisClient.del(`${USER_DATA_PREFIX}${socketId}`);

    console.log(`Комната ${roomName} и ее данные полностью удалены.`);
  } catch (error) {
    console.error(`Ошибка при очистке сессии для ${socketId}:`, error);
  }
}

// --- 5. Логика Socket.IO ---
io.on("connection", async (socket) => {
  console.log(`Пользователь подключен: ${socket.id}`);

  socket.on("find", async (data) => {
    try {
      // Валидация имени пользователя
      const userName = data?.userName?.trim();
      if (!userName || userName.length < 2 || userName.length > 20) {
        socket.emit("error", { message: "Некорректное имя пользователя." });
        return;
      }

      // Ищем партнера в очереди (FIFO: берем первого, кто вошел)
      const partnerSocketId = await redisClient.lPop(WAITING_USERS_KEY);

      if (!partnerSocketId) {
        // Если партнера нет, добавляем текущего пользователя в конец очереди (FIFO)
        await redisClient.set(`${USER_DATA_PREFIX}${socket.id}`, userName);
        await redisClient.rPush(WAITING_USERS_KEY, socket.id);
        socket.emit("waiting");
        console.log(
          `Пользователь ${userName} (${socket.id}) добавлен в очередь.`
        );
      } else {
        // Партнер найден! Создаем комнату.
        const partnerUserName = await redisClient.get(
          `${USER_DATA_PREFIX}${partnerSocketId}`
        );
        if (!partnerUserName) {
          // Если данные партнера почему-то отсутствуют, возвращаем его в начало очереди и пробуем найти снова для текущего
          await redisClient.lPush(WAITING_USERS_KEY, partnerSocketId); // lPush чтобы он был следующим
          socket.emit("find", data); // Рекурсивный вызов для поиска другого партнера
          return;
        }

        const roomName = `room-${crypto.randomUUID()}`;
        console.log(
          `Создана комната ${roomName} для ${userName} и ${partnerUserName}`
        );

        // Генерируем токены
        const token1 = await createToken(roomName, userName);
        const token2 = await createToken(roomName, partnerUserName);

        // Сохраняем информацию о комнате в Redis
        await redisClient.set(
          `${ROOM_DATA_PREFIX}${roomName}`,
          JSON.stringify([socket.id, partnerSocketId])
        );
        await redisClient.set(`${USER_ROOM_PREFIX}${socket.id}`, roomName);
        await redisClient.set(
          `${USER_ROOM_PREFIX}${partnerSocketId}`,
          roomName
        );

        // Отправляем данные для подключения обоим пользователям
        socket.emit("match", {
          roomName,
          liveKitUrl: LIVEKIT_URL,
          token: token1,
          partner: partnerUserName,
        });
        io.to(partnerSocketId).emit("match", {
          roomName,
          liveKitUrl: LIVEKIT_URL,
          token: token2,
          partner: userName,
        });
      }
    } catch (error) {
      console.error('Ошибка в обработчике "find":', error);
      socket.emit("error", { message: "Произошла внутренняя ошибка сервера." });
    }
  });

  socket.on("end", async () => {
    console.log(`Пользователь ${socket.id} инициировал завершение чата.`);
    await cleanupUserSession(socket.id);
  });

  socket.on("disconnect", async () => {
    console.log(`Пользователь отключен: ${socket.id}`);
    await cleanupUserSession(socket.id);
  });
});
