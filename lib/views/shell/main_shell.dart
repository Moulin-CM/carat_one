import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dashboard/dashboard_view.dart';
import '../purchase/purchase_list_view.dart';
import '../invoice/invoice_list_view.dart';
import '../settings/settings_view.dart';
import '../../constants/app_translations.dart';
import '../../services/modern_ui_service.dart';



class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static int _currentIndex = 0;
  static const _accent = Color(0xFF4F8AF4);

  // We cannot use const here because .tr is evaluated at runtime
  List<_NavItem> get _items => [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'.tr),
    _NavItem(icon: Icons.diamond_rounded, label: 'Purchases'.tr),
    _NavItem(icon: Icons.receipt_long_rounded, label: 'Sells'.tr),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings'.tr),
  ];

  // Total height the floating nav reserves below the body (pill height
  // + bottom margin inside the nav widget). Inflated into MediaQuery so
  // inner Scaffolds' FABs (centerFloat) anchor above the floating pill
  // instead of behind it.
  static const double _floatingNavReserve = 96;

  @override
  Widget build(BuildContext context) {
    final modernUiEnabled = context.watch<ModernUiService>().enabled;

    final indexedStack = IndexedStack(
      index: _currentIndex,
      children: const [
        _DashboardTab(),
        PurchaseListView(),
        InvoiceListView(),
        _SettingsTab(),
      ],
    );

    if (!modernUiEnabled) {
      return Scaffold(
        body: indexedStack,
        bottomNavigationBar: _buildClassicNav(),
      );
    }

    // ── Modern UI: floating nav ────────────────────────────────────────
    //
    // Bypass Scaffold.bottomNavigationBar entirely — that slot wraps the
    // child in a Material widget that paints an opaque background,
    // which is what was rendering as a "black box" behind the pill and
    // killing the floating effect.
    //
    // Instead, render the body normally and overlay the floating pill
    // via a Stack. The body's MediaQuery is inflated so descendant
    // scrollables and centerFloat FABs leave room for the pill.
    final media = MediaQuery.of(context);
    final inflatedMedia = media.copyWith(
      padding: media.padding.copyWith(
        bottom: media.padding.bottom + _floatingNavReserve,
      ),
      viewPadding: media.viewPadding.copyWith(
        bottom: media.viewPadding.bottom + _floatingNavReserve,
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // Body fills the entire scaffold; padded MediaQuery tells
          // children there's a "reserve" at the bottom for the
          // floating pill.
          Positioned.fill(
            child: MediaQuery(
              data: inflatedMedia,
              child: indexedStack,
            ),
          ),
          // Floating pill: bottom-aligned, never touches the Scaffold's
          // bottomNavigationBar slot, so no Material backdrop is drawn
          // behind it.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ModernBottomNav(
              items: _items,
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicNav() {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _items.asMap().entries.map((e) {
                  final selected = _currentIndex == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _currentIndex = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? _accent.withOpacity(0.12)
                            : Colors.transparent,
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
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected ? _accent : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// Dashboard tab wraps the existing DashboardView
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    // DashboardView creates its own ChangeNotifierProvider<DashboardViewModel>
    // internally, so we just render it directly here.
    return const DashboardView();
  }
}

// Settings tab
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return const SettingsView();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//                     MODERN BOTTOM NAV (Carat One website style)
// ─────────────────────────────────────────────────────────────────────────────

/// Animated dark-navy bottom nav with a gradient "pill" sliding under the
/// active tab. Palette + motion mirror the marketing site
/// (docs/index.html → :root): primary `#4f8af4`, accent `#38bdf8`,
/// violet `#a78bfa` on a `#0c1230` → `#11173b` navy base.
class _ModernBottomNav extends StatelessWidget {
  const _ModernBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _accent = Color(0xFF38BDF8);
  static const _violet = Color(0xFFA78BFA);

  @override
  Widget build(BuildContext context) {
    // Transparent outer so body content scrolls behind. The pill is
    // wrapped in Center + ConstrainedBox so it behaves like a compact
    // floating FAB — significant breathing room from the screen edges
    // and a visible gap above the system gesture bar.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        // Align with explicit heightFactor sizes to the pill's height
        // — without it, Center/Align defaults to filling the whole
        // bottomNavigationBar slot vertically, making the nav balloon
        // up into the body.
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(38),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    // Translucent navy gradient — content blurs through.
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF131A38).withOpacity(0.86),
                        const Color(0xFF0F1530).withOpacity(0.86),
                        const Color(0xFF111738).withOpacity(0.86),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(38),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.14),
                      width: 1,
                    ),
                    boxShadow: [
                      // Cyan halo above + violet glow below — same
                      // floating language as the Sell FAB.
                      BoxShadow(
                        color: _accent.withOpacity(0.35),
                        blurRadius: 36,
                        offset: const Offset(0, -6),
                      ),
                      BoxShadow(
                        color: _violet.withOpacity(0.28),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.55),
                        blurRadius: 34,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < items.length; i++)
                          _ModernNavItem(
                            item: items[i],
                            selected: currentIndex == i,
                            onTap: () => onTap(i),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernNavItem extends StatelessWidget {
  const _ModernNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  static const _primary = Color(0xFF4F8AF4);
  static const _accent = Color(0xFF38BDF8);
  static const _violet = Color(0xFFA78BFA);

  static const _curve = Curves.easeOutCubic;
  static const _dur = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    final inactiveColor = Colors.white.withOpacity(0.58);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: _accent.withOpacity(0.18),
        highlightColor: _accent.withOpacity(0.06),
        child: AnimatedContainer(
          duration: _dur,
          curve: _curve,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 16 : 14,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primary, _accent, _violet],
                    stops: [0.0, 0.55, 1.0],
                  )
                : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _accent.withOpacity(0.55),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: _violet.withOpacity(0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                duration: _dur,
                curve: _curve,
                tween: Tween(begin: 1.0, end: selected ? 1.12 : 1.0),
                builder: (_, scale, child) => Transform.scale(
                  scale: scale,
                  child: child,
                ),
                child: Icon(
                  item.icon,
                  size: 22,
                  color: selected ? Colors.white : inactiveColor,
                ),
              ),
              // Smoothly grows/shrinks the label as the pill expands.
              // heightFactor must be set explicitly — otherwise AnimatedAlign
              // tries to expand to fill its parent's height, which in the
              // bottomNavigationBar slot is unbounded and makes the active
              // pill stretch to the full screen height.
              ClipRect(
                child: AnimatedAlign(
                  duration: _dur,
                  curve: _curve,
                  alignment: Alignment.centerLeft,
                  widthFactor: selected ? 1.0 : 0.0,
                  heightFactor: 1.0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: AnimatedOpacity(
                      duration: _dur,
                      curve: _curve,
                      opacity: selected ? 1.0 : 0.0,
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
