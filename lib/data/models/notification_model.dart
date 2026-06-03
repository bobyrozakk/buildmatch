class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'bid', 'chat', 'project_update', 'system'
  final String? chatId;
  final String? projectId;
  final String? bidId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.chatId,
    this.projectId,
    this.bidId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      chatId: json['chat_id'] as String?,
      projectId: json['project_id'] as String?,
      bidId: json['bid_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      chatId: chatId,
      projectId: projectId,
      bidId: bidId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
