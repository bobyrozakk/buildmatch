import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../data/providers/project_provider.dart';
import '../../../data/providers/chat_provider.dart';

class KirimDesainScreen extends StatefulWidget {
  final String chatId;
  final String receiverName;
  final String bidId;
  final String termId;

  const KirimDesainScreen({
    super.key,
    required this.chatId,
    required this.receiverName,
    required this.bidId,
    required this.termId,
  });

  @override
  State<KirimDesainScreen> createState() => _KirimDesainScreenState();
}

class _KirimDesainScreenState extends State<KirimDesainScreen> {
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;
  int _revisionNumber = 1;
  bool _isLoadingRevision = true;

  // Selected files list
  final List<File> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadRevisionNumber();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRevisionNumber() async {
    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select('content')
          .eq('chat_id', widget.chatId);

      int designCount = 0;
      for (var row in response) {
        final content = row['content'] as String? ?? '';
        if (content.startsWith('{')) {
          try {
            final data = jsonDecode(content);
            if (data['type'] == 'design') {
              designCount++;
            }
          } catch (_) {}
        }
      }
      setState(() {
        _revisionNumber = designCount + 1;
        _isLoadingRevision = false;
      });
    } catch (e) {
      debugPrint('Error loading revision number: $e');
      setState(() {
        _isLoadingRevision = false;
      });
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['dwg', 'dxf', 'pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result == null || result.files.isEmpty) return;

      int imageCount = _selectedFiles.where((file) {
        final ext = file.path.split('.').last.toLowerCase();
        return ['jpg', 'jpeg', 'png'].contains(ext);
      }).length;

      List<File> addedFiles = [];
      String? errorMessage;

      for (var pickedFile in result.files) {
        if (pickedFile.path == null) continue;
        final file = File(pickedFile.path!);
        final size = pickedFile.size; // in bytes
        final name = pickedFile.name;
        final ext = name.split('.').last.toLowerCase();

        // Limit size: 5MB (5 * 1024 * 1024)
        if (size > 5 * 1024 * 1024) {
          errorMessage = 'File "$name" melebihi batas ukuran 5MB.';
          break;
        }

        final isImage = ['jpg', 'jpeg', 'png'].contains(ext);
        if (isImage) {
          if (imageCount >= 10) {
            errorMessage = 'Batas maksimal file foto/gambar adalah 10 file.';
            break;
          }
          imageCount++;
        }

        // Avoid adding duplicates
        if (!_selectedFiles.any((f) => f.path == file.path)) {
          addedFiles.add(file);
        }
      }

      if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
        );
      }

      if (addedFiles.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(addedFiles);
        });
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memilih file.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submitDesign() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih minimal 1 berkas desain untuk dikirim.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    final projectProv = Provider.of<ProjectProvider>(context, listen: false);
    final chatProv = Provider.of<ChatProvider>(context, listen: false);
    final supabase = Supabase.instance.client;

    List<Map<String, String>> uploadedFilesMetadata = [];
    List<String> rawFileUrls = [];

    try {
      // 1. Upload each selected file to Supabase Storage
      for (var file in _selectedFiles) {
        final rawName = file.path.split(Platform.isWindows ? '\\' : '/').last;
        final extension = rawName.split('.').last.toLowerCase();
        final storagePath = 'designs/${widget.bidId}/${DateTime.now().millisecondsSinceEpoch}_$rawName';

        // Upload to 'documents' bucket
        await supabase.storage.from('documents').upload(storagePath, file);
        final publicUrl = supabase.storage.from('documents').getPublicUrl(storagePath);

        rawFileUrls.add(publicUrl);

        String typeStr = 'file';
        if (['jpg', 'jpeg', 'png'].contains(extension)) {
          typeStr = 'image';
        } else if (extension == 'pdf') {
          typeStr = 'pdf';
        } else if (['dwg', 'dxf'].contains(extension)) {
          typeStr = 'autocad';
        }

        uploadedFilesMetadata.add({
          'name': rawName,
          'type': typeStr,
          'url': publicUrl,
        });
      }

      // 2. Call ProjectProvider to update payment term status to 'progress_submitted'
      final dbSuccess = await projectProv.submitDesignFiles(
        termId: widget.termId,
        description: _notesCtrl.text.trim(),
        fileUrls: rawFileUrls,
      );

      if (!dbSuccess) throw Exception('Gagal menyimpan detail pengiriman di database.');

      // 3. Send structured design message to Chat
      final chatSuccess = await chatProv.sendDesignMessage(
        chatId: widget.chatId,
        bidId: widget.bidId,
        files: uploadedFilesMetadata,
        notes: _notesCtrl.text.trim(),
        revisionNumber: _revisionNumber,
      );

      if (!chatSuccess) throw Exception('Gagal mengirim notifikasi pengiriman ke obrolan.');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Berkas desain berhasil dikirim ke klien!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error submit design: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim desain: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Kirim Desain',
          style: TextStyle(color: Color(0xFF8F2A0C), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: _isLoadingRevision
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail Pengiriman Desain',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kirim hasil rancangan denah/desain ke client. Ini merupakan pengiriman revisi ke-$_revisionNumber.',
                    style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  _buildLabel('Pilih Klien / Proyek'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5DCD3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.receiverName, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                        const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  _buildLabel('Upload File Desain (Draf) *'),
                  
                  GestureDetector(
                    onTap: _isLoading ? null : _pickFiles,
                    child: CustomPaint(
                      painter: DashedBorderPainter(color: const Color(0xFFD6C8BB), strokeWidth: 1.5, gap: 5),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFA07A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.upload_file, color: Color(0xFF8F2A0C), size: 24),
                            ),
                            const SizedBox(height: 16),
                            const Text('Klik untuk memilih berkas desain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                            const SizedBox(height: 4),
                            const Text('Mendukung JPG, PNG, PDF, DWG/DXF (Maks. 5MB per file)', style: TextStyle(color: Colors.black54, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (_selectedFiles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSelectedFilesList(),
                  ],

                  const SizedBox(height: 24),
                  _buildLabel('Catatan untuk Klien'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5DCD3)),
                    ),
                    child: TextField(
                      controller: _notesCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Berikan penjelasan singkat mengenai revisi atau poin penting dalam desain ini...',
                        hintStyle: TextStyle(color: Colors.black45, fontSize: 12),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: Color(0xFF8F2A0C)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8F2A0C), fontSize: 14)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.send, size: 16, color: Colors.white),
                                label: const Text('Kirim ke Klien', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                                onPressed: _submitDesign,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5C1C08),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 11)),
    );
  }

  Widget _buildSelectedFilesList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_selectedFiles.length, (index) {
        final file = _selectedFiles[index];
        final name = file.path.split(Platform.isWindows ? '\\' : '/').last;
        final ext = name.split('.').last.toLowerCase();

        IconData icon = Icons.insert_drive_file_outlined;
        if (['jpg', 'jpeg', 'png'].contains(ext)) {
          icon = Icons.image_outlined;
        } else if (ext == 'pdf') {
          icon = Icons.picture_as_pdf_outlined;
        } else if (['dwg', 'dxf'].contains(ext)) {
          icon = Icons.architecture_rounded;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EBE3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5DCD3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: const Color(0xFF8F2A0C)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  name.length > 20 ? '${name.substring(0, 18)}...' : name,
                  style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _removeFile(index),
                child: const Icon(Icons.close, size: 14, color: Colors.black54),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({required this.color, required this.strokeWidth, required this.gap});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final double dashWidth = gap;
    final double dashSpace = gap;
    
    final RRect rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12));
    Path path = Path()..addRRect(rrect);
    
    Path dashPath = Path();
    for (var measurePath in path.computeMetrics()) {
      double distance = 0;
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
