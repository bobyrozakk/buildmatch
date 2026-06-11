import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
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
import 'package:buildmatch/modules/client/ui/screens/architect_offer_detail/architect_offer_detail_screen.dart';
import 'package:buildmatch/modules/client/ui/screens/client_design_review/client_design_review_screen.dart';
import 'package:buildmatch/modules/client/logic/chat/chat_cubit.dart';

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
  String _activeProjectStatus = 'pending';

  String _offerPaymentStatus = 'none'; // 'none' | 'pending' | 'paid' | 'confirmed' | 'submitted' | 'revision_requested' | 'completed'
  dynamic _existingReview;    // Holds ReviewModel? or similar json map (dynamic to avoid direct ReviewModel cast if needed)
  bool _loadingReview = false;
  bool _hideRatingReview = false;
  bool _isSplitPayment = false;
  bool _isDesignApproved = false;
  String? _lastProcessedMessageId;

  // Track status per bid id to keep cards independent
  final Map<String, String> _bidStatuses = {}; // bidId -> status ('pending', 'paid', etc.)
  final Map<String, String> _bidTermIds = {};  // bidId -> termId
  final Map<String, String> _bidProjectIds = {}; // bidId -> projectId
  final Map<String, String> _bidActualStatuses = {}; // bidId -> bid actual status ('pending', 'accepted', 'rejected', 'cancelled', etc.)
  final Map<String, DateTime> _bidCreatedAts = {}; // bidId -> bid created_at
  final Map<String, int> _bidActiveTermOrderIndexes = {}; // bidId -> active term order index
  final Map<String, bool> _bidIsDesignApproved = {}; // bidId -> is design approved
  final Map<String, bool> _bidIsSplitPayment = {};   // bidId -> is split payment
  final Map<String, int> _bidMaxDesignRevisions = {}; // bidId -> max design revision

  // Track the highest revision number across all design messages in this chat
  int _maxDesignRevision = -1;

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
          .select('id, bid_id, status, project_id, paid_at, confirmed_at, progress_submitted_at, progress_reviewed_at, revision_requested_at, order_index')
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
        
        // Group payment terms by bid_id
        final Map<String, List<Map<String, dynamic>>> termsByBid = {};
        for (final term in termsResponse) {
          final bidId = term['bid_id'] as String;
          termsByBid.putIfAbsent(bidId, () => []).add(term);
        }
        
        // Map active status for each bid
        for (final bidId in bidIds) {
          final bidTerms = termsByBid[bidId] ?? [];
          if (bidTerms.isEmpty) continue;
          
          // Sort terms by order_index ascending
          bidTerms.sort((a, b) => (a['order_index'] as int? ?? 1).compareTo(b['order_index'] as int? ?? 1));
          
          // Find the active term: first non-completed term, or last term if all completed
          final activeTerm = bidTerms.firstWhere(
            (t) => t['status'] != 'completed',
            orElse: () => bidTerms.last,
          );
          
          final termId = activeTerm['id'] as String;
          _bidTermIds[bidId] = termId;
          _bidActiveTermOrderIndexes[bidId] = activeTerm['order_index'] as int? ?? 1;
          if (activeTerm['project_id'] != null) {
            _bidProjectIds[bidId] = activeTerm['project_id'] as String;
          }
          
          final termStatus = activeTerm['status'] as String? ?? 'pending';
          final isCompleted = termStatus == 'completed';
          final isProgressSubmitted = activeTerm['progress_submitted_at'] != null;
          final isRevisionRequested = activeTerm['revision_requested_at'] != null && activeTerm['progress_reviewed_at'] == null;
          final isConfirmed = activeTerm['confirmed_at'] != null;
          final isWaitingConfirmation = activeTerm['paid_at'] != null && activeTerm['confirmed_at'] == null;
          
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

          // Populate split and design approved flags for this bid
          final isSplit = bidTerms.length > 1;
          _bidIsSplitPayment[bidId] = isSplit;
          
          bool isApproved = false;
          if (isSplit) {
            final dpTerm = bidTerms.firstWhere((t) => t['order_index'] == 1, orElse: () => bidTerms.first);
            isApproved = dpTerm['status'] == 'completed';
          } else {
            isApproved = bidTerms.first['status'] == 'completed';
          }
          _bidIsDesignApproved[bidId] = isApproved;
        }
      });
    } catch (e) {
      debugPrint('Error loading bids statuses: $e');
    }
  }

  void _checkAndLoadBidStatuses(List<Map<String, dynamic>> messages) {
    if (messages.isNotEmpty) {
      final lastMsg = messages.last;
      final lastMsgId = lastMsg['id'] as String?;
      if (lastMsgId != _lastProcessedMessageId) {
        _lastProcessedMessageId = lastMsgId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadActiveBidStatus();
            final bidIds = _bidStatuses.keys.toList();
            if (bidIds.isNotEmpty) {
              _loadBidsStatuses(bidIds);
            }
          }
        });
      }
    }

    final List<String> newBidIds = [];
    final Map<String, int> tempMaxRevs = {};
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
          } else if (data['type'] == 'design') {
            final bidId = data['bid_id'] as String?;
            if (bidId != null) {
              final rev = data['revision_number'] as int? ?? 0;
              final currentMax = tempMaxRevs[bidId] ?? -1;
              if (rev > currentMax) {
                tempMaxRevs[bidId] = rev;
              }
            }
          }
        } catch (_) {}
      }
    }

    bool changed = false;
    for (final entry in tempMaxRevs.entries) {
      if (_bidMaxDesignRevisions[entry.key] != entry.value) {
        _bidMaxDesignRevisions[entry.key] = entry.value;
        changed = true;
      }
    }

    // Keep _maxDesignRevision in sync for the active bid
    if (_activeBidId != null) {
      final activeMax = tempMaxRevs[_activeBidId!] ?? -1;
      if (activeMax > _maxDesignRevision) {
        _maxDesignRevision = activeMax;
        changed = true;
      }
    }

    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
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

  Future<void> _loadExistingReview() async {
    if (_activeProjectId == null || _loadingReview) return;
    setState(() => _loadingReview = true);
    try {
      final review = await Provider.of<ProjectProvider>(context, listen: false)
          .fetchProjectReview(_activeProjectId!);
      if (mounted) {
        setState(() {
          _existingReview = review;
          _loadingReview = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading existing review: $e');
      if (mounted) {
        setState(() => _loadingReview = false);
      }
    }
  }

  /// Scan messages for the latest offer and check its payment status
  Future<void> _loadActiveBidStatus() async {
    try {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
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
                // Fetch actual status of the bid and project to see if it is rejected/cancelled/expired
                final bidRes = await supabase
                    .from('bids')
                    .select('status, projects(status)')
                    .eq('id', bidId)
                    .maybeSingle();

                final bidActualStatus = bidRes?['status'] as String? ?? 'pending';
                if (bidActualStatus == 'rejected' || bidActualStatus == 'cancelled' || bidActualStatus == 'expired') {
                  continue; // Skip this offer, look for another one
                }

                final projectMap = bidRes?['projects'] as Map<String, dynamic>?;
                final projectStatus = projectMap?['status'] as String? ?? 'pending';

                final term = await projectProvider.fetchPaymentTermByBidId(bidId);
                final allTermsRes = await supabase
                    .from('payment_terms')
                    .select('*')
                    .eq('bid_id', bidId)
                    .order('order_index', ascending: true);
                
                final List<Map<String, dynamic>> termsList = List<Map<String, dynamic>>.from(allTermsRes);
                
                bool isDesignApproved = false;
                bool isSplitPayment = false;
                if (termsList.isNotEmpty) {
                  isSplitPayment = termsList.length > 1;
                  if (isSplitPayment) {
                    final dpTerm = termsList.firstWhere((t) => t['order_index'] == 1, orElse: () => termsList.first);
                    isDesignApproved = dpTerm['status'] == 'completed';
                  } else {
                    isDesignApproved = termsList.first['status'] == 'completed';
                  }
                }

                setState(() {
                  _activeBidId = bidId;
                  _activeTermId = term?.id;
                  _activeProjectId = term?.projectId;
                  _activeProjectStatus = projectStatus;
                  _isDesignApproved = isDesignApproved;
                  _isSplitPayment = isSplitPayment;
                  _maxDesignRevision = -1;
                  
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

                  // Synchronize local maps for the active bid
                  _bidStatuses[bidId] = _offerPaymentStatus;
                  _bidIsSplitPayment[bidId] = isSplitPayment;
                  _bidIsDesignApproved[bidId] = isDesignApproved;
                });

                if (_offerPaymentStatus == 'completed' && _activeProjectId != null) {
                  _loadExistingReview();
                }
                return;
              }
            }
          } catch (_) {}
        }
      }

      // If no active offer is found, reset the state
      setState(() {
        _activeBidId = null;
        _activeTermId = null;
        _activeProjectId = null;
        _activeProjectStatus = 'pending';
        _offerPaymentStatus = 'none';
        _maxDesignRevision = -1;
        _isSplitPayment = false;
        _isDesignApproved = false;
      });
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
            builder: (context, chatProv, child) {
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
    final isSplitPayment = data['is_split_payment'] as bool? ?? false;
    final dpPercentage = data['dp_percentage'] as int? ?? 50;
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
              if (isSplitPayment) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.teal.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('DP ($dpPercentage%): ${fmt.format(price * dpPercentage / 100)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal)),
                      Text('Pelunasan: ${fmt.format(price * (100 - dpPercentage) / 100)}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(description, style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 14),
              // Action buttons
              _buildOfferActions(bidId, isMe, price, title, description, revisions, durationDays, isSplitPayment, dpPercentage),
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
  Widget _buildOfferActions(String bidId, bool isMe, double price, String title, String description, int revisions, int durationDays, bool isSplitPayment, int dpPercentage) {
    final status = _bidStatuses[bidId] ?? 'pending';
    final actualStatus = _bidActualStatuses[bidId] ?? 'pending';
    final createdAt = _bidCreatedAts[bidId];
    final termId = _bidTermIds[bidId];
    final projectId = _bidProjectIds[bidId];
    final activeTermOrderIndex = _bidActiveTermOrderIndexes[bidId] ?? 1;

    final isCancelled = actualStatus == 'cancelled';
    final isExpired = actualStatus == 'expired' ||
        (actualStatus == 'pending' &&
         status == 'pending' &&
         createdAt != null &&
         DateTime.now().difference(createdAt).inHours >= 24);

    final isPaid = status == 'paid' || status == 'confirmed' ||
        status == 'submitted' || status == 'revision_requested' || status == 'completed';

    final isPaidOrInProgress = isPaid || activeTermOrderIndex > 1 || actualStatus == 'accepted';

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
      // Arsitek: edit atau batalkan (hanya jika belum dibayar/proyek belum jalan)
      if (isPaidOrInProgress) {
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
                    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
                    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                    setState(() => _isSending = true);
                    final ok = await projectProvider.architectConfirmClientPayment(
                          termId: termId,
                          bidId: bidId,
                          projectId: projectId,
                        );
                    if (ok) {
                      if (activeTermOrderIndex > 1) {
                        await chatProvider.sendMessage(widget.chatId, '✅ Arsitek telah mengonfirmasi pelunasan pembayaran! Proyek konsultasi selesai secara keseluruhan.');
                      } else {
                        await chatProvider.sendMessage(widget.chatId, '✅ Arsitek telah mengonfirmasi pembayaran! Proyek pembuatan denah/desain resmi dimulai.');
                      }
                      if (mounted) {
                        _loadBidsStatuses([bidId]);
                        _loadActiveBidStatus();
                      }
                    }
                    if (mounted) {
                      setState(() => _isSending = false);
                    }
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

        // States: confirmed, submitted, revision_requested, completed, or pending (sisa pembayaran)
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
          statusLabel = 'Proyek selesai & Lunas ✓';
          boxColor = Colors.blue.shade50;
          borderAndTextColor = Colors.blue.shade700;
          icon = Icons.verified_rounded;
        } else if (status == 'pending' && activeTermOrderIndex > 1) {
          statusLabel = 'Menunggu pelunasan sisa pembayaran oleh client';
          boxColor = Colors.orange.shade50;
          borderAndTextColor = Colors.orange.shade700;
          icon = Icons.hourglass_top_rounded;
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
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(color: borderAndTextColor, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showEditOfferSheet(bidId, price, title, description, revisions, durationDays, isSplitPayment, dpPercentage),
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
          clientStatusLabel = 'Proyek selesai & Lunas ✓';
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
                  chatId: widget.chatId,
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

  void _showEditOfferSheet(String bidId, double price, String title, String description, int revisions, int durationDays, bool initialSplit, int initialDp) {
    final titleCtrl = TextEditingController(text: title);
    final descCtrl = TextEditingController(text: description);
    final formatter = NumberFormat.decimalPattern('id');
    final priceCtrl = TextEditingController(text: formatter.format(price));
    final durationCtrl = TextEditingController(text: durationDays.toString());
    int editRevisions = revisions;
    bool editSplit = initialSplit;
    int editDp = initialDp;

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
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      if (val.isEmpty) {
                        setS(() {});
                        return;
                      }
                      String cleanString = val.replaceAll(RegExp(r'\D'), '');
                      if (cleanString.isEmpty) {
                        priceCtrl.value = const TextEditingValue(
                          text: '',
                          selection: TextSelection.collapsed(offset: 0),
                        );
                        setS(() {});
                        return;
                      }
                      double value = double.parse(cleanString);
                      if (value > 500000000) {
                        value = 500000000;
                      }
                      String formatted = formatter.format(value);
                      priceCtrl.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                      setS(() {});
                    },
                    decoration: _inputDeco('Harga'),
                  ),
                  const SizedBox(height: 6),
                  Builder(
                    builder: (context) {
                      final valStr = priceCtrl.text.replaceAll('.', '').replaceAll(',', '');
                      final val = double.tryParse(valStr) ?? 0.0;
                      final isOver = val >= 500000000;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isOver ? Colors.red.shade50 : Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isOver ? Colors.red.shade200 : Colors.teal.shade100,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isOver ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                              size: 14,
                              color: isOver ? Colors.red.shade700 : Colors.teal.shade700,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isOver
                                    ? 'Harga maksimal Rp 500.000.000 (jumlah maksimal tercapai)'
                                    : 'Batas harga: Maksimal Rp 500.000.000',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isOver ? Colors.red.shade700 : Colors.teal.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 14),
                  const Text('Estimasi (hari)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      if (val.isEmpty) {
                        setS(() {});
                        return;
                      }
                      int value = int.tryParse(val) ?? 0;
                      if (value > 365) {
                        durationCtrl.value = const TextEditingValue(
                          text: '365',
                          selection: TextSelection.collapsed(offset: 3),
                        );
                      }
                      setS(() {});
                    },
                    decoration: _inputDeco('Jumlah hari'),
                  ),
                  const SizedBox(height: 6),
                  Builder(
                    builder: (context) {
                      final durStr = durationCtrl.text;
                      final val = int.tryParse(durStr) ?? 0;
                      final isOver = val >= 365;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isOver ? Colors.red.shade50 : Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isOver ? Colors.red.shade200 : Colors.teal.shade100,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isOver ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                              size: 14,
                              color: isOver ? Colors.red.shade700 : Colors.teal.shade700,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isOver
                                    ? 'Estimasi waktu maksimal 365 hari (jumlah maksimal tercapai)'
                                    : 'Batas estimasi waktu: Maksimal 365 hari',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isOver ? Colors.red.shade700 : Colors.teal.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 14),
                  const Text('Jumlah Revisi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (editRevisions > 0) {
                            setS(() => editRevisions--);
                          }
                        },
                      ),
                      Text('$editRevisions ×', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: editRevisions == 5 ? Colors.grey.shade400 : AppColors.primary,
                        ),
                        onPressed: editRevisions == 5
                            ? null
                            : () {
                                if (editRevisions < 5) {
                                  setS(() => editRevisions++);
                                }
                              },
                      ),
                    ],
                  ),
                  if (editRevisions == 5) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red.shade700),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'jumlah revisi maksimal',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text('Termin Pembayaran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Penuh (100%)', style: TextStyle(fontSize: 12))),
                          selected: !editSplit,
                          onSelected: (val) {
                            setS(() {
                              editSplit = false;
                            });
                          },
                          selectedColor: AppColors.primary.withOpacity(0.15),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: !editSplit ? AppColors.primary : Colors.black87,
                            fontWeight: !editSplit ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('DP & Pelunasan', style: TextStyle(fontSize: 12))),
                          selected: editSplit,
                          onSelected: (val) {
                            setS(() {
                              editSplit = true;
                            });
                          },
                          selectedColor: AppColors.primary.withOpacity(0.15),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: editSplit ? AppColors.primary : Colors.black87,
                            fontWeight: editSplit ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (editSplit) ...[
                    const SizedBox(height: 14),
                    const Text('Persentase DP (%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: editDp,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black45, size: 16),
                          items: [20, 30, 40, 50, 60, 70].map((pct) => DropdownMenuItem(
                            value: pct,
                            child: Text('$pct% DP - ${100 - pct}% Pelunasan', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                          )).toList(),
                          onChanged: (val) => setS(() => editDp = val!),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final newPrice = double.tryParse(priceCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? price;
                        if (newPrice <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Harga penawaran harus lebih dari Rp 0!'),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }
                        if (newPrice > 500000000.0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Harga tidak boleh melebihi Rp 500.000.000 (standar tertinggi)!'),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }

                        final newDays = int.tryParse(durationCtrl.text) ?? 0;
                        if (newDays <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Estimasi waktu pengerjaan harus lebih dari 0 hari!'),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }
                        if (newDays > 365) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Estimasi waktu tidak boleh melebihi 365 hari!'),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }

                        if (editRevisions > 5) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Jumlah revisi tidak boleh melebihi 5 kali!'),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }

                        final ok = await Provider.of<ArchitectProvider>(context, listen: false).editArchitectOffer(
                          bidId: bidId,
                          price: newPrice,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          revisions: editRevisions,
                          durationDays: newDays,
                          isSplitPayment: editSplit,
                          dpPercentage: editDp,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok ? '✅ Penawaran diperbarui' : '❌ Gagal memperbarui penawaran'),
                            backgroundColor: ok ? Colors.green : Colors.red,
                          ));
                          if (ok) {
                            final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
                            final titleStr = titleCtrl.text.trim();
                            await Provider.of<ChatProvider>(context, listen: false).sendMessage(
                              widget.chatId,
                              '✏️ Arsitek memperbarui penawaran: "$titleStr" seharga ${formatter.format(newPrice)}',
                              bidId: bidId,
                            );
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
          _bidIsSplitPayment.remove(bidId);
          _bidIsDesignApproved.remove(bidId);
          _bidMaxDesignRevisions.remove(bidId);
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
    final revisionNumber = data['revision_number'] as int? ?? 0;
    final filesRaw = data['files'] as List<dynamic>? ?? [];
    final files = filesRaw.map((f) => Map<String, String>.from(f as Map)).toList();

    // Determine if this is the latest design card for this specific bid
    final maxRevForBid = _bidMaxDesignRevisions[bidId] ?? 0;
    final isLatestDesign = revisionNumber >= maxRevForBid;

    // Effective status for this card
    // - If not the latest card: always show as "revised"
    // - If latest card: use specific bid's status
    final bidStatus = _bidStatuses[bidId] ?? (bidId == _activeBidId ? _offerPaymentStatus : 'pending');
    final effectiveStatus = isLatestDesign ? bidStatus : 'previously_revised';

    final bidIsSplitPayment = _bidIsSplitPayment[bidId] ?? (bidId == _activeBidId ? _isSplitPayment : false);
    final bidIsDesignApproved = _bidIsDesignApproved[bidId] ?? (bidId == _activeBidId ? _isDesignApproved : false);

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
                        Text(revisionNumber == 0 ? 'Desain Awal' : 'Revisi ke-$revisionNumber', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
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
              // File chips — always tappable regardless of status
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: files.map((f) {
                  final name = f['name'] ?? 'File';
                  final type = f['type'] ?? 'file';
                  final url = f['url'] ?? '';
                  final icon = type == 'image' ? Icons.image_outlined :
                               type == 'pdf' ? Icons.picture_as_pdf :
                               Icons.insert_drive_file_outlined;
                  final color = type == 'pdf' ? Colors.red.shade700 : type == 'image' ? Colors.blue.shade700 : Colors.grey.shade700;
                  return GestureDetector(
                    onTap: url.isNotEmpty ? () async {
                      try {
                        final uri = Uri.parse(url);
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
                    } : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: url.isNotEmpty ? Colors.grey.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: url.isNotEmpty ? Colors.grey.shade200 : Colors.grey.shade300),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(icon, size: 13, color: color),
                        const SizedBox(width: 5),
                        Text(name.length > 20 ? '${name.substring(0, 18)}...' : name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                        if (url.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.open_in_new_rounded, size: 10, color: Colors.grey.shade500),
                        ],
                      ]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              // Status area
              _buildDesignCardStatus(
                effectiveStatus: effectiveStatus,
                bidId: bidId,
                data: data,
                isLatestDesign: isLatestDesign,
                bidIsSplitPayment: bidIsSplitPayment,
                bidIsDesignApproved: bidIsDesignApproved,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bangun area status/aksi di bawah card desain
  Widget _buildDesignCardStatus({
    required String effectiveStatus,
    required String bidId,
    required Map<String, dynamic> data,
    required bool isLatestDesign,
    required bool bidIsSplitPayment,
    required bool bidIsDesignApproved,
  }) {
    // Card desain yang sudah direvisi (bukan yang terbaru)
    if (effectiveStatus == 'previously_revised') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.loop_rounded, color: Colors.grey.shade600, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Desain Direvisi',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isArchitect) {
      // Client
      if (bidIsDesignApproved && bidIsSplitPayment) {
        String statusLabel = '';
        Color boxColor = Colors.green.shade50;
        Color textColor = Colors.green.shade700;
        IconData icon = Icons.check_circle_outline;

        if (effectiveStatus == 'completed') {
          statusLabel = 'Desain Telah Selesai & Lunas ✓';
          boxColor = Colors.blue.shade50;
          textColor = Colors.blue.shade700;
          icon = Icons.verified_rounded;
        } else if (effectiveStatus == 'paid') {
          statusLabel = 'Pelunasan Dibayar – Menunggu Konfirmasi Arsitek';
          boxColor = Colors.orange.shade50;
          textColor = Colors.orange.shade700;
          icon = Icons.hourglass_top_rounded;
        } else {
          statusLabel = 'Desain Disetujui – Menunggu Pelunasan Pembayaran';
          boxColor = Colors.teal.shade50;
          textColor = Colors.teal.shade700;
          icon = Icons.hourglass_bottom_rounded;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: boxColor == Colors.green.shade50 ? Colors.green.shade100 :
                     boxColor == Colors.blue.shade50 ? Colors.blue.shade100 :
                     boxColor == Colors.orange.shade50 ? Colors.orange.shade100 : Colors.teal.shade100,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }

      if (effectiveStatus == 'completed') {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded, color: Colors.green.shade700, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Desain Telah Selesai ✓',
                  style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      } else if (effectiveStatus == 'revision_requested') {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_top_rounded, color: Colors.orange.shade700, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Revisi Diajukan – Menunggu Arsitek',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      } else {
        // submitted or confirmed — can still review
        return SizedBox(
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
        );
      }
    } else {
      // Arsitek
      if (bidIsDesignApproved && bidIsSplitPayment) {
        String statusLabel = '';
        Color boxColor = Colors.green.shade50;
        Color borderAndTextColor = Colors.green.shade700;
        IconData icon = Icons.check_circle_outline;

        if (effectiveStatus == 'completed') {
          statusLabel = 'Desain Telah Selesai & Lunas ✓';
          boxColor = Colors.blue.shade50;
          borderAndTextColor = Colors.blue.shade700;
          icon = Icons.verified_rounded;
        } else if (effectiveStatus == 'paid') {
          statusLabel = 'Pelunasan Dibayar – Menunggu Konfirmasi Anda';
          boxColor = Colors.orange.shade50;
          borderAndTextColor = Colors.orange.shade700;
          icon = Icons.hourglass_empty_rounded;
        } else {
          statusLabel = 'Desain Disetujui – Menunggu Pelunasan oleh Client';
          boxColor = Colors.teal.shade50;
          borderAndTextColor = Colors.teal.shade700;
          icon = Icons.hourglass_bottom_rounded;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: boxColor == Colors.green.shade50 ? Colors.green.shade100 :
                     boxColor == Colors.blue.shade50 ? Colors.blue.shade100 :
                     boxColor == Colors.orange.shade50 ? Colors.orange.shade100 : Colors.teal.shade100,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: borderAndTextColor, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(color: borderAndTextColor, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }

      if (effectiveStatus == 'completed') {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(Icons.verified_rounded, color: Colors.green.shade700, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Desain Telah Selesai ✓ (Client Setujui)',
                  style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      } else if (effectiveStatus == 'revision_requested') {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Colors.orange.shade700, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Client meminta revisi draf',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      } else {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: Colors.teal.shade700, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Menunggu tinjauan client',
                  style: TextStyle(color: Colors.teal.shade700, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }
    }
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

  void _showProjectCompletedDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.celebration_rounded, color: Colors.teal, size: 24),
            SizedBox(width: 8),
            Text('Selesaikan Proyek?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin menandai proyek desain ini sebagai selesai? Klien akan diminta memberikan ulasan setelah ini.',
          style: TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 0,
            ),
            child: const Text('Ya, Selesai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );

    if (ok == true && _activeProjectId != null) {
      if (!mounted) return;
      setState(() => _isSending = true);
      final success = await Provider.of<ProjectProvider>(context, listen: false)
          .completeProject(_activeProjectId!);
      if (!mounted) return;
      setState(() => _isSending = false);

      if (success) {
        await Provider.of<ChatProvider>(context, listen: false).sendMessage(
          widget.chatId,
          '🎉 Arsitek telah menandai proyek desain ini selesai secara keseluruhan! Klien silakan memberikan ulasan dan rating.',
          bidId: _activeBidId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Proyek berhasil diselesaikan!')),
          );
        }
        _loadActiveBidStatus();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Gagal menyelesaikan proyek, silakan coba lagi.')),
          );
        }
      }
    }
  }

  Widget _buildWaitingForArchitectSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F5F1),
        border: Border(top: BorderSide(color: Color(0xFFE5DCD3), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Pembayaran Lunas. Menunggu arsitek menyelesaikan proyek...',
                style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelesaikanProyekSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F5F1),
        border: Border(top: BorderSide(color: Color(0xFFE5DCD3), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text('Pelunasan Pembayaran Diterima 🎉', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Pembayaran pelunasan telah terkonfirmasi. Silakan tandai proyek desain ini sebagai selesai agar klien dapat memberikan ulasan.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showProjectCompletedDialog();
                },
                icon: const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                label: const Text(
                  'Selesaikan Desain Proyek',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F5F1), // Cream background matching the theme
        border: Border(top: BorderSide(color: Color(0xFFE5DCD3), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.celebration_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text('Proyek Konsultasi Selesai! 🎉', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _hideRatingReview = true;
                    });
                  },
                  child: const Text('Tulis Pesan', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Berikan penilaian dan ulasan Anda untuk arsitek:', style: TextStyle(color: Colors.black54, fontSize: 11)),
            const SizedBox(height: 8),
            _RatingInputWidget(
              onSubmitted: (rating, comment) async {
                if (_activeProjectId == null) return;
                final architectProv = Provider.of<ArchitectProvider>(context, listen: false);
                final projectProv = Provider.of<ProjectProvider>(context, listen: false);
                
                // Fetch bid to get vendor_id
                final bid = await architectProv.fetchBidById(_activeBidId!);
                final vendorId = bid?['vendor_id'] as String?;
                if (vendorId == null) return;

                final ok = await projectProv.addReview(
                  projectId: _activeProjectId!,
                  vendorId: vendorId,
                  rating: rating,
                  comment: comment,
                );

                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Ulasan berhasil dikirim!'), backgroundColor: Colors.green),
                  );
                  _loadActiveBidStatus();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal mengirim ulasan.'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCompletedSection() {
    final ratingVal = _existingReview != null ? (_existingReview is Map ? _existingReview['rating'] : _existingReview.rating) as int? ?? 5 : 5;
    final commentVal = _existingReview != null ? (_existingReview is Map ? _existingReview['comment'] : _existingReview.comment) as String? ?? '' : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F5F1),
        border: Border(top: BorderSide(color: Color(0xFFE5DCD3), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                const Text('Ulasan Anda Telah Dikirim', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _hideRatingReview = true;
                    });
                  },
                  child: const Text('Tulis Pesan', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(5, (index) => Icon(
                index < ratingVal ? Icons.star_rounded : Icons.star_border_rounded,
                color: Colors.amber,
                size: 20,
              )),
            ),
            if (commentVal.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('"$commentVal"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Consumer<ChatProvider>(
      builder: (context, chatProv, child) {
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
                          if (rejected && context.mounted) {
                            context.read<ChatCubit>().fetchChats();
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
                        if (ok && context.mounted) {
                          context.read<ChatCubit>().fetchChats();
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

        // Flow baru: Arsitek menekan tombol Selesaikan Proyek, Client mengisi rating setelah selesai.
        if (_offerPaymentStatus == 'completed') {
          if (!_isArchitect) {
            // Client
            if (_activeProjectStatus == 'completed') {
              if (!_hideRatingReview) {
                if (_loadingReview) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );
                }
                if (_existingReview == null) {
                  return _buildRatingInputSection();
                } else {
                  return _buildRatingCompletedSection();
                }
              }
            } else {
              // Pembayaran sudah lunas tetapi proyek belum ditandai selesai oleh arsitek
              return _buildWaitingForArchitectSection();
            }
          } else {
            // Arsitek melihat tombol Selesaikan Desain Proyek jika status belum completed
            if (_activeProjectStatus != 'completed') {
              return _buildSelesaikanProyekSection();
            }
          }
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
                  Expanded(child: _buildAttachmentPill(
                    Icons.assignment_outlined,
                    'Penawaran',
                    (_offerPaymentStatus == 'none' || _offerPaymentStatus == 'completed') ? () {
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
                    } : null,
                    disabled: _offerPaymentStatus != 'none' && _offerPaymentStatus != 'completed',
                  )),
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
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSending = true);
    
    try {
      final supabase = Supabase.instance.client;
      final fileName = 'chats/attachments/${widget.chatId}/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      
      // Upload to 'documents' bucket
      await supabase.storage.from('documents').upload(fileName, file);
      final publicUrl = supabase.storage.from('documents').getPublicUrl(fileName);
      
      // Send message with the public URL as content
      await chatProvider.sendMessage(widget.chatId, publicUrl);
          
      if (mounted) {
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error uploading attachment: $e');
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal mengunggah file: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
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

class _RatingInputWidget extends StatefulWidget {
  final Function(int rating, String comment) onSubmitted;

  const _RatingInputWidget({required this.onSubmitted});

  @override
  State<_RatingInputWidget> createState() => _RatingInputWidgetState();
}

class _RatingInputWidgetState extends State<_RatingInputWidget> {
  int _selectedRating = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starVal = index + 1;
            return IconButton(
              onPressed: _submitting
                  ? null
                  : () {
                      setState(() {
                        _selectedRating = starVal;
                      });
                    },
              icon: Icon(
                starVal <= _selectedRating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: Colors.amber,
                size: 28,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            );
          }),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentCtrl,
          maxLines: 2,
          enabled: !_submitting,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Tulis ulasan Anda untuk arsitek...',
            hintStyle: const TextStyle(fontSize: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.teal.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.teal),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 38,
          child: ElevatedButton(
            onPressed: _submitting
                ? null
                : () async {
                    setState(() {
                      _submitting = true;
                    });
                    await widget.onSubmitted(
                      _selectedRating,
                      _commentCtrl.text,
                    );
                    if (mounted) {
                      setState(() {
                        _submitting = false;
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Kirim Ulasan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
