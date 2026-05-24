import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_model.dart';

class ChatProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  List<ChatModel> _chats = [];
  List<ChatModel> get chats => _chats;

  int _totalUnreadCount = 0;
  int get totalUnreadCount => _totalUnreadCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Fetch all active chats for the current user
  Future<List<ChatModel>> fetchChats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Fetch chats where user is either client or vendor
      final response = await _supabase
          .from('chats')
          .select('*, client:client_id(name, avatar_url), vendor:vendor_id(name, avatar_url), messages(content, is_read, sender_id, created_at)')
          .or('client_id.eq.$userId,vendor_id.eq.$userId')
          .order('updated_at', ascending: false);

      List<ChatModel> chats = [];
      int totalUnread = 0;

      for (var row in response) {
        final messages = row['messages'] as List<dynamic>? ?? [];
        
        // Sort messages manually if not sorted by supabase
        messages.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
        
        final lastMessage = messages.isNotEmpty ? messages.first['content'] : null;
        
        // Count unread messages for this user (where user is not the sender and is_read is false)
        int unreadCount = messages.where((m) => m['is_read'] == false && m['sender_id'] != userId).length;
        totalUnread += unreadCount;

        final client = row['client'] as Map<String, dynamic>? ?? {};
        final vendor = row['vendor'] as Map<String, dynamic>? ?? {};

        chats.add(ChatModel(
          id: row['id'],
          clientId: row['client_id'],
          vendorId: row['vendor_id'],
          projectId: row['project_id'],
          createdAt: DateTime.parse(row['created_at']),
          updatedAt: DateTime.parse(row['updated_at']),
          clientName: client['name'],
          clientAvatar: client['avatar_url'],
          vendorName: vendor['name'],
          vendorAvatar: vendor['avatar_url'],
          lastMessage: lastMessage,
          unreadCount: unreadCount,
        ));
      }

      _chats = chats;
      _totalUnreadCount = totalUnread;
      notifyListeners();
      return chats;
    } catch (e) {
      debugPrint("Error fetch chats: $e");
      return [];
    }
  }

  /// Create or get existing chat room
  Future<String?> getOrCreateChat(String otherUserId, {String? projectId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("Not logged in");

      // Check if chat exists
      final existing = await _supabase
          .from('chats')
          .select('id')
          .or('and(client_id.eq.$userId,vendor_id.eq.$otherUserId),and(client_id.eq.$otherUserId,vendor_id.eq.$userId)')
          .limit(1);

      if (existing.isNotEmpty) {
        _isLoading = false;
        notifyListeners();
        return existing[0]['id'] as String;
      }

      // Determine who is client and who is vendor based on role (simplification: current user is client)
      final userRole = _supabase.auth.currentUser?.userMetadata?['role'];
      final isVendor = userRole == 'vendor' || userRole == 'kontraktor';

      final insertData = {
        'client_id': isVendor ? otherUserId : userId,
        'vendor_id': isVendor ? userId : otherUserId,
        if (projectId != null) 'project_id': projectId,
      };

      final response = await _supabase.from('chats').insert(insertData).select('id');
      
      _isLoading = false;
      notifyListeners();
      
      return response[0]['id'] as String;
    } catch (e) {
      debugPrint("Error create chat: $e");
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Fetch messages for a chat
  Future<List<MessageModel>> fetchMessages(String chatId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response)
          .map((json) => MessageModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error fetch messages: $e");
      return [];
    }
  }

  /// Send message
  Future<bool> sendMessage(String chatId, String content) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': userId,
        'content': content,
      });

      // Also trigger a notification to the other user
      // Determine receiver id
      final chatData = await _supabase.from('chats').select('client_id, vendor_id').eq('id', chatId).single();
      final receiverId = chatData['client_id'] == userId ? chatData['vendor_id'] : chatData['client_id'];
      
      final senderName = _supabase.auth.currentUser?.userMetadata?['name'] ?? 'User';
      
      await _supabase.from('notifications').insert({
        'user_id': receiverId,
        'title': 'Pesan Baru',
        'message': '$senderName mengirim pesan: $content',
        'type': 'chat'
      });

      return true;
    } catch (e) {
      debugPrint("Error send message: $e");
      return false;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .neq('sender_id', userId)
          .eq('is_read', false);
          
      fetchChats(); // Refresh unread count
    } catch (e) {
      debugPrint("Error mark messages as read: $e");
    }
  }

  /// Listen to new messages
  SupabaseStreamBuilder streamMessages(String chatId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);
  }
}
