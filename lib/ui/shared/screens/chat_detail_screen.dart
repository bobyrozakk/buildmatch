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
import '../../arsitek/widgets/buat_penawaran_sheet.dart';
import '../../arsitek/screens/kirim_desain_screen.dart';

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
    });
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
  }) {
    final timeStr = time != null ? DateFormat('HH:mm').format(time) : '';
    const myColor = AppColors.primary; // Dark red-brown for "me"
    const otherColor = Color(0xFFF0EAE2); // Cream for "other"

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
                      final uri = Uri.parse(content);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: _buildImageBubble(content, isMe),
                  )
                else if (isUrl)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(content);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
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
            // Attachment row (only for architects)
            if (_isArchitect) ...[
              Row(
                children: [
                  Expanded(child: _buildAttachmentPill(Icons.assignment_outlined, 'Penawaran', () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => BuatPenawaranSheet(
                        clientId: widget.receiverId ?? widget.chatId,
                        onOfferSent: (bidId) {},
                      ),
                    );
                  })),
                  const SizedBox(width: 8),
                  Expanded(child: _buildAttachmentPill(Icons.send_outlined, 'Kirim Desain', () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => KirimDesainScreen(
                        chatId: widget.chatId,
                        receiverName: widget.receiverName,
                      ),
                    ));
                  })),
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

  Widget _buildAttachmentPill(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEDE5DB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 15),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
