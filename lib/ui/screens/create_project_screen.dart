import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/project_provider.dart';
import '../../core/utils/glass_card.dart'; // Pastikan import IOSGlassCard lu ada di sini

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers Baru Sesuai Database
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _buildingSizeController = TextEditingController();
  final _floorsController = TextEditingController(text: '1');
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();

  // Template & Dropdowns
  final List<String> _houseStyles = ['Minimalis', 'Modern', 'Tropis', 'Industrial', 'Klasik', 'Scandinavian'];
  String? _selectedStyle;

  final List<Map<String, dynamic>> _landTemplates = [
    {'label': 'Tipe 36 (6 x 10 m)', 'size': 60.0, 'basePrice': 250000000.0},
    {'label': 'Tipe 45 (8 x 12 m)', 'size': 96.0, 'basePrice': 350000000.0},
    {'label': 'Tipe 60 (10 x 15 m)', 'size': 150.0, 'basePrice': 550000000.0},
    {'label': 'Custom Mansion (12 x 20 m)', 'size': 240.0, 'basePrice': 900000000.0},
  ];

  Map<String, dynamic>? _selectedLand;
  double _budget = 0;
  double _minBudget = 0;
  final double _maxBudget = 2000000000.0; 

  bool _isButtonPressed = false;

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  void _onTemplateSelected(Map<String, dynamic>? template) {
    if (template != null) {
      setState(() {
        _selectedLand = template;
        _minBudget = template['basePrice'];
        _budget = template['basePrice']; 
      });
    }
  }

  void _submitData() async {
    if (_formKey.currentState!.validate() && _selectedLand != null && _selectedStyle != null) {
      final provider = Provider.of<ProjectProvider>(context, listen: false);
      
      bool success = await provider.createProject(
        title: _titleController.text,
        description: _descController.text,
        budget: _budget,
        landSize: _selectedLand!['size'],
        buildingSize: double.tryParse(_buildingSizeController.text) ?? 0.0,
        floors: int.tryParse(_floorsController.text) ?? 1,
        bedrooms: int.tryParse(_bedroomsController.text) ?? 0,
        bathrooms: int.tryParse(_bathroomsController.text) ?? 0,
        houseStyle: _selectedStyle!,
        location: _locationController.text,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Proyek berhasil dibuat! 🚀'), 
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade800,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua template & gaya desain, bro!'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProjectProvider>().isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F8FF), Color(0xFFFFF0F5)], // Soft pastel gradient ala iOS
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Transparent AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('Detail Proyek Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Informasi Dasar'),
                        _buildSmoothTextField(_titleController, 'Nama Proyek', Icons.home_work_outlined),
                        const SizedBox(height: 16),
                        _buildSmoothTextField(_descController, 'Deskripsi Mimpimu...', Icons.description_outlined, maxLines: 3),
                        const SizedBox(height: 16),
                        _buildSmoothTextField(_locationController, 'Lokasi / Kota', Icons.location_on_outlined),
                        const SizedBox(height: 16),
                        
                        // Dropdown Gaya Rumah
                        _buildGlassDropdown<String>(
                          value: _selectedStyle,
                          hint: 'Gaya Desain',
                          icon: Icons.architecture_rounded,
                          items: _houseStyles.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => setState(() => _selectedStyle = val),
                        ),
                        
                        const SizedBox(height: 32),
                        _buildSectionTitle('Spesifikasi Ruangan'),
                        Row(
                          children: [
                            Expanded(child: _buildSmoothTextField(_buildingSizeController, 'Luas Bangunan (m2)', Icons.square_foot_rounded, isNumber: true)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildSmoothTextField(_floorsController, 'Jml. Lantai', Icons.layers_outlined, isNumber: true)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildSmoothTextField(_bedroomsController, 'Kamar Tidur', Icons.bed_outlined, isNumber: true)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildSmoothTextField(_bathroomsController, 'Kamar Mandi', Icons.bathtub_outlined, isNumber: true)),
                          ],
                        ),

                        const SizedBox(height: 32),
                        _buildSectionTitle('Tanah & Budget'),
                        
                        _buildGlassDropdown<Map<String, dynamic>>(
                          value: _selectedLand,
                          hint: 'Template Luas Tanah',
                          icon: Icons.landscape_outlined,
                          items: _landTemplates.map((t) => DropdownMenuItem(value: t, child: Text(t['label']))).toList(),
                          onChanged: _onTemplateSelected,
                        ),

                        const SizedBox(height: 24),

                        // Slider Budget dengan Glassmorphism
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _selectedLand != null ? 1.0 : 0.4,
                          child: IOSGlassCard(
                            blur: 15,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Estimasi Budget', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                                      Text(
                                        _formatRupiah(_budget),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFB53D1B)), // Warna Terakota
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 6.0,
                                      activeTrackColor: const Color(0xFFB53D1B),
                                      inactiveTrackColor: Colors.black12,
                                      thumbColor: Colors.white,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14.0, elevation: 4),
                                    ),
                                    child: Slider(
                                      value: _budget < _minBudget ? _minBudget : _budget,
                                      min: _minBudget > 0 ? _minBudget : 0,
                                      max: _maxBudget,
                                      divisions: 100,
                                      onChanged: _selectedLand != null ? (val) => setState(() => _budget = val) : null,
                                    ),
                                  ),
                                  if (_selectedLand != null)
                                    Text(
                                      '*Base price mulai dari ${_formatRupiah(_minBudget)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black38, fontStyle: FontStyle.italic),
                                    )
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Tombol Submit (Terakota)
                        GestureDetector(
                          onTapDown: (_) => setState(() => _isButtonPressed = true),
                          onTapUp: (_) {
                            setState(() => _isButtonPressed = false);
                            if (!isLoading) _submitData();
                          },
                          onTapCancel: () => setState(() => _isButtonPressed = false),
                          child: AnimatedScale(
                            scale: _isButtonPressed ? 0.95 : 1.0,
                            duration: const Duration(milliseconds: 100),
                            child: Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFB53D1B), Color(0xFFD85A31)], // Terakota gradient persis di Beranda
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: _isButtonPressed ? [] : [
                                  BoxShadow(color: const Color(0xFFB53D1B).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                                ],
                              ),
                              child: Center(
                                child: isLoading
                                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : const Text(
                                        'Mulai Proyek',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget buat Bikin Dropdown Glassmorphism
  Widget _buildGlassDropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return IOSGlassCard(
      blur: 15,
      child: DropdownButtonFormField<T>(
        value: value,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFB53D1B).withOpacity(0.8)),
          labelText: hint,
          labelStyle: const TextStyle(color: Colors.black54),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildSmoothTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, bool isNumber = false}) {
    return IOSGlassCard(
      blur: 15,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFFB53D1B).withOpacity(0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white.withOpacity(0.5), // Semi transparan biar kerasa glass
        ),
        validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
      ),
    );
  }
}