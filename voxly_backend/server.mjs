import express from "express";
import { Server as SocketIOServer } from "socket.io";
import { AccessToken } from "livekit-server-sdk";
import dotenv from "dotenv";
import cors from "cors";

dotenv.config();

const LIVEKIT_URL = process.env.LIVEKIT_URL;
const LIVEKIT_API_KEY = process.env.LIVEKIT_API_KEY;
const LIVEKIT_API_SECRET = process.env.LIVEKIT_API_SECRET;

const app = express();
const port = 3000;

app.use(express.json());
app.use(cors());

const server = app.listen(port, () => console.log(`HTTP server on ${port}`));

const io = new SocketIOServer(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

let waitingUsers = [];
let activeRooms = {};

function createToken(roomName, userName) {
  const at = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, {
    identity: userName,
    ttl: "60m",
  });

  at.addGrant({ roomJoin: true, room: roomName, canPublish: true, canSubscribe: true });

  return at.toJwt();
}

io.on("connection", (socket) => {
  console.log("User connected:", socket.id);

  socket.on("find", async (data) => {
    socket.userName = data.userName;

    if (waitingUsers.length === 0) {
      waitingUsers.push(socket);
      socket.emit("waiting");
    } else {
      const partner = waitingUsers.shift();
      const roomName = `room-${Date.now()}`;
      const token1 = await createToken(roomName, socket.userName);
      const token2 = await createToken(roomName, partner.userName);

      activeRooms[roomName] = [socket, partner];

      socket.emit("match", { roomName, liveKitUrl: LIVEKIT_URL, token: token1, partner: partner.userName });
      partner.emit("match", { roomName, liveKitUrl: LIVEKIT_URL, token: token2, partner: socket.userName });
    }
  });

  socket.on("end", () => {
    const room = Object.entries(activeRooms).find(([_, users]) => users.includes(socket));
    if (room) {
      const [roomName, users] = room;
      users.forEach(u => {
        if (u !== socket) u.emit("ended");
      });
      delete activeRooms[roomName];
    }
  });

  socket.on("disconnect", () => {
    waitingUsers = waitingUsers.filter(u => u !== socket);
    for (const [roomName, users] of Object.entries(activeRooms)) {
      if (users.includes(socket)) {
        users.forEach(u => { if (u !== socket) u.emit("ended"); });
        delete activeRooms[roomName];
        break;
      }
    }
  });
});

