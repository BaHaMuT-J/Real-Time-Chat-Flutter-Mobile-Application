interface MessageChat {
  userId: string;
  chatId: string;
  chat: object;
  chatName: string;
  message: object;
  title: string;
  body: string;
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
  friendId: string;
}

interface SentRequestMessage {
  userId: string;
  request: object;
  isUpdate?: boolean;
  isDelete?: boolean;
}

interface ReceivedRequestMessage {
  userId: string;
  request: object;
  isCreate?: boolean;
  isDelete?: boolean;
}
