import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../invoice/invoice_list_view.dart';
import '../invoice/invoice_form_view.dart';
import '../profile/profile_view.dart';
import '../reminders/reminders_view.dart';
import '../finance/expenses_view.dart';
import '../finance/withdrawals_view.dart';
import '../finance/buy_sell_report_view.dart';
import '../finance/brokerage_report_view.dart';
import '../../widgets/sell_options_sheet.dart';
import '../../widgets/dashboard_skeleton.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel()..loadInvoices(),
      child: const _DashboardViewContent(),
    );
  }
}

class _DashboardViewContent extends StatelessWidget {
  const _DashboardViewContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    const accent = Color(0xFF4F8AF4);
    const deepAccent = Color(0xFF1E3C72);

    if (viewModel.isLoading) {
      // Show a shimmer skeleton that mirrors the populated dashboard layout,
      // so the load-to-content transition is smooth instead of a blank
      // screen with a spinner.
      return const DashboardSkeleton();
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                child: Icon(Icons.dashboard_rounded, color: accent),
              ),
              const SizedBox(width: 10),
              const Text('Dashboard'),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => viewModel.loadInvoices(),
            tooltip: 'Refresh',
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reminders',
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Reminders'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'reminders') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RemindersView(),
                  ),
                );
              } else if (value == 'logout') {
                await _handleLogout(context, viewModel);
              } else if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileView(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBackdrop(accent, deepAccent),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => viewModel.loadInvoices(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCards(context, viewModel, accent, deepAccent),
                    const SizedBox(height: 20),
                    _buildFinanceCard(context, viewModel, accent, deepAccent),
                    const SizedBox(height: 20),
                    _buildRecentInvoices(context, viewModel, accent, deepAccent),
                    const SizedBox(height: 20),
                    _buildQuickActions(context, accent),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNewSell(context),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Sell', style: TextStyle(color: Colors.white)),
        backgroundColor: accent,
      ),
    );
  }

  Widget _buildBackdrop(Color accent, Color deepAccent) {
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
            child: _blurredCircle(220, accent.withOpacity(0.22)),
          ),
          Positioned(
            top: 140,
            left: -90,
            child: _blurredCircle(200, deepAccent.withOpacity(0.12)),
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

  Widget _buildStatsCards(BuildContext context, DashboardViewModel viewModel, Color accent, Color deepAccent) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final caratFormat = NumberFormat('#,##0.##');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Sells',
                viewModel.totalSells.toString(),
                Icons.receipt_long_rounded,
                accent,
                deepAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Purchases',
                viewModel.totalPurchases.toString(),
                Icons.diamond_rounded,
                Colors.teal,
                deepAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                viewModel.netProfitOrLoss >= 0 ? 'Net Profit' : 'Net Loss',
                (viewModel.netProfitOrLoss >= 0 ? '+' : '-') +
                    currencyFormat
                        .format(viewModel.netProfitOrLoss.abs()),
                viewModel.netProfitOrLoss >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                viewModel.netProfitOrLoss >= 0 ? Colors.green : Colors.red,
                deepAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Remaining Carat',
                '${caratFormat.format(viewModel.totalRemainingCarat)} ct',
                Icons.scale_rounded,
                Colors.indigo,
                deepAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Buy Amount',
                currencyFormat.format(viewModel.totalBuyAmount),
                Icons.shopping_cart_rounded,
                Colors.orange,
                deepAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Sell Amount',
                currencyFormat.format(viewModel.totalSellAmount),
                Icons.point_of_sale_rounded,
                Colors.purple,
                deepAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinanceCard(
      BuildContext context, DashboardViewModel viewModel, Color accent, Color deepAccent) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF5F7FB),
                ),
                child: Icon(Icons.account_balance_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              const Text(
                'Finance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFinanceTile(
                  context,
                  icon: Icons.receipt_long_rounded,
                  title: 'Expenses',
                  value: 'Manage',
                  color: Colors.blueGrey,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExpensesView()),
                    );
                    await viewModel.loadInvoices();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFinanceTile(
                  context,
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Withdrawals',
                  value:
                      '- ${currencyFormat.format(viewModel.outstandingWithdrawals)}',
                  color: Colors.orange,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WithdrawalsView()),
                    );
                    await viewModel.loadInvoices();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildReportsRow(context, accent),
        ],
      ),
    );
  }

  Widget _buildReportsRow(BuildContext context, Color accent) {
    return Row(
      children: [
        Expanded(
          child: _buildReportTile(
            context,
            color: accent,
            icon: Icons.assessment_rounded,
            title: 'Buy / Sell',
            subtitle: 'Monthly & yearly',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BuySellReportView()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildReportTile(
            context,
            color: Colors.deepPurple,
            icon: Icons.handshake_rounded,
            title: 'Brokerage',
            subtitle: 'Per broker report',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BrokerageReportView()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportTile(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      color: color.withOpacity(0.7), size: 18),
                ],
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3C72))),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      color: color.withOpacity(0.7), size: 18),
                ],
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, Color deepAccent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: deepAccent,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvoices(BuildContext context, DashboardViewModel viewModel, Color accent, Color deepAccent) {
    final recent = viewModel.recentInvoices;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF5F7FB),
                ),
                child: Icon(Icons.history_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recent Sells',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No sells yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...recent.map((invoice) => _buildRecentInvoiceItem(
                  context,
                  invoice,
                  dateFormat,
                  accent,
                  deepAccent,
                )),
          if (recent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InvoiceListView()),
                    );
                  },
                  child: const Text('View All Sells'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentInvoiceItem(
    BuildContext context,
    invoice,
    DateFormat dateFormat,
    Color accent,
    Color deepAccent,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceFormView(invoice: invoice),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.insert_drive_file_rounded, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.buyerName.isNotEmpty ? invoice.buyerName : 'Unnamed Buyer',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${invoice.invoiceNo} • ${dateFormat.format(invoice.invoiceDate)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₹${invoice.grandTotal.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: deepAccent,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Color accent) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF5F7FB),
                ),
                child: Icon(Icons.flash_on_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  'Sell',
                  Icons.add_rounded,
                  accent,
                  () => _startNewSell(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  'All Sells',
                  Icons.list_rounded,
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InvoiceListView()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startNewSell(BuildContext context) async {
    final isCash = await showSellOptionsSheet(context);
    if (isCash == null || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceFormView(isCashSell: isCash),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, DashboardViewModel viewModel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await viewModel.logout();
        // Navigation will be handled by AuthWrapper automatically
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

