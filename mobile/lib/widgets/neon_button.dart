import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// A button with neon glow effect
/// Used for primary actions throughout Fanmania
class NeonButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double height;
  final double borderRadius;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final bool iconLeading;

  const NeonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.textColor,
    this.width,
    this.height = 56,
    this.borderRadius = 12,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.iconLeading = true,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? AppColors.electricCyan;
    final isDisabled = widget.onPressed == null;
    final effectiveColor = isDisabled ? buttonColor.withOpacity(0.5) : buttonColor;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: widget.isOutlined
                  ? null
                  : LinearGradient(
                      colors: [
                        effectiveColor,
                        effectiveColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              border: widget.isOutlined
                  ? Border.all(
                      color: effectiveColor,
                      width: _isPressed ? 2.5 : 2,
                    )
                  : null,
              boxShadow: isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: effectiveColor
                            .withOpacity(0.5 * _glowAnimation.value),
                        blurRadius: 12 * _glowAnimation.value,
                        spreadRadius: 2 * _glowAnimation.value,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.isOutlined
                                ? effectiveColor
                                : (widget.textColor ?? AppColors.deepSpace),
                          ),
                        ),
                      )
                    : _buildContent(effectiveColor),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(Color effectiveColor) {
    final textStyle = AppTypography.labelLarge.copyWith(
      color: widget.isOutlined
          ? effectiveColor
          : (widget.textColor ?? AppColors.deepSpace),
      fontWeight: FontWeight.w700,
    );

    if (widget.icon == null) {
      return Text(widget.text, style: textStyle);
    }

    final iconWidget = Icon(
      widget.icon,
      size: 20,
      color: widget.isOutlined
          ? effectiveColor
          : (widget.textColor ?? AppColors.deepSpace),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.iconLeading) ...[
          iconWidget,
          const SizedBox(width: 8),
        ],
        Text(widget.text, style: textStyle),
        if (!widget.iconLeading) ...[
          const SizedBox(width: 8),
          iconWidget,
        ],
      ],
    );
  }
}

/// Ghost button variant - transparent with subtle border
class GhostButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final double? width;
  final double height;
  final IconData? icon;

  const GhostButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.width,
    this.height = 48,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.textSecondary;
    final isDisabled = onPressed == null;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDisabled ? AppColors.ghostBorder : buttonColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: buttonColor),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: AppTypography.labelMedium.copyWith(
                color: isDisabled ? AppColors.textTertiary : buttonColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Difficulty selector button
class DifficultyButton extends StatelessWidget {
  final int tier;
  final String label;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback? onTap;

  const DifficultyButton({
    super.key,
    required this.tier,
    required this.label,
    this.isSelected = false,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = AppColors.getTierColor(tier);

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected ? tierColor.withOpacity(0.15) : Colors.transparent,
          border: Border.all(
            color: isSelected ? tierColor : AppColors.ghostBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: tierColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocked)
              const Icon(
                Icons.lock_outline,
                size: 16,
                color: AppColors.textTertiary,
              )
            else
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tierColor,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: tierColor.withOpacity(0.6),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isLocked
                    ? AppColors.textTertiary
                    : (isSelected ? tierColor : AppColors.textSecondary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
