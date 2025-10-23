import redisClient from "./redisClient.js";
import {
  createToken,
  cleanupUserSession,
  generateRoomName,
  WAITING_USERS_KEY,
  USER_DATA_PREFIX,
  ROOM_DATA_PREFIX,
  USER_ROOM_PREFIX,
} from "./utils.js";
import { LIVEKIT_URL } from "./config.js";

async function handleFindMatch(socket, data, io) {
  try {
    const userName = data?.userName?.trim();
    if (!userName || userName.length < 2 || userName.length > 20) {
      socket.emit("error", { message: "Некорректное имя пользователя." });
      return;
    }

    const partnerSocketId = await redisClient.lPop(WAITING_USERS_KEY);

    if (!partnerSocketId) {
      await redisClient.set(`${USER_DATA_PREFIX}${socket.id}`, userName);
      await redisClient.rPush(WAITING_USERS_KEY, socket.id);
      socket.emit("waiting");
      console.log(
        `Пользователь ${userName} (${socket.id}) добавлен в очередь ожидания.`
      );
    } else {
      const partnerUserName = await redisClient.get(
        `${USER_DATA_PREFIX}${partnerSocketId}`
      );
      if (!partnerUserName) {
        await redisClient.lPush(WAITING_USERS_KEY, partnerSocketId);
        socket.emit("find", data);
        return;
      }

      const roomName = generateRoomName();
      console.log(
        `Создана комната ${roomName} для ${userName} и ${partnerUserName}`
      );

      const token1 = await createToken(roomName, userName);
      const token2 = await createToken(roomName, partnerUserName);

      await redisClient.set(
        `${ROOM_DATA_PREFIX}${roomName}`,
        JSON.stringify([socket.id, partnerSocketId])
      );
      await redisClient.set(`${USER_ROOM_PREFIX}${socket.id}`, roomName);
      await redisClient.set(`${USER_ROOM_PREFIX}${partnerSocketId}`, roomName);

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
}

export function setupSocketListeners(socket, io) {
  console.log(`Пользователь подключен: ${socket.id}`);

  socket.on("cancel_find", async () => {
    await cleanupUserSession(socket.id, io);
    socket.emit("cancelled_find");
    console.log(`Пользователь ${socket.id} отменил поиск.`);
  });

  socket.on("find", (data) => handleFindMatch(socket, data, io));

  socket.on("end", async () => {
    console.log(`Пользователь ${socket.id} инициировал завершение чата.`);
    await cleanupUserSession(socket.id, io);
  });

  socket.on("disconnect", async () => {
    console.log(`Пользователь отключен: ${socket.id}`);
    await cleanupUserSession(socket.id, io);
  });
}
