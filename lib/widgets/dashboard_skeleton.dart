import 'package:flutter/material.dart';
import 'package:invoice_generator/constants/app_translations.dart';
import 'package:shimmer/shimmer.dart';


/// Skeleton placeholder shown in place of the Dashboard while data is
/// loading. Mirrors the real Dashboard layout (gradient backdrop,
/// 3×2 stat grid, finance card, recent invoices, quick actions) so the
/// transition into the populated screen is seamless rather than a
/// blank-white-with-spinner flash.
///
/// Use anywhere we'd otherwise render
/// `Scaffold(body: Center(child: CircularProgressIndicator()))` on the
/// path leading into the dashboard (auth-wrapper bootstrap, dashboard
/// initial load, etc.).
class DashboardSkeleton extends StatelessWidget {
  /// When false, the AppBar is omitted — useful for hosts that already
  /// provide their own AppBar (none of the current call sites do, but
  /// the flag keeps the widget reusable).
  final bool showAppBar;

  /// When true, render a non-functional bottom-nav placeholder that
  /// matches MainShell's layout so the navbar doesn'.trt pop in 2-3 seconds
  /// after the dashboard skeleton appears. Set this only when the
  /// destination *is* MainShell (i.e. AuthWrapper's bootstrap phase) —
  /// otherwise MainShell already provides the real bottom nav and a
  /// second one would stack on top.
  final bool showBottomNav;

  const DashboardSkeleton({
    super.key,
    this.showAppBar = true,
    this.showBottomNav = false,
  });

  static const _accent = Color(0xFF4F8AF4);
  static const _deepAccent = Color(0xFF1E3C72);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: showAppBar
          ? AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              title: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      child:
                          const Icon(Icons.dashboard_rounded, color: _accent),
                    ),
                    const SizedBox(width: 10),
                    Text('Dashboard'.tr),
                  ],
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Shimmer.fromColors(
                baseColor: const Color(0xFFE7EAF1),
                highlightColor: const Color(0xFFF7F8FB),
                period: const Duration(milliseconds: 1400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(),
                    const SizedBox(height: 20),
                    _buildFinanceCard(),
                    const SizedBox(height: 20),
                    _buildRecentInvoices(),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: showBottomNav ? const _BottomNavPlaceholder() : null,
    );
  }

  // ─── Backdrop ─────────────────────────────────────────────────────────────

  Widget _buildBackdrop() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE7EEFF),
            Color(0xFFF9FBFF),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: _blurredCircle(220, _accent.withOpacity(0.22)),
          ),
          Positioned(
            top: 140,
            left: -90,
            child: _blurredCircle(200, _deepAccent.withOpacity(0.12)),
          ),
        ],
      ),
    );
  }

  Widget _blurredCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // ─── Skeleton building blocks ─────────────────────────────────────────────

  /// Solid grey rectangle of a fixed shape; the parent `Shimmer.fromColors`
  /// animates the gradient sweep across all of these together.
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

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(width: 42, height: 42, radius: 12),
          const SizedBox(height: 12),
          _box(width: 110, height: 22, radius: 6),
          const SizedBox(height: 6),
          _box(width: 70, height: 12, radius: 6),
        ],
      ),
    );
  }

  Widget _buildFinanceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _box(width: 40, height: 40, radius: 20),
              const SizedBox(width: 12),
              _box(width: 100, height: 18, radius: 6),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildFinanceTile()),
              const SizedBox(width: 12),
              Expanded(child: _buildFinanceTile()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildFinanceTile()),
              const SizedBox(width: 12),
              Expanded(child: _buildFinanceTile()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceTile() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(width: 22, height: 22, radius: 6),
          const SizedBox(height: 10),
          _box(width: 80, height: 12, radius: 6),
          const SizedBox(height: 4),
          _box(width: 60, height: 16, radius: 6),
        ],
      ),
    );
  }

  Widget _buildRecentInvoices() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _box(width: 40, height: 40, radius: 20),
              const SizedBox(width: 12),
              _box(width: 130, height: 18, radius: 6),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < 3; i++) ...[
            _buildInvoiceRow(),
            if (i != 2) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceRow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _box(width: 36, height: 36, radius: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(width: 130, height: 14, radius: 6),
                const SizedBox(height: 6),
                _box(width: 90, height: 11, radius: 6),
              ],
            ),
          ),
          _box(width: 60, height: 14, radius: 6),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _box(width: 40, height: 40, radius: 20),
              const SizedBox(width: 12),
              _box(width: 120, height: 18, radius: 6),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildActionButton()),
              const SizedBox(width: 12),
              Expanded(child: _buildActionButton()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _box(width: 28, height: 28, radius: 14),
          const SizedBox(height: 8),
          _box(width: 60, height: 13, radius: 6),
        ],
      ),
    );
  }
}

/// Inert bottom-nav placeholder that mimics MainShell's bottom nav so
/// the AuthWrapper-stage skeleton already shows the navbar in its final
/// position. Cannot be tapped — auth state hasn't resolved yet, so
/// switching tabs would be meaningless.
class _BottomNavPlaceholder extends StatelessWidget {
  const _BottomNavPlaceholder();

  static const _accent = Color(0xFF4F8AF4);

  static final _items = <_NavMockItem>[
    _NavMockItem(icon: Icons.dashboard_rounded, label: 'Dashboard'.tr),
    _NavMockItem(icon: Icons.diamond_rounded, label: 'Purchases'.tr),
    _NavMockItem(icon: Icons.receipt_long_rounded, label: 'Sells'.tr),
    _NavMockItem(icon: Icons.settings_rounded, label: 'Settings'.tr),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _items.asMap().entries.map((e) {
              // Pre-select Dashboard so the highlight matches what the
              // user will land on a moment later.
              final selected = e.key == 0;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      selected ? _accent.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      e.value.icon,
                      color: selected ? _accent : Colors.grey[400],
                      size: 24,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      e.value.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? _accent : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavMockItem {
  final IconData icon;
  final String label;
  const _NavMockItem({required this.icon, required this.label});
}
