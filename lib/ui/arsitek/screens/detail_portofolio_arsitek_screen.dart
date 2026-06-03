import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/providers/architect_provider.dart';

class DetailPortofolioArsitekScreen extends StatefulWidget {
  final Map<String, dynamic>? portfolioData;
  const DetailPortofolioArsitekScreen({super.key, this.portfolioData});

  @override
  State<DetailPortofolioArsitekScreen> createState() => _DetailPortofolioArsitekScreenState();
}

class _DetailPortofolioArsitekScreenState extends State<DetailPortofolioArsitekScreen> {
  Map<String, dynamic>? _architectProfile;
  bool _isLoadingArchitect = false;

  late Map<String, dynamic> _currentPortfolioData;
  bool _isEditing = false;
  bool _hasChanges = false;

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _styleCtrl;
  late TextEditingController _projectTypeCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _costCtrl;

  // Image slider
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentPortfolioData = Map<String, dynamic>.from(widget.portfolioData ?? {});
    _titleCtrl = TextEditingController(text: _currentPortfolioData['title']?.toString() ?? '');
    _descCtrl = TextEditingController(text: _currentPortfolioData['description']?.toString() ?? '');
    _styleCtrl = TextEditingController(text: _currentPortfolioData['style']?.toString() ?? 'Modern');
    _projectTypeCtrl = TextEditingController(text: _currentPortfolioData['project_type']?.toString() ?? 'Rumah Tinggal');
    _areaCtrl = TextEditingController(text: _currentPortfolioData['area']?.toString() ?? '120');
    
    final double rawCost = (_currentPortfolioData['cost'] as num?)?.toDouble() ?? 0.0;
    _costCtrl = TextEditingController(text: _formatCostRaw(rawCost));
    _fetchArchitectProfile();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _styleCtrl.dispose();
    _projectTypeCtrl.dispose();
    _areaCtrl.dispose();
    _costCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchArchitectProfile() async {
    final vendorId = _currentPortfolioData['vendor_id'] ?? _currentPortfolioData['id_arsitek'];
    if (vendorId == null) return;
    
    setState(() => _isLoadingArchitect = true);
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', vendorId)
          .single();
      if (mounted) {
        setState(() {
          _architectProfile = res;
          _isLoadingArchitect = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching architect profile: $e");
      if (mounted) {
        setState(() => _isLoadingArchitect = false);
      }
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

  String _formatCostRaw(double cost) {
    if (cost <= 0) return '0';
    return NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(cost).trim();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          title: const Text(
            'Detail Portofolio',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          actions: const [], // Removed share action
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildArchitectHeader(),
                  _buildImageGallery(),
                  if (!_isEditing) ...[
                    _buildTitleAndTags(),
                    _buildSpesifikasi(),
                    _buildDeskripsi(),
                  ] else ...[
                    _buildEditForm(),
                  ],
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildFloatingBottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchitectHeader() {
    if (_isLoadingArchitect) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
      );
    }

    final name = _architectProfile?['name'] ?? 'Arsitek';
    final avatarUrl = _architectProfile?['avatar_url'];
    final studioName = _architectProfile?['company_name'] ?? 'Studio Arsitektur';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'A', style: const TextStyle(fontWeight: FontWeight.bold)) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(studioName, style: const TextStyle(color: Colors.black54, fontSize: 10)),
              ],
            ),
          ),
          // Removed Follow Button
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    final List<dynamic> rawUrls = _currentPortfolioData['image_urls'] ?? [];
    List<String> imageUrls = rawUrls.map((e) => e.toString()).toList();

    // Fallback: use single image_url if image_urls is empty
    final String? singleImage = _currentPortfolioData['image_url'] as String?;
    if (imageUrls.isEmpty && singleImage != null && singleImage.isNotEmpty) {
      imageUrls = [singleImage];
    }
    if (imageUrls.isEmpty) {
      imageUrls = ['https://via.placeholder.com/800x400?text=No+Image'];
    }

    final style = _currentPortfolioData['style'] ?? 'Modern';
    final totalImages = imageUrls.length;

    return Column(
      children: [
        // ── PageView Slider ──────────────────────────────────────────
        SizedBox(
          height: 260,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: totalImages,
                onPageChanged: (idx) {
                  setState(() => _currentImageIndex = idx);
                },
                itemBuilder: (context, index) {
                  return Image.network(
                    imageUrls[index],
                    width: double.infinity,
                    height: 260,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey, size: 48),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // Style tag – top left
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.home, color: AppColors.primary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        style,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Image counter – top right (only if more than 1 photo)
              if (totalImages > 1)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1} / $totalImages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Gradient overlay at the bottom for dot visibility
              if (totalImages > 1)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black45, Colors.transparent],
                      ),
                    ),
                  ),
                ),

              // Dot indicators – bottom center
              if (totalImages > 1)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(totalImages, (index) {
                      final isActive = index == _currentImageIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.white54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleAndTags() {
    final title = _currentPortfolioData['title'] ?? 'Desain Tanpa Judul';
    final double costVal = (_currentPortfolioData['cost'] as num?)?.toDouble() ?? 0.0;
    final costStr = _formatCost(costVal);
    final style = _currentPortfolioData['style'] ?? 'Modern';
    final double areaVal = (_currentPortfolioData['area'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87, height: 1.2),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFFDECE4), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Text('Estimasi Biaya', style: TextStyle(color: Colors.black54, fontSize: 9)),
                    const SizedBox(height: 2),
                    Text(costStr, style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTagItem(Icons.architecture, style),
              _buildTagItem(Icons.square_foot, 'Luas: ${areaVal.toStringAsFixed(0)} m²'),
              _buildTagItem(Icons.location_on, _architectProfile?['location'] ?? 'Indonesia'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF7EFE7), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSpesifikasi() {
    final double areaVal = (_currentPortfolioData['area'] as num?)?.toDouble() ?? 0.0;
    final projectType = _currentPortfolioData['project_type'] ?? 'Rumah Tinggal';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Spesifikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSpecCard(Icons.layers, 'Tipe Proyek', projectType)),
              const SizedBox(width: 12),
              Expanded(child: _buildSpecCard(Icons.straighten, 'Luas Lahan', '${areaVal.toStringAsFixed(0)} m²')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.black45, fontSize: 9)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeskripsi() {
    final description = _currentPortfolioData['description'] ?? 'Belum ada deskripsi.';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Detail Portofolio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 16),
          
          _buildFormLabel('Judul Desain'),
          _buildFormTextField(_titleCtrl, 'Masukkan judul desain'),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Gaya Desain'),
                    _buildDropdown(_styleCtrl.text, ["Modern Kontemporer", "Minimalis", "Modern Tropis", "Industrial", "Skandinavia", "Brutalis"], (val) {
                      setState(() {
                        _styleCtrl.text = val!;
                      });
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Tipe Proyek'),
                    _buildDropdown(_projectTypeCtrl.text, ["Rumah Tinggal", "Kafe & Resto", "Kantor Modern", "Villa Resort", "Renovasi"], (val) {
                      setState(() {
                        _projectTypeCtrl.text = val!;
                      });
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Luas Lahan (m²)'),
                    _buildFormTextField(_areaCtrl, '120', keyboardType: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Estimasi Biaya (Rp)'),
                    _buildFormTextField(_costCtrl, '500.000.000', keyboardType: TextInputType.number),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildFormLabel('Deskripsi Lengkap'),
          _buildFormTextField(_descCtrl, 'Ceritakan konsep dan material unik yang Anda gunakan...', maxLines: 8),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 12),
      ),
    );
  }

  Widget _buildFormTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8F2A0C))),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    String val = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: val,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, color: Colors.black87)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFloatingBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!_isEditing) ...[
              // Delete Button
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    label: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: _confirmDelete,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Edit Button
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                    label: const Text('Edit Detail Portofolio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8F2A0C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Cancel Button
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    child: const Text('Batal', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      setState(() {
                        _titleCtrl.text = _currentPortfolioData['title']?.toString() ?? '';
                        _descCtrl.text = _currentPortfolioData['description']?.toString() ?? '';
                        _styleCtrl.text = _currentPortfolioData['style']?.toString() ?? 'Modern';
                        _projectTypeCtrl.text = _currentPortfolioData['project_type']?.toString() ?? 'Rumah Tinggal';
                        _areaCtrl.text = _currentPortfolioData['area']?.toString() ?? '120';
                        
                        final double rawCost = (_currentPortfolioData['cost'] as num?)?.toDouble() ?? 0.0;
                        _costCtrl.text = _formatCostRaw(rawCost);
                        
                        _isEditing = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Save Button
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: _savePortfolioChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8F2A0C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Portofolio', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8F2A0C))),
        content: const Text('Apakah Anda yakin ingin menghapus portofolio ini secara permanen?'),
        actions: [
          TextButton(
            child: const Text('Batal', style: TextStyle(color: Colors.black54)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Hapus', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final portfolioId = _currentPortfolioData['id'];
      if (portfolioId == null) return;

      setState(() => _isLoadingArchitect = true);
      final provider = Provider.of<ArchitectProvider>(context, listen: false);
      final success = await provider.deletePortfolio(portfolioId);

      if (mounted) {
        setState(() => _isLoadingArchitect = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Portofolio berhasil dihapus'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus portofolio'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _savePortfolioChanges() async {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul tidak boleh kosong!')));
      return;
    }

    setState(() => _isLoadingArchitect = true);

    final portfolioId = _currentPortfolioData['id'];
    final double area = double.tryParse(_areaCtrl.text) ?? 120.0;
    final double cost = double.tryParse(_costCtrl.text.replaceAll('.', '').replaceAll(',', '').trim()) ?? 0.0;
    final List<dynamic> rawUrls = _currentPortfolioData['image_urls'] ?? [];
    final List<String> imageUrls = rawUrls.map((e) => e.toString()).toList();
    final String year = _currentPortfolioData['year']?.toString() ?? DateTime.now().year.toString();

    final provider = Provider.of<ArchitectProvider>(context, listen: false);
    final success = await provider.updatePortfolio(
      id: portfolioId,
      title: _titleCtrl.text.trim(),
      style: _styleCtrl.text,
      projectType: _projectTypeCtrl.text,
      area: area,
      cost: cost,
      description: _descCtrl.text.trim(),
      imageUrls: imageUrls,
      year: year,
    );

    if (mounted) {
      setState(() => _isLoadingArchitect = false);
      if (success) {
        setState(() {
          _isEditing = false;
          _hasChanges = true;
          _currentPortfolioData['title'] = _titleCtrl.text.trim();
          _currentPortfolioData['style'] = _styleCtrl.text;
          _currentPortfolioData['project_type'] = _projectTypeCtrl.text;
          _currentPortfolioData['area'] = area;
          _currentPortfolioData['cost'] = cost;
          _currentPortfolioData['description'] = _descCtrl.text.trim();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Detail portofolio berhasil disimpan'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan perubahan'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
