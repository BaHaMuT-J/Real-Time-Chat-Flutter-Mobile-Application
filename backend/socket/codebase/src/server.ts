import { createServer } from "http";
import { Server } from "socket.io";
import { createClient } from "redis";
import { createAdapter } from "@socket.io/redis-adapter";
import express, { Request, Response } from "express";
import { sendNotificationMessage } from "./firebase";

const app = express();
app.use(express.json());
const server = createServer(app);

const io = new Server(server, {
  cors: {
    origin: [process.env.IP!],
  },
});

const port = 3000;

// Redis Pub/Sub clients for socket.io adapter
const pubClient = createClient({
  socket: {
    host: process.env.REDIS_IP!,
    port: parseInt(process.env.REDIS_PORT!),
  },
  password: process.env.REDIS_PASSWORD,
});
const subClient = pubClient.duplicate();

// Redis client for storing user-socket mapping
const redis = createClient({
  socket: {
    host: process.env.REDIS_IP!,
    port: parseInt(process.env.REDIS_PORT!),
  },
  password: process.env.REDIS_PASSWORD,
});
redis.connect().catch(console.error);

const userKey = (userId: string) => `socket:user:${userId}`;
const tokenFCM = (userId: string) => `fcm:token:${userId}`;

async function registerUser(userId: string, socketId: string) {
  await redis.set(userKey(userId), socketId);
}

async function unregisterUser(userId: string) {
  await redis.del(userKey(userId));
}

async function getSocketId(userId: string): Promise<string | null> {
  return await redis.get(userKey(userId));
}

async function registerTokenFCM(userId: string, token: string) {
  await redis.set(tokenFCM(userId), token);
}

async function unregisterTokenFCM(userId: string) {
  await redis.del(tokenFCM(userId));
}

async function getTokenFCM(userId: string): Promise<string | null> {
  return await redis.get(tokenFCM(userId));
}

const start = async () => {
  await pubClient.connect();
  await subClient.connect();
  io.adapter(createAdapter(pubClient, subClient));
  console.log("✅ Redis adapter attached to Socket.IO");

  io.on("connection", (socket) => {
    console.log(`User connected: ${socket.id}`);

    socket.on("register", async ({ userId }: { userId: string }) => {
      console.log(`User registered: ${userId}`);
      if (!userId) return;
      await registerUser(userId, socket.id);
      console.log(`Registered user ${userId} to socket ${socket.id}`);
    });

    socket.on("unregister", async ({ userId }: { userId: string }) => {
      console.log(`User unregistered: ${userId}`);
      if (!userId) return;
      await unregisterUser(userId);
      console.log(`Unregistered user ${userId}`);
    });

    socket.on(
      "message",
      async ({ userId, data }: { userId: string; data: object }) => {
        console.log(`Socket listen to message with userId: ${userId}`);
        console.log(data);

        const recipientSocketId = await getSocketId(userId);
        if (recipientSocketId) {
          io.to(recipientSocketId).emit("message", data);
          console.log(
            `Message sent to user ${userId} with socket ${recipientSocketId}`
          );
        } else {
          console.log(`No socket found for user ${userId}`);
        }

        const tokenFCM = await getTokenFCM(userId);
        if (tokenFCM) {
          sendNotificationMessage(tokenFCM, `socket title`, `socket body`);
        } else {
          console.log(`No FCM token found for user ${userId}`);
        }
      }
    );

    socket.on(
      "read",
      async ({ userId, data }: { userId: string; data: object }) => {
        console.log(`Socket listen to read with userId: ${userId}`);
        console.log(data);

        const recipientSocketId = await getSocketId(userId.toString());
        if (recipientSocketId) {
          io.to(recipientSocketId).emit("read", data);
          console.log(
            `Read sent to user ${userId} with socket ${recipientSocketId}`
          );
        } else {
          console.log(`No socket found for user ${userId}`);
        }
      }
    );

    socket.on("disconnect", async () => {
      console.log(`User disconnected: ${socket.id}`);

      const keys = await redis.keys("socket:user:*");
      for (const key of keys) {
        const id = await redis.get(key);
        if (id === socket.id) {
          await redis.del(key);
          console.log(`Cleaned up disconnected socket: ${key}`);
        }
      }
    });
  });

  app.post("/api/fcm/set", async (req: Request, res: Response) => {
    console.log("/api/fcm/set: ", req.body);
    const { userId, tokenFCM } = req.body;

    await registerTokenFCM(userId, tokenFCM);
    const tokenFromRedis = await getTokenFCM(userId);
    console.log(`Registered user ${userId} to token ${tokenFromRedis}`);
  });

  app.post("/api/fcm/unset", async (req: Request, res: Response) => {
    console.log("/api/fcm/unset: ", req.body);
    const { userId } = req.body;

    await unregisterTokenFCM(userId);
    console.log(`Unregistered user ${userId} for FCM token`);
  });

  server.listen(port, () => {
    console.log(`Socket server running at http://localhost:${port}`);
  });
};

start();
