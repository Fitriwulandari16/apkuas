import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'dart:math';

class ParentGateScreen extends StatefulWidget {
  const ParentGateScreen({super.key});

  @override
  State<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends State<ParentGateScreen> {
  late int num1;
  late int num2;
  late int correctAnswer;
  final TextEditingController _controller = TextEditingController();
  String errorText = '';

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _generateQuestion() {
    final random = Random();
    num1 = random.nextInt(10) + 10; // 10-19
    num2 = random.nextInt(10) + 1;  // 1-9
    correctAnswer = num1 + num2;
    _controller.clear();
    errorText = '';
  }

  void _verify() {
    if (_controller.text == correctAnswer.toString()) {
      Navigator.pushReplacementNamed(context, '/parent_dashboard');
    } else {
      setState(() {
        errorText = 'Jawaban salah, coba lagi!';
        _generateQuestion();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person_rounded, size: 80, color: CilikTheme.tealTua),
            const SizedBox(height: 24),
            Text(
              'Akses Orang Tua',
              style: GoogleFonts.fredoka(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Selesaikan pertanyaan berikut untuk melanjutkan:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    '$num1 + $num2 = ?',
                    style: GoogleFonts.fredoka(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: CilikTheme.tealTua,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Hasil',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: CilikTheme.tealTua, width: 2),
                      ),
                    ),
                    onSubmitted: (_) => _verify(),
                  ),
                  if (errorText.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(errorText, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CilikTheme.tealTua,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _verify,
                child: const Text('VERIFIKASI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
