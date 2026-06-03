import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/providers/architect_provider.dart';
import '../../../data/providers/project_provider.dart';
import '../../arsitek/widgets/buat_penawaran_sheet.dart';
import '../../arsitek/screens/kirim_desain_screen.dart';
import '../../client/screens/architect_offer_detail_screen.dart';
import '../../client/screens/client_design_review_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String receiverName;
  final String? receiverAvatar;
  final String? receiverId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.receiverName,
    this.receiverAvatar,
    this.receiverId,
    this.chatStatus = 'accepted',
  });

  final String? chatStatus;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  String? _currentUserId;
  String? _currentUserRole;

  // Track active offer state for button enabling
  String? _activeBidId;       // bidId dari penawaran aktif di chat ini
  String? _activeTermId;      // termId dari payment term aktif
  String? _activeProjectId;   // projectId dari penawaran aktif
  String _offerPaymentStatus = 'none'; // 'none' | 'pending' | 'paid' | 'confirmed' | 'submitted' | 'revision_requested' | 'completed'

  // Track status per bid id to keep cards independent
  final Map<String, String> _bidStatuses = {}; // bidId -> status ('pending', 'paid', etc.)
  final Map<String, String> _bidTermIds = {};  // bidId -> termId
  final Map<String, String> _bidProjectIds = {}; // bidId -> projectId
  final Map<String, String> _bidActualStatuses = {}; // bidId -> bid actual status ('pending', 'accepted', 'rejected', 'cancelled', etc.)
  final Map<String, DateTime> _bidCreatedAts = {}; // bidId -> bid created_at

  Future<void> _loadBidsStatuses(List<String> bidIds) async {
    if (bidIds.isEmpty) return;
    try {
      final supabase = Supabase.instance.client;
      
      // Query bids
      final bidsResponse = await supabase
          .from('bids')
          .select('id, status, created_at, project_id')
          .inFilter('id', bidIds);
          
      // Query payment terms
      final termsResponse = await supabase
          .from('payment_terms')
          .select('id, bid_id, status, project_id, paid_at, confirmed_at, progress_submitted_at, progress_reviewed_at, revision_requested_at')
          .inFilter('bid_id', bidIds);
          
      if (!mounted) return;
      
      setState(() {
        for (final bid in bidsResponse) {
          final bidId = bid['id'] as String;
          _bidActualStatuses[bidId] = bid['status'] as String? ?? 'pending';
          if (bid['created_at'] != null) {
            _bidCreatedAts[bidId] = DateTime.parse(bid['created_at']);
          }
          if (bid['project_id'] != null) {
            _bidProjectIds[bidId] = bid['project_id'] as String;
          }
        }
        
        for (final bidId in bidIds) {
          if (!_bidStatuses.containsKey(bidId)) {
            _bidStatuses[bidId] = 'pending';
          }
        }
        
        for (final term in termsResponse) {
          final bidId = term['bid_id'] as String;
          final termId = term['id'] as String;
          _bidTermIds[bidId] = termId;
          if (term['project_id'] != null) {
            _bidProjectIds[bidId] = term['project_id'] as String;
          }
          
          final termStatus = term['status'] as String? ?? 'pending';
          final isCompleted = termStatus == 'completed';
          final isProgressSubmitted = term['progress_submitted_at'] != null;
          final isRevisionRequested = term['revision_requested_at'] != null && term['progress_reviewed_at'] == null;
          final isConfirmed = term['confirmed_at'] != null;
          final isWaitingConfirmation = term['paid_at'] != null && term['confirmed_at'] == null;
          
          if (isCompleted) {
            _bidStatuses[bidId] = 'completed';
          } else if (isProgressSubmitted) {
            _bidStatuses[bidId] = 'submitted';
          } else if (isRevisionRequested) {
            _bidStatuses[bidId] = 'revision_requested';
          } else if (isConfirmed) {
            _bidStatuses[bidId] = 'confirmed';
          } else if (isWaitingConfirmation) {
            _bidStatuses[bidId] = 'paid';
          } else {
            _bidStatuses[bidId] = 'pending';
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading bids statuses: $e');
    }
  }

  void _checkAndLoadBidStatuses(List<Map<String, dynamic>> messages) {
    final List<String> newBidIds = [];
    for (final m in messages) {
      final content = m['content'] as String? ?? '';
      if (content.startsWith('{')) {
        try {
          final data = jsonDecode(content);
          if (data['type'] == 'offer') {
            final bidId = data['bid_id'] as String?;
            if (bidId != null && !_bidStatuses.containsKey(bidId)) {
              newBidIds.add(bidId);
            }
          }
        } catch (_) {}
      }
    }
    
    if (newBidIds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadBidsStatuses(newBidIds);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _currentUserId = user?.id;
    _currentUserRole = user?.userMetadata?['role'] as String?;

    // Mark messages as read after a tiny delay to let the stream settle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false)
          .markMessagesAsRead(widget.chatId);
      _loadActiveBidStatus();
    });
  }

  /// Scan messages for the latest offer and check its payment status
  Future<void> _loadActiveBidStatus() async {
    try {
      final supabase = Supabase.instance.client;
      final msgs = await supabase
          .from('messages')
          .select('content')
          .eq('chat_id', widget.chatId)
          .order('created_at', ascending: false)
          .limit(50);

      for (final m in msgs) {
        final content = m['content'] as String? ?? '';
        if (content.startsWith('{')) {
          try {
            final data = jsonDecode(content) as Map<String, dynamic>;
            if (data['type'] == 'offer') {
              final bidId = data['bid_id'] as String?;
              if (bidId != null && mounted) {
                final term = await Provider.of<ProjectProvider>(context, listen: false)
                    .fetchPaymentTermByBidId(bidId);
                setState(() {
                  _activeBidId = bidId;
                  _activeTermId = term?.id;
                  _activeProjectId = term?.projectId;
                  
                  if (term == null) {
                    _offerPaymentStatus = 'pending';
                  } else if (term.isCompleted) {
                    _offerPaymentStatus = 'completed';
                  } else if (term.isProgressSubmitted) {
                    _offerPaymentStatus = 'submitted';
                  } else if (term.isRevisionRequested) {
                    _offerPaymentStatus = 'revision_requested';
                  } else if (term.isConfirmed) {
                    _offerPaymentStatus = 'confirmed';
                  } else if (term.isWaitingConfirmation) {
                    _offerPaymentStatus = 'paid';
                  } else {
                    _offerPaymentStatus = 'pending';
                  }
                });
                return;
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    await Provider.of<ChatProvider>(context, listen: false)
        .sendMessage(widget.chatId, text);

    setState(() => _isSending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool get _isArchitect =>
      _currentUserRole == 'architect' || _currentUserRole == 'arsitek';

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Pending status banner
          Consumer<ChatProvider>(
            builder: (_, chatProv, __) {
              // Check if this chat is still pending
              final isPending = chatProv.pendingChats.any((c) => c.id == widget.chatId) ||
                  (widget.chatStatus == 'pending' && !chatProv.chats.any((c) => c.id == widget.chatId));

              if (!isPending) return const SizedBox.shrink();

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFFFFF3CD),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF856404), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isArchitect
                            ? 'Terima permintaan ini terlebih dahulu untuk membalas.'
                            : 'Menunggu arsitek menerima permintaan konsultasi kamu.',
                        style: const TextStyle(
                          color: Color(0xFF856404),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Messages stream
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: chatProvider.streamMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final messages = snapshot.data ?? [];
                _checkAndLoadBidStatuses(messages);

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Mulai percakapan dengan\n${widget.receiverName}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black45, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                // Auto scroll when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                // Group messages by date
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final senderId = msg['sender_id'] as String? ?? '';
                    final isMe = senderId == _currentUserId;
                    final content = msg['content'] as String? ?? '';
                    final createdAt = msg['created_at'] as String? ?? '';
                    final isRead = msg['is_read'] as bool? ?? false;

                    DateTime? msgTime;
                    try {
                      msgTime = DateTime.parse(createdAt).toLocal();
                    } catch (_) {}

                    // Show date separator if needed
                    bool showDateSep = false;
                    if (index == 0) {
                      showDateSep = true;
                    } else {
                      final prevMsg = messages[index - 1];
                      final prevTime = DateTime.tryParse(
                              (prevMsg['created_at'] as String? ?? ''))
                          ?.toLocal();
                      if (prevTime != null &&
                          msgTime != null &&
                          !_isSameDay(prevTime, msgTime)) {
                        showDateSep = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showDateSep && msgTime != null)
                          _buildDateSeparator(msgTime),
                        _buildMessageBubble(
                          content: content,
                          isMe: isMe,
                          time: msgTime,
                          isRead: isRead,
                          rawMsg: msg,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    final avatarUrl = widget.receiverAvatar;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.cardCream,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : NetworkImage(
                        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.receiverName)}&background=8B2B0F&color=fff&size=64'),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiverName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text('Online', style: TextStyle(color: Colors.green, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildMessageBubble({
    required String content,
    required bool isMe,
    DateTime? time,
    required bool isRead,
    Map<String, dynamic>? rawMsg,
  }) {
    // Detect JSON special message types
    if (content.startsWith('{')) {
      try {
        final data = jsonDecode(content) as Map<String, dynamic>;
        final msgType = data['type'] as String?;
        if (msgType == 'offer') {
          return _buildOfferCard(data, isMe, time);
        }
        if (msgType == 'design') {
          return _buildDesignCard(data, isMe, time);
        }
      } catch (_) {}
    }

    final timeStr = time != null ? DateFormat('HH:mm').format(time) : '';
    const myColor = AppColors.primary;
    const otherColor = Color(0xFFF0EAE2);

    final isUrl = content.startsWith('http://') || content.startsWith('https://');
    final isImage = isUrl && (
        content.toLowerCase().contains('.png') ||
        content.toLowerCase().contains('.jpg') ||
        content.toLowerCase().contains('.jpeg') ||
        content.toLowerCase().contains('.gif') ||
        content.toLowerCase().contains('.webp')
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.cardCream,
              backgroundImage: widget.receiverAvatar != null
                  ? NetworkImage(widget.receiverAvatar!)
                  : NetworkImage(
                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.receiverName)}&background=8B2B0F&color=fff&size=64'),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (isImage)
                  GestureDetector(
                    onTap: () async {
                      try {
                        final uri = Uri.parse(content);
                        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                          throw 'Could not launch';
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Tidak dapat membuka gambar: $e'), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
                    child: _buildImageBubble(content, isMe),
                  )
                else if (isUrl)
                  GestureDetector(
                    onTap: () async {
                      try {
                        final uri = Uri.parse(content);
                        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                          throw 'Could not launch';
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Tidak dapat membuka file: $e'), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
                    child: _buildFileBubble(content, isMe),
                  )
                else
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? myColor : otherColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      content,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(color: Colors.black38, fontSize: 10),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      Icon(
                        isRead ? Icons.done_all_rounded : Icons.done_rounded,
                        size: 13,
                        color: isRead ? AppColors.primaryLight : Colors.black38,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> data, bool isMe, DateTime? time) {
    final bidId = data['bid_id'] as String? ?? '';
    final title = data['title'] as String? ?? 'Penawaran Desain';
    final price = (data['price'] as num?)?.toDouble() ?? 0.0;
    final revisions = data['revisions'] as int? ?? 2;
    final description = data['description'] as String? ?? '';
    final durationDays = data['duration_days'] as int? ?? 14;
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Center(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PENAWARAN DESAIN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5)),
                        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 0.5, color: Colors.black12),
              const SizedBox(height: 12),
              // Stats row
              Row(
                children: [
                  Expanded(child: _buildOfferStat(Icons.payments_outlined, 'Harga', fmt.format(price), AppColors.primary)),
                  Expanded(child: _buildOfferStat(Icons.loop_rounded, 'Revisi', '$revisions×', Colors.teal)),
                  Expanded(child: _buildOfferStat(Icons.schedule_outlined, 'Estimasi', '$durationDays hari', Colors.orange.shade700)),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(description, style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 14),
              // Action buttons
              _buildOfferActions(bidId, isMe, price, title, description, revisions, durationDays),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferStat(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.black45)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
  Widget _buildOfferActions(String bidId, bool isMe, double price, String title, String description, int revisions, int durationDays) {
    final status = _bidStatuses[bidId] ?? 'pending';
    final actualStatus = _bidActualStatuses[bidId] ?? 'pending';
    final createdAt = _bidCreatedAts[bidId];
    final termId = _bidTermIds[bidId];
    final projectId = _bidProjectIds[bidId];

    final isCancelled = actualStatus == 'cancelled';
    final isExpired = actualStatus == 'expired' ||
        (actualStatus == 'pending' &&
         status == 'pending' &&
         createdAt != null &&
         DateTime.now().difference(createdAt).inHours >= 24);

    final isPaid = status == 'paid' || status == 'confirmed' ||
        status == 'submitted' || status == 'revision_requested' || status == 'completed';

    if (isCancelled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, color: Colors.grey.shade500, size: 16),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Penawaran Dibatalkan',
                    style: TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (isMe && _isArchitect) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _deleteOffer(bidId),
                icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.red),
                label: const Text('Hapus Penawaran', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      );
    }

    if (isExpired) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.history_toggle_off_rounded, color: Colors.red.shade700, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Penawaran Kadaluarsa',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (isMe && _isArchitect) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _deleteOffer(bidId),
                icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.red),
                label: const Text('Hapus Penawaran', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      );
    }

    if (isMe && _isArchitect) {
      // Arsitek: edit atau batalkan (hanya jika belum dibayar)
      if (isPaid) {
        if (status == 'paid') {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_empty_rounded, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Client mengklaim sudah bayar. Hubungi client jika belum masuk.',
                        style: TextStyle(color: Color(0xFF856404), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (termId == null || projectId == null) return;
                    setState(() => _isSending = true);
                    final ok = await Provider.of<ProjectProvider>(context, listen: false)
                        .architectConfirmClientPayment(
                          termId: termId,
                          bidId: bidId,
                          projectId: projectId,
                        );
                    if (ok) {
                      await Provider.of<ChatProvider>(context, listen: false)
                          .sendMessage(widget.chatId, '✅ Arsitek telah mengonfirmasi pembayaran! Proyek pembuatan denah/desain resmi dimulai.');
                      _loadBidsStatuses([bidId]);
                      _loadActiveBidStatus();
                    }
                    setState(() => _isSending = false);
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                  label: const Text('Konfirmasi Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          );
        }

        // States: confirmed, submitted, revision_requested, completed
        String statusLabel = '';
        Color boxColor = Colors.green.shade50;
        Color borderAndTextColor = Colors.green.shade700;
        IconData icon = Icons.check_circle_outline;

        if (status == 'confirmed') {
          statusLabel = 'Pembayaran dikonfirmasi – proyek aktif';
        } else if (status == 'submitted') {
          statusLabel = 'Desain sudah dikirim – menunggu review';
        } else if (status == 'revision_requested') {
          statusLabel = 'Client meminta revisi draf';
          boxColor = Colors.orange.shade50;
          borderAndTextColor = Colors.orange.shade700;
          icon = Icons.edit_note_rounded;
        } else if (status == 'completed') {
          statusLabel = 'Proyek selesai ✓';
          boxColor = Colors.blue.shade50;
          borderAndTextColor = Colors.blue.shade700;
          icon = Icons.verified_rounded;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: boxColor == Colors.green.shade50 ? Colors.green.shade100 :
                                   boxColor == Colors.orange.shade50 ? Colors.orange.shade100 : Colors.blue.shade100),
          ),
          child: Row(
            children: [
              Icon(icon, color: borderAndTextColor, size: 16),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: TextStyle(color: borderAndTextColor, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showEditOfferSheet(bidId, price, title, description, revisions, durationDays),
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _cancelOffer(bidId),
              icon: const Icon(Icons.close, size: 14),
              label: const Text('Batalkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      );
    } else if (!_isArchitect) {
      // Client: bayar atau lihat status
      if (isPaid) {
        String clientStatusLabel = '';
        if (status == 'paid') {
          clientStatusLabel = 'Menunggu konfirmasi arsitek...';
        } else if (status == 'confirmed') {
          clientStatusLabel = 'Pembayaran dikonfirmasi – arsitek sedang mengerjakan';
        } else if (status == 'submitted') {
          clientStatusLabel = 'Desain sudah dikirim – silakan tinjau';
        } else if (status == 'revision_requested') {
          clientStatusLabel = 'Menunggu arsitek mengirim revisi...';
        } else if (status == 'completed') {
          clientStatusLabel = 'Proyek selesai ✓';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  clientStatusLabel,
                  style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArchitectOfferDetailScreen(
                  bidId: bidId,
                  title: title,
                  price: price,
                  description: description,
                  revisions: revisions,
                  durationDays: durationDays,
                  architectName: widget.receiverName,
                ),
              ),
            );
            _loadBidsStatuses([bidId]);
            _loadActiveBidStatus();
          },
          icon: const Icon(Icons.payment_rounded, size: 16, color: Colors.white),
          label: const Text('Lihat & Bayar Penawaran', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showEditOfferSheet(String bidId, double price, String title, String description, int revisions, int durationDays) {
    final titleCtrl = TextEditingController(text: title);
    final descCtrl = TextEditingController(text: description);
    final priceCtrl = TextEditingController(text: price.toStringAsFixed(0));
    final durationCtrl = TextEditingController(text: durationDays.toString());
    int editRevisions = revisions;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Edit Penawaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const CircleAvatar(backgroundColor: Color(0xFFF3F2EF), radius: 14, child: Icon(Icons.close, size: 16, color: Colors.black54)),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text('Judul', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: titleCtrl, decoration: _inputDeco('Judul layanan')),
                  const SizedBox(height: 14),
                  const Text('Deskripsi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: descCtrl, maxLines: 3, decoration: _inputDeco('Deskripsi layanan')),
                  const SizedBox(height: 14),
                  const Text('Harga (Rp)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: _inputDeco('Harga')),
                  const SizedBox(height: 14),
                  const Text('Estimasi (hari)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: durationCtrl, keyboardType: TextInputType.number, decoration: _inputDeco('Jumlah hari')),
                  const SizedBox(height: 14),
                  const Text('Jumlah Revisi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () { if (editRevisions > 0) setS(() => editRevisions--); }),
                      Text('$editRevisions ×', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.add_circle_outline, color: AppColors.primary), onPressed: () => setS(() => editRevisions++)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final newPrice = double.tryParse(priceCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? price;
                        final newDays = int.tryParse(durationCtrl.text) ?? durationDays;
                        final ok = await Provider.of<ArchitectProvider>(context, listen: false).editArchitectOffer(
                          bidId: bidId,
                          price: newPrice,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          revisions: editRevisions,
                          durationDays: newDays,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok ? '✅ Penawaran diperbarui' : '❌ Gagal memperbarui penawaran'),
                            backgroundColor: ok ? Colors.green : Colors.red,
                          ));
                          if (ok) {
                            _loadBidsStatuses([bidId]);
                            _loadActiveBidStatus();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.black38, fontSize: 12),
    filled: true,
    fillColor: Colors.grey.shade50,
    contentPadding: const EdgeInsets.all(14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
  );

  Future<void> _cancelOffer(String bidId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Penawaran'),
        content: const Text('Yakin ingin membatalkan penawaran ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final done = await Provider.of<ArchitectProvider>(context, listen: false).cancelArchitectOffer(bidId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(done ? '✅ Penawaran dibatalkan' : '❌ Gagal membatalkan'),
        backgroundColor: done ? Colors.orange : Colors.red,
      ));
      if (done) {
        setState(() {
          _activeBidId = null;
          _offerPaymentStatus = 'none';
        });
        _loadBidsStatuses([bidId]);
        _loadActiveBidStatus();
      }
    }
  }

  Future<void> _deleteOffer(String bidId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text('Hapus Penawaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87)),
          ],
        ),
        content: const Text(
          'Yakin ingin menghapus penawaran ini secara permanen dari percakapan?',
          style: TextStyle(color: Colors.black54, height: 1.5, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black54,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tidak', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              foregroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Ya, Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _isSending = true);
    final done = await Provider.of<ArchitectProvider>(context, listen: false).deleteArchitectOffer(bidId);
    setState(() => _isSending = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(done ? '✅ Penawaran berhasil dihapus' : '❌ Gagal menghapus penawaran'),
        backgroundColor: done ? Colors.red : Colors.red,
      ));
      if (done) {
        setState(() {
          _bidStatuses.remove(bidId);
          _bidActualStatuses.remove(bidId);
          _bidTermIds.remove(bidId);
          _bidProjectIds.remove(bidId);
          _bidCreatedAts.remove(bidId);
          if (_activeBidId == bidId) {
            _activeBidId = null;
            _offerPaymentStatus = 'none';
          }
        });
        _loadActiveBidStatus();
      }
    }
  }

  Widget _buildDesignCard(Map<String, dynamic> data, bool isMe, DateTime? time) {
    final bidId = data['bid_id'] as String? ?? '';
    final notes = data['notes'] as String? ?? '';
    final revisionNumber = data['revision_number'] as int? ?? 1;
    final filesRaw = data['files'] as List<dynamic>? ?? [];
    final files = filesRaw.map((f) => Map<String, String>.from(f as Map)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Center(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.teal.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.architecture, color: Colors.teal, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PENGIRIMAN DESAIN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.teal, letterSpacing: 0.5)),
                        Text('Revisi ke-$revisionNumber', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text('${files.length} file', style: TextStyle(color: Colors.teal.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(height: 0.5, color: Colors.black12),
              const SizedBox(height: 10),
              if (notes.isNotEmpty) ...[
                Text('Catatan: $notes', style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
              ],
              // File chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: files.map((f) {
                  final name = f['name'] ?? 'File';
                  final type = f['type'] ?? 'file';
                  final icon = type == 'image' ? Icons.image_outlined :
                               type == 'pdf' ? Icons.picture_as_pdf :
                               Icons.insert_drive_file_outlined;
                  final color = type == 'pdf' ? Colors.red.shade700 : type == 'image' ? Colors.blue.shade700 : Colors.grey.shade700;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon, size: 13, color: color),
                      const SizedBox(width: 5),
                      Text(name.length > 20 ? '${name.substring(0, 18)}...' : name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                    ]),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              if (!_isArchitect) ...[
                if (_offerPaymentStatus == 'completed')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded, color: Colors.green.shade700, size: 16),
                        const SizedBox(width: 6),
                        Text('Desain Disetujui ✓', style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                else if (_offerPaymentStatus == 'revision_requested')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_top_rounded, color: Colors.orange.shade700, size: 16),
                        const SizedBox(width: 6),
                        Text('Revisi Diajukan – Menunggu Arsitek', style: TextStyle(color: Colors.orange.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientDesignReviewScreen(
                            bidId: bidId,
                            chatId: widget.chatId,
                            designData: data,
                            onReviewed: () {
                              _loadActiveBidStatus();
                            },
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.rate_review_outlined, size: 16, color: Colors.white),
                      label: const Text('Tinjau Desain', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
              ] else ...[
                if (_offerPaymentStatus == 'completed')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(Icons.verified_rounded, color: Colors.green.shade700, size: 14),
                        const SizedBox(width: 6),
                        Text('Desain Disetujui ✓ (Selesai)', style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                else if (_offerPaymentStatus == 'revision_requested')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(Icons.edit_note_rounded, color: Colors.orange.shade700, size: 14),
                        const SizedBox(width: 6),
                        Text('Client meminta revisi draf', style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_top_rounded, color: Colors.teal.shade700, size: 14),
                        const SizedBox(width: 6),
                        Text('Menunggu tinjauan client', style: TextStyle(color: Colors.teal.shade700, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ===== Original message bubble continues =====
  Widget _buildImageBubble(String imageUrl, bool isMe) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
          maxHeight: 220,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12, width: 0.5),
        ),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 150,
              height: 150,
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade200,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined, color: Colors.black45),
                  SizedBox(width: 8),
                  Text('Gagal memuat gambar', style: TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFileBubble(String fileUrl, bool isMe) {
    final filename = _getFilenameFromUrl(fileUrl);
    final isPdf = filename.toLowerCase().endsWith('.pdf');
    final bubbleColor = isMe ? AppColors.primary.withOpacity(0.08) : Colors.white;
    final textColor = isMe ? AppColors.primary : Colors.black87;

    return Container(
      width: MediaQuery.of(context).size.width * 0.65,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isMe ? AppColors.primary.withOpacity(0.2) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
            color: isPdf ? Colors.red.shade700 : AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ketuk untuk membuka',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.open_in_new_rounded, size: 14, color: isMe ? AppColors.primary : Colors.black45),
        ],
      ),
    );
  }

  String _getFilenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final lastSegment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'Lampiran';
      return Uri.decodeComponent(lastSegment);
    } catch (_) {
      return 'File Lampiran';
    }
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(date, now)) {
      label = 'Hari ini';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'Kemarin';
    } else {
      label = DateFormat('d MMMM yyyy', 'id').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Container(height: 0.5, color: Colors.black12)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label, style: const TextStyle(color: Colors.black38, fontSize: 11)),
          ),
          Expanded(child: Container(height: 0.5, color: Colors.black12)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Consumer<ChatProvider>(
      builder: (_, chatProv, __) {
        final isPending = chatProv.pendingChats.any((c) => c.id == widget.chatId) ||
            (widget.chatStatus == 'pending' && !chatProv.chats.any((c) => c.id == widget.chatId));

        if (isPending && _isArchitect) {
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black12, width: 0.5)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Tolak Permintaan'),
                            content: Text('Tolak permintaan dari ${widget.receiverName}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Tolak', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          final rejected = await chatProv.rejectChat(widget.chatId);
                          if (rejected && mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8F2A0C),
                        side: const BorderSide(color: Color(0xFF8F2A0C)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final ok = await chatProv.acceptChat(widget.chatId);
                        if (ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Permintaan konsultasi diterima')),
                          );
                        }
                      },
                      icon: const Icon(Icons.check, size: 16, color: Colors.white),
                      label: const Text('Terima', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8F2A0C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildRegularInputArea();
      },
    );
  }

  Widget _buildRegularInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              if (_isArchitect) ...[
              Row(
                children: [
                  Expanded(child: _buildAttachmentPill(Icons.assignment_outlined, 'Penawaran', () {
                    if (widget.receiverId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tidak dapat menemukan ID client.')),
                      );
                      return;
                    }
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => BuatPenawaranSheet(
                        clientId: widget.receiverId!,
                        chatId: widget.chatId,
                        onOfferSent: (bidId) {
                          setState(() {
                            _activeBidId = bidId;
                            _offerPaymentStatus = 'pending';
                          });
                        },
                      ),
                    );
                  })),
                  const SizedBox(width: 8),
                  Expanded(child: _buildAttachmentPill(
                    Icons.send_outlined,
                    'Kirim Desain',
                    (_offerPaymentStatus == 'confirmed' || _offerPaymentStatus == 'revision_requested') ? () async {
                      final ok = await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => KirimDesainScreen(
                          chatId: widget.chatId,
                          receiverName: widget.receiverName,
                          bidId: _activeBidId ?? '',
                          termId: _activeTermId ?? '',
                        ),
                      ));
                      if (ok == true) {
                        _loadActiveBidStatus();
                      }
                    } : null,
                    disabled: _offerPaymentStatus != 'confirmed' && _offerPaymentStatus != 'revision_requested',
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _buildAttachmentPill(Icons.attach_file_rounded, 'Lampiran', () {
                    _showUploadAttachmentPopup();
                  })),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // Message input row (clean — no emoji/mic)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!_isArchitect) ...[
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28),
                    onPressed: _showUploadAttachmentPopup,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EAE2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      decoration: const InputDecoration(
                        hintText: 'Tulis pesan...',
                        hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isSending
                          ? Colors.grey.shade300
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadAttachmentPopup() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lampirkan File',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pilih gambar atau dokumen (maksimal ukuran 5MB).',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildPopupItem(
                        icon: Icons.image_rounded,
                        label: 'Foto / Galeri',
                        color: Colors.blue.shade50,
                        iconColor: Colors.blue.shade700,
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImageForChat();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPopupItem(
                        icon: Icons.insert_drive_file_rounded,
                        label: 'Dokumen / File',
                        color: Colors.orange.shade50,
                        iconColor: Colors.orange.shade700,
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickFileForChat();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopupItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageForChat() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) {
        final file = File(picked.path);
        final double sizeInMB = file.lengthSync() / (1024 * 1024);
        if (sizeInMB > 5.0) {
          _showErrorSnackBar('Ukuran gambar melebihi batas maksimal 5MB!');
          return;
        }
        await _uploadAndSendAttachment(file, picked.path.split('.').last);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickFileForChat() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final double sizeInMB = file.lengthSync() / (1024 * 1024);
        if (sizeInMB > 5.0) {
          _showErrorSnackBar('Ukuran file melebihi batas maksimal 5MB!');
          return;
        }
        await _uploadAndSendAttachment(file, result.files.single.extension ?? 'file');
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _uploadAndSendAttachment(File file, String fileExtension) async {
    setState(() => _isSending = true);
    
    try {
      final supabase = Supabase.instance.client;
      final fileName = 'chats/attachments/${widget.chatId}/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      
      // Upload to 'documents' bucket
      await supabase.storage.from('documents').upload(fileName, file);
      final publicUrl = supabase.storage.from('documents').getPublicUrl(fileName);
      
      // Send message with the public URL as content
      await Provider.of<ChatProvider>(context, listen: false)
          .sendMessage(widget.chatId, publicUrl);
          
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error uploading attachment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunggah file: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Widget _buildAttachmentPill(IconData icon, String label, VoidCallback? onTap, {bool disabled = false}) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade200 : const Color(0xFFFAF6F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: disabled ? Colors.grey.shade300 : const Color(0xFFEDE5DB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: disabled ? Colors.grey.shade400 : AppColors.primary, size: 15),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: disabled ? Colors.grey.shade400 : Colors.black54, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
