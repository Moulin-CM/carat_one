import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/dashboard_viewmodel.dart';
import '../../services/modern_ui_service.dart';
import '../../services/auth_service.dart';
import '../../services/quota_service.dart';
import '../../constants/app_translations.dart';
import '../../models/invoice_model.dart';
import '../../widgets/sell_options_sheet.dart';
import '../../widgets/trial_banner.dart';
import '../invoice/invoice_form_view.dart';
import '../invoice/invoice_list_view.dart';
import '../finance/expenses_view.dart';
import '../finance/withdrawals_view.dart';
import '../finance/buy_sell_report_view.dart';
import '../finance/brokerage_report_view.dart';
import '../profile/profile_view.dart';
import '../reminders/reminders_view.dart';
import '../subscription/subscription_plans_view.dart';
import '../settings/language_selection_view.dart';

/// The "Modern UI" rendition of the dashboard.
///
/// Mirrors the marketing site's visual language — deep-navy gradient
/// backdrop, serif italic accent typography, glass-morphism cards with
/// soft shadows, and stagger-fade animations on first build. It reuses
/// the same [DashboardViewModel] that the classic dashboard consumes
/// (provided one level above by [DashboardView]) so both surfaces stay
/// in sync with no double-loading.
class ModernDashboardView extends StatefulWidget {
  const ModernDashboardView({super.key});

  @override
  State<ModernDashboardView> createState() => _ModernDashboardViewState();
}

class _ModernDashboardViewState extends State<ModernDashboardView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  // Modern palette — deliberately mirrors the website hero gradient.
  static const _deepNavy = Color(0xFF0D1B3E);
  static const _midNavy = Color(0xFF1A2F5A);
  static const _accentNavy = Color(0xFF1E3C72);
  static const _violet = Color(0xFF6366F1);
  static const _violetSoft = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _deepNavy,
      extendBodyBehindAppBar: true,
      drawer: _ModernDrawer(
        userName: viewModel.userProfile?.userName ?? '',
        userEmail: viewModel.userProfile?.email ?? '',
      ),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          const _AmbientBackdrop(),
          SafeArea(
            child: viewModel.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : RefreshIndicator(
                    color: _violet,
                    onRefresh: () => viewModel.loadInvoices(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TrialBanner(),
                          _StaggerReveal(
                            order: 0,
                            child: _Hero(
                              userName: viewModel.userProfile?.userName ?? '',
                              netProfit: viewModel.netProfitOrLoss,
                              currency: _currency,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _StaggerReveal(
                            order: 1,
                            child: _StatsGrid(viewModel: viewModel, currency: _currency),
                          ),
                          const SizedBox(height: 18),
                          _StaggerReveal(
                            order: 2,
                            child: _PaymentStatus(viewModel: viewModel, currency: _currency),
                          ),
                          const SizedBox(height: 18),
                          _StaggerReveal(
                            order: 3,
                            child: _FinanceCard(
                              viewModel: viewModel,
                              currency: _currency,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _StaggerReveal(
                            order: 4,
                            child: _RecentSells(viewModel: viewModel),
                          ),
                          const SizedBox(height: 18),
                          _StaggerReveal(
                            order: 5,
                            child: _QuickActions(
                              onSell: () => _startSell(context),
                              onViewAll: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const InvoiceListView()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _ModernFab(onPressed: () => _startSell(context)),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          tooltip: 'Open Menu'.tr,
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_violet, _violetSoft],
              ),
              boxShadow: [
                BoxShadow(
                  color: _violet.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.diamond_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            'Dashboard'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSell(BuildContext context) async {
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
      // Reuse the upstream ViewModel so both dashboards stay synced.
      await context.read<DashboardViewModel>().loadInvoices();
    }
  }

  void _showPaywall(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Limit Reached'.tr),
        content: Text(
            'You have reached your monthly limit for adding sells. Please upgrade your plan to continue adding unlimited entries.'
                .tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                ctx,
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

// ─────────────────────────────────────────────────────────────────────────
// Ambient backdrop — soft violet glow over deep navy. Mirrors the website's
// hero blob lighting.
// ─────────────────────────────────────────────────────────────────────────
class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _ModernDashboardViewState._deepNavy,
            _ModernDashboardViewState._midNavy,
            _ModernDashboardViewState._accentNavy,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _BlurGlow(
              color: _ModernDashboardViewState._violet.withValues(alpha: 0.35),
              size: 280,
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: _BlurGlow(
              color: _ModernDashboardViewState._violetSoft.withValues(alpha: 0.22),
              size: 240,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurGlow extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Stagger reveal — fades & slides each section up in turn on first build.
// ─────────────────────────────────────────────────────────────────────────
class _StaggerReveal extends StatelessWidget {
  final int order;
  final Widget child;
  const _StaggerReveal({required this.order, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 480 + (order * 90)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1.0 - t) * 18),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Hero — greeting + signature net profit/loss with serif italic accent.
// ─────────────────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final String userName;
  final double netProfit;
  final NumberFormat currency;
  const _Hero({required this.userName, required this.netProfit, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isProfit = netProfit >= 0;
    final accent = isProfit ? const Color(0xFF34D399) : const Color(0xFFF87171);
    final firstName = userName.split(' ').first;

    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: accent.withValues(alpha: 0.7), blurRadius: 8),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isProfit ? 'Net Profit'.tr : 'Net Loss'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (firstName.isNotEmpty)
            Text(
              'Welcome back,'.tr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          if (firstName.isNotEmpty) const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                if (firstName.isNotEmpty)
                  TextSpan(
                    text: '$firstName ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                TextSpan(
                  text: firstName.isNotEmpty ? "today's" : "Today's",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.2,
                  ),
                ),
                const TextSpan(
                  text: ' books',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            (isProfit ? '+' : '−') + currency.format(netProfit.abs()),
            style: TextStyle(
              color: accent,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'For the current financial year'.tr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Stats grid — 2x2 of headline metrics.
// ─────────────────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final DashboardViewModel viewModel;
  final NumberFormat currency;
  const _StatsGrid({required this.viewModel, required this.currency});

  @override
  Widget build(BuildContext context) {
    final caratFormat = NumberFormat('#,##0.##');
    final isProfit = viewModel.netProfitOrLoss >= 0;

    final tiles = <_StatTileData>[
      _StatTileData(
        icon: Icons.receipt_long_rounded,
        iconGradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        label: 'Total Sells'.tr,
        value: viewModel.totalSells.toString(),
      ),
      _StatTileData(
        icon: Icons.diamond_rounded,
        iconGradient: const [Color(0xFF14B8A6), Color(0xFF06B6D4)],
        label: 'Total Purchases'.tr,
        value: viewModel.totalPurchases.toString(),
      ),
      _StatTileData(
        icon: isProfit
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
        iconGradient: isProfit
            ? const [Color(0xFF34D399), Color(0xFF10B981)]
            : const [Color(0xFFF87171), Color(0xFFEF4444)],
        label: isProfit ? 'Net Profit'.tr : 'Net Loss'.tr,
        value: (isProfit ? '+' : '−') +
            currency.format(viewModel.netProfitOrLoss.abs()),
      ),
      _StatTileData(
        icon: Icons.scale_rounded,
        iconGradient: const [Color(0xFF818CF8), Color(0xFF6366F1)],
        label: 'Remaining Carat'.tr,
        value: '${caratFormat.format(viewModel.totalRemainingCarat)} ct',
      ),
      _StatTileData(
        icon: Icons.shopping_cart_rounded,
        iconGradient: const [Color(0xFFFB923C), Color(0xFFF59E0B)],
        label: 'Total Buy Amount'.tr,
        value: currency.format(viewModel.totalBuyAmount),
      ),
      _StatTileData(
        icon: Icons.point_of_sale_rounded,
        iconGradient: const [Color(0xFFA855F7), Color(0xFFD946EF)],
        label: 'Total Sell Amount'.tr,
        value: currency.format(viewModel.totalSellAmount),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (_, i) => _StatTile(data: tiles[i]),
    );
  }
}

class _StatTileData {
  final IconData icon;
  final List<Color> iconGradient;
  final String label;
  final String value;
  _StatTileData({
    required this.icon,
    required this.iconGradient,
    required this.label,
    required this.value,
  });
}

class _StatTile extends StatefulWidget {
  final _StatTileData data;
  const _StatTile({required this.data});

  @override
  State<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<_StatTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: _GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.data.iconGradient,
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: widget.data.iconGradient.last.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.data.icon, color: Colors.white, size: 18),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.data.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Payment status — pending receivable and payable.
// ─────────────────────────────────────────────────────────────────────────
class _PaymentStatus extends StatelessWidget {
  final DashboardViewModel viewModel;
  final NumberFormat currency;
  const _PaymentStatus({required this.viewModel, required this.currency});

  @override
  Widget build(BuildContext context) {
    final netPosition = viewModel.netPositionAmount;
    final isPositive = netPosition >= 0;
    final netColor =
        isPositive ? const Color(0xFF34D399) : const Color(0xFFF87171);

    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                'Payment Status'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PaymentRow(
                  arrowDown: true,
                  label: 'Pending from Buyers'.tr,
                  sublabel: 'Receivable (Sell)'.tr,
                  value: currency.format(viewModel.pendingSellAmount),
                  tint: const Color(0xFFFBBF24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PaymentRow(
                  arrowDown: false,
                  label: 'Pending to Sellers'.tr,
                  sublabel: 'Payable (Purchase)'.tr,
                  value: currency.format(viewModel.pendingPurchaseAmount),
                  tint: const Color(0xFFF87171),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  netColor.withValues(alpha: 0.22),
                  netColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: netColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: netColor.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.savings_rounded,
                      color: netColor, size: 20),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pending from Buyers − Pending to Sellers'.tr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    (isPositive ? '' : '− ') +
                        currency.format(netPosition.abs()),
                    style: TextStyle(
                      color: netColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
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
}

class _PaymentRow extends StatelessWidget {
  final bool arrowDown;
  final String label;
  final String sublabel;
  final String value;
  final Color tint;
  const _PaymentRow({
    required this.arrowDown,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              arrowDown ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: tint,
              size: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            sublabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Quick actions row.
// ─────────────────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final VoidCallback onSell;
  final VoidCallback onViewAll;
  const _QuickActions({required this.onSell, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                'Quick Actions'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.add_rounded,
                  label: 'Sell'.tr,
                  primary: true,
                  onTap: onSell,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.list_rounded,
                  label: 'All Sells'.tr,
                  primary: false,
                  onTap: onViewAll,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          decoration: BoxDecoration(
            gradient: widget.primary
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _ModernDashboardViewState._violet,
                      _ModernDashboardViewState._violetSoft,
                    ],
                  )
                : null,
            color: widget.primary ? null : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: widget.primary
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: widget.primary
                ? [
                    BoxShadow(
                      color: _ModernDashboardViewState._violet
                          .withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Modern FAB — pill-shaped primary action, white surface on dark canvas
// for maximum legibility, with a violet "+" badge for instant scanability.
// Animates scale + lift on press (Material press feedback adapted for the
// modern aesthetic). Stays out of bottom-nav reach by riding endFloat.
// ─────────────────────────────────────────────────────────────────────────
class _ModernFab extends StatefulWidget {
  final VoidCallback onPressed;
  const _ModernFab({required this.onPressed});

  @override
  State<_ModernFab> createState() => _ModernFabState();
}

class _ModernFabState extends State<_ModernFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'New Sell'.tr,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(
              minHeight: 56, // Material tap target floor
            ),
            padding: const EdgeInsets.fromLTRB(8, 8, 22, 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF1F5FF)],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                // Outer violet glow — signals "premium / primary" without
                // shouting over the dark canvas like a flat drop shadow would.
                BoxShadow(
                  color: _ModernDashboardViewState._violet
                      .withValues(alpha: _pressed ? 0.55 : 0.40),
                  blurRadius: _pressed ? 30 : 22,
                  spreadRadius: _pressed ? 1 : 0,
                  offset: Offset(0, _pressed ? 6 : 10),
                ),
                // Soft contact shadow for grounding.
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _ModernDashboardViewState._violet,
                        _ModernDashboardViewState._violetSoft,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _ModernDashboardViewState._violet
                            .withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'New Sell'.tr,
                  style: const TextStyle(
                    color: _ModernDashboardViewState._deepNavy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Finance card — Expenses, Withdrawals, and Reports.
// ─────────────────────────────────────────────────────────────────────────
class _FinanceCard extends StatelessWidget {
  final DashboardViewModel viewModel;
  final NumberFormat currency;
  const _FinanceCard({required this.viewModel, required this.currency});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                'Finance'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FinanceTile(
                  icon: Icons.receipt_long_rounded,
                  title: 'Expenses'.tr,
                  value: 'Manage'.tr,
                  tint: const Color(0xFF94A3B8),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ExpensesView()),
                    );
                    await viewModel.loadInvoices();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FinanceTile(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Withdrawals'.tr,
                  value:
                      '− ${currency.format(viewModel.outstandingWithdrawals)}',
                  tint: const Color(0xFFFBBF24),
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
          Row(
            children: [
              Expanded(
                child: _ReportTile(
                  icon: Icons.assessment_rounded,
                  title: 'Buy / Sell'.tr,
                  subtitle: 'Monthly & yearly'.tr,
                  tint: const Color(0xFF60A5FA),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BuySellReportView()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReportTile(
                  icon: Icons.handshake_rounded,
                  title: 'Brokerage'.tr,
                  subtitle: 'Per broker report'.tr,
                  tint: const Color(0xFFC084FC),
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
}

class _FinanceTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color tint;
  final VoidCallback onTap;
  const _FinanceTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.tint,
    required this.onTap,
  });

  @override
  State<_FinanceTile> createState() => _FinanceTileState();
}

class _FinanceTileState extends State<_FinanceTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: widget.tint.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.icon, color: widget.tint, size: 20),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      color: widget.tint.withValues(alpha: 0.65), size: 18),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.tint,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;
  const _ReportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
  });

  @override
  State<_ReportTile> createState() => _ReportTileState();
}

class _ReportTileState extends State<_ReportTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: widget.tint.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.icon, color: widget.tint, size: 20),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      color: widget.tint.withValues(alpha: 0.65), size: 18),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Recent sells — list of latest invoices with tap-to-open.
// ─────────────────────────────────────────────────────────────────────────
class _RecentSells extends StatelessWidget {
  final DashboardViewModel viewModel;
  const _RecentSells({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final recent = viewModel.recentInvoices;
    final dateFormat = DateFormat('dd MMM yyyy'.tr);

    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                'Recent Sells'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No sells yet'.tr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...recent.map((invoice) =>
                _RecentSellItem(invoice: invoice, dateFormat: dateFormat)),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFA5B4FC),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 8),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const InvoiceListView()),
                ),
                child: Text(
                  'View All Sells'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentSellItem extends StatefulWidget {
  final InvoiceModel invoice;
  final DateFormat dateFormat;
  const _RecentSellItem({required this.invoice, required this.dateFormat});

  @override
  State<_RecentSellItem> createState() => _RecentSellItemState();
}

class _RecentSellItemState extends State<_RecentSellItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoiceFormView(invoice: inv),
        ),
      ),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insert_drive_file_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.buyerName.isNotEmpty
                          ? inv.buyerName
                          : 'Unnamed Buyer'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${inv.invoiceNo} • ${widget.dateFormat.format(inv.invoiceDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${inv.grandTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Reusable glass card.
// ─────────────────────────────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _GlassCard({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Modern drawer — same items as the classic drawer, restyled to fit the
// dark gradient theme. Includes the Modern UI toggle so the user can
// always switch back.
// ─────────────────────────────────────────────────────────────────────────
class _ModernDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  const _ModernDrawer({required this.userName, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(userName);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: _ModernDashboardViewState._deepNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(initials),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
              children: [
                _modernTile(
                  context,
                  icon: Icons.person_outline_rounded,
                  iconGradient: const [Color(0xFF1A73E8), Color(0xFF6366F1)],
                  label: 'Profile'.tr,
                  subtitle: 'View & edit your info'.tr,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProfileView()));
                  },
                ),
                _modernTile(
                  context,
                  icon: Icons.notifications_active_rounded,
                  iconGradient: const [Color(0xFF7B5CF0), Color(0xFFA855F7)],
                  label: 'Reminders'.tr,
                  subtitle: 'Manage your alerts'.tr,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RemindersView()));
                  },
                ),
                _modernTile(
                  context,
                  icon: Icons.workspace_premium_rounded,
                  iconGradient: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  label: 'Subscription'.tr,
                  subtitle: 'Upgrade your plan'.tr,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SubscriptionPlansView()));
                  },
                ),
                _modernTile(
                  context,
                  icon: Icons.language_rounded,
                  iconGradient: const [Color(0xFF14B8A6), Color(0xFF06B6D4)],
                  label: 'Change Language'.tr,
                  subtitle: 'App Language'.tr,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LanguageSelectionView(
                                isFromDrawer: true)));
                  },
                ),
                _modernToggleTile(context),
              ],
            ),
          ),
          _buildLogoutTile(context),
        ],
      ),
    );
  }

  Widget _buildHeader(String initials) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFA855F7),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.18),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName.isEmpty ? 'Carat One'.tr : userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Modern UI Active'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernTile(
    BuildContext context, {
    required IconData icon,
    required List<Color> iconGradient,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: iconGradient,
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: iconGradient.last.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modernToggleTile(BuildContext context) {
    final modernUi = context.watch<ModernUiService>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => modernUi.setEnabled(!modernUi.enabled),
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _ModernDashboardViewState._violet,
                        _ModernDashboardViewState._violetSoft,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: _ModernDashboardViewState._violet
                            .withValues(alpha: 0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modern UI'.tr,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Premium experience'.tr,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: modernUi.enabled,
                  onChanged: (v) => modernUi.setEnabled(v),
                  activeColor: Colors.white,
                  activeTrackColor:
                      _ModernDashboardViewState._violet.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
      child: Material(
        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _handleLogout(context),
          splashColor: const Color(0xFFEF4444).withValues(alpha: 0.18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Logout'.tr,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFCA5A5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sign out of your account'.tr,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Logout'.tr),
        content: Text('Are you sure you want to logout?'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Logout'.tr,
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      // AuthWrapper is listening on FirebaseAuth.authStateChanges() and
      // will swap to the sign-in screen as soon as signOut() resolves —
      // we deliberately don't push a route ourselves.
      await AuthService().signOut();
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }
}
