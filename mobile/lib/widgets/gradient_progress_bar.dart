import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// A progress bar with gradient fill (Violet → Blue → Cyan)
/// Used for mastery percentage, challenge progress, etc.
class GradientProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final double borderRadius;
  final Gradient? gradient;
  final Color? backgroundColor;
  final bool showPercentage;
  final bool showGlow;
  final String? label;

  const GradientProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.borderRadius = 4,
    this.gradient,
    this.backgroundColor,
    this.showPercentage = false,
    this.showGlow = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(label!, style: AppTypography.labelMedium),
                if (showPercentage)
                  Text(
                    '${(clampedProgress * 100).toInt()}%',
                    style: AppTypography.mono.copyWith(
                      fontSize: 12,
                      color: AppColors.electricCyan,
                    ),
                  ),
              ],
            ),
          ),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.ghostBorder,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Stack(
            children: [
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                widthFactor: clampedProgress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradient ?? AppColors.progressGradient,
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: showGlow && clampedProgress > 0.05
                        ? [
                            BoxShadow(
                              color: AppColors.electricCyan.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Circular progress indicator with gradient
class GradientCircularProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Widget? child;
  final bool showPercentage;

  const GradientCircularProgress({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = 8,
    this.gradient,
    this.backgroundColor,
    this.child,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: Size(size, size),
            painter: _CircularProgressPainter(
              progress: 1.0,
              strokeWidth: strokeWidth,
              color: backgroundColor ?? AppColors.ghostBorder,
            ),
          ),
          // Progress arc
          CustomPaint(
            size: Size(size, size),
            painter: _GradientCircularProgressPainter(
              progress: clampedProgress,
              strokeWidth: strokeWidth,
              gradient: gradient ?? AppColors.progressGradient,
            ),
          ),
          // Center content
          if (child != null)
            child!
          else if (showPercentage)
            Text(
              '${(clampedProgress * 100).toInt()}%',
              style: AppTypography.mono.copyWith(
                fontSize: size * 0.2,
                color: AppColors.electricCyan,
              ),
            ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Gradient gradient;

  _GradientCircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * 3.141592653589793 * progress;

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -3.141592653589793 / 2, // Start from top
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Timer countdown progress (for challenge time limits)
class TimerProgressBar extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final double height;

  const TimerProgressBar({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final progress = remainingSeconds / totalSeconds;
    final isLow = progress < 0.25;
    final isCritical = progress < 0.1;

    Color getColor() {
      if (isCritical) return AppColors.error;
      if (isLow) return AppColors.warning;
      return AppColors.electricCyan;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(remainingSeconds),
          style: AppTypography.mono.copyWith(
            fontSize: 14,
            color: getColor(),
            fontWeight: isCritical ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.ghostBorder,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 100),
            widthFactor: progress.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: getColor(),
                borderRadius: BorderRadius.circular(height / 2),
                boxShadow: [
                  BoxShadow(
                    color: getColor().withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Animated helper widget for progress transitions
class AnimatedFractionallySizedBox extends StatelessWidget {
  final Duration duration;
  final Curve curve;
  final double widthFactor;
  final AlignmentGeometry alignment;
  final Widget child;

  const AnimatedFractionallySizedBox({
    super.key,
    required this.duration,
    this.curve = Curves.linear,
    required this.widthFactor,
    this.alignment = Alignment.centerLeft,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: widthFactor),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return FractionallySizedBox(
          widthFactor: value,
          alignment: alignment,
          child: child,
        );
      },
      child: child,
    );
  }
}
