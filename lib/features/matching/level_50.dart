import 'package:flutter/material.dart';

class Level50Screen extends StatefulWidget {
  const Level50Screen({Key? key}) : super(key: key);

  @override
  State<Level50Screen> createState() => _Level50ScreenState();
}

class _Level50ScreenState extends State<Level50Screen> {
  // Definisi ukuran grid (4 Kolom x 5 Baris)
  final int totalColumns = 4;
  final int totalRows = 5;

  // Track panel yang sudah selesai (0: Ungu Tua, 1: Oranye, 2: Hijau, 3: Ungu Muda)
  List<bool> panelSuccess = [false, false, false, false];
  
  // State untuk menyimpan garis yang sedang digambar user pada panel aktif
  int activePanel = 0;
  List<PointIndex> userPath = [];
  PointIndex? drawingStart;
  Offset? currentDragOffset;

  // Kunci Jawaban koordinat untuk masing-masing panel (pola garis terhubung)
  // Format: Menghubungkan titik (kolom, baris)
  final List<List<LineSegment>> targetAnswers = [
    // Panel 1: Bentuk 'P' Terbalik (Ungu Tua)
    [
      LineSegment(PointIndex(0, 0), PointIndex(3, 0)),
      LineSegment(PointIndex(3, 0), PointIndex(3, 2)),
      LineSegment(PointIndex(3, 2), PointIndex(0, 2)),
      LineSegment(PointIndex(0, 2), PointIndex(0, 0)),
      LineSegment(PointIndex(0, 2), PointIndex(0, 4)),
    ],
    // Panel 2: Bentuk 'U' Ganda (Oranye)
    [
      LineSegment(PointIndex(0, 0), PointIndex(0, 4)),
      LineSegment(PointIndex(0, 4), PointIndex(1, 4)),
      LineSegment(PointIndex(1, 4), PointIndex(1, 1)),
      LineSegment(PointIndex(1, 1), PointIndex(2, 1)),
      LineSegment(PointIndex(2, 1), PointIndex(2, 4)),
      LineSegment(PointIndex(2, 4), PointIndex(3, 4)),
      LineSegment(PointIndex(3, 4), PointIndex(3, 0)),
    ],
    // Panel 3: Bentuk Tangga Berliku (Hijau Tua)
    [
      LineSegment(PointIndex(0, 0), PointIndex(2, 0)),
      LineSegment(PointIndex(2, 0), PointIndex(2, 2)),
      LineSegment(PointIndex(2, 2), PointIndex(0, 2)),
      LineSegment(PointIndex(0, 2), PointIndex(0, 4)),
      LineSegment(PointIndex(0, 4), PointIndex(3, 4)),
    ],
    // Panel 4: Bentuk Jembatan/Gerbang (Ungu Muda)
    [
      LineSegment(PointIndex(0, 4), PointIndex(0, 2)),
      LineSegment(PointIndex(0, 2), PointIndex(1, 2)),
      LineSegment(PointIndex(1, 2), PointIndex(1, 0)),
      LineSegment(PointIndex(1, 0), PointIndex(2, 0)),
      LineSegment(PointIndex(2, 0), PointIndex(2, 2)),
      LineSegment(PointIndex(2, 2), PointIndex(3, 2)),
      LineSegment(PointIndex(3, 2), PointIndex(3, 4)),
    ],
  ];

  final List<Color> panelColors = [
    Colors.purple.shade900,
    Colors.orange.shade700,
    Colors.green.shade800,
    Colors.purple.shade400,
  ];

  void _checkValidation() {
    // Logika pencocokan sederhana: periksa apakah user berhasil membuat semua segmen kunci
    List<LineSegment> required = targetAnswers[activePanel];
    int correctCount = 0;

    for (var req in required) {
      bool found = false;
      for (int i = 0; i < userPath.length - 1; i++) {
        var seg = LineSegment(userPath[i], userPath[i + 1]);
        if ((seg.start == req.start && seg.end == req.end) ||
            (seg.start == req.end && seg.end == req.start)) {
          found = true;
          break;
        }
      }
      if (found) correctCount++;
    }

    if (correctCount == required.length) {
      setState(() {
        panelSuccess[activePanel] = true;
        userPath.clear();
        if (activePanel < 3) {
          activePanel++; // Lanjut ke panel berikutnya
        } else {
          _showWinDialog(); // Semua selesai!
        }
      });
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Milestone Selesai!'),
        content: const Text('Hebat! Kamu berhasil menyelesaikan tantangan Level 50!'),
        actions: [
          TextButton(
            onPressed: () async {
              // Integrasi Firebase progress simpan data UAS
              // await UserService.updateProgress(50); 
              Navigator.pop(context);
              Navigator.pop(context); // Kembali ke Map Screen
            },
            child: const Text('Selesai & Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Level 50: Replikasi Pola Titik'),
        backgroundColor: panelColors[activePanel],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Tantangan Panel Aktif: ${activePanel + 1} / 4',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            // Indikator Progress Miniatur Panel
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 40,
                height: 10,
                decoration: BoxDecoration(
                  color: panelSuccess[index] ? Colors.green : (index == activePanel ? panelColors[index] : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(5),
                ),
              )),
            ),
            const SizedBox(height: 15),
            // Play Area Utama
            Expanded(
              child: Row(
                children: [
                  // SISI KIRI: Referensi Kunci Jawaban (Static)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('CONTOH', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        AspectRatio(
                          aspectRatio: 4 / 5,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                            child: CustomPaint(
                              painter: GridPainter(
                                columns: totalColumns,
                                rows: totalRows,
                                color: panelColors[activePanel],
                                staticSegments: targetAnswers[activePanel],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // SISI KANAN: Tempat Menggambar Anak (Interactive)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('GAMBAR DI SINI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        const SizedBox(height: 5),
                        AspectRatio(
                          aspectRatio: 4 / 5,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue, width: 2),
                              color: Colors.blue.shade50.withOpacity(0.3),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return GestureDetector(
                                  onPanStart: (details) {
                                    RenderBox box = context.findRenderObject() as RenderBox;
                                    Offset localPos = box.globalToLocal(details.globalPosition);
                                    PointIndex? node = _getNodeFromOffset(localPos, constraints.maxWidth, constraints.maxHeight);
                                    if (node != null) {
                                      setState(() {
                                        drawingStart = node;
                                        if (userPath.isEmpty || userPath.last != node) {
                                          userPath.add(node);
                                        }
                                      });
                                    }
                                  },
                                  onPanUpdate: (details) {
                                    RenderBox box = context.findRenderObject() as RenderBox;
                                    Offset localPos = box.globalToLocal(details.globalPosition);
                                    setState(() {
                                      currentDragOffset = localPos;
                                    });
                                    PointIndex? node = _getNodeFromOffset(localPos, constraints.maxWidth, constraints.maxHeight);
                                    if (node != null && drawingStart != null && node != drawingStart) {
                                      // Jika mendeteksi node baru yang tetangga dekat, kunci jalurnya
                                      if ((node.col - drawingStart!.col).abs() + (node.row - drawingStart!.row).abs() == 1) {
                                        setState(() {
                                          if (!userPath.contains(node)) {
                                            userPath.add(node);
                                          }
                                          drawingStart = node;
                                        });
                                      }
                                    }
                                  },
                                  onPanEnd: (details) {
                                    setState(() {
                                      drawingStart = null;
                                      currentDragOffset = null;
                                    });
                                    _checkValidation();
                                  },
                                  child: CustomPaint(
                                    painter: GridPainter(
                                      columns: totalColumns,
                                      rows: totalRows,
                                      color: panelColors[activePanel],
                                      userPath: userPath,
                                      liveDragOffset: currentDragOffset,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tombol Reset Panel Aktif
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () => setState(() => userPath.clear()),
                icon: const Icon(Icons.refresh),
                label: const Text('Ulangi Gambar'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Helper pencarian titik koordinat terdekat dari sentuhan jari anak (Snap)
  PointIndex? _getNodeFromOffset(Offset offset, double width, double height) {
    double cellWidth = width / (totalColumns + 1);
    double cellHeight = height / (totalRows + 1);

    for (int c = 0; c < totalColumns; c++) {
      for (int r = 0; r < totalRows; r++) {
        double nodeX = cellWidth * (c + 1);
        double nodeY = cellHeight * (r + 1);
        // Radius toleransi tap anak (padding hitbox diatur longgar 30px)
        if ((offset.dx - nodeX).abs() < 30 && (offset.dy - nodeY).abs() < 30) {
          return PointIndex(c, r);
        }
      }
    }
    return null;
  }
}

// Data Model Pendukung Koordinat Grid Matrix
class PointIndex {
  final int col;
  final int row;
  PointIndex(this.col, this.row);

  @override
  bool operator ==(Object other) => other is PointIndex && col == other.col && row == other.row;
  @override
  int get hashCode => Object.hash(col, row);
}

class LineSegment {
  final PointIndex start;
  final PointIndex end;
  LineSegment(this.start, this.end);
}

// Custom Painter untuk merender Titik dan Garis Matrix
class GridPainter extends CustomPainter {
  final int columns;
  final int rows;
  final Color color;
  final List<LineSegment>? staticSegments;
  final List<PointIndex>? userPath;
  final Offset? liveDragOffset;

  GridPainter({
    required this.columns,
    required this.rows,
    required this.color,
    this.staticSegments,
    this.userPath,
    this.liveDragOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double cellWidth = size.width / (columns + 1);
    double cellHeight = size.height / (rows + 1);

    Paint linePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // 1. Gambar Garis Referensi Kunci Jawaban (jika ada di sisi kiri)
    if (staticSegments != null) {
      for (var seg in staticSegments!) {
        Offset p1 = Offset(cellWidth * (seg.start.col + 1), cellHeight * (seg.start.row + 1));
        Offset p2 = Offset(cellWidth * (seg.end.col + 1), cellHeight * (seg.end.row + 1));
        canvas.drawLine(p1, p2, linePaint);
      }
    }

    // 2. Gambar Jalur Garis Hasil Input Sentuhan User (Sisi Kanan)
    if (userPath != null && userPath!.isNotEmpty) {
      Paint userLinePaint = Paint()
        ..color = Colors.blue.shade700
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < userPath!.length - 1; i++) {
        Offset p1 = Offset(cellWidth * (userPath![i].col + 1), cellHeight * (userPath![i].row + 1));
        Offset p2 = Offset(cellWidth * (userPath![i + 1].col + 1), cellHeight * (userPath![i + 1].row + 1));
        canvas.drawLine(p1, p2, userLinePaint);
      }

      // Gambar garis transisi drag saat jari masih bergeser
      if (liveDragOffset != null) {
        Offset lastNodeOffset = Offset(
          cellWidth * (userPath!.last.col + 1),
          cellHeight * (userPath!.last.row + 1),
        );
        canvas.drawLine(lastNodeOffset, liveDragOffset!, userLinePaint..color = Colors.blue.withOpacity(0.5));
      }
    }

    // 3. Gambar Simpul Bulatan Titik Grid Matrix (Rendering Nodes)
    Paint dotPaint = Paint()..color = color;
    for (int c = 0; c < columns; c++) {
      for (int r = 0; r < rows; r++) {
        Offset nodeCenter = Offset(cellWidth * (c + 1), cellHeight * (r + 1));
        canvas.drawCircle(nodeCenter, 8, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}