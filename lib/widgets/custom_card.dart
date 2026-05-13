import 'package:flutter/material.dart';


class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.color = Colors.white,
    this.borderRadius = 16.0,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius!),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: child,
    );
  }
}
