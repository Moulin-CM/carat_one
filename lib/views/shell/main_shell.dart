import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dashboard/dashboard_view.dart';
import '../purchase/purchase_list_view.dart';
import '../invoice/invoice_list_view.dart';
import '../settings/settings_view.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../widgets/ads/banner_ad_widget.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  static const _accent = Color(0xFF4F8AF4);

  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.diamond_rounded, label: 'Purchases'),
    _NavItem(icon: Icons.receipt_long_rounded, label: 'Sells'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardTab(),
          PurchaseListView(),
          InvoiceListView(),
          _SettingsTab(),
        ],
      ),
      bottomNavigationBar: Container(
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
              // Persistent banner ad sits just above the bottom nav so it's
              // visible across Dashboard / Purchases / Sells / Settings tabs.
              // Placed inside the nav container so it never overlaps content.
              const BannerAdWidget(showDivider: false),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? _accent.withOpacity(0.12) : Colors.transparent,
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
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel()..loadInvoices(),
      child: const _DashboardTabContent(),
    );
  }
}

class _DashboardTabContent extends StatelessWidget {
  const _DashboardTabContent();

  @override
  Widget build(BuildContext context) {
    // Reuse DashboardView but without its own navigation shell
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
