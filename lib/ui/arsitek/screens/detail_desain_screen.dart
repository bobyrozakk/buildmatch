import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../data/providers/architect_provider.dart';

class DetailDesainScreen extends StatefulWidget {
  final Map<String, dynamic>? designData;
  const DetailDesainScreen({super.key, this.designData});

  @override
  State<DetailDesainScreen> createState() => _DetailDesainScreenState();
}

class _DetailDesainScreenState extends State<DetailDesainScreen> {
  bool _isLoadingReviews = false;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final portfolioId = widget.designData?['id'];
    if (portfolioId == null) return;

    setState(() => _isLoadingReviews = true);
    final provider = Provider.of<ArchitectProvider>(context, listen: false);
    final reviews = await provider.fetchPortfolioReviews(portfolioId);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    }
  }

  void _showAddReviewDialog() {
    final portfolioId = widget.designData?['id'];
    if (portfolioId == null) return;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anda harus login untuk memberi ulasan.')));
      return;
    }
    
    if (currentUserId == widget.designData?['vendor_id']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anda tidak dapat memberi ulasan pada portofolio Anda sendiri.')));
      return;
    }
    
    // Check if user already reviewed
    final hasReviewed = _reviews.any((r) => r['reviewer_id'] == currentUserId);
    if (hasReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anda sudah memberikan ulasan pada desain ini.')));
      return;
    }

    int selectedRating = 5;
    final TextEditingController commentCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Beri Ulasan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Rating:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < selectedRating ? Icons.star : Icons.star_border,
                            color: const Color(0xFFD97706),
                            size: 32,
                          ),
                          onPressed: () {
                            setModalState(() {
                              selectedRating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text('Komentar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tulis komentar Anda (opsional)...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                // Confirmation Dialog
                                final confirm = await showDialog<bool>(
                                  context: ctx,
                                  builder: (dialogCtx) => AlertDialog(
                                    title: const Text('Konfirmasi Ulasan'),
                                    content: const Text('Apakah anda yakin ingin memberikan rating ini? Anda hanya bisa memberikan ulasan satu kali pada proyek ini.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogCtx, false),
                                        child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(dialogCtx, true),
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8F2A0C)),
                                        child: const Text('Yakin', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirm != true) return;

                                setModalState(() => isSubmitting = true);
                                final provider = Provider.of<ArchitectProvider>(context, listen: false);
                                final success = await provider.addPortfolioReview(
                                  portfolioId: portfolioId,
                                  reviewerId: currentUserId,
                                  rating: selectedRating,
                                  comment: commentCtrl.text.trim(),
                                );
                                
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ulasan berhasil ditambahkan!'), backgroundColor: Colors.green));
                                    _loadReviews();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menambahkan ulasan.'), backgroundColor: Colors.red));
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8F2A0C),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSubmitting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Kirim Ulasan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return '';
    }
  }

  String _formatCost(double cost) {
    if (cost <= 0) return 'Rp -';
    if (cost >= 1000000000) {
      return 'Rp ${(cost / 1000000000).toStringAsFixed(1).replaceAll('.0', '')} M';
    } else if (cost >= 1000000) {
      return 'Rp ${(cost / 1000000).toStringAsFixed(1).replaceAll('.0', '')} Jt';
    } else {
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(cost);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.designData?['title'] ?? 'Desain Tanpa Judul';
    final imageUrl = widget.designData?['image_url'] ?? 'https://via.placeholder.com/500';
    
    final style = widget.designData?['style'] ?? 'Modern';
    final projectType = widget.designData?['project_type'] ?? 'Rumah Tinggal';
    final areaVal = (widget.designData?['area'] as num?)?.toDouble() ?? 0.0;
    final costVal = (widget.designData?['cost'] as num?)?.toDouble() ?? 0.0;
    final description = widget.designData?['description'] ?? 'Belum ada deskripsi.';
    
    final architectName = widget.designData?['architect_name'] ?? 'Arsitek';
    final architectAvatar = widget.designData?['architect_avatar'];
    
    // Calculate avg rating directly from fetched reviews
    double currentAvgRating = 0.0;
    if (_reviews.isNotEmpty) {
      currentAvgRating = _reviews.fold(0.0, (sum, rev) => sum + (rev['rating'] as int? ?? 0)) / _reviews.length;
    } else {
      // Fallback to data if available, else 0
      currentAvgRating = (widget.designData?['avg_rating'] as num?)?.toDouble() ?? 0.0;
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5), // Light cream
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF8F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5C1C08), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail Desain', style: TextStyle(color: Color(0xFF5C1C08), fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), // spacing for bottom bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image
                Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 250,
                      child: imageUrl.toString().startsWith('http') 
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : Container(color: AppColors.cardCream),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8F2A0C), // Reddish brown
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Aktif',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      
                      // Architect Info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFFF3EBE3),
                            backgroundImage: architectAvatar != null ? NetworkImage(architectAvatar) : null,
                            child: architectAvatar == null 
                                ? Text(architectName.isNotEmpty ? architectName[0].toUpperCase() : 'A', style: const TextStyle(color: Color(0xFF8F2A0C), fontWeight: FontWeight.bold, fontSize: 12))
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Oleh', style: TextStyle(color: Colors.black54, fontSize: 10)),
                                Text(architectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                              ],
                            ),
                          ),
                          // Rating Badge
                          if (currentAvgRating > 0)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7), // Light amber
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: Color(0xFFD97706), size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    currentAvgRating.toStringAsFixed(1),
                                    style: const TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          // Cost Info
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: const Color(0xFFFDECE4), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Estimasi Biaya', style: TextStyle(color: Colors.black54, fontSize: 9)),
                                const SizedBox(height: 2),
                                Text(_formatCost(costVal), style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Features Grid
                      Row(
                        children: [
                          _buildFeatureCard(Icons.architecture, 'Gaya', style),
                          const SizedBox(width: 12),
                          _buildFeatureCard(Icons.business, 'Tipe', projectType),
                          const SizedBox(width: 12),
                          _buildFeatureCard(Icons.square_foot_outlined, 'Luas', '${areaVal.toStringAsFixed(0)} m²'),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Deskripsi
                      const Text('Deskripsi Desain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Rating & Ulasan (Sesama Arsitek)
                      const Text('Rating & Ulasan (Sesama Arsitek)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      const SizedBox(height: 16),
                      
                      if (_isLoadingReviews)
                        const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      else if (_reviews.isEmpty)
                        const Text('Belum ada ulasan untuk desain ini.', style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic))
                      else
                        ..._reviews.map((rev) {
                          final reviewerName = rev['reviewer']?['name'] ?? 'Arsitek';
                          final reviewerAvatar = rev['reviewer']?['avatar_url'];
                          final initials = reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : 'A';
                          final rating = rev['rating'] as int? ?? 5;
                          final comment = rev['comment'] ?? '';
                          final date = _formatDate(rev['created_at']);
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildReviewCard(reviewerName, initials, reviewerAvatar, date, rating, comment),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAddReviewDialog,
                    icon: const Icon(Icons.star_outline, size: 18, color: Colors.white),
                    label: const Text('Beri Ulasan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8F2A0C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5DCD3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF8F2A0C), size: 20),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(String name, String initials, String? avatarUrl, String date, int rating, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DCD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFF3EBE3),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? Text(initials, style: const TextStyle(color: Color(0xFF8F2A0C), fontWeight: FontWeight.bold, fontSize: 12)) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    Row(
                      children: List.generate(5, (index) => Icon(Icons.star, size: 12, color: index < rating ? const Color(0xFFD97706) : Colors.grey.shade300)),
                    ),
                  ],
                ),
              ),
              Text(date, style: const TextStyle(fontSize: 10, color: Colors.black45)),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(text, style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
