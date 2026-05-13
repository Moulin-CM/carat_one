import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../invoice/invoice_list_view.dart';
import '../invoice/invoice_form_view.dart';
import '../profile/profile_view.dart';
import '../reminders/reminders_view.dart';
import '../finance/expenses_view.dart';
import '../finance/withdrawals_view.dart';
import '../finance/buy_sell_report_view.dart';
import '../finance/brokerage_report_view.dart';
import '../subscription/subscription_plans_view.dart';
import '../settings/language_selection_view.dart';
import '../../constants/app_translations.dart';
import '../../widgets/sell_options_sheet.dart';
import '../../widgets/dashboard_skeleton.dart';
import '../../widgets/trial_banner.dart';
import '../../services/quota_service.dart';


import 'package:invoice_generator/constants/app_translations.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
    with AutomaticKeepAliveClientMixin {
  // Keep the ViewModel alive for the entire lifetime of the widget so that
  // Flutter rebuilds triggered by async operations (showMenu, showBottomSheet,
  // Navigator.push/pop etc.) never recreate the VM or reset _hasLoadedOnce.
  late final DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel()..loadInvoices();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider<DashboardViewModel>.value(
      value: _viewModel,
      child: const _DashboardViewContent(),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _DashboardViewContent extends StatefulWidget {
  const _DashboardViewContent();

  @override
  State<_DashboardViewContent> createState() => _DashboardViewContentState();
}

class _DashboardViewContentState extends State<_DashboardViewContent> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    const accent = Color(0xFF4F8AF4);
    const deepAccent = Color(0xFF1E3C72);

    if (viewModel.isLoading) {
      return const DashboardSkeleton();
    }

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(context, viewModel, accent, deepAccent),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Open Menu'.tr,
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.8),
                ),
                child: Icon(Icons.diamond_rounded, color: accent, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Dashboard'.tr),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBackdrop(accent, deepAccent),
          SafeArea(
            child: Column(
              children: [
                const TrialBanner(),
                Expanded(
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNewSell(context),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Sell'.tr, style: const TextStyle(color: Colors.white)),
        backgroundColor: accent,
      ),
    );
  }

  // ─────────────────────────────  DRAWER  ──────────────────────────────────

  /// Generates initials from a full name (e.g. "Raj Patel".tr → "RP").
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  Widget _buildDrawer(
    BuildContext context,
    DashboardViewModel viewModel,
    Color accent,
    Color deepAccent,
  ) {
    final userName  = viewModel.userProfile?.userName  ?? '';
    final userEmail = viewModel.userProfile?.email     ?? '';
    final initials  = _initials(userName);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.80,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      elevation: 24,
      shadowColor: Colors.black45,
      child: Column(
        children: [
          // ── Rich dark header ──────────────────────────────────────────
          _buildDrawerHeader(initials, userName, userEmail, accent, deepAccent),

          // ── Menu items ───────────────────────────────────────────────
          Expanded(
            child: Container(
              color: const Color(0xFFF7F9FC),
              child: ListView(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                children: [
                  _drawerTile(
                    context,
                    icon: Icons.person_outline_rounded,
                    label: 'Profile'.tr,
                    subtitle: 'View & edit your info'.tr,
                    iconBg: const Color(0xFF1A73E8),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ProfileView()));
                    },
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.notifications_active_rounded,
                    label: 'Reminders'.tr,
                    subtitle: 'Manage your alerts'.tr,
                    iconBg: const Color(0xFF7B5CF0),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RemindersView()));
                    },
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.workspace_premium_rounded,
                    label: 'Subscription'.tr,
                    subtitle: 'Upgrade your plan'.tr,
                    iconBg: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SubscriptionPlansView()));
                    },
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.language_rounded,
                    label: 'Change Language'.tr,
                    subtitle: 'App Language'.tr,
                    iconBg: const Color(0xFF009688),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LanguageSelectionView(isFromDrawer: true)));
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Logout row ───────────────────────────────────────────────
          _buildLogoutTile(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(
    String initials,
    String userName,
    String userEmail,
    Color accent,
    Color deepAccent,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1B3E),  // deep navy
            Color(0xFF1A2F5A),  // mid navy
            Color(0xFF1E3C72),  // accent navy
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Initials avatar
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [accent, accent.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials.isEmpty ? '?' : initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // App logo pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.diamond_rounded,
                            color: accent, size: 14),
                        const SizedBox(width: 6),
                        Text('Carat One'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // User name
              Text(
                userName.isEmpty ? 'Loading…' : userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Email
              Text(
                userEmail.isEmpty ? '' : userEmail,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: iconBg.withOpacity(0.07),
          highlightColor: iconBg.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon box
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                // Labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D1B3E),
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF8A94A6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Color(0xFFB0BAC9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context, DashboardViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Material(
            color: const Color(0xFFFFF1F1),
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              splashColor: Colors.red.withOpacity(0.08),
              highlightColor: Colors.red.withOpacity(0.04),
              onTap: () async {
                Navigator.pop(context);
                await _handleLogout(context, viewModel);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Logout'.tr,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD32F2F),
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sign out of your account'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: Colors.red.shade300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
                'Total Sells'.tr,
                viewModel.totalSells.toString(),
                Icons.receipt_long_rounded,
                accent,
                deepAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Purchases'.tr,
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
                viewModel.netProfitOrLoss >= 0 ? 'Net Profit'.tr : 'Net Loss'.tr,
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
                'Remaining Carat'.tr,
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
                'Total Buy Amount'.tr,
                currencyFormat.format(viewModel.totalBuyAmount),
                Icons.shopping_cart_rounded,
                Colors.orange,
                deepAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Sell Amount'.tr,
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
              Text(
                'Finance'.tr,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                  title: 'Expenses'.tr,
                  value: 'Manage'.tr,
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
                  title: 'Withdrawals'.tr,
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
            title: 'Buy / Sell'.tr,
            subtitle: 'Monthly & yearly'.tr,
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
            title: 'Brokerage'.tr,
            subtitle: 'Per broker report'.tr,
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
    final dateFormat = DateFormat('dd MMM yyyy'.tr);

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
              Text(
                'Recent Sells'.tr,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No sells yet'.tr,
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
                  child: Text('View All Sells'.tr),
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
                    invoice.buyerName.isNotEmpty ? invoice.buyerName : 'Unnamed Buyer'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${invoice.invoiceNo} • ${dateFormat.format(invoice.invoiceDate)}'.tr,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text('₹${invoice.grandTotal.toStringAsFixed(0)}'.tr,
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
              Text(
                'Quick Actions'.tr,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  'Sell'.tr,
                  Icons.add_rounded,
                  accent,
                  () => _startNewSell(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  'All Sells'.tr,
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
    final viewModel = context.read<DashboardViewModel>();

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
        builder: (_) => InvoiceFormView(
          isCashSell: isCash,
        ),
      ),
    );

    if (result == true && mounted) {
      Future.microtask(() async {
        if (mounted) {
          await viewModel.loadInvoices();
        }
      });
    }
  }

  void _showPaywall(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Limit Reached'.tr),
        content: Text(
            'You have reached your monthly limit for adding sells. Please upgrade your plan to continue adding unlimited entries.'.tr),
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
                MaterialPageRoute(builder: (_) => const SubscriptionPlansView()),
              );
            },
            child: Text('View Plans'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, DashboardViewModel viewModel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout'.tr),
        content: Text('Are you sure you want to logout?'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Logout'.tr),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await viewModel.logout();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logged out successfully'.tr),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'Error logging out: '.tr}$e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

}
