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

    socket.on("message", async (data: MessageChat) => {
      console.log(`Socket listen to message with userId: ${data.userId}`);
      console.log(data);

      const recipientSocketId = await getSocketId(data.userId);
      if (recipientSocketId) {
        io.to(recipientSocketId).emit("message", data);
        console.log(
          `Message sent to user ${data.userId} with socket ${recipientSocketId}`
        );
      } else {
        console.log(`No socket found for user ${data.userId}`);
      }

      const tokenFCM = await getTokenFCM(data.userId);
      if (tokenFCM) {
        sendNotificationMessage(tokenFCM, data["title"], data["body"], data);
      } else {
        console.log(`No FCM token found for user ${data.userId}`);
      }
    });

    socket.on("read", async (data: ReadMessage) => {
      console.log(`Socket listen to read with userId: ${data.userId}`);
      console.log(data);

      const recipientSocketId = await getSocketId(data.userId);
      if (recipientSocketId) {
        io.to(recipientSocketId).emit("read", data);
        console.log(
          `Read sent to user ${data.userId} with socket ${recipientSocketId}`
        );
      } else {
        console.log(`No socket found for user ${data.userId}`);
      }
    });

    socket.on("allRead", async (data: AllReadMessage) => {
      console.log(`Socket listen to allRead with userId: ${data.userId}`);
      console.log(data);

      const recipientSocketId = await getSocketId(data.userId);
      if (recipientSocketId) {
        io.to(recipientSocketId).emit("allRead", data);
        console.log(
          `All Read sent to user ${data.userId} with socket ${recipientSocketId}`
        );
      } else {
        console.log(`No socket found for user ${data.userId}`);
      }
    });

    socket.on("friend", async (data: FriendMessage) => {
      console.log(`Socket listen to friend with userId: ${data.userId}`);
      console.log(data);

      const recipientSocketId = await getSocketId(data.userId);
      if (recipientSocketId) {
        io.to(recipientSocketId).emit("friend", data);
        console.log(
          `Friend sent to user ${data.userId} with socket ${recipientSocketId}`
        );
      } else {
        console.log(`No socket found for user ${data.userId}`);
      }
    });

    socket.on("sentRequest", async (data: SentRequestMessage) => {
      console.log(`Socket listen to sentRequest with userId: ${data.userId}`);
      console.log(data);

      const recipientSocketId = await getSocketId(data.userId);
      if (recipientSocketId) {
        io.to(recipientSocketId).emit("sentRequest", data);
        console.log(
          `SentRequest sent to user ${data.userId} with socket ${recipientSocketId}`
        );
      } else {
        console.log(`No socket found for user ${data.userId}`);
      }
    });

    socket.on("receivedRequest", async (data: ReceivedRequestMessage) => {
      console.log(
        `Socket listen to receivedRequest with userId: ${data.userId}`
      );
      console.log(data);

      const recipientSocketId = await getSocketId(data.userId);
      if (recipientSocketId) {
        io.to(recipientSocketId).emit("receivedRequest", data);
        console.log(
          `ReceivedRequest sent to user ${data.userId} with socket ${recipientSocketId}`
        );
      } else {
        console.log(`No socket found for user ${data.userId}`);
      }
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

  app.post("/api/fcm/set", async (req: Request, res: Response) => {
    console.log("/api/fcm/set: ", req.body);
    const { userId, tokenFCM } = req.body;

    await registerTokenFCM(userId, tokenFCM);
    const tokenFromRedis = await getTokenFCM(userId);
    console.log(`Registered user ${userId} to token ${tokenFromRedis}`);

    res.status(200).send("Registered token successfully.");
  });

  app.post("/api/fcm/unset", async (req: Request, res: Response) => {
    console.log("/api/fcm/unset: ", req.body);
    const { userId } = req.body;

    await unregisterTokenFCM(userId);
    console.log(`Unregistered user ${userId} for FCM token`);

    res.status(200).send("Unregistered token successfully.");
  });

  server.listen(port, () => {
    console.log(`Socket server running at http://localhost:${port}`);
  });
};

start();
