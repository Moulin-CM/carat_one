import 'package:flutter/material.dart';


class CustomSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;
  final Color? iconColor;
  final Color? backgroundColor;

  const CustomSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
    this.iconColor,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = iconColor ?? theme.primaryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.1),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3C72),
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
