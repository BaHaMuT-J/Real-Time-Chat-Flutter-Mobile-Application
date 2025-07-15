interface MessageChat {
  userId: string;
  chatId: string;
  message: object;
}

interface ReadMessage {
  userId: string;
  chatId: string;
  message: object;
}

interface AllReadMessage {
  userId: string;
  chatId: string;
}
