import 'package:flutter/material.dart';


class CustomInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;
  final double fontSize;

  const CustomInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: fontSize,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                fontSize: fontSize,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
