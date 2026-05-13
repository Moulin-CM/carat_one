import 'package:flutter/material.dart';


class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final double? width;
  final double height;
  final double fontSize;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.borderRadius = 14.0,
    this.width = double.infinity,
    this.height = 56.0,
    this.fontSize = 16.0,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.primaryColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
