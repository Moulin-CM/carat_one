import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/purchase_model.dart';
import '../../models/stock_valuation_item.dart';
import '../../viewmodels/purchase_viewmodel.dart';
import '../../widgets/ads/native_ad_card.dart';
import '../../widgets/list_skeleton.dart';
import '../../widgets/paywall_dialog.dart';
import '../../services/quota_service.dart';
import '../../constants/app_translations.dart';
import '../finance/buy_sell_report_view.dart';
import 'purchase_form_view.dart';
import 'purchase_detail_view.dart';

/// Modern UI surface for the Purchases tab.
///
/// Expects a [PurchaseViewModel] provided above it (the parent
/// [PurchaseListView] supplies one). Visual language mirrors the
/// marketing site: deep navy backdrop, blue → cyan → violet gradient
/// accents, glass cards.
class ModernPurchaseListContent extends StatefulWidget {
  const ModernPurchaseListContent({super.key});

  @override
  State<ModernPurchaseListContent> createState() =>
      _ModernPurchaseListContentState();
}

class _ModernPurchaseListContentState extends State<ModernPurchaseListContent> {
  final _searchController = TextEditingController();

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

  static const int _adInterval = 7;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PurchaseViewModel>();
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final caratFmt = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: _bg0,
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildSummaryCard(context, vm, fmt, caratFmt),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: _buildActionRow(context, vm),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildSearchBar(context),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: vm.isLoading
                      ? const ListSkeleton(dark: true)
                      : vm.isEmpty
                          ? _emptyState()
                          : RefreshIndicator(
                              color: _accent,
                              backgroundColor: _bg1,
                              onRefresh: () => context
                                  .read<PurchaseViewModel>()
                                  .loadPurchases(),
                              child: _buildPurchaseListWithAds(
                                  context, vm, fmt, caratFmt),
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
            top: 200,
            left: -100,
            child: _glow(240, _violet.withOpacity(0.18)),
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
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }

  // ───────────────────────  SUMMARY CARD  ─────────────────────────────────

  Widget _buildSummaryCard(BuildContext context, PurchaseViewModel vm,
      NumberFormat fmt, NumberFormat caratFmt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      decoration: BoxDecoration(
        gradient: _grad,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildYearEndBadge(context, vm),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  'Opening Carats'.tr,
                  '${caratFmt.format(vm.openingTotalCarat)} ct',
                  Icons.diamond_rounded,
                ),
              ),
              _divider(),
              Expanded(
                child: _summaryTile(
                  'Opening Amount'.tr,
                  fmt.format(vm.openingTotalAmount),
                  Icons.currency_rupee_rounded,
                ),
              ),
              _divider(),
              Expanded(
                child: _summaryTile(
                  'Remaining'.tr,
                  '${caratFmt.format(vm.totalRemainingCarat)} ct',
                  Icons.balance_rounded,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Divider(color: Colors.white24, height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  'Sold Carat'.tr,
                  '${caratFmt.format(vm.totalSoldCarat)} ct',
                  Icons.sell_rounded,
                ),
              ),
              _divider(),
              Expanded(
                child: _summaryTile(
                  'Sold Amount'.tr,
                  fmt.format(vm.totalSellAmount),
                  Icons.payments_rounded,
                ),
              ),
              _divider(),
              Expanded(
                child: InkWell(
                  onTap: () => _manageStockValuation(context, vm),
                  borderRadius: BorderRadius.circular(12),
                  child: _summaryTile(
                    'Stock Valuation'.tr,
                    fmt.format(vm.stockValuationTotal),
                    Icons.savings_rounded,
                    editable: true,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Container(height: 1, color: Colors.white24),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                '${'Pending Payment'.tr}: ',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                fmt.format(vm.totalPendingPaymentAmount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 35, color: Colors.white24);

  Widget _summaryTile(String label, String value, IconData icon,
      {bool editable = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.85), size: 18),
            if (editable) ...[
              const SizedBox(width: 4),
              const Icon(Icons.edit_rounded, color: Colors.white70, size: 12),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildYearEndBadge(BuildContext context, PurchaseViewModel vm) {
    final end = vm.yearEndDate;
    final label = end == null
        ? 'Set Year End'.tr
        : '${'FY End: '.tr}${DateFormat('dd MMM yyyy'.tr).format(end)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => _pickYearEnd(context, vm),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_rounded,
                      color: Colors.white, size: 13),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_rounded,
                      color: Colors.white70, size: 11),
                ],
              ),
            ),
          ),
          if (end != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _clearYearEnd(context, vm),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white70, size: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────  ACTION ROW  ───────────────────────────────────

  Widget _buildActionRow(BuildContext context, PurchaseViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BuySellReportView()),
                );
                if (context.mounted) {
                  context.read<PurchaseViewModel>().loadPurchases();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _accent.withOpacity(0.40)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assessment_rounded,
                        size: 18, color: _accent),
                    const SizedBox(width: 8),
                    Text(
                      'Buy / Sell Report'.tr,
                      style: const TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _accent.withOpacity(0.40)),
          ),
          child: IconButton(
            onPressed: vm.isSyncing ? null : () => vm.syncInventory(),
            icon: vm.isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _accent,
                    ),
                  )
                : const Icon(Icons.sync_rounded, color: _accent),
            tooltip: 'Sync Inventory'.tr,
          ),
        ),
      ],
    );
  }

  // ───────────────────────  SEARCH BAR  ───────────────────────────────────

  Widget _buildSearchBar(BuildContext context) {
    final hasText = _searchController.text.isNotEmpty;
    return TextField(
      controller: _searchController,
      onChanged: (v) =>
          context.read<PurchaseViewModel>().setSearchQuery(v),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: _accent,
      decoration: InputDecoration(
        hintText: 'Search by seller, broker, size...'.tr,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.45),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(Icons.search_rounded,
            color: _accent, size: 20),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 0),
        suffixIcon: hasText
            ? IconButton(
                icon: Icon(Icons.clear_rounded,
                    color: Colors.white.withOpacity(0.65), size: 20),
                onPressed: () {
                  _searchController.clear();
                  context.read<PurchaseViewModel>().setSearchQuery('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
    );
  }

  // ───────────────────────  LIST + CARDS  ─────────────────────────────────

  Widget _buildPurchaseListWithAds(BuildContext context, PurchaseViewModel vm,
      NumberFormat fmt, NumberFormat caratFmt) {
    final purchases = vm.purchases;
    final adCount = purchases.length ~/ _adInterval;
    final totalSlots = purchases.length + adCount;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      itemCount: totalSlots,
      itemBuilder: (ctx, index) {
        const groupSize = _adInterval + 1;
        final positionInGroup = index % groupSize;
        if (positionInGroup == _adInterval) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: NativeAdCard(),
          );
        }
        final purchaseIndex =
            (index ~/ groupSize) * _adInterval + positionInGroup;
        if (purchaseIndex >= purchases.length) {
          return const SizedBox.shrink();
        }
        return _purchaseCard(
            ctx, purchases[purchaseIndex], vm, fmt, caratFmt);
      },
    );
  }

  Widget _purchaseCard(BuildContext context, PurchaseModel p,
      PurchaseViewModel vm, NumberFormat fmt, NumberFormat caratFmt) {
    final dateFormat = DateFormat('dd MMM yy'.tr);
    final paid = p.isFullyPaid;
    final partial = p.totalPaidCarat > 0 && !paid;
    final statusLabel = paid
        ? 'Paid'.tr
        : partial
            ? 'Partial'.tr
            : 'Unpaid'.tr;
    final statusColor = paid
        ? const Color(0xFF34D399)
        : partial
            ? const Color(0xFFFBBF24)
            : const Color(0xFFF87171);

    return Dismissible(
      key: Key(p.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFF87171)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 28),
      ),
      confirmDismiss: (dir) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Confirm Delete'.tr),
            content: Text(
                'Are you sure you want to delete this purchase? This will also remove its sale tracking data.'
                    .tr),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancel'.tr)),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Delete'.tr),
              ),
            ],
          ),
        );
      },
      onDismissed: (dir) {
        vm.deletePurchase(p.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${'Purchase from'.tr} ${p.sellerName} ${'deleted'.tr}')),
        );
      },
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PurchaseDetailView(purchase: p)),
          );
          if (context.mounted) vm.loadPurchases();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: _grad,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.diamond_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.sellerName.isNotEmpty
                                ? p.sellerName
                                : 'Unknown Seller'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${'Broker'.tr}: ${p.brokerName.isNotEmpty ? p.brokerName : "-"}  •  ${'Size'.tr}: ${p.size.isNotEmpty ? p.size : "-"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: statusColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (p.isForOther) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _accent.withOpacity(0.5)),
                            ),
                            child: Text(
                              'For Other'.tr,
                              style: const TextStyle(
                                color: _accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoChip('Net Amt'.tr, fmt.format(p.netAmount),
                          const Color(0xFFFBBF24)),
                      _infoChip(
                          'Carat'.tr,
                          '${caratFmt.format(p.totalCarat)} ct',
                          _accent),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 13, color: Colors.white.withOpacity(0.45)),
                    const SizedBox(width: 4),
                    Text(
                      '${'Buy'.tr}: ${dateFormat.format(p.buyDate)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.55)),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.payment_rounded,
                        size: 13, color: Colors.white.withOpacity(0.45)),
                    const SizedBox(width: 4),
                    Text(
                      '${'Pay'.tr}: ${dateFormat.format(p.paymentDate)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.55)),
                    ),
                    const Spacer(),
                    Icon(Icons.schedule_rounded,
                        size: 13, color: Colors.white.withOpacity(0.45)),
                    const SizedBox(width: 4),
                    Text(
                      '${p.dueDays}${'d due'.tr}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.55)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.55),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: _grad,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.diamond_outlined,
                size: 40, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Text(
            'No purchases yet'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first purchase'.tr,
            style: TextStyle(color: Colors.white.withOpacity(0.55)),
          ),
        ],
      ),
    );
  }

  // ───────────────────────  FAB  ──────────────────────────────────────────

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
          onTap: () => _startNewPurchase(context),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'Add Purchase'.tr,
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

  // ───────────────────────  ACTIONS / DIALOGS  ────────────────────────────

  Future<void> _startNewPurchase(BuildContext context) async {
    final canAdd = await QuotaService().canAddEntry(true);
    if (!canAdd && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => PaywallDialog(
          message:
              'You have reached your monthly limit for adding purchases. Please upgrade your plan to continue adding unlimited entries.'
                  .tr,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PurchaseFormView()),
    );
    if (result == true && context.mounted) {
      context.read<PurchaseViewModel>().loadPurchases();
    }
  }

  Future<void> _pickYearEnd(
      BuildContext context, PurchaseViewModel vm) async {
    final initial =
        vm.yearEndDate ?? DateTime(DateTime.now().year, 3, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select Financial Year End'.tr,
    );
    if (picked != null) {
      await vm.setYearEndDate(picked);
    }
  }

  Future<void> _clearYearEnd(
      BuildContext context, PurchaseViewModel vm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear Year End?'.tr),
        content: Text(
            'This removes the financial year filter. All-time totals will be shown.'
                .tr),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel'.tr)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Clear'.tr),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await vm.setYearEndDate(null);
    }
  }

  Future<void> _manageStockValuation(
      BuildContext context, PurchaseViewModel vm) async {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final caratFmt = NumberFormat('#,##0.00');
    final items = List<StockValuationItem>.from(vm.stockValuationItems);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final totalVal =
              items.fold(0.0, (sum, item) => sum + item.totalValue);
          final totalCarat =
              items.fold(0.0, (sum, item) => sum + item.carats);
          final remainingActual = vm.totalRemainingCarat;
          final diff = (remainingActual - totalCarat).abs();
          final isMismatch = diff > 0.001;

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: _bg0,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_bg1, Color(0xFF11173B)],
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                    border: Border(
                      bottom: BorderSide(
                          color: Colors.white.withOpacity(0.08)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 38,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: _grad,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.savings_rounded,
                                    color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Stock Valuation'.tr,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _miniStat(
                                'Total Value'.tr,
                                fmt.format(totalVal),
                                _accent),
                          ),
                          Expanded(
                            child: _miniStat(
                                'Total Carats'.tr,
                                '${caratFmt.format(totalCarat)} ct',
                                const Color(0xFFFBBF24)),
                          ),
                          Expanded(
                            child: _miniStat(
                                'Actual Remaining'.tr,
                                '${caratFmt.format(remainingActual)} ct',
                                const Color(0xFF34D399)),
                          ),
                        ],
                      ),
                      if (isMismatch)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Warning: Valuation carats do not match actual remaining carats.'
                                .tr,
                            style: const TextStyle(
                              color: Color(0xFFFCA5A5),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 48,
                                  color: Colors.white.withOpacity(0.25)),
                              const SizedBox(height: 12),
                              Text(
                                'No valuation items added'.tr,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final item = items[i];
                            final hasDeductions =
                                item.discountPercent > 0 ||
                                    item.brokeragePercent > 0;
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color:
                                        Colors.white.withOpacity(0.08)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.itemName.isNotEmpty
                                              ? item.itemName
                                              : 'Unnamed Item'.tr,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          '${caratFmt.format(item.carats)} ct @ ${fmt.format(item.ratePerCarat)}/ct'
                                              .tr,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white
                                                .withOpacity(0.55),
                                          ),
                                        ),
                                        if (hasDeductions)
                                          Text(
                                            '${'Disc'.tr} ${item.discountPercent.toStringAsFixed(item.discountPercent.truncateToDouble() == item.discountPercent ? 0 : 2)}% • ${'Brok'.tr} ${item.brokeragePercent.toStringAsFixed(item.brokeragePercent.truncateToDouble() == item.brokeragePercent ? 0 : 2)}% → ${fmt.format(item.effectiveRatePerCarat)}/ct',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFFFBBF24),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    fmt.format(item.totalValue),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _accent,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined,
                                        size: 20,
                                        color: Colors.white
                                            .withOpacity(0.75)),
                                    onPressed: () async {
                                      final updated =
                                          await _showItemDialog(
                                              context, item);
                                      if (updated != null) {
                                        setModalState(() {
                                          items[i] = updated;
                                        });
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 20,
                                        color: Color(0xFFFCA5A5)),
                                    onPressed: () {
                                      setModalState(() {
                                        items.removeAt(i);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              final newItem = await _showItemDialog(context);
                              if (newItem != null) {
                                setModalState(() {
                                  items.add(newItem);
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: _accent.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: _accent.withOpacity(0.40)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_rounded,
                                      color: _accent, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Add Item'.tr,
                                    style: const TextStyle(
                                      color: _accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              await vm.setStockValuationItems(items);
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                gradient: _grad,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _accent.withOpacity(0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'Save Valuation'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.55),
          ),
        ),
      ],
    );
  }

  Future<StockValuationItem?> _showItemDialog(BuildContext context,
      [StockValuationItem? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.itemName ?? '');
    final caratCtrl = TextEditingController(
        text: existing != null && existing.carats > 0
            ? existing.carats.toString()
            : '');
    final rateCtrl = TextEditingController(
        text: existing != null && existing.ratePerCarat > 0
            ? existing.ratePerCarat.toString()
            : '');
    final discountCtrl = TextEditingController(
        text: existing != null && existing.discountPercent > 0
            ? existing.discountPercent.toString()
            : '');
    final brokerageCtrl = TextEditingController(
        text: existing != null && existing.brokeragePercent > 0
            ? existing.brokeragePercent.toString()
            : '');
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return showDialog<StockValuationItem>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final carats = double.tryParse(caratCtrl.text) ?? 0.0;
          final rate = double.tryParse(rateCtrl.text) ?? 0.0;
          final disc = double.tryParse(discountCtrl.text) ?? 0.0;
          final brok = double.tryParse(brokerageCtrl.text) ?? 0.0;
          final effRate = (rate * (1 - (disc / 100)) * (1 - (brok / 100)))
              .clamp(0.0, double.infinity);
          final totalVal = carats * effRate;

          return AlertDialog(
            title: Text(existing == null
                ? 'Add Stock Item'.tr
                : 'Edit Stock Item'.tr),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                        labelText:
                            'Item Name (e.g. Rough, Polished)'.tr),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: caratCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: InputDecoration(
                              labelText: 'Carats'.tr, suffixText: 'ct'),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: rateCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: InputDecoration(
                              labelText: 'Rate'.tr, prefixText: '₹'),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: discountCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: InputDecoration(
                              labelText: 'Discount'.tr,
                              suffixText: '%'),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: brokerageCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: InputDecoration(
                              labelText: 'Brokerage'.tr,
                              suffixText: '%'),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Effective Rate'.tr,
                                style: const TextStyle(fontSize: 12)),
                            Text('${fmt.format(effRate)}/ct'.tr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Value'.tr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                )),
                            Text(fmt.format(totalVal),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _accent,
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel'.tr)),
              ElevatedButton(
                onPressed: () {
                  if (carats > 0 && rate > 0) {
                    Navigator.pop(
                        ctx,
                        (existing ?? StockValuationItem()).copyWith(
                          itemName: nameCtrl.text.trim(),
                          carats: carats,
                          ratePerCarat: rate,
                          discountPercent: disc,
                          brokeragePercent: brok,
                        ));
                  }
                },
                child: Text('OK'.tr),
              ),
            ],
          );
        },
      ),
    );
  }
}
