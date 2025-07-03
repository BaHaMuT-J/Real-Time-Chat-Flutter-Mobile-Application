import { createServer } from "http";
import { Server } from "socket.io";
import { createClient } from "redis";
import { createAdapter } from "@socket.io/redis-adapter";
import express from "express";

const app = express();
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

async function registerUser(userId: string, socketId: string) {
  await redis.set(userKey(userId), socketId);
}

async function unregisterUser(userId: string) {
  await redis.del(userKey(userId));
}

async function getSocketId(userId: string): Promise<string | null> {
  return await redis.get(userKey(userId));
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

  server.listen(port, () => {
    console.log(`Socket server running at http://localhost:${port}`);
  });
};

start();
