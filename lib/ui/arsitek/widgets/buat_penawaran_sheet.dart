import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../data/providers/architect_provider.dart';
import '../../../data/providers/chat_provider.dart';

class BuatPenawaranSheet extends StatefulWidget {
  final String clientId;
  final String chatId;
  final Function(String bidId) onOfferSent;

  const BuatPenawaranSheet({
    super.key,
    required this.clientId,
    required this.chatId,
    required this.onOfferSent,
  });

  @override
  State<BuatPenawaranSheet> createState() => _BuatPenawaranSheetState();
}

class _BuatPenawaranSheetState extends State<BuatPenawaranSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: "2.500.000");
  final _durationCtrl = TextEditingController(text: "14");

  String _durationUnit = "Hari";
  int _revisions = 2;
  bool _isSplitPayment = false;
  int _dpPercentage = 50;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  void _incrementRevisions() {
    if (_revisions < 5) {
      setState(() {
        _revisions++;
      });
    }
  }

  void _decrementRevisions() {
    if (_revisions > 0) {
      setState(() {
        _revisions--;
      });
    }
  }

  void _submitOffer() async {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul Layanan wajib diisi!')),
      );
      return;
    }

    final double price = double.tryParse(_priceCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga penawaran harus lebih dari Rp 0!'), backgroundColor: Colors.red),
      );
      return;
    }
    if (price > 500000000.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga tidak boleh melebihi Rp 500.000.000 (standar tertinggi)!'), backgroundColor: Colors.red),
      );
      return;
    }

    final int duration = int.tryParse(_durationCtrl.text) ?? 0;
    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estimasi waktu pengerjaan harus lebih dari 0!'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_durationUnit == "Hari" && duration > 365) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estimasi waktu tidak boleh melebihi 365 hari!'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_durationUnit == "Minggu" && duration > 52) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estimasi waktu tidak boleh melebihi 52 minggu!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_revisions > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah revisi tidak boleh melebihi 5 kali!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final int durationDays = _durationUnit == "Minggu" ? duration * 7 : duration;
    final title = _titleCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final revisions = _revisions;

    final architect = Provider.of<ArchitectProvider>(context, listen: false);
    final bidId = await architect.submitArchitectOffer(
      clientId: widget.clientId,
      price: price,
      title: title,
      description: description,
      revisions: revisions,
      durationDays: durationDays,
      isSplitPayment: _isSplitPayment,
      dpPercentage: _dpPercentage,
      chatId: widget.chatId,
    );

    if (bidId != null && mounted) {
      // Kirim offer card message ke chat
      await Provider.of<ChatProvider>(context, listen: false).sendOfferMessage(
        chatId: widget.chatId,
        bidId: bidId,
        title: title,
        price: price,
        revisions: revisions,
        description: description,
        durationDays: durationDays,
        isSplitPayment: _isSplitPayment,
        dpPercentage: _dpPercentage,
      );
      widget.onOfferSent(bidId);
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim penawaran.'), backgroundColor: Colors.red),
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Buat Penawaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                    SizedBox(height: 2),
                    Text('Isi detail layanan yang ingin kamu tawarkan', style: TextStyle(color: Colors.black45, fontSize: 12)),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFFF3F2EF),
                    radius: 14,
                    child: Icon(Icons.close, size: 16, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            _buildLabel('Judul Layanan *'),
            _buildTextField(_titleCtrl, 'contoh: Desain Rumah Minimalis 2 Lantai'),
            
            const SizedBox(height: 14),
            _buildLabel('Deskripsi'),
            _buildTextField(_descCtrl, 'Jelaskan lingkup pekerjaan, material yang digunakan, dan hal penting lainnya...', maxLines: 3),

            const SizedBox(height: 14),
            _buildLabel('Harga *'),
            _buildPriceField(),
            const SizedBox(height: 6),
            _buildPriceLimitWarning(),

            const SizedBox(height: 14),
            _buildLabel('Estimasi Waktu *'),
            _buildDurationField(),
            const SizedBox(height: 6),
            _buildDurationLimitWarning(),

            const SizedBox(height: 14),
            _buildLabel('Jumlah Revisi *'),
            _buildRevisionsStepper(),

            const SizedBox(height: 14),
            _buildLabel('Termin Pembayaran *'),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Penuh (100%)', style: TextStyle(fontSize: 12))),
                    selected: !_isSplitPayment,
                    onSelected: (val) {
                      setState(() {
                        _isSplitPayment = false;
                      });
                    },
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: !_isSplitPayment ? AppColors.primary : Colors.black87,
                      fontWeight: !_isSplitPayment ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('DP & Pelunasan', style: TextStyle(fontSize: 12))),
                    selected: _isSplitPayment,
                    onSelected: (val) {
                      setState(() {
                        _isSplitPayment = true;
                      });
                    },
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _isSplitPayment ? AppColors.primary : Colors.black87,
                      fontWeight: _isSplitPayment ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            if (_isSplitPayment) ...[
              const SizedBox(height: 14),
              _buildLabel('Persentase DP (%)'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _dpPercentage,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black45, size: 16),
                    items: [20, 30, 40, 50, 60, 70].map((pct) => DropdownMenuItem(
                      value: pct,
                      child: Text('$pct% DP - ${100 - pct}% Pelunasan', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    )).toList(),
                    onChanged: (val) => setState(() => _dpPercentage = val!),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Text('PRATINJAU PENAWARAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black45, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            _buildLivePreview(),

            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      label: const Text('Kirim Penawaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: _submitOffer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
            const SizedBox(height: 14),
            Center(
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(color: Colors.black38, fontSize: 10),
                  children: [
                    TextSpan(text: "Dengan mengirim penawaran, kamu menyetujui "),
                    TextSpan(text: "Syarat & Ketentuan", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    TextSpan(text: " BuildMatch."),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 12)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 12),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
      ),
    );
  }

  Widget _buildPriceField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text('Rp', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black45)),
          ),
          Expanded(
            child: TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              onChanged: (val) {
                if (val.isEmpty) return;
                String cleanString = val.replaceAll(RegExp(r'\D'), '');
                if (cleanString.isEmpty) {
                  _priceCtrl.value = const TextEditingValue(
                    text: '',
                    selection: TextSelection.collapsed(offset: 0),
                  );
                  return;
                }
                double value = double.parse(cleanString);
                if (value > 500000000) {
                  value = 500000000;
                }
                final formatter = NumberFormat.decimalPattern('id');
                String formatted = formatter.format(value);
                _priceCtrl.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
                setState(() {});
              },
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceLimitWarning() {
    final valStr = _priceCtrl.text.replaceAll('.', '').replaceAll(',', '');
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

  Widget _buildDurationField() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              onChanged: (val) {
                if (val.isEmpty) return;
                int value = int.tryParse(val) ?? 0;
                int maxVal = _durationUnit == "Hari" ? 365 : 52;
                if (value > maxVal) {
                  _durationCtrl.value = TextEditingValue(
                    text: maxVal.toString(),
                    selection: TextSelection.collapsed(offset: maxVal.toString().length),
                  );
                }
                setState(() {});
              },
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _durationUnit,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black45, size: 16),
                items: ["Hari", "Minggu"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12, color: Colors.black87)))).toList(),
                onChanged: (val) {
                  setState(() {
                    _durationUnit = val!;
                    final durStr = _durationCtrl.text;
                    int value = int.tryParse(durStr) ?? 0;
                    int maxVal = _durationUnit == "Hari" ? 365 : 52;
                    if (value > maxVal) {
                      _durationCtrl.text = maxVal.toString();
                    }
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationLimitWarning() {
    final durStr = _durationCtrl.text;
    final val = int.tryParse(durStr) ?? 0;
    final maxVal = _durationUnit == "Hari" ? 365 : 52;
    final isOver = val >= maxVal;
    final limitText = _durationUnit == "Hari" ? '365 hari' : '52 minggu';
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
                  ? 'Estimasi waktu maksimal $limitText (jumlah maksimal tercapai)'
                  : 'Batas estimasi waktu: Maksimal $limitText',
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

  Widget _buildRevisionsStepper() {
    final bool isMax = _revisions == 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _decrementRevisions,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Icon(Icons.remove, color: Colors.black54, size: 16),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$_revisions', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const Text('revisi', style: TextStyle(fontSize: 10, color: Colors.black45)),
                ],
              ),
              GestureDetector(
                onTap: isMax ? null : _incrementRevisions,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isMax ? Colors.grey.shade400 : const Color(0xFF8F2A0C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
        if (isMax) ...[
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
      ],
    );
  }

  Widget _buildLivePreview() {
    final title = _titleCtrl.text.isEmpty ? "Desain Rumah Minimalis 2 Lantai" : _titleCtrl.text;
    final priceStr = _priceCtrl.text.isEmpty ? "2.500.000" : _priceCtrl.text;
    final double priceVal = double.tryParse(priceStr.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final duration = _durationCtrl.text.isEmpty ? "14" : _durationCtrl.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EBE3), // Light cream brown
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PRATINJAU PENAWARAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF8F2A0C), letterSpacing: 0.5)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF8F2A0C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.description, color: Colors.white, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.black12),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Harga', style: TextStyle(fontSize: 10, color: Colors.black54)),
                    const SizedBox(height: 2),
                    Text(fmt.format(priceVal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF8F2A0C))),
                    if (_isSplitPayment) ...[
                      const SizedBox(height: 6),
                      Text('DP ($_dpPercentage%):', style: const TextStyle(fontSize: 9, color: Colors.black54)),
                      Text(fmt.format(priceVal * _dpPercentage / 100), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal)),
                      const SizedBox(height: 4),
                      Text('Pelunasan (${100 - _dpPercentage}%):', style: const TextStyle(fontSize: 9, color: Colors.black54)),
                      Text(fmt.format(priceVal * (100 - _dpPercentage) / 100), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ],
                ),
              ),
              Container(width: 1, height: _isSplitPayment ? 110 : 30, color: Colors.black12),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Estimasi', style: TextStyle(fontSize: 10, color: Colors.black54)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 12, color: Colors.black87),
                        const SizedBox(width: 4),
                        Text('$duration $_durationUnit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: _isSplitPayment ? 110 : 30, color: Colors.black12),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Revisi', style: TextStyle(fontSize: 10, color: Colors.black54)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.loop, size: 12, color: Colors.black87),
                        const SizedBox(width: 4),
                        Text('$_revisions x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
