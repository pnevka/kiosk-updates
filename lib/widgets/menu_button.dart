import 'package:flutter/material.dart';
import '../utils/constants.dart';

class MenuButton extends StatefulWidget {
  final String title;
  final String route;
  final bool isPrimary;
  final IconData icon;
  final VoidCallback onTap;

  const MenuButton({
    super.key,
    required this.title,
    required this.route,
    this.isPrimary = false,
    required this.icon,
    required this.onTap,
  });

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: AppDurations.buttonAnimation,
          child: AnimatedContainer(
            duration: AppDurations.buttonAnimation,
            width: double.infinity,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.gradientLeft,
                  AppColors.gradientRight,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isHovered
                    ? AppColors.accent.withOpacity(0.5)
                    : AppColors.primary.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                if (_isHovered)
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 42,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    widget.title,
                    style: AppTextStyles.buttonTitle.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
