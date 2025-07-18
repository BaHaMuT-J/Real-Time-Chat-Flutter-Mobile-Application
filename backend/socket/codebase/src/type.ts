interface MessageChat {
  userId: string;
  chatId: string;
  message: string;
}

interface ReadMessage {
  userId: string;
  chatId: string;
  readerId: string;
  chat: object;
  chatName: string;
  message: object;
}

interface AllReadMessage {
  userId: string;
  chatId: string;
  readerId: string;
}

interface FriendMessage {
  userId: string;
  request: object;
}

interface SentRequestMessage {
  userId: string;
  request: object;
}

interface ReceivedRequestMessage {
  userId: string;
  request: object;
}
