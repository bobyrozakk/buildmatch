import 'package:equatable/equatable.dart';
import 'package:buildmatch/data/models/chat_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final List<ChatModel> chats;
  final List<ChatModel> pendingChats;
  final int totalUnreadCount;

  const ChatLoaded({
    this.chats = const [],
    this.pendingChats = const [],
    this.totalUnreadCount = 0,
  });

  ChatLoaded copyWith({
    List<ChatModel>? chats,
    List<ChatModel>? pendingChats,
    int? totalUnreadCount,
  }) {
    return ChatLoaded(
      chats: chats ?? this.chats,
      pendingChats: pendingChats ?? this.pendingChats,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
    );
  }

  @override
  List<Object?> get props => [chats, pendingChats, totalUnreadCount];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
