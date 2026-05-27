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
      // Fallback: try named route, pop if it fails
      Navigator.pop(context);
    }
  }
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

