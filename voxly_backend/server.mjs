import express from "express";
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

const createToken = async (req, res) => {
  const { roomName, userName } = req.body;

  if (!roomName || !userName)
    return res.status(400).json({ error: "roomName and userName required" });

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

  const token = await at.toJwt();

  return res.json({ token, liveKitUrl: LIVEKIT_URL });
};

app.post("/getToken", createToken);

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
