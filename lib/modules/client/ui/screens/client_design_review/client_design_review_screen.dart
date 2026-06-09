import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:buildmatch/data/providers/project_provider.dart';
import 'package:buildmatch/data/providers/architect_provider.dart';
import 'package:buildmatch/data/providers/chat_provider.dart';
import 'package:buildmatch/data/models/payment_term_model.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'widgets/design_revisions_info_panel.dart';
import 'widgets/design_files_list.dart';

class ClientDesignReviewScreen extends StatefulWidget {
  final String bidId;
  final String chatId;
  final Map<String, dynamic> designData;
  final VoidCallback onReviewed;

  const ClientDesignReviewScreen({
    super.key,
    required this.bidId,
    required this.chatId,
    required this.designData,
    required this.onReviewed,
  });

  @override
  State<ClientDesignReviewScreen> createState() => _ClientDesignReviewScreenState();
}

class _ClientDesignReviewScreenState extends State<ClientDesignReviewScreen> {
  bool _isLoading = false;
  PaymentTermModel? _paymentTerm;
  Map<String, dynamic>? _bidDetails;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final projectProv = Provider.of<ProjectProvider>(context, listen: false);
      final architectProv = Provider.of<ArchitectProvider>(context, listen: false);

      _paymentTerm = await projectProv.fetchPaymentTermByBidId(widget.bidId);
      _bidDetails = await architectProv.fetchBidById(widget.bidId);
    } catch (e) {
      debugPrint('Error loading review screen data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka file: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _approveDesign() async {
    if (_paymentTerm == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Setujui Desain?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Dengan menyetujui desain ini, Anda menyatakan bahwa pekerjaan arsitek telah selesai sesuai dengan kesepakatan dan proyek akan ditutup.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ya, Setujui', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);
    final projectProv = Provider.of<ProjectProvider>(context, listen: false);
    final chatProv = Provider.of<ChatProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final success = await projectProv.clientReviewProgress(_paymentTerm!.id!);
      if (success) {
        // Cek apakah ini termin pembayaran terakhir
        final termsRes = await Supabase.instance.client
            .from('payment_terms')
            .select('id, order_index')
            .eq('bid_id', widget.bidId)
            .order('order_index', ascending: true);
        
        final List<dynamic> terms = termsRes;
        final currentTerm = terms.firstWhere((t) => t['id'] == _paymentTerm!.id);
        final int orderIndex = currentTerm['order_index'] as int? ?? 1;
        final bool isLastTerm = terms.every((t) => (t['order_index'] as int? ?? 1) <= orderIndex);

        if (isLastTerm) {
          await chatProv.sendMessage(widget.chatId, '✅ Client menyetujui desain! Proyek konsultasi selesai ✓');
        } else {
          await chatProv.sendMessage(widget.chatId, '✅ Client menyetujui draf desain! Silakan lakukan Pelunasan Pembayaran untuk menyelesaikan proyek.');
        }
        widget.onReviewed();
        messenger.showSnackBar(
          const SnackBar(content: Text('✅ Desain disetujui secara formal!'), backgroundColor: Colors.green),
        );
        if (context.mounted) {
          navigator.pop();
        }
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Gagal menyetujui desain.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRevisionDialog() {
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ajukan Revisi Desain', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Jelaskan bagian desain mana saja yang perlu diperbaiki oleh arsitek. Harap deskripsikan dengan jelas.',
                style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Contoh: Posisi pintu utama digeser ke kiri 1 meter, dan tambahkan area taman kecil di belakang...',
                  hintStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Catatan revisi wajib diisi' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final notes = noteCtrl.text.trim();
              Navigator.pop(ctx);
              await _submitRevision(notes);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Kirim Catatan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRevision(String notes) async {
    if (_paymentTerm == null) return;

    setState(() => _isLoading = true);
    final projectProv = Provider.of<ProjectProvider>(context, listen: false);
    final chatProv = Provider.of<ChatProvider>(context, listen: false);

    try {
      final success = await projectProv.clientRequestRevision(
        termId: _paymentTerm!.id!,
        revisionNotes: notes,
      );
      if (success) {
        // Send chat message
        await chatProv.sendMessage(widget.chatId, '↩️ Client meminta revisi: "$notes"');
        widget.onReviewed();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('↩️ Catatan revisi berhasil dikirim!'), backgroundColor: Colors.orange),
          );
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengajukan revisi.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = widget.designData['notes'] as String? ?? '';
    final revisionNumber = widget.designData['revision_number'] as int? ?? 0;
    final filesRaw = widget.designData['files'] as List<dynamic>? ?? [];
    final files = filesRaw.map((f) => Map<String, String>.from(f as Map)).toList();

    int maxRevisions = _bidDetails?['revisions'] ?? 0;
    int remainingRevisions = maxRevisions - revisionNumber;
    if (remainingRevisions < 0) remainingRevisions = 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF8F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tinjau Hasil Desain',
          style: TextStyle(color: Color(0xFF8F2A0C), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Draf Desain Masuk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(revisionNumber == 0 ? 'Desain Awal' : 'Revisi ke-$revisionNumber', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 20),

                  // Info Panel Revisions
                  DesignRevisionsInfoPanel(maxRevisions: maxRevisions, remainingRevisions: remainingRevisions),
                  const SizedBox(height: 20),

                  // Notes section
                  if (notes.isNotEmpty) ...[
                    const Text('Catatan dari Arsitek', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5DCD3)),
                      ),
                      child: Text(
                        notes,
                        style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Files section
                  const Text('Berkas Desain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 8),
                  DesignFilesList(files: files, onOpenFile: _launchURL),
                  const SizedBox(height: 36),

                  // Action buttons
                  _buildActionButtons(remainingRevisions),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButtons(int remainingRevisions) {
    final canRequestRevision = remainingRevisions > 0;

    return Row(
      children: [
        if (canRequestRevision) ...[
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Minta Revisi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onPressed: _showRevisionDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                side: BorderSide(color: Colors.orange.shade700),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
            label: const Text('Setujui Desain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
            onPressed: _approveDesign,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
