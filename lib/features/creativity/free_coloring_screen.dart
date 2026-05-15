import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/gallery_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';

class FreeColoringScreen extends StatefulWidget {
  const FreeColoringScreen({super.key});

  @override
  State<FreeColoringScreen> createState() => _FreeColoringScreenState();
}

class _FreeColoringScreenState extends State<FreeColoringScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  List<_DrawnLine?> lines = [];
  Color selectedColor = Colors.red;
  double strokeWidth = 5.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: CilikTheme.tealTua),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kanvas Bebas',
          style: GoogleFonts.fredoka(color: CilikTheme.tealTua, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => setState(() => lines.clear()),
          ),
          IconButton(
            icon: const Icon(Icons.save_alt_rounded, color: Colors.teal),
            onPressed: _saveToGallery,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: RepaintBoundary(
                  key: _canvasKey,
                  child: GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        lines.add(_DrawnLine(
                          points: [details.localPosition],
                          color: selectedColor,
                          width: strokeWidth,
                        ));
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        if (lines.isNotEmpty) {
                          lines.last!.points.add(details.localPosition);
                        }
                      });
                    },
                    onPanEnd: (details) {
                      setState(() {
                        lines.add(null);
                      });
                    },
                    child: CustomPaint(
                      painter: _DrawingPainter(lines: lines),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildToolbox(),
        ],
      ),
    );
  }

  Widget _buildToolbox() {
    final colors = [
      Colors.red, Colors.orange, Colors.yellow, Colors.green, 
      Colors.blue, Colors.purple, Colors.pink, Colors.brown, Colors.black
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: colors.map((color) {
                bool isSelected = selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => selectedColor = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: isSelected ? 45 : 35,
                    height: isSelected ? 45 : 35,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? CilikTheme.tealTua : Colors.white,
                        width: 3,
                      ),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.brush, color: Colors.grey, size: 20),
              Expanded(
                child: Slider(
                  value: strokeWidth,
                  min: 1, max: 20,
                  activeColor: CilikTheme.tealTua,
                  onChanged: (v) => setState(() => strokeWidth = v),
                ),
              ),
              const Icon(Icons.brush, color: Colors.grey, size: 30),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveToGallery() async {
    try {
      // 1. Request Permissions (especially for Android)
      if (Platform.isAndroid || Platform.isIOS) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            _showErrorSnackBar('Izin penyimpanan dibutuhkan untuk menyimpan karya.');
            return;
          }
        }
      }

      // 2. Capture Image from RepaintBoundary
      RenderRepaintBoundary? boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _showErrorSnackBar('Gagal mengambil gambar kanvas.');
        return;
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showErrorSnackBar('Gagal memproses data gambar.');
        return;
      }
      Uint8List pngBytes = byteData.buffer.asUint8List();

      // 3. Ensure Directory Exists
      final directory = await getApplicationDocumentsDirectory();
      final String folderPath = '${directory.path}/drawings';
      final Directory drawingsDir = Directory(folderPath);
      if (!await drawingsDir.exists()) {
        await drawingsDir.create(recursive: true);
      }

      // 4. Save to File
      final String fileName = 'drawing_${DateTime.now().millisecondsSinceEpoch}.png';
      final File imageFile = File('$folderPath/$fileName');
      await imageFile.writeAsBytes(pngBytes);

      // 5. Save Path to Service/Database
      await GalleryService.saveImagePath(imageFile.path);

      HapticService.success();
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      print('DEBUG ERROR: Save failed - $e');
      _showErrorSnackBar('Terjadi kesalahan saat menyimpan: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            Text(
              'Berhasil!',
              style: GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Karyamu sudah disimpan di Galeri!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/gallery');
            },
            child: const Text('LIHAT GALERI'),
          ),
        ],
      ),
    );
  }
}

class _DrawnLine {
  final List<Offset> points;
  final Color color;
  final double width;
  _DrawnLine({required this.points, required this.color, required this.width});
}

class _DrawingPainter extends CustomPainter {
  final List<_DrawnLine?> lines;
  _DrawingPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    for (var line in lines) {
      if (line == null) continue;
      final paint = Paint()
        ..color = line.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = line.width
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < line.points.length - 1; i++) {
        canvas.drawLine(line.points[i], line.points[i + 1], paint);
      }
    }
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
