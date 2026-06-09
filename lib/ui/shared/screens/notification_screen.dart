import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../../../core/constants/colors.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/providers/notification_provider.dart';
import '../../../data/providers/project_provider.dart';
import '../../../data/providers/chat_provider.dart';
import 'package:buildmatch/modules/client/ui/screens/project_detail/project_detail_screen.dart';
import 'chat_detail_screen.dart';
import 'contractor_chat_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const String _markAllReadAction = 'mark_all_read';
  static const String _deleteReadAction = 'delete_read';
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).fetchNotifications();
      }
    });
  }

  Future<void> _confirmDeleteRead(NotificationProvider notifProvider) async {
    if (notifProvider.readCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada notifikasi terbaca untuk dihapus'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Notifikasi Terbaca?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${notifProvider.readCount} notifikasi yang sudah dibaca akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await notifProvider.deleteReadNotifications();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Notifikasi terbaca berhasil dihapus'
              : 'Gagal menghapus notifikasi terbaca',
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _handleNotificationTap(
    NotificationModel notif,
    NotificationProvider notifProvider,
  ) async {
    if (!notif.isRead) {
      await notifProvider.markAsRead(notif.id);
    }

    bool opened = false;

    if (notif.type == 'chat') {
      opened = await _openChatNotification(notif);
    } else if (notif.type == 'bid' || notif.type == 'project_update') {
      // Coba buka room chat terkait terlebih dahulu
      opened = await _openChatFromProjectOrBidNotification(notif);
      // Jika gagal/belum ada chat, arahkan ke detail proyek
      if (!opened) {
        opened = await _openProjectNotification(notif);
      }
    }

    if (!opened) {
      _showNavigationUnavailable();
    }
  }

  Future<bool> _navigateToChatRoom(String chatId, Map<String, dynamic> chatRow) async {
    if (!mounted) return false;
    final currentUserId = _supabase.auth.currentUser?.id;
    final isClientSide = currentUserId == chatRow['client_id'];

    final client = Map<String, dynamic>.from(
      (chatRow['client'] as Map?) ?? {},
    );
    final vendor = Map<String, dynamic>.from(
      (chatRow['vendor'] as Map?) ?? {},
    );

    final receiverName = isClientSide
        ? (vendor['name'] as String? ?? 'Pengguna')
        : (client['name'] as String? ?? 'Pengguna');
    final receiverAvatar = isClientSide
        ? vendor['avatar_url'] as String?
        : client['avatar_url'] as String?;
    final receiverId = isClientSide
        ? chatRow['vendor_id'] as String?
        : chatRow['client_id'] as String?;

    final vendorRole = vendor['role'] as String?;
    final isContractor = vendorRole == 'vendor' || vendorRole == 'kontraktor';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isContractor
            ? ContractorChatDetailScreen(
                chatId: chatId,
                receiverName: receiverName,
                receiverAvatar: receiverAvatar,
                receiverId: receiverId,
              )
            : ChatDetailScreen(
                chatId: chatId,
                receiverName: receiverName,
                receiverAvatar: receiverAvatar,
                receiverId: receiverId,
                chatStatus: chatRow['status'] as String? ?? 'accepted',
              ),
      ),
    );
    return true;
  }

  Future<bool> _openChatNotification(NotificationModel notif) async {
    try {
      final chatRow = notif.chatId != null
          ? await _fetchChatById(notif.chatId!)
          : await _findChatFromNotificationContent(notif);
      if (chatRow == null) return false;

      return await _navigateToChatRoom(chatRow['id'] as String, chatRow);
    } catch (e) {
      debugPrint('Error open chat notification: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _fetchChatById(String chatId) async {
    final response = await _supabase
        .from('chats')
        .select(
          'id, client_id, vendor_id, status, client:client_id(name, avatar_url, role), vendor:vendor_id(name, avatar_url, role)',
        )
        .eq('id', chatId)
        .maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>?> _findChatFromNotificationContent(
    NotificationModel notif,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final messagePart = notif.message.contains(':')
        ? notif.message.substring(notif.message.indexOf(':') + 1).trim()
        : notif.message.trim();

    final response = await _supabase
        .from('chats')
        .select(
          'id, client_id, vendor_id, status, updated_at, client:client_id(name, avatar_url, role), vendor:vendor_id(name, avatar_url, role), messages(content, created_at, sender_id)',
        )
        .or('client_id.eq.$userId,vendor_id.eq.$userId')
        .order('updated_at', ascending: false)
        .limit(20);

    final chats = List<Map<String, dynamic>>.from(response);
    for (final chat in chats) {
      final messages = List<Map<String, dynamic>>.from(
        (chat['messages'] as List?) ?? [],
      );
      final hasMatchingMessage = messages.any((message) {
        final content = message['content'] as String? ?? '';

        // Exact match
        if (content == messagePart) return true;

        // Image match
        if ((messagePart == '[Gambar dilampirkan]' || messagePart == 'Gambar dilampirkan') &&
            (content.startsWith('http://') || content.startsWith('https://')) &&
            (content.toLowerCase().contains('.png') ||
             content.toLowerCase().contains('.jpg') ||
             content.toLowerCase().contains('.jpeg') ||
             content.toLowerCase().contains('.gif') ||
             content.toLowerCase().contains('.webp'))) {
          return true;
        }

        // File match
        if ((messagePart == '[File dilampirkan]' || messagePart == 'File dilampirkan') &&
            (content.startsWith('http://') || content.startsWith('https://')) &&
            !(content.toLowerCase().contains('.png') ||
              content.toLowerCase().contains('.jpg') ||
              content.toLowerCase().contains('.jpeg') ||
              content.toLowerCase().contains('.gif') ||
              content.toLowerCase().contains('.webp'))) {
          return true;
        }

        // Offer match
        if ((messagePart.contains('penawaran') || messagePart.contains('Penawaran')) &&
            content.startsWith('{') &&
            content.contains('"type":"offer"')) {
          return true;
        }

        // Design match
        if ((messagePart.contains('desain') || messagePart.contains('Desain') || messagePart.contains('revisi') || messagePart.contains('Revisi')) &&
            content.startsWith('{') &&
            content.contains('"type":"design"')) {
          return true;
        }

        return false;
      });
      if (hasMatchingMessage) return chat;
    }

    return null;
  }

  Future<bool> _openChatFromProjectOrBidNotification(NotificationModel notif) async {
    try {
      final chatProvider = context.read<ChatProvider>();
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      String? projectId = notif.projectId;
      String? vendorId;
      String? clientId;

      // 1. Jika ada bidId, ambil detail bid untuk mendapatkan vendorId dan projectId
      if (notif.bidId != null && notif.bidId!.isNotEmpty) {
        final bidRow = await _supabase
            .from('bids')
            .select('project_id, vendor_id, projects:project_id(client_id)')
            .eq('id', notif.bidId!)
            .maybeSingle();

        if (bidRow != null) {
          projectId = bidRow['project_id'] as String?;
          vendorId = bidRow['vendor_id'] as String?;
          if (bidRow['projects'] is Map) {
            clientId = bidRow['projects']['client_id'] as String?;
          }
        }
      }

      // 2. Jika clientId kosong tetapi projectId ada, ambil detail project
      if ((clientId == null || clientId.isEmpty) && projectId != null && projectId.isNotEmpty) {
        final projectRow = await _supabase
            .from('projects')
            .select('client_id')
            .eq('id', projectId)
            .maybeSingle();
        if (projectRow != null) {
          clientId = projectRow['client_id'] as String?;
        }
      }

      // 3. Cari jika sudah ada chat untuk project ini dan user saat ini
      if (projectId != null && projectId.isNotEmpty) {
        final existingChats = await _supabase
            .from('chats')
            .select(
              'id, client_id, vendor_id, status, client:client_id(name, avatar_url, role), vendor:vendor_id(name, avatar_url, role)',
            )
            .eq('project_id', projectId)
            .or('client_id.eq.$userId,vendor_id.eq.$userId')
            .order('updated_at', ascending: false)
            .limit(1);

        if (existingChats.isNotEmpty) {
          final chatRow = Map<String, dynamic>.from(existingChats[0]);
          return await _navigateToChatRoom(chatRow['id'] as String, chatRow);
        }
      }

      // 4. Jika belum ada chat, tetapi info lengkap untuk buat chat tersedia
      String? otherUserId;
      if (userId == clientId) {
        otherUserId = vendorId;
      } else if (userId == vendorId) {
        otherUserId = clientId;
      } else {
        if (clientId != null && userId != clientId) {
          otherUserId = clientId;
        }
      }

      if (otherUserId != null && otherUserId.isNotEmpty) {
        final chatId = await chatProvider.getOrCreateChat(
          otherUserId,
          projectId: projectId,
          forceStatus: 'accepted',
        );

        if (chatId != null) {
          final chatRow = await _fetchChatById(chatId);
          if (chatRow != null) {
            return await _navigateToChatRoom(chatId, chatRow);
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error open chat from project/bid notification: $e');
      return false;
    }
  }

  Future<bool> _openProjectNotification(NotificationModel notif) async {
    try {
      final projectProvider = context.read<ProjectProvider>();
      String? projectId = notif.projectId;
      if ((projectId == null || projectId.isEmpty) && notif.bidId != null) {
        final bid = await _supabase
            .from('bids')
            .select('project_id')
            .eq('id', notif.bidId!)
            .maybeSingle();
        projectId = bid?['project_id'] as String?;
      }
      if (projectId == null || projectId.isEmpty) return false;

      final project = await projectProvider.fetchProjectById(projectId);
      if (project == null || !mounted) return false;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(project: project),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Error open project notification: $e');
      return false;
    }
  }

  void _showNavigationUnavailable() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tujuan notifikasi ini belum tersedia'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == _markAllReadAction) {
                    notifProvider.markAllAsRead();
                  } else if (value == _deleteReadAction) {
                    _confirmDeleteRead(notifProvider);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _markAllReadAction,
                    enabled: notifProvider.unreadCount > 0,
                    child: const Row(
                      children: [
                        Icon(Icons.done_all_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Tandai Semua Dibaca'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _deleteReadAction,
                    enabled: notifProvider.readCount > 0,
                    child: const Row(
                      children: [
                        Icon(Icons.delete_sweep_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Hapus yang Dibaca'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notifProvider, child) {
          if (notifProvider.isLoading && notifProvider.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final notifications = notifProvider.notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tidak ada notifikasi',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => notifProvider.fetchNotifications(),
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 70),
              itemBuilder: (context, index) {
                final notif = notifications[index];

                IconData icon;
                Color iconColor;

                switch (notif.type) {
                  case 'bid':
                    icon = Icons.local_offer_outlined;
                    iconColor = Colors.orange;
                    break;
                  case 'chat':
                    icon = Icons.chat_bubble_outline_rounded;
                    iconColor = AppColors.primary;
                    break;
                  case 'project_update':
                    icon = Icons.check_circle_outline_rounded;
                    iconColor = Colors.green;
                    break;
                  default:
                    icon = Icons.notifications_none_rounded;
                    iconColor = Colors.grey;
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  tileColor: notif.isRead
                      ? Colors.transparent
                      : AppColors.primary.withValues(alpha: 0.05),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: iconColor.withValues(alpha: 0.1),
                    child: Icon(icon, color: iconColor),
                  ),
                  title: Text(
                    notif.title,
                    style: TextStyle(
                      fontWeight: notif.isRead
                          ? FontWeight.w600
                          : FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        _formatMessagePreview(notif.message),
                        style: TextStyle(
                          color: notif.isRead ? Colors.grey : Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _timeAgo(notif.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _handleNotificationTap(notif, notifProvider),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatMessagePreview(String message) {
    String sender = '';
    String body = message;

    if (message.contains(':')) {
      final colonIndex = message.indexOf(':');
      sender = message.substring(0, colonIndex).trim();
      body = message.substring(colonIndex + 1).trim();
    }

    if (body.isEmpty) return message;

    String formattedBody = body;

    if (body.startsWith('{')) {
      try {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final type = data['type'] as String?;
        if (type == 'offer') {
          formattedBody = '📋 Penawaran telah dikirim';
        } else if (type == 'design') {
          final rev = data['revision_number'] as int? ?? 1;
          formattedBody = '🎨 Revisi ke-$rev telah diberikan';
        }
      } catch (_) {}
    } else if (body.startsWith('http://') || body.startsWith('https://')) {
      final lower = body.toLowerCase();
      final isImage = lower.contains('.png') ||
          lower.contains('.jpg') ||
          lower.contains('.jpeg') ||
          lower.contains('.gif') ||
          lower.contains('.webp');
      if (isImage) {
        formattedBody = '🖼️ Gambar dilampirkan';
      } else {
        formattedBody = '📎 File dilampirkan';
      }
    }

    return sender.isNotEmpty ? '$sender: $formattedBody' : formattedBody;
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 30) return '${diff.inDays} hari yang lalu';
    return '${date.day}/${date.month}/${date.year}';
  }
}
