import 'package:equatable/equatable.dart';

class ChatModel extends Equatable {
  final String id;
  final String clientId;
  final String vendorId;
  final String? projectId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  /// 'pending' = menunggu diterima arsitek, 'accepted' = sudah diterima
  final String status;

  // Joined fields for display
  final String? clientName;
  final String? vendorName;
  final String? clientAvatar;
  final String? vendorAvatar;
  final String? clientRole;
  final String? vendorRole;
  final String? lastMessage;
  final int unreadCount;

  const ChatModel({
    required this.id,
    required this.clientId,
    required this.vendorId,
    this.projectId,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'pending',
    this.clientName,
    this.vendorName,
    this.clientAvatar,
    this.vendorAvatar,
    this.clientRole,
    this.vendorRole,
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
      status: json['status'] as String? ?? 'pending',
      clientName: json['client_name'] as String?,
      vendorName: json['vendor_name'] as String?,
      clientAvatar: json['client_avatar'] as String?,
      vendorAvatar: json['vendor_avatar'] as String?,
      clientRole: json['client_role'] as String?,
      vendorRole: json['vendor_role'] as String?,
      lastMessage: json['last_message'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  ChatModel copyWith({
    String? id,
    String? clientId,
    String? vendorId,
    String? projectId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? clientName,
    String? vendorName,
    String? clientAvatar,
    String? vendorAvatar,
    String? clientRole,
    String? vendorRole,
    String? lastMessage,
    int? unreadCount,
  }) {
    return ChatModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      vendorId: vendorId ?? this.vendorId,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      clientName: clientName ?? this.clientName,
      vendorName: vendorName ?? this.vendorName,
      clientAvatar: clientAvatar ?? this.clientAvatar,
      vendorAvatar: vendorAvatar ?? this.vendorAvatar,
      clientRole: clientRole ?? this.clientRole,
      vendorRole: vendorRole ?? this.vendorRole,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientId,
        vendorId,
        projectId,
        createdAt,
        updatedAt,
        status,
        clientName,
        vendorName,
        clientAvatar,
        vendorAvatar,
        clientRole,
        vendorRole,
        lastMessage,
        unreadCount,
      ];
}
