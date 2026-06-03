import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:path_provider/path_provider.dart';

class ImageCropperScreen extends StatefulWidget {
  final File imageFile;
  const ImageCropperScreen({super.key, required this.imageFile});

  @override
  State<ImageCropperScreen> createState() => _ImageCropperScreenState();
}

class _ImageCropperScreenState extends State<ImageCropperScreen> {
  final _controller = CropController();
  Uint8List? _imageData;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    setState(() {
      _imageData = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Potong Foto', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_imageData != null && !_isCropping)
            TextButton(
              onPressed: () {
                setState(() => _isCropping = true);
                _controller.crop();
              },
              child: const Text('Selesai', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
        ],
      ),
      body: _imageData == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                Crop(
                  image: _imageData!,
                  controller: _controller,
                  onCropped: (result) async {
                    if (result is CropSuccess) {
                      try {
                        final tempDir = await getTemporaryDirectory();
                        final file = File('${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
                        await file.writeAsBytes(result.croppedImage);
                        if (mounted) {
                          Navigator.pop(context, file);
                        }
                      } catch (e) {
                        debugPrint('Error saving cropped image: $e');
                        if (mounted) {
                          setState(() => _isCropping = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gagal menyimpan foto hasil crop'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    } else {
                      if (mounted) {
                        setState(() => _isCropping = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gagal memotong foto'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  aspectRatio: 1.0, // Force square crop for avatar
                  cornerDotBuilder: (size, edgeAlignment) => const DotControl(color: Colors.white),
                ),
                if (_isCropping)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
    );
  }
}
