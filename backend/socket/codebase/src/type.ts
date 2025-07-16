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
