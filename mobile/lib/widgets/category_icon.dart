import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Abstract geometric icon for categories
/// Supports: cube, triangle, wave, hexagon, diamond, circle, star
class CategoryIcon extends StatelessWidget {
  final String iconType;
  final Color primaryColor;
  final Color secondaryColor;
  final double size;
  final bool enableGlow;
  final bool animated;

  const CategoryIcon({
    super.key,
    required this.iconType,
    this.primaryColor = AppColors.electricCyan,
    this.secondaryColor = AppColors.vividViolet,
    this.size = 48,
    this.enableGlow = true,
    this.animated = false,
  });

  /// Create from category data
  factory CategoryIcon.fromCategory({
    required String iconType,
    required String colorPrimary,
    required String colorSecondary,
    double size = 48,
    bool enableGlow = true,
  }) {
    return CategoryIcon(
      iconType: iconType,
      primaryColor: _parseColor(colorPrimary),
      secondaryColor: _parseColor(colorSecondary),
      size: size,
      enableGlow: enableGlow,
    );
  }

  static Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (animated) {
      return _AnimatedCategoryIcon(
        iconType: iconType,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        size: size,
        enableGlow: enableGlow,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: enableGlow
          ? BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: size * 0.3,
                  spreadRadius: size * 0.05,
                ),
              ],
            )
          : null,
      child: CustomPaint(
        size: Size(size, size),
        painter: _CategoryIconPainter(
          iconType: iconType,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
        ),
      ),
    );
  }
}

class _AnimatedCategoryIcon extends StatefulWidget {
  final String iconType;
  final Color primaryColor;
  final Color secondaryColor;
  final double size;
  final bool enableGlow;

  const _AnimatedCategoryIcon({
    required this.iconType,
    required this.primaryColor,
    required this.secondaryColor,
    required this.size,
    required this.enableGlow,
  });

  @override
  State<_AnimatedCategoryIcon> createState() => _AnimatedCategoryIconState();
}

class _AnimatedCategoryIconState extends State<_AnimatedCategoryIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: widget.enableGlow
              ? BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Color.lerp(
                        widget.primaryColor,
                        widget.secondaryColor,
                        _controller.value,
                      )!
                          .withOpacity(0.4),
                      blurRadius: widget.size * 0.3,
                      spreadRadius: widget.size * 0.05,
                    ),
                  ],
                )
              : null,
          child: Transform.rotate(
            angle: _controller.value * 0.5, // Subtle rotation
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _CategoryIconPainter(
                iconType: widget.iconType,
                primaryColor: widget.primaryColor,
                secondaryColor: widget.secondaryColor,
                animationValue: _controller.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryIconPainter extends CustomPainter {
  final String iconType;
  final Color primaryColor;
  final Color secondaryColor;
  final double animationValue;

  _CategoryIconPainter({
    required this.iconType,
    required this.primaryColor,
    required this.secondaryColor,
    this.animationValue = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    final gradient = LinearGradient(
      colors: [primaryColor, secondaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCenter(center: center, width: size.width, height: size.height),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (iconType.toLowerCase()) {
      case 'cube':
        _drawCube(canvas, center, radius, paint);
        break;
      case 'triangle':
        _drawTriangle(canvas, center, radius, paint);
        break;
      case 'wave':
        _drawWave(canvas, center, radius, paint);
        break;
      case 'hexagon':
        _drawHexagon(canvas, center, radius, paint);
        break;
      case 'diamond':
        _drawDiamond(canvas, center, radius, paint);
        break;
      case 'circle':
        _drawCircle(canvas, center, radius, paint);
        break;
      case 'star':
        _drawStar(canvas, center, radius, paint);
        break;
      case 'spiral':
        _drawSpiral(canvas, center, radius, paint);
        break;
      default:
        _drawCube(canvas, center, radius, paint);
    }
  }

  void _drawCube(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final offset = radius * 0.3;

    // Front face
    path.addRect(Rect.fromCenter(
      center: center.translate(-offset * 0.5, offset * 0.5),
      width: radius * 1.2,
      height: radius * 1.2,
    ));

    // Top edge
    path.moveTo(center.dx - radius * 0.6 - offset * 0.5, center.dy - radius * 0.6 + offset * 0.5);
    path.lineTo(center.dx - radius * 0.6 + offset * 0.5, center.dy - radius * 0.6 - offset * 0.5);
    path.lineTo(center.dx + radius * 0.6 + offset * 0.5, center.dy - radius * 0.6 - offset * 0.5);

    // Right edge
    path.moveTo(center.dx + radius * 0.6 - offset * 0.5, center.dy - radius * 0.6 + offset * 0.5);
    path.lineTo(center.dx + radius * 0.6 + offset * 0.5, center.dy - radius * 0.6 - offset * 0.5);
    path.lineTo(center.dx + radius * 0.6 + offset * 0.5, center.dy + radius * 0.6 - offset * 0.5);

    canvas.drawPath(path, paint);
  }

  void _drawTriangle(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();

    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx - radius * 0.866, center.dy + radius * 0.5);
    path.lineTo(center.dx + radius * 0.866, center.dy + radius * 0.5);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawWave(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();

    path.moveTo(center.dx - radius, center.dy);
    path.quadraticBezierTo(
      center.dx - radius * 0.5, center.dy - radius * 0.6,
      center.dx, center.dy,
    );
    path.quadraticBezierTo(
      center.dx + radius * 0.5, center.dy + radius * 0.6,
      center.dx + radius, center.dy,
    );

    // Second wave below
    path.moveTo(center.dx - radius, center.dy + radius * 0.4);
    path.quadraticBezierTo(
      center.dx - radius * 0.5, center.dy - radius * 0.2,
      center.dx, center.dy + radius * 0.4,
    );
    path.quadraticBezierTo(
      center.dx + radius * 0.5, center.dy + radius * 1.0,
      center.dx + radius, center.dy + radius * 0.4,
    );

    canvas.drawPath(path, paint);
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();

    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawDiamond(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();

    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx + radius * 0.7, center.dy);
    path.lineTo(center.dx, center.dy + radius);
    path.lineTo(center.dx - radius * 0.7, center.dy);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawCircle(center, radius, paint);

    // Inner circle
    canvas.drawCircle(center, radius * 0.5, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final innerRadius = radius * 0.4;

    for (int i = 0; i < 5; i++) {
      // Outer point
      final outerAngle = (math.pi * 2 / 5) * i - math.pi / 2;
      final outerX = center.dx + radius * math.cos(outerAngle);
      final outerY = center.dy + radius * math.sin(outerAngle);

      // Inner point
      final innerAngle = outerAngle + math.pi / 5;
      final innerX = center.dx + innerRadius * math.cos(innerAngle);
      final innerY = center.dy + innerRadius * math.sin(innerAngle);

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawSpiral(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();

    path.moveTo(center.dx, center.dy);

    for (double angle = 0; angle < math.pi * 4; angle += 0.1) {
      final r = radius * angle / (math.pi * 4);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CategoryIconPainter oldDelegate) {
    return oldDelegate.iconType != iconType ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.animationValue != animationValue;
  }
}
