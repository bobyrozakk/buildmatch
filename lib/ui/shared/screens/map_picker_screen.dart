import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // Default koordinat di-set ke area Malang / Polinema
  LatLng _currentLocation = const LatLng(-7.9467, 112.6155); 
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Titik Lokasi", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // MESIN PETA OPENSTREETMAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
              onTap: (tapPosition, point) {
                // Pas user nge-tap peta, pindahin pin-nya!
                setState(() {
                  _currentLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.buildmatch.app', // Penting biar gak diblokir OSM
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_on, color: Color(0xFF8B2B0F), size: 45), // Pin Terakota
                  ),
                ],
              ),
            ],
          ),
          
          // BOX INSTRUKSI DI ATAS
          Positioned(
            top: 16, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF8B2B0F)), SizedBox(width: 8),
                  Expanded(child: Text("Geser peta dan ketuk lokasi presisi proyek Anda.", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          ),

          // TOMBOL KONFIRMASI DI BAWAH
          Positioned(
            bottom: 24, left: 24, right: 24,
            child: ElevatedButton(
              onPressed: () {
                // Balik ke layar sebelumnya sambil bawa data Latitude & Longitude
                Navigator.pop(context, _currentLocation);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF8B2B0F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
              ),
              child: const Text("Pilih Lokasi Ini", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }
}