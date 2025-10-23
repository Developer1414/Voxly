import { AccessToken } from "livekit-server-sdk";
import crypto from "crypto";
import redisClient from "./redisClient.mjs";
import { LIVEKIT_API_KEY, LIVEKIT_API_SECRET } from "./config.mjs";

export const WAITING_USERS_KEY = "waiting_users";
export const USER_DATA_PREFIX = "user:";
export const ROOM_DATA_PREFIX = "room:";
export const USER_ROOM_PREFIX = "user_room:";

export function generateRoomName() {
  return `room-${crypto.randomUUID()}`;
}

export async function createToken(roomName, userName) {
  const at = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, {
    identity: userName,
    ttl: "60m",
  });
  at.addGrant({
    roomJoin: true,
    room: roomName,
    canPublish: true,
    canSubscribe: true,
  });

  const token = at.toJwt();

  if (typeof token !== "string" || token.length === 0) {
    console.error(
      "ОШИБКА ГЕНЕРАЦИИ ТОКЕНА LIVEKIT: Токен не является строкой."
    );
    throw new Error("Не удалось сгенерировать токен доступа LiveKit.");
  }

  return token;
}

export async function cleanupUserSession(socketId, io) {
  try {
    const removedCount = await redisClient.lRem(WAITING_USERS_KEY, 1, socketId);
    if (removedCount > 0) {
      console.log(`Пользователь ${socketId} удален из очереди ожидания.`);
      await redisClient.del(`${USER_DATA_PREFIX}${socketId}`);
      return;
    }

    const roomName = await redisClient.get(`${USER_ROOM_PREFIX}${socketId}`);
    if (!roomName) return;

    const roomDataRaw = await redisClient.get(`${ROOM_DATA_PREFIX}${roomName}`);
    if (!roomDataRaw) return;

    const roomUsers = JSON.parse(roomDataRaw);
    const partnerSocketId = roomUsers.find((id) => id !== socketId);

    if (partnerSocketId) {
      io.to(partnerSocketId).emit("ended", { reason: "partner_disconnected" });
      console.log(
        `Партнер ${partnerSocketId} уведомлен о завершении комнаты ${roomName}.`
      );
    }

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
