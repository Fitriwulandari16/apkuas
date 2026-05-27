import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/utils/level_resolver.dart';
import 'dart:math' as math;

class LevelUpOverlay extends StatefulWidget {
  final String title;
  final String message;
  final String nextRoute;
  final bool isEmbedded;

  const LevelUpOverlay({
    super.key,
    required this.title,
    required this.message,
    required this.nextRoute,
    this.isEmbedded = false,
  });

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Extract level ID from route string like '/level_24' -> 24
  int? _extractLevelId(String route) {
    final match = RegExp(r'/level_(\d+)').firstMatch(route);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  void _navigateToNext() {
    final levelId = _extractLevelId(widget.nextRoute);
    if (levelId != null) {
      // Use LevelResolver directly — it has a built-in fallback for undefined levels
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LevelResolver.buildLevel(levelId),
        ),
      );
    } else {
      // Fallback for non-level routes
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.amber, width: 6),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  RotationTransition(
                    turns: _rotateAnimation,
                    child: const Icon(Icons.stars_rounded, size: 120, color: Colors.amber),
                  ),
                  const Positioned(
                    top: 40,
                    child: Icon(Icons.celebration_rounded, size: 40, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: CilikTheme.tealTua,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 8,
                  ),
                  onPressed: _navigateToNext,
                  child: Text(
                    'LANJUT',
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.7),
      body: content,
    );
  }
}
