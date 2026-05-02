import 'package:flutter/material.dart';
import 'dart:async';

// 1. Model untuk Blok Coding
enum ActionType { maju, kiri, kanan, lompat }

class CodeBlock {
  final ActionType type;
  final IconData icon;
  final Color color;

  CodeBlock({required this.type, required this.icon, required this.color});
}

class CodingWorkspace extends StatefulWidget {
  const CodingWorkspace({super.key});

  @override
  State<CodingWorkspace> createState() => _CodingWorkspaceState();
}

class _CodingWorkspaceState extends State<CodingWorkspace> {
  // Daftar instruksi yang disusun anak
  List<CodeBlock> workspaceBlocks = [];
  
  // State untuk karakter
  double charX = 0;
  double charY = 0;
  int currentExecutingIndex = -1;
  bool isExecuting = false;

  // Daftar blok yang tersedia di menu
  final List<CodeBlock> menuBlocks = [
    CodeBlock(type: ActionType.maju, icon: Icons.arrow_upward, color: Colors.blue),
    CodeBlock(type: ActionType.kiri, icon: Icons.rotate_left, color: Colors.orange),
    CodeBlock(type: ActionType.kanan, icon: Icons.rotate_right, color: Colors.orange),
    CodeBlock(type: ActionType.lompat, icon: Icons.upgrade, color: Colors.purple),
  ];

  // Fungsi untuk menjalankan kode
  Future<void> runCode() async {
    if (isExecuting) return;
    
    setState(() {
      isExecuting = true;
      charX = 0; // Reset posisi
      charY = 0;
    });

    for (int i = 0; i < workspaceBlocks.length; i++) {
      setState(() => currentExecutingIndex = i);
      
      // Logika pergerakan sederhana
      await Future.delayed(const Duration(milliseconds: 800));
      
      setState(() {
        if (workspaceBlocks[i].type == ActionType.maju) charY -= 40;
        if (workspaceBlocks[i].type == ActionType.kiri) charX -= 40;
        if (workspaceBlocks[i].type == ActionType.kanan) charX += 40;
      });
    }

    setState(() {
      currentExecutingIndex = -1;
      isExecuting = false;
    });
    
    // Tampilkan pesan sukses sederhana
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hebat! Kamu berhasil menyusun kode!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text("Coding Workspace"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Row(
        children: [
          // PANEL KIRI: Menu Blok (Inventory)
          Container(
            width: 120,
            color: Colors.white,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Pilih", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: menuBlocks.length,
                    itemBuilder: (context, index) {
                      final block = menuBlocks[index];
                      return Draggable<CodeBlock>(
                        data: block,
                        feedback: _buildBlock(block, isDragging: true),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: _buildBlock(block),
                        ),
                        child: _buildBlock(block),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // PANEL TENGAH: Area Kerja (Workspace)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Susun Disini", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: DragTarget<CodeBlock>(
                    onAccept: (block) {
                      setState(() {
                        workspaceBlocks.add(block);
                      });
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
                        ),
                        child: workspaceBlocks.isEmpty 
                          ? const Center(child: Text("Tarik blok ke sini!"))
                          : ListView.builder(
                              padding: const EdgeInsets.all(10),
                              itemCount: workspaceBlocks.length,
                              itemBuilder: (context, index) {
                                return _buildWorkspaceBlock(workspaceBlocks[index], index);
                              },
                            ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton.icon(
                    onPressed: workspaceBlocks.isEmpty ? null : runCode,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("JALANKAN"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                )
              ],
            ),
          ),

          // PANEL KANAN: Preview Karakter
          Expanded(
            child: Container(
              color: Colors.blue[50],
              child: Stack(
                children: [
                  const Center(child: Text("Preview Gerakan", style: TextStyle(color: Colors.blueGrey))),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    left: (MediaQuery.of(context).size.width / 6) + charX,
                    top: (MediaQuery.of(context).size.height / 2) + charY,
                    child: const Icon(Icons.smart_toy, size: 60, color: Colors.blue),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => setState(() => workspaceBlocks.clear()),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pembantu untuk membangun tampilan blok
  Widget _buildBlock(CodeBlock block, {bool isDragging = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: block.color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: isDragging ? [const BoxShadow(color: Colors.black26, blurRadius: 10)] : null,
      ),
      child: Icon(block.icon, color: Colors.white, size: 32),
    );
  }

  // Widget untuk blok yang ada di workspace (dengan indikator eksekusi)
  Widget _buildWorkspaceBlock(CodeBlock block, int index) {
    bool isActive = index == currentExecutingIndex;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: block.color,
        borderRadius: BorderRadius.circular(15),
        border: isActive ? Border.all(color: Colors.yellow, width: 4) : null,
        boxShadow: isActive ? [const BoxShadow(color: Colors.yellow, blurRadius: 15)] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(block.icon, color: Colors.white),
          const SizedBox(width: 10),
          Text("Langkah ${index + 1}", style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
