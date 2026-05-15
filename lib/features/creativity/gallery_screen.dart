import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/gallery_service.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:io';
import 'dart:typed_data';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<String> imagePaths = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  void _loadImages() {
    setState(() {
      imagePaths = GalleryService.getSavedImages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: CilikTheme.tealTua),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Galeri Karyaku',
          style: GoogleFonts.fredoka(color: CilikTheme.tealTua, fontWeight: FontWeight.bold),
        ),
      ),
      body: imagePaths.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: imagePaths.length,
              itemBuilder: (context, index) {
                final path = imagePaths[index];
                return GestureDetector(
                  onTap: () => _openFullScreen(path),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(
                                File(path),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Karya #${imagePaths.length - index}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => _deleteImage(path),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.palette_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Belum ada karya nih...',
            style: GoogleFonts.fredoka(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text('Ayo mulai mewarnai!', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _openFullScreen(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImage(path: path, onDelete: () {
          _loadImages();
        }),
      ),
    );
  }

  Future<void> _deleteImage(String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Karya?'),
        content: const Text('Apakah kamu yakin ingin menghapus karya indah ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('TIDAK')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('HAPUS', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await GalleryService.deleteImage(path);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      _loadImages();
    }
  }
}

class FullScreenImage extends StatelessWidget {
  final String path;
  final VoidCallback onDelete;

  const FullScreenImage({super.key, required this.path, required this.onDelete});

  Future<void> _saveToPhone(BuildContext context) async {
    try {
      final File imageFile = File(path);
      final Uint8List bytes = await imageFile.readAsBytes();
      final result = await ImageGallerySaver.saveImage(bytes);
      
      if (result['isSuccess'] == true) {
        HapticService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil disimpan ke Galeri HP!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan ke HP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _saveToPhone(context),
            tooltip: 'Simpan ke HP',
          ),
        ],
      ),
      body: Center(
        child: Hero(
          tag: path,
          child: InteractiveViewer(
            child: Image.file(File(path)),
          ),
        ),
      ),
    );
  }
}
