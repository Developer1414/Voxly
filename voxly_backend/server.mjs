import express from "express";
import { Server as SocketIOServer } from "socket.io";
import cors from "cors";
import { PORT } from "./config.js";
import "./redisClient.js";
import apiRouter from "./api.js";
import { setupSocketListeners } from "./socket.js";

const app = express();
app.use(express.json());
app.use(cors());

app.use(apiRouter);

const server = app.listen(PORT, () =>
  console.log(`HTTP сервер запущен на порту ${PORT}`)
);

const io = new SocketIOServer(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
  path: "/socket.io/",
});

io.on("connection", (socket) => setupSocketListeners(socket, io));
