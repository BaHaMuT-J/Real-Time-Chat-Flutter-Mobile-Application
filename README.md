# 📱 Real Time Chat Mobile Application

## 🧭 Overview

This project is a side project developed to deepen my understanding of **Flutter** and how it integrates with multiple backend services and tools. It serves as a hands-on learning experience, bringing together technologies like **Firebase**, **WebSockets**, **Docker**, and local storage in a real-world mobile application.

The app demonstrates a complete, production-like implementation of a real-time chat platform — including authentication, data syncing, notifications, UI theming, and persistent preferences. It’s designed to be both a functional app and a technical sandbox for exploring modern mobile development best practices.

## ✨ Features

- 🚀 **Onboarding**

  - Learn about the app through a few simple onboarding screens
  - Shown only once per installation

- 🔐 **Authentication**

  - Login using email & password
  - Stay logged in across sessions
  - Synchronous data between devices

- 👥 **Friend System**

  - Send, cancel, receive, accept, or reject friend requests
  - All updates are real-time via WebSocket

- 💬 **Real-Time Messaging**

  - Chat with friends in real-time
  - All chats and messages are synced across devices instantly
  - Message notifications for new incoming messages

- 🎨 **User Customization**

  - Choose preferred font size and color palette
  - Preferences persist across app restarts

- 🧾 **User Profile**
  - Set and update username, description, and profile image anytime

## 🧰 Tech Stack

| Layer         | Technology                                                 |
| ------------- | ---------------------------------------------------------- |
| Frontend      | Flutter                                                    |
| Backend       | Node.js and Socket.io WebSocket server (Dockerized)        |
| Auth          | Firebase Authentication                                    |
| Database      | Firebase Firestore                                         |
| File Storage  | Firebase Storage                                           |
| Notifications | Local notifications (Flutter) and Firebase Cloud Messaging |

## Prerequisite

- Flutter SDK
- Android Emulator or physical Android device
- Docker

## Firebase Configuration

- Go to [Firebase Console](https://console.firebase.google.com) and create a new project

- Register android app using package name `com.example.chat` and download `google-services.json` file

- Create Firebase Authentication using Email/Password as sign-in provider

- Create Firebase Firestore Database with the following rules:

```bash
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if true;

      // Only the user can update their profile
      allow write: if request.auth.uid == userId;

      // Friends subcollection
      match /friends/{friendId} {
        allow read, write: if request.auth.uid == userId;
        allow create, delete: if request.auth.uid == friendId;
      }

      // Sent friend requests subcollection
      match /sent_friend_requests/{receiverId} {
        allow read, delete: if request.auth.uid == userId;
        allow create, update: if request.auth.uid == userId
        && request.resource.data.status in ['Pending...', 'Accepted', 'Rejected'];

        allow update: if request.auth.uid == receiverId
        && request.resource.data.keys().hasOnly(['status', 'user'])
				&& request.resource.data.user == resource.data.user
        && request.resource.data.status in ['Pending...', 'Accepted', 'Rejected'];
        allow read, delete: if request.auth.uid == receiverId;
      }

      // Received friend requests subcollection
      match /received_friend_requests/{requesterId} {
        allow read, write: if request.auth.uid == userId;
  			allow create: if request.auth.uid == requesterId;
  			allow delete: if request.auth.uid == requesterId;
      }

      match /chats/{chatId} {
      	allow read, write: if request.auth.uid == userId;
        allow create, delete: if request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.users;
      }
    }

    match /chats/{chatId} {
  		allow read, update, delete: if request.auth.uid in resource.data.users;
  		allow create: if request.auth.uid in request.resource.data.users;

  		match /messages/{messageId} {
    		allow read, write: if request.auth.uid in get(/databases/(default)/documents/chats/$(chatId)).data.users;
  		}
    }
  }
}
```

- Create Firebase Storage (⚠️ This requires enabling the **Blaze (pay-as-you-go) plan**) with the following rules:

```bash
rules_version = '2';

// Craft rules based on data in your Firestore database
// allow write: if firestore.get(
//    /databases/(default)/documents/users/$(request.auth.uid)).data.isAdmin;
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_images/{userId}/{fileName} {
      // Anyone can read, but only owner can write
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

- Go to **Project Settings > Service Accounts** in Firebase Console, click **"Generate New Private Key"**, download `.json` file and rename it to `serviceAccountKey.json`

## How to run

1. Clone the repository

```bash
git clone git@github.com:BaHaMuT-J/Real-Time-Chat-Flutter-Mobile-Application.git

cd Real-Time-Chat-Flutter-Mobile-Application
```

2. Copy the Firebase config files into the correct locations:

```bash
chat/android/app/google-services.json  # for Flutter Android

backend/socket/codebase/asset/serviceAccountKey.json # for backend auth
```

3. Create a `.env` file in `docker/` directory based on the example:

```bash
cp docker/.env.example docker/.env

# Inside .env
REDIS_PASSWORD=YOUR_REDIS_PASSWORD # replace with your desired password
```

4. Run the following inside `docker/` directory

```bash
docker compose build

docker compose up -d
```

5. Run the following inside root directory

```bash
flutter pub get

flutter devices # to see your device name

flutter run -d YOUR_DEVICE_NAME # replace with your device name
```

6. After stop flutter app, close the backend by running the following inside `docker` directory

```bash
docker compose down
```
