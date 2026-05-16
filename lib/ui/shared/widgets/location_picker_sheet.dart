import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/indonesia_locations.dart';

/// Hasil pemilihan lokasi dari picker.
class LocationResult {
  final String? province;
  final String? city;
  const LocationResult({this.province, this.city});

  /// Format tampilan singkat. `null` untuk filter "Semua".
  String? get display {
    if (province == null) return null;
    if (city == null) return province;
    return '$province · $city';
  }

  /// Format pendek untuk button label (kota saja jika ada).
  String get short {
    if (province == null) return 'Semua';
    return city ?? province!;
  }
}

/// Bottom sheet picker lokasi Indonesia (Provinsi -> Kota).
class LocationPickerSheet extends StatefulWidget {
  final LocationResult? initial;
  const LocationPickerSheet({super.key, this.initial});

  static Future<LocationResult?> show(BuildContext context, {LocationResult? initial}) {
    return showModalBottomSheet<LocationResult>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => LocationPickerSheet(initial: initial),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  String? _province;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _province = widget.initial?.province;
  }

  List<String> get _items {
    final source = _province == null
        ? ['Semua', ...IndonesiaLocations.provinces]
        : ['Semua Kota', ...IndonesiaLocations.citiesOf(_province!)];
    if (_query.isEmpty) return source;
    return source.where((s) => s.toLowerCase().contains(_query.toLowerCase())).toList();
  }

  void _onPick(String value) {
    if (_province == null) {
      if (value == 'Semua') {
        Navigator.pop(context, const LocationResult());
      } else {
        setState(() {
          _province = value;
          _query = '';
        });
      }
    } else {
      if (value == 'Semua Kota') {
        Navigator.pop(context, LocationResult(province: _province));
      } else {
        Navigator.pop(context, LocationResult(province: _province, city: value));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProvinceStep = _province == null;
    final title = isProvinceStep ? 'Pilih Provinsi' : 'Pilih Kota';

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          const SizedBox(height: 12),
          _buildHeader(title, isProvinceStep),
          const SizedBox(height: 12),
          _buildSearch(),
          const SizedBox(height: 8),
          Flexible(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
    );
  }

  Widget _buildHeader(String title, bool isProvinceStep) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (!isProvinceStep)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => setState(() {
                _province = null;
                _query = '';
              }),
            ),
          if (!isProvinceStep) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (!isProvinceStep)
                  Text(_province!, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: AppColors.cardCream, borderRadius: BorderRadius.circular(22)),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: _province == null ? 'Cari provinsi...' : 'Cari kota...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final items = _items;
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text('Tidak ditemukan', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      );
    }
    final isProvinceStep = _province == null;
    return ListView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return ListTile(
          dense: true,
          leading: Icon(
            i == 0 ? Icons.public_rounded : (isProvinceStep ? Icons.map_outlined : Icons.location_city_rounded),
            color: AppColors.primary,
            size: 20,
          ),
          title: Text(item, style: const TextStyle(fontSize: 14)),
          trailing: isProvinceStep && i != 0
              ? const Icon(Icons.chevron_right_rounded, color: Colors.black38, size: 20)
              : null,
          onTap: () => _onPick(item),
        );
      },
    );
  }
}
