import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer skeleton for any list-style screen (invoices, purchases,
/// inventory, expenses, withdrawals, reminders, reports, etc.).
///
/// Renders a column of card-shaped placeholders so the user sees the
/// destination layout immediately instead of a blank screen with a
/// CircularProgressIndicator.
///
/// Drop-in replacement at the call sites:
///
/// ```dart
/// vm.isLoading
///   ? const ListSkeleton()
///   : _buildList(...);
/// ```
class ListSkeleton extends StatelessWidget {
  /// How many placeholder rows to render. Keep this above what fits on
  /// a typical screen so the bottom of the list also shimmers.
  final int itemCount;

  /// Outer padding around the column. Matches the padding used by the
  /// real list views (most use `EdgeInsets.fromLTRB(16, 16, 16, 100)`
  /// or similar to leave room for the FAB).
  final EdgeInsetsGeometry padding;

  /// Use a denser, single-line row style (good for compact lists like
  /// inventory) instead of the default two-line invoice/purchase row.
  final bool dense;

  const ListSkeleton({
    super.key,
    this.itemCount = 8,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 100),
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE7EAF1),
      highlightColor: const Color(0xFFF7F8FB),
      period: const Duration(milliseconds: 1400),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => dense ? _buildDenseRow() : _buildRow(),
      ),
    );
  }

  /// Solid white rectangle; the parent `Shimmer.fromColors` animates a
  /// gradient sweep across all of them in unison.
  Widget _box({double? width, double height = 14, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildRow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _box(width: 44, height: 44, radius: 10),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(width: 160, height: 14, radius: 6),
                const SizedBox(height: 8),
                _box(width: 110, height: 12, radius: 6),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _box(width: 70, height: 14, radius: 6),
              const SizedBox(height: 8),
              _box(width: 50, height: 11, radius: 6),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDenseRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _box(width: 32, height: 32, radius: 8),
          const SizedBox(width: 12),
          Expanded(child: _box(width: double.infinity, height: 14, radius: 6)),
          const SizedBox(width: 12),
          _box(width: 60, height: 14, radius: 6),
        ],
      ),
    );
  }
}
