import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:google_fonts/google_fonts.dart';

class CarModel {
  final int index;
  final String id;
  final Color color;
  final String name;
  Color? leftWheelColor;
  Color? rightWheelColor;

  CarModel({
    required this.index,
    required this.id,
    required this.color,
    required this.name,
    this.leftWheelColor,
    this.rightWheelColor,
  });

  bool get isFullyAssembled => leftWheelColor == color && rightWheelColor == color;
}

class WheelModel {
  final String id;
  final Color color;
  bool isPlaced;

  WheelModel({
    required this.id,
    required this.color,
    this.isPlaced = false,
  });
}

class CarWheelMatchingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const CarWheelMatchingScreen({super.key, this.levelId = 40});

  @override
  ConsumerState<CarWheelMatchingScreen> createState() => _CarWheelMatchingScreenState();
}

class _CarWheelMatchingScreenState extends ConsumerState<CarWheelMatchingScreen> with TickerProviderStateMixin {
  // 4 main car colors
  static const Color colRed = Color(0xFFEF4444);
  static const Color colBlue = Color(0xFF3B82F6);
  static const Color colGreen = Color(0xFF22C55E);
  static const Color colOrange = Color(0xFFF97316);

  late List<CarModel> _cars;
  late List<WheelModel> _looseWheels;

  // Drive-away animation controllers for each of the 4 cars
  late List<AnimationController> _driveControllers;
  late List<Animation<double>> _driveAnimations;

  bool _isSolved = false;

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  @override
  void dispose() {
    for (var controller in _driveControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initLevel() {
    _cars = [
      CarModel(index: 0, id: 'car_red', color: colRed, name: 'Mobil Merah'),
      CarModel(index: 1, id: 'car_blue', color: colBlue, name: 'Mobil Biru'),
      CarModel(index: 2, id: 'car_green', color: colGreen, name: 'Mobil Hijau'),
      CarModel(index: 3, id: 'car_orange', color: colOrange, name: 'Mobil Oranye'),
    ];

    // Shuffled loose wheels at bottom
    _looseWheels = [
      WheelModel(id: 'w_red_1', color: colRed),
      WheelModel(id: 'w_blue_1', color: colBlue),
      WheelModel(id: 'w_green_1', color: colGreen),
      WheelModel(id: 'w_orange_1', color: colOrange),
      WheelModel(id: 'w_red_2', color: colRed),
      WheelModel(id: 'w_blue_2', color: colBlue),
      WheelModel(id: 'w_green_2', color: colGreen),
      WheelModel(id: 'w_orange_2', color: colOrange),
    ];
    _looseWheels.shuffle();

    // Drive away sequential animation setups
    _driveControllers = List.generate(4, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      );
    });

    _driveAnimations = _driveControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 600.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInBack),
      );
    }).toList();
  }

  void _handleWheelDrop(CarModel car, String slot, WheelModel wheel) {
    if (wheel.color != car.color) return;

    SoundService.playSuccess();
    HapticService.success();

    setState(() {
      if (slot == 'left') {
        car.leftWheelColor = wheel.color;
      } else {
        car.rightWheelColor = wheel.color;
      }
      wheel.isPlaced = true;
    });

    // Check level completion
    if (_cars.every((c) => c.isFullyAssembled)) {
      _onLevelComplete();
    }
  }

  void _handleIncorrectDrop() {
    SoundService.playError();
    HapticService.failure();
  }

  void _onLevelComplete() async {
    setState(() {
      _isSolved = true;
    });

    // 1. Mark complete locally in provider
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    // 2. Sync to cloud database
    try {
      await UserService.updateProgress(40);
    } catch (e) {
      debugPrint('Cloud progress update failed for level 40: $e');
    }

    // 3. Sequentially animate cars driving away with beep honk!
    for (int i = 0; i < 4; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      
      // Play horn/beep sound
      SoundService.playSuccess(); // plays friendly 'ting' or successful sound
      HapticService.light();

      _driveControllers[i].forward();
    }

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // 4. Show success victory dialog
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'CarSuccess',
      transitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final scaleValue = Curves.elasticOut.transform(anim1.value);
        return Transform.scale(
          scale: scaleValue,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.amber, width: 6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.amber,
                      size: 110,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'BIP BIP! HEBAT!',
                      style: GoogleFonts.fredoka(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: CilikTheme.tealTua,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Semua mobil sudah memiliki roda yang lengkap dan siap melaju kencang!',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        // Return back to Adventure Map
                        Navigator.pop(context); // close dialog
                        Navigator.pop(context); // close level 40 screen
                      },
                      child: Text(
                        'SELESAI',
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Soft road asphalt background
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            const SizedBox(height: 8),
            // Play Area with Cars & Slots
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 4.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _cars.length,
                    itemBuilder: (context, index) {
                      final car = _cars[index];
                      return AnimatedBuilder(
                        animation: _driveAnimations[index],
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_driveAnimations[index].value, 0),
                            child: _buildCarRow(car),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildPartsBin(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: CilikTheme.tealTua),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Level 40',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: CilikTheme.tealTua,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.airport_shuttle_rounded, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Tarik roda dari bagian bawah ke lubang roda mobil yang warnanya cocok!',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarRow(CarModel car) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      height: 96,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: car.color.withOpacity(0.15), width: 2),
      ),
      child: Row(
        children: [
          // Cute Car Vector UI inside
          Expanded(
            child: Stack(
              children: [
                // Car Cabin Outline Shape
                Positioned(
                  left: 20,
                  top: 4,
                  bottom: 8,
                  right: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: car.color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: car.color.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                // Headlight
                Positioned(
                  right: 32,
                  top: 24,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.yellow,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Windows
                Positioned(
                  left: 45,
                  top: 10,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.cyan.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 24,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.cyan.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                // Wheels Slots Drag Targets
                Positioned(
                  left: 36,
                  bottom: 0,
                  child: _buildWheelSlot(car, 'left'),
                ),
                Positioned(
                  left: 108,
                  bottom: 0,
                  child: _buildWheelSlot(car, 'right'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Checkmark Indicator
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: car.isFullyAssembled ? const Color(0xFF4CAF50) : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelSlot(CarModel car, String slot) {
    final bool isFilled = slot == 'left' ? car.leftWheelColor != null : car.rightWheelColor != null;
    final Color? wheelColor = slot == 'left' ? car.leftWheelColor : car.rightWheelColor;

    return DragTarget<WheelModel>(
      onWillAccept: (data) => data != null && data.color == car.color && !isFilled,
      onAccept: (data) => _handleWheelDrop(car, slot, data),
      builder: (context, candidateData, rejectedData) {
        final bool isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isFilled ? wheelColor : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isFilled
                  ? const Color(0xFF334155)
                  : (isHovering ? car.color : Colors.grey.shade400),
              width: isHovering ? 3.0 : (isFilled ? 2.5 : 2.0),
              style: isFilled ? BorderStyle.solid : BorderStyle.none,
            ),
            boxShadow: [
              if (isHovering)
                BoxShadow(
                  color: car.color.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
            ],
          ),
          child: isFilled
              ? _buildWheelCore(wheelColor!)
              : (isHovering
                  ? Icon(Icons.add, color: car.color, size: 20)
                  : CustomPaint(
                      painter: DashedCirclePainter(color: Colors.grey.shade400),
                    )),
        );
      },
    );
  }

  Widget _buildWheelCore(Color color) {
    return Center(
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF334155), width: 1.5),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartsBin() {
    // Filter out placed wheels
    final activeWheels = _looseWheels.where((w) => !w.isPlaced).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PARTS BIN (SERET RODA DARI SINI)',
            style: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: activeWheels.isEmpty
                ? Center(
                    child: Text(
                      'Semua roda sudah terpasang!',
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: activeWheels.length,
                    itemBuilder: (context, idx) {
                      final wheel = activeWheels[idx];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Draggable<WheelModel>(
                          data: wheel,
                          feedback: _buildDraggableWheel(wheel.color, isFeedback: true),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _buildDraggableWheel(wheel.color),
                          ),
                          onDraggableCanceled: (velocity, offset) {
                            _handleIncorrectDrop();
                          },
                          child: _buildDraggableWheel(wheel.color),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableWheel(Color color, {bool isFeedback = false}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF334155), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isFeedback ? 0.25 : 0.1),
            blurRadius: isFeedback ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF334155), width: 2),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashedCirclePainter extends CustomPainter {
  final Color color;
  DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const double circumference = 2 * pi;
    const double dashWidth = 0.15;
    const double spaceWidth = 0.15;
    double startAngle = 0.0;

    while (startAngle < circumference) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashWidth,
        false,
        paint,
      );
      startAngle += dashWidth + spaceWidth;
    }
  }

  @override
  bool shouldRepaint(covariant DashedCirclePainter oldDelegate) => oldDelegate.color != color;
}
