import admin from "firebase-admin";
import fs from "fs";

const serviceAccount = JSON.parse(
  fs.readFileSync("asset/serviceAccountKey.json", "utf-8")
);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

export const sendNotificationMessage = async (
  targetFcmToken: string,
  title: string,
  body: string,
  data = {}
) => {
  console.log(
    `token: ${targetFcmToken} | title: ${title} | body: ${body} | data: ${data}`
  );
  const message = {
    token: targetFcmToken,
    notification: {
      title,
      body,
    },
    data,
    android: {
      priority: "high" as "high",
    },
    apns: {
      payload: {
        aps: {
          contentAvailable: true,
          sound: "default",
        },
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("✅ Successfully sent notification message:", response);
  } catch (error) {
    console.error("🔥 Error sending notification message:", error);
  }
};
