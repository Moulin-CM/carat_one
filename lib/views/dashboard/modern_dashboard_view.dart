import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../constants/app_translations.dart';
import '../../widgets/dashboard_skeleton.dart';
import '../../widgets/sell_options_sheet.dart';
import '../../widgets/trial_banner.dart';
import '../../widgets/subscription_badge.dart';
import '../../services/quota_service.dart';
import '../invoice/invoice_form_view.dart';
import '../invoice/invoice_list_view.dart';
import '../finance/expenses_view.dart';
import '../finance/withdrawals_view.dart';
import '../finance/buy_sell_report_view.dart';
import '../finance/brokerage_report_view.dart';
import '../subscription/subscription_plans_view.dart';
import '../shell/modern_drawer.dart';

/// Modern UI surface for the dashboard.
///
/// Re-uses the existing [DashboardViewModel] (provided by the parent
/// [DashboardView]) so figures stay in sync with the classic dashboard.
/// The visual language mirrors the Carat One marketing site: deep navy
/// background with a blue → cyan → violet gradient accent, soft glows,
/// and Plus-Jakarta-style weights.
class ModernDashboardView extends StatelessWidget {
  const ModernDashboardView({super.key});

  // Website tokens (docs/index.html → :root)
  static const _bg0 = Color(0xFF07091C);
  static const _bg1 = Color(0xFF0C1230);
  static const _primary = Color(0xFF4F8AF4);
  static const _accent = Color(0xFF38BDF8);
  static const _violet = Color(0xFFA78BFA);

  static const _grad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primary, _accent, _violet],
    stops: [0.0, 0.5, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return const _ModernDashboardContent();
  }
}

// Stateful so we can hold a GlobalKey<ScaffoldState> for the drawer.
class _ModernDashboardContent extends StatefulWidget {
  const _ModernDashboardContent();

  @override
  State<_ModernDashboardContent> createState() =>
      _ModernDashboardContentState();
}

class _ModernDashboardContentState extends State<_ModernDashboardContent> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Re-expose tokens from the public class so helpers stay readable.
  static const _bg0 = ModernDashboardView._bg0;
  static const _bg1 = ModernDashboardView._bg1;
  static const _primary = ModernDashboardView._primary;
  static const _accent = ModernDashboardView._accent;
  static const _violet = ModernDashboardView._violet;
  static const _grad = ModernDashboardView._grad;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    if (vm.isLoading) {
      return const DashboardSkeleton(dark: true);
    }

    final userName = vm.userProfile?.userName ?? '';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg0,
      extendBodyBehindAppBar: true,
      drawer: ModernDrawer(
        userName: vm.userProfile?.userName ?? '',
        userEmail: vm.userProfile?.email ?? '',
        onLogout: () => vm.logout(),
      ),
      appBar: _buildAppBar(context, userName),
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: Column(
              children: [
                const TrialBanner(),
                Expanded(
                  child: RefreshIndicator(
                    color: _accent,
                    backgroundColor: _bg1,
                    onRefresh: () => vm.loadInvoices(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(20, 12, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGreeting(userName),
                          const SizedBox(height: 20),
                          _buildHeroCard(vm),
                          const SizedBox(height: 20),
                          _buildStatsGrid(vm),
                          const SizedBox(height: 20),
                          _buildPaymentSummary(vm),
                          const SizedBox(height: 20),
                          _buildFinanceCard(context, vm),
                          const SizedBox(height: 20),
                          _buildRecentSells(context, vm),
                          const SizedBox(height: 20),
                          _buildQuickActions(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildGradientFab(context),
    );
  }

  // ─────────────────────────────  APP BAR  ────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context, String userName) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 8,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          tooltip: 'Open Menu'.tr,
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: _grad,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.diamond_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1)],
            ).createShader(rect),
            child: Text(
              'Carat One'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 12),
          child: Center(child: SubscriptionBadge()),
        ),
      ],
    );
  }

  // ─────────────────────────────  BACKDROP  ───────────────────────────────

  Widget _buildBackdrop() {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bg1, _bg0],
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: _glow(280, _primary.withOpacity(0.28)),
          ),
          Positioned(
            top: 80,
            left: -100,
            child: _glow(240, _violet.withOpacity(0.20)),
          ),
          Positioned(
            top: 320,
            right: -60,
            child: _glow(180, _accent.withOpacity(0.18)),
          ),
        ],
      ),
    );
  }

  Widget _glow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }


  // ─────────────────────────────  CONTENT  ────────────────────────────────

  Widget _buildGreeting(String userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,'.tr,
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userName.isEmpty ? 'Dashboard'.tr : userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(DashboardViewModel vm) {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final isProfit = vm.netProfitOrLoss >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _grad,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 16),
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
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isProfit
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isProfit ? 'Net Profit'.tr : 'Net Loss'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              (isProfit ? '+' : '-') +
                  currency.format(vm.netProfitOrLoss.abs()),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'For the current financial year'.tr,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(DashboardViewModel vm) {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final caratFormat = NumberFormat('#,##0.##');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statTile(
                icon: Icons.receipt_long_rounded,
                label: 'Total Sells'.tr,
                value: vm.totalSells.toString(),
                gradient: const [Color(0xFF4F8AF4), Color(0xFF38BDF8)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statTile(
                icon: Icons.diamond_rounded,
                label: 'Total Purchases'.tr,
                value: vm.totalPurchases.toString(),
                gradient: const [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statTile(
                icon: vm.netProfitOrLoss >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                label:
                    vm.netProfitOrLoss >= 0 ? 'Net Profit'.tr : 'Net Loss'.tr,
                value: (vm.netProfitOrLoss >= 0 ? '+' : '-') +
                    currency.format(vm.netProfitOrLoss.abs()),
                gradient: vm.netProfitOrLoss >= 0
                    ? const [Color(0xFF10B981), Color(0xFF34D399)]
                    : const [Color(0xFFEF4444), Color(0xFFF87171)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statTile(
                icon: Icons.scale_rounded,
                label: 'Remaining Carat'.tr,
                value: '${caratFormat.format(vm.totalRemainingCarat)} ct',
                gradient: const [Color(0xFF6366F1), Color(0xFFA78BFA)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statTile(
                icon: Icons.shopping_cart_rounded,
                label: 'Total Buy Amount'.tr,
                value: currency.format(vm.totalBuyAmount),
                gradient: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statTile(
                icon: Icons.point_of_sale_rounded,
                label: 'Total Sell Amount'.tr,
                value: currency.format(vm.totalSellAmount),
                gradient: const [Color(0xFFA78BFA), Color(0xFFF0ABFC)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────  PAYMENT SUMMARY  ──────────────────────────────

  Widget _buildPaymentSummary(DashboardViewModel vm) {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final pendingSell = vm.pendingSellAmount;
    final pendingPurchase = vm.pendingPurchaseAmount;
    final netPosition = vm.netPositionAmount;
    final isPositive = netPosition >= 0;
    final positiveColor = const Color(0xFF34D399);
    final negativeColor = const Color(0xFFF87171);
    final netColor = isPositive ? positiveColor : negativeColor;

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Payment Status'.tr,
            gradient: const [_accent, _violet],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _pendingTile(
                  icon: Icons.south_west_rounded,
                  label: 'Pending from Buyers'.tr,
                  helper: 'Receivable (Sell)'.tr,
                  amount: currency.format(pendingSell),
                  color: const Color(0xFFFBBF24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _pendingTile(
                  icon: Icons.north_east_rounded,
                  label: 'Pending to Sellers'.tr,
                  helper: 'Payable (Purchase)'.tr,
                  amount: currency.format(pendingPurchase),
                  color: const Color(0xFFF87171),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  netColor.withOpacity(0.20),
                  netColor.withOpacity(0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: netColor.withOpacity(0.45)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: netColor.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(Icons.savings_rounded, color: netColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Position'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pending from Buyers − Pending to Sellers'.tr,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    (isPositive ? '' : '- ') +
                        currency.format(netPosition.abs()),
                    style: TextStyle(
                      color: netColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingTile({
    required IconData icon,
    required String label,
    required String helper,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────  FINANCE CARD  ─────────────────────────────────

  Widget _buildFinanceCard(BuildContext context, DashboardViewModel vm) {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.account_balance_rounded,
            title: 'Finance'.tr,
            gradient: const [_primary, _accent],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _financeTile(
                  icon: Icons.receipt_long_rounded,
                  title: 'Expenses'.tr,
                  value: 'Manage'.tr,
                  color: const Color(0xFF94A3B8),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ExpensesView()),
                    );
                    await vm.loadInvoices();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _financeTile(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Withdrawals'.tr,
                  value:
                      '- ${currency.format(vm.outstandingWithdrawals)}',
                  color: const Color(0xFFFBBF24),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WithdrawalsView()),
                    );
                    await vm.loadInvoices();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _financeTile(
                  icon: Icons.assessment_rounded,
                  title: 'Buy / Sell'.tr,
                  value: 'Monthly & yearly'.tr,
                  color: _accent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BuySellReportView()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _financeTile(
                  icon: Icons.handshake_rounded,
                  title: 'Brokerage'.tr,
                  value: 'Per broker report'.tr,
                  color: _violet,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BrokerageReportView()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _financeTile({
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
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.30)),
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
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────  RECENT SELLS  ─────────────────────────────────

  Widget _buildRecentSells(BuildContext context, DashboardViewModel vm) {
    final dateFormat = DateFormat('dd MMM yyyy'.tr);
    final recent = vm.recentInvoices;

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.history_rounded,
            title: 'Recent Sells'.tr,
            gradient: const [_primary, _violet],
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No sells yet'.tr,
                  style: TextStyle(color: Colors.white.withOpacity(0.55)),
                ),
              ),
            )
          else
            ...recent.map((inv) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InvoiceFormView(invoice: inv),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: _grad,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.insert_drive_file_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inv.buyerName.isNotEmpty
                                        ? inv.buyerName
                                        : 'Unnamed Buyer'.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${inv.invoiceNo} • ${dateFormat.format(inv.invoiceDate)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withOpacity(0.55),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${inv.grandTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
          if (recent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const InvoiceListView()),
                  ),
                  style: TextButton.styleFrom(foregroundColor: _accent),
                  child: Text('View All Sells'.tr),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────────  QUICK ACTIONS  ────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.flash_on_rounded,
            title: 'Quick Actions'.tr,
            gradient: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _quickActionButton(
                  label: 'Sell'.tr,
                  icon: Icons.add_rounded,
                  gradient: const [_primary, _accent, _violet],
                  onTap: () => _startNewSell(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionButton(
                  label: 'All Sells'.tr,
                  icon: Icons.list_rounded,
                  gradient: const [Color(0xFF38BDF8), Color(0xFF60A5FA)],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const InvoiceListView()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton({
    required String label,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────  SHARED PIECES  ────────────────────────────────

  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required List<Color> gradient,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  // ───────────────────────  FAB & ACTIONS  ────────────────────────────────

  Widget _buildGradientFab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: _grad,
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _startNewSell(context),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'Sell'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startNewSell(BuildContext context) async {
    final canAdd = await QuotaService().canAddEntry(false);
    if (!canAdd && context.mounted) {
      _showPaywall(context);
      return;
    }
    if (!context.mounted) return;

    final isCash = await showSellOptionsSheet(context);
    if (isCash == null || !context.mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceFormView(isCashSell: isCash),
      ),
    );

    if (result == true && context.mounted) {
      context.read<DashboardViewModel>().notifyListeners();
    }
  }

  void _showPaywall(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Limit Reached'.tr),
        content: Text(
            'You have reached your monthly limit for adding sells. Please upgrade your plan to continue adding unlimited entries.'
                .tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SubscriptionPlansView()),
              );
            },
            child: Text('View Plans'.tr),
          ),
        ],
      ),
    );
  }
}
