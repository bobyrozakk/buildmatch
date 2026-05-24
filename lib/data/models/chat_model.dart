class ChatModel {
  final String id;
  final String clientId;
  final String vendorId;
  final String? projectId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Joined fields for display
  final String? clientName;
  final String? vendorName;
  final String? clientAvatar;
  final String? vendorAvatar;
  final String? lastMessage;
  final int unreadCount;

  ChatModel({
    required this.id,
    required this.clientId,
    required this.vendorId,
    this.projectId,
    required this.createdAt,
    required this.updatedAt,
    this.clientName,
    this.vendorName,
    this.clientAvatar,
    this.vendorAvatar,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      vendorId: json['vendor_id'] as String,
      projectId: json['project_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      clientName: json['client_name'] as String?,
      vendorName: json['vendor_name'] as String?,
      clientAvatar: json['client_avatar'] as String?,
      vendorAvatar: json['vendor_avatar'] as String?,
      lastMessage: json['last_message'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
