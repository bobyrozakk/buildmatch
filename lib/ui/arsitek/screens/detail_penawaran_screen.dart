import 'package:flutter/material.dart';
// import '../../../core/constants/colors.dart';

class DetailPenawaranScreen extends StatefulWidget {
  final bool isDone;

  const DetailPenawaranScreen({super.key, this.isDone = false});

  @override
  State<DetailPenawaranScreen> createState() => _DetailPenawaranScreenState();
}

class _DetailPenawaranScreenState extends State<DetailPenawaranScreen> {
  late String _title;
  late String _price;
  late String _lastPayment;
  late String _paymentDate;
  late bool _isDone;

  @override
  void initState() {
    super.initState();
    _title = 'Desain Rumah Minimalis 2 Lantai';
    _price = 'Rp 670.000';
    _lastPayment = '22 Mei 2026';
    _paymentDate = '21 Mei 2026';
    _isDone = widget.isDone;
  }

  void _editField(String fieldName, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFFCF8F5),
        title: Text(
          'Ubah $fieldName', 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8F2A0C), fontSize: 16)
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: fieldName,
            labelStyle: const TextStyle(color: Colors.black45),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8F2A0C), width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8F2A0C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  onSave(controller.text.trim());
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$fieldName berhasil diperbarui!'),
                    backgroundColor: const Color(0xFF8F2A0C),
                  ),
                );
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5), // Light cream
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF8F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5C1C08), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Penawaran', 
          style: TextStyle(color: Color(0xFF5C1C08), fontWeight: FontWeight.bold, fontSize: 16)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF5C1C08), size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image with Done/Pending Badge
            Stack(
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDone = !_isDone;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Status diubah ke ${_isDone ? "Done" : "Pending"}'),
                          backgroundColor: _isDone ? Colors.green : const Color(0xFFFFC107),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isDone ? const Color(0xFF00E676) : const Color(0xFFFFC107),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Text(
                        _isDone ? 'Done' : 'Pending',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
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
                  // Title Area with Light Cream Card Background
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF7F4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEFE8E2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 20, 
                              color: Colors.black87, 
                              height: 1.2
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _editField('Judul Desain', _title, (val) => _title = val),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Icon(Icons.edit_outlined, color: Colors.black87, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Stats Row
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(Icons.layers_outlined, 'Lantai', '2 Tingkat')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(Icons.bed_outlined, 'Kamar', '3 Ruang')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(Icons.aspect_ratio_outlined, 'Luas', '180 m²')),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  const Text('Deskripsi Desain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 8),
                  const Text(
                    'Desain ini memadukan material bata ekspos lokal dengan struktur baja modern. Fokus utama adalah sirkulasi udara alami dan pencahayaan maksimal melalui atrium tengah yang memberikan kesan luas dan sejuk di iklim tropis Indonesia.',
                    style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Price Field
                  const Text(
                    'HARGA PENAWARAN (RP)', 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black45, letterSpacing: 0.5)
                  ),
                  const SizedBox(height: 8),
                  _buildEditBox(
                    label: 'Total Penawaran',
                    value: _price,
                    showEdit: true,
                    onTap: () => _editField('Harga Penawaran', _price, (val) => _price = val),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Last Payment Field
                  const Text(
                    'PEMBAYARAN TERAKHIR', 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black45, letterSpacing: 0.5)
                  ),
                  const SizedBox(height: 8),
                  _buildEditBox(
                    label: null,
                    value: _lastPayment,
                    showEdit: true,
                    onTap: () => _editField('Pembayaran Terakhir', _lastPayment, (val) => _lastPayment = val),
                  ),
                  
                  if (_isDone) ...[
                    const SizedBox(height: 16),
                    // Payment Date Field (Only visible when Done)
                    const Text(
                      'PEMBAYARAN PADA', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black45, letterSpacing: 0.5)
                    ),
                    const SizedBox(height: 8),
                    _buildEditBox(
                      label: null,
                      value: _paymentDate,
                      showEdit: true,
                      onTap: () => _editField('Pembayaran Pada', _paymentDate, (val) => _paymentDate = val),
                    ),
                  ],
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF8F2A0C), size: 20),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEditBox({
    String? label, 
    required String value, 
    required bool showEdit, 
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EBE3), // Light brownish gray
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (label != null) ...[
                    Text(label, style: const TextStyle(color: Colors.black45, fontSize: 10)),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    value, 
                    style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (showEdit)
              const Icon(Icons.edit_outlined, color: Colors.black87, size: 20),
          ],
        ),
      ),
    );
  }
}
