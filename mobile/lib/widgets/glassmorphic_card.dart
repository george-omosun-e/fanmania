import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A glassmorphic card with blur effect and subtle border
/// Used throughout Fanmania for cards, modals, and elevated surfaces
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final bool enableGlow;
  final Color? glowColor;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.blur = 10,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.boxShadow,
    this.onTap,
    this.enableGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.cardBackground,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AppColors.cardBorder,
              width: borderWidth,
            ),
            boxShadow: boxShadow ??
                (enableGlow
                    ? [
                        BoxShadow(
                          color: (glowColor ?? AppColors.electricCyan)
                              .withOpacity(0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : AppColors.cardShadow),
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// A variant with animated glow effect on tap
class GlassmorphicCardAnimated extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? accentColor;

  const GlassmorphicCardAnimated({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.onTap,
    this.accentColor,
  });

  @override
  State<GlassmorphicCardAnimated> createState() =>
      _GlassmorphicCardAnimatedState();
}

class _GlassmorphicCardAnimatedState extends State<GlassmorphicCardAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? AppColors.electricCyan;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            margin: widget.margin,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: widget.padding ?? const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: Color.lerp(
                        AppColors.cardBorder,
                        accentColor,
                        _glowAnimation.value,
                      )!,
                      width: 1 + (_glowAnimation.value * 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            accentColor.withOpacity(0.3 * _glowAnimation.value),
                        blurRadius: 16 * _glowAnimation.value,
                        spreadRadius: 2 * _glowAnimation.value,
                      ),
                      ...AppColors.cardShadow,
                    ],
                  ),
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
