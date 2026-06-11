import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_model.dart';

class ChatProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // Accepted chats (status = 'accepted') — untuk tab Inbox/Pesan
  List<ChatModel> _chats = [];
  List<ChatModel> get chats => _chats;

  // Pending chats (status = 'pending') — untuk tab Permintaan (arsitek)
  List<ChatModel> _pendingChats = [];
  List<ChatModel> get pendingChats => _pendingChats;

  int _totalUnreadCount = 0;
  int get totalUnreadCount => _totalUnreadCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Fetch semua chat untuk user saat ini, pisah accepted vs pending
  Future<void> fetchChats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('chats')
          .select(
            '*, client:client_id(name, avatar_url, role), vendor:vendor_id(name, avatar_url, role), messages(content, is_read, sender_id, created_at)',
          )
          .or('client_id.eq.$userId,vendor_id.eq.$userId')
          .order('updated_at', ascending: false);

      List<ChatModel> accepted = [];
      List<ChatModel> pending = [];
      int totalUnread = 0;

      for (var row in response) {
        final messages = row['messages'] as List<dynamic>? ?? [];
        messages.sort(
          (a, b) => DateTime.parse(
            b['created_at'],
          ).compareTo(DateTime.parse(a['created_at'])),
        );

        final lastMessage = messages.isNotEmpty
            ? messages.first['content'] as String?
            : null;

        int unreadCount = messages
            .where((m) => m['is_read'] == false && m['sender_id'] != userId)
            .length;
        totalUnread += unreadCount;

        final client = row['client'] as Map<String, dynamic>? ?? {};
        final vendor = row['vendor'] as Map<String, dynamic>? ?? {};
        final status = row['status'] as String? ?? 'pending';

        final chat = ChatModel(
          id: row['id'],
          clientId: row['client_id'],
          vendorId: row['vendor_id'],
          projectId: row['project_id'],
          createdAt: DateTime.parse(row['created_at']),
          updatedAt: DateTime.parse(row['updated_at']),
          status: status,
          clientName: client['name'],
          clientAvatar: client['avatar_url'],
          clientRole: client['role'],
          vendorName: vendor['name'],
          vendorAvatar: vendor['avatar_url'],
          vendorRole: vendor['role'],
          lastMessage: lastMessage,
          unreadCount: unreadCount,
        );

        if (status == 'accepted') {
          accepted.add(chat);
        } else if (status == 'pending') {
          pending.add(chat);
        }
      }

      _chats = accepted;
      _pendingChats = pending;
      _totalUnreadCount = totalUnread;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetch chats: $e');
    }
  }

  /// Buat atau dapatkan chat yang sudah ada
  /// Client → status 'pending', arsitek/vendor harus terima dulu
  /// Jika forceStatus diisi (misal 'accepted'), langsung diset status tersebut
  Future<String?> getOrCreateChat(
    String otherUserId, {
    String? projectId,
    String? forceStatus,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      // Cek apakah chat sudah ada
      final existing = await _supabase
          .from('chats')
          .select('id, status')
          .or(
            'and(client_id.eq.$userId,vendor_id.eq.$otherUserId),and(client_id.eq.$otherUserId,vendor_id.eq.$userId)',
          )
          .limit(1);

      if (existing.isNotEmpty) {
        _isLoading = false;
        notifyListeners();
        return existing[0]['id'] as String;
      }

      // Tentukan siapa client dan vendor
      final userRole =
          _supabase.auth.currentUser?.userMetadata?['role'] as String?;
      final isVendorSide =
          userRole == 'vendor' ||
          userRole == 'kontraktor' ||
          userRole == 'architect' ||
          userRole == 'arsitek';

      // Client memulai chat → status 'pending'
      // Arsitek/vendor yang memulai → langsung 'accepted'
      final chatStatus = forceStatus ?? (isVendorSide ? 'accepted' : 'pending');

      final insertData = {
        'client_id': isVendorSide ? otherUserId : userId,
        'vendor_id': isVendorSide ? userId : otherUserId,
        'status': chatStatus,
      };
      if (projectId != null) insertData['project_id'] = projectId;

      final response = await _supabase
          .from('chats')
          .insert(insertData)
          .select('id');

      _isLoading = false;
      notifyListeners();

      return response[0]['id'] as String;
    } catch (e) {
      debugPrint('Error create chat: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Arsitek menerima permintaan chat dari client
  Future<bool> acceptChat(String chatId) async {
    try {
      await _supabase
          .from('chats')
          .update({'status': 'accepted'})
          .eq('id', chatId);

      await fetchChats();
      return true;
    } catch (e) {
      debugPrint('Error accept chat: $e');
      return false;
    }
  }

  /// Arsitek menolak permintaan chat (set status = 'rejected')
  Future<bool> rejectChat(String chatId) async {
    try {
      await _supabase
          .from('chats')
          .update({'status': 'rejected'})
          .eq('id', chatId);

      // Hapus data terkait secara opsional, abaikan jika RLS melarang
      try {
        await _supabase.from('notifications').delete().eq('chat_id', chatId);
      } catch (_) {}
      try {
        await _supabase.from('messages').delete().eq('chat_id', chatId);
      } catch (_) {}

      _pendingChats.removeWhere((c) => c.id == chatId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error reject chat: $e');
      return false;
    }
  }

  /// Kirim pesan
  Future<bool> sendMessage(
    String chatId,
    String content, {
    String? bidId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final messageData = {
        'chat_id': chatId,
        'sender_id': userId,
        'content': content,
      };
      if (bidId != null) messageData['bid_id'] = bidId;

      await _supabase.from('messages').insert(messageData);

      // Update updated_at agar naik ke atas
      await _supabase
          .from('chats')
          .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', chatId);

      // Kirim notifikasi ke penerima (ignore error jika tabel tidak ada)
      try {
        final chatData = await _supabase
            .from('chats')
            .select('client_id, vendor_id')
            .eq('id', chatId)
            .single();
        final receiverId = chatData['client_id'] == userId
            ? chatData['vendor_id']
            : chatData['client_id'];
        final senderName =
            _supabase.auth.currentUser?.userMetadata?['name'] ?? 'User';

        final previewContent = _formatNotificationMessage(content);
        final notificationData = {
          'user_id': receiverId,
          'title': 'Pesan Baru',
          'message': '$senderName: $previewContent',
          'type': 'chat',
          'chat_id': chatId,
        };

        try {
          await _supabase.from('notifications').insert(notificationData);
        } catch (_) {
          await _supabase.from('notifications').insert({
            'user_id': receiverId,
            'title': 'Pesan Baru',
            'message': '$senderName: $previewContent',
            'type': 'chat',
          });
        }
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('Error send message: $e');
      return false;
    }
  }

  String _formatNotificationMessage(String content) {
    if (content.startsWith('{')) {
      try {
        final data = jsonDecode(content) as Map<String, dynamic>;
        final type = data['type'] as String?;
        if (type == 'offer') {
          return '📋 Penawaran telah dikirim';
        } else if (type == 'design') {
          final rev = data['revision_number'] as int? ?? 0;
          return rev == 0
              ? '🎨 Desain awal telah dikirim'
              : '🎨 Revisi ke-$rev telah diberikan';
        }
      } catch (_) {}
    }

    if (content.startsWith('http://') || content.startsWith('https://')) {
      final lower = content.toLowerCase();
      final isImage = lower.contains('.png') ||
          lower.contains('.jpg') ||
          lower.contains('.jpeg') ||
          lower.contains('.gif') ||
          lower.contains('.webp');
      if (isImage) return '🖼️ Gambar dilampirkan';
      return '📎 File dilampirkan';
    }

    return content;
  }

  /// Tandai pesan sebagai sudah dibaca
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

      fetchChats();
    } catch (e) {
      debugPrint('Error mark messages as read: $e');
    }
  }

  /// Stream pesan real-time
  SupabaseStreamBuilder streamMessages(String chatId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);
  }

  /// Kirim pesan penawaran (offer card) dari arsitek ke client
  Future<bool> sendOfferMessage({
    required String chatId,
    required String bidId,
    required String title,
    required double price,
    required int revisions,
    required String description,
    required int durationDays,
    bool isSplitPayment = false,
    int dpPercentage = 50,
  }) async {
    final content = jsonEncode({
      'type': 'offer',
      'bid_id': bidId,
      'title': title,
      'price': price,
      'revisions': revisions,
      'description': description,
      'duration_days': durationDays,
      'is_split_payment': isSplitPayment,
      'dp_percentage': dpPercentage,
      'status': 'pending',
    });
    return sendMessage(chatId, content, bidId: bidId);
  }

  /// Kirim pesan pengiriman desain dari arsitek ke client
  Future<bool> sendDesignMessage({
    required String chatId,
    required String bidId,
    required List<Map<String, String>> files,
    required String notes,
    required int revisionNumber,
  }) async {
    final content = jsonEncode({
      'type': 'design',
      'bid_id': bidId,
      'files': files,
      'notes': notes,
      'revision_number': revisionNumber,
    });
    return sendMessage(chatId, content);
  }
}
