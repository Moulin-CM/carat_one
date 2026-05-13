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
import '../finance/buy_sell_report_view.dart';
import 'purchase_form_view.dart';
import 'purchase_detail_view.dart';
import '../../constants/app_translations.dart';


import 'package:invoice_generator/constants/app_translations.dart';

class PurchaseListView extends StatefulWidget {
  const PurchaseListView({super.key});

  @override
  State<PurchaseListView> createState() => _PurchaseListViewState();
}

class _PurchaseListViewState extends State<PurchaseListView>
    with AutomaticKeepAliveClientMixin {
  late final PurchaseViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PurchaseViewModel()..loadPurchases();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ChangeNotifierProvider<PurchaseViewModel>.value(
      value: _viewModel,
      child: const _PurchaseListContent(),
    );
  }
}

class _PurchaseListContent extends StatefulWidget {
  const _PurchaseListContent();
  @override
  State<_PurchaseListContent> createState() => _PurchaseListContentState();
}

class _PurchaseListContentState extends State<_PurchaseListContent> {
  final _searchController = TextEditingController();
  static const _accent = Color(0xFF4F8AF4);

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
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          _backdrop(),
          SafeArea(
            child: Column(
              children: [
                // Global Summary Bar
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3C72), Color(0xFF4F8AF4)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _yearEndBadge(context, vm),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _summaryTile('Opening Carats'.tr,
                                '${caratFmt.format(vm.openingTotalCarat)} ct',
                                Icons.diamond_rounded),
                          ),
                          Container(width: 1, height: 35, color: Colors.white24),
                          Expanded(
                            child: _summaryTile('Opening Amount'.tr,
                                fmt.format(vm.openingTotalAmount),
                                Icons.currency_rupee_rounded),
                          ),
                          Container(width: 1, height: 35, color: Colors.white24),
                          Expanded(
                            child: _summaryTile('Remaining'.tr,
                                '${caratFmt.format(vm.totalRemainingCarat)} ct',
                                Icons.balance_rounded),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                        child: Divider(color: Colors.white24, height: 1),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _summaryTile('Sold Carat'.tr,
                                '${caratFmt.format(vm.totalSoldCarat)} ct',
                                Icons.sell_rounded),
                          ),
                          Container(width: 1, height: 35, color: Colors.white24),
                          Expanded(
                            child: _summaryTile('Sold Amount'.tr,
                                fmt.format(vm.totalSellAmount),
                                Icons.payments_rounded),
                          ),
                          Container(width: 1, height: 35, color: Colors.white24),
                          Expanded(
                            child: InkWell(
                              onTap: () => _manageStockValuation(context, vm),
                              borderRadius: BorderRadius.circular(12),
                              child: _summaryTile(
                                  'Stock Valuation'.tr,
                                  fmt.format(vm.stockValuationTotal),
                                  Icons.savings_rounded,
                                  editable: true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BuySellReportView()),
                            );
                            if (context.mounted) {
                              context.read<PurchaseViewModel>().loadPurchases();
                            }
                          },
                          icon: const Icon(Icons.assessment_rounded, size: 18),
                          label: Text('Buy / Sell Report'.tr),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _accent,
                            side: const BorderSide(color: _accent),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: vm.isSyncing ? null : () => vm.syncInventory(),
                        icon: vm.isSyncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync_rounded, color: _accent),
                        tooltip: 'Sync Inventory'.tr,
                      ),
                    ],
                  ),
                ),
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => context.read<PurchaseViewModel>().setSearchQuery(v),
                    decoration: InputDecoration(
                      hintText: 'Search by seller, broker, size...'.tr,
                      prefixIcon: const Icon(Icons.search_rounded, color: _accent),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                context.read<PurchaseViewModel>().setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: vm.isLoading
                      ? const ListSkeleton()
                      : vm.isEmpty
                          ? _emptyState()
                          : RefreshIndicator(
                              onRefresh: () => context.read<PurchaseViewModel>().loadPurchases(),
                              child: _buildPurchaseListWithAds(context, vm, fmt, caratFmt),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNewPurchase(context),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Purchase'.tr, style: const TextStyle(color: Colors.white)),
        backgroundColor: _accent,
      ),
    );
  }

  Future<void> _startNewPurchase(BuildContext context) async {
    final canAdd = await QuotaService().canAddEntry(true);
    if (!canAdd && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => PaywallDialog(
          message: 'You have reached your monthly limit for adding purchases. Please upgrade your plan to continue adding unlimited entries.'.tr,
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

  Widget _summaryTile(String label, String value, IconData icon,
      {bool editable = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.8), size: 18),
            if (editable) ...[
              const SizedBox(width: 4),
              const Icon(Icons.edit_rounded, color: Colors.white70, size: 12),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
            textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.85), 
                fontSize: 10, 
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _yearEndBadge(BuildContext context, PurchaseViewModel vm) {
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
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

  Future<void> _pickYearEnd(
      BuildContext context, PurchaseViewModel vm) async {
    final initial = vm.yearEndDate ??
        DateTime(DateTime.now().year, 3, 31); // default 31 March
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
            'This removes the financial year filter. All-time totals will be shown.'.tr),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel'.tr)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Clear'.tr)),
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
          final totalVal = items.fold(0.0, (sum, item) => sum + item.totalValue);
          final totalCarat = items.fold(0.0, (sum, item) => sum + item.carats);
          final remainingActual = vm.totalRemainingCarat;
          final diff = (remainingActual - totalCarat).abs();
          final isMismatch = diff > 0.001;

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Stock Valuation'.tr,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _miniStat('Total Value'.tr, fmt.format(totalVal), _accent),
                          ),
                          Expanded(
                            child: _miniStat('Total Carats'.tr,
                                '${caratFmt.format(totalCarat)} ct', Colors.orange),
                          ),
                          Expanded(
                            child: _miniStat('Actual Remaining'.tr,
                                '${caratFmt.format(remainingActual)} ct', Colors.green),
                          ),
                        ],
                      ),
                      if (isMismatch)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Warning: Valuation carats do not match actual remaining carats.'.tr,
                            style: TextStyle(color: Colors.red[700], fontSize: 11, fontWeight: FontWeight.w500),
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
                                  size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('No valuation items added'.tr,
                                  style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final item = items[i];
                            final hasDeductions = item.discountPercent > 0 ||
                                item.brokeragePercent > 0;
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.itemName.isNotEmpty ? item.itemName : 'Unnamed Item'.tr,
                                            style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('${caratFmt.format(item.carats)} ct @ ${fmt.format(item.ratePerCarat)}/ct'.tr,
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                        if (hasDeductions)
                                          Text(
                                              '${'Disc'.tr} ${item.discountPercent.toStringAsFixed(item.discountPercent.truncateToDouble() == item.discountPercent ? 0 : 2)}% • ${'Brok'.tr} ${item.brokeragePercent.toStringAsFixed(item.brokeragePercent.truncateToDouble() == item.brokeragePercent ? 0 : 2)}% → ${fmt.format(item.effectiveRatePerCarat)}/ct',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.orange[700],
                                                  fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  Text(fmt.format(item.totalValue),
                                      style: const TextStyle(fontWeight: FontWeight.w700, color: _accent)),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () async {
                                      final updated = await _showItemDialog(context, item);
                                      if (updated != null) {
                                        setModalState(() {
                                          items[i] = updated;
                                        });
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded,
                                        size: 20, color: Colors.red[300]),
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
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final newItem = await _showItemDialog(context);
                            if (newItem != null) {
                              setModalState(() {
                                items.add(newItem);
                              });
                            }
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: Text('Add Item'.tr),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await vm.setStockValuationItems(items);
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text('Save Valuation'.tr),
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
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
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
            title: Text(existing == null ? 'Add Stock Item'.tr : 'Edit Stock Item'.tr),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                        labelText: 'Item Name (e.g. Rough, Polished)'.tr),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: caratCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
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
                              const TextInputType.numberWithOptions(decimal: true),
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
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                              labelText: 'Discount'.tr, suffixText: '%'),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: brokerageCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                              labelText: 'Brokerage'.tr, suffixText: '%'),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Effective Rate'.tr,
                                style: const TextStyle(fontSize: 12)),
                            Text('${fmt.format(effRate)}/ct'.tr,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Value'.tr,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            Text(fmt.format(totalVal),
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _accent)),
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

  /// One native ad after every [_adInterval] purchase rows.
  /// Same approach as the invoice list — see notes there.
  static const int _adInterval = 7;

  Widget _buildPurchaseListWithAds(
      BuildContext context,
      PurchaseViewModel vm,
      NumberFormat fmt,
      NumberFormat caratFmt) {
    final purchases = vm.purchases;
    final adCount = purchases.length ~/ _adInterval;
    final totalSlots = purchases.length + adCount;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: totalSlots,
      itemBuilder: (ctx, index) {
        const groupSize = _adInterval + 1;
        final positionInGroup = index % groupSize;
        if (positionInGroup == _adInterval) {
          return const NativeAdCard();
        }
        final purchaseIndex =
            (index ~/ groupSize) * _adInterval + positionInGroup;
        if (purchaseIndex >= purchases.length) {
          return const SizedBox.shrink();
        }
        return _purchaseCard(ctx, purchases[purchaseIndex], vm, fmt, caratFmt);
      },
    );
  }

  Widget _purchaseCard(BuildContext context, PurchaseModel p,
      PurchaseViewModel vm, NumberFormat fmt, NumberFormat caratFmt) {
    final dateFormat = DateFormat('dd MMM yy'.tr);
    final paid = p.isFullyPaid;
    final partial = p.totalPaidCarat > 0 && !paid;
    final statusLabel = paid ? 'Paid'.tr : partial ? 'Partial'.tr : 'Unpaid'.tr;
    final statusColor =
        paid ? Colors.green : partial ? Colors.orange : Colors.red;

    return Dismissible(
      key: Key(p.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (dir) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Confirm Delete'.tr),
            content: Text('Are you sure you want to delete this purchase? This will also remove its sale tracking data.'.tr),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel'.tr)),
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
          SnackBar(content: Text('${'Purchase from'.tr} ${p.sellerName} ${'deleted'.tr}')),
        );
      },
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PurchaseDetailView(purchase: p)),
          );
          if (context.mounted) vm.loadPurchases();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.diamond_rounded, color: _accent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.sellerName.isNotEmpty ? p.sellerName : 'Unknown Seller'.tr,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          Text(
                            '${'Broker'.tr}: ${p.brokerName.isNotEmpty ? p.brokerName : "-"}  •  ${'Size'.tr}: ${p.size.isNotEmpty ? p.size : "-"}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: statusColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12),
                          ),
                        ),
                        if (p.isForOther) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: _accent.withOpacity(0.4)),
                            ),
                            child: Text(
                              'For Other'.tr,
                              style: const TextStyle(
                                  color: _accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10),
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
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoChip('Net Amt'.tr, fmt.format(p.netAmount), Colors.orange),
                      _infoChip('Carat'.tr, '${caratFmt.format(p.totalCarat)} ct', _accent),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('${'Buy'.tr}: ${dateFormat.format(p.buyDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(width: 12),
                    Icon(Icons.payment_rounded, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('${'Pay'.tr}: ${dateFormat.format(p.paymentDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const Spacer(),
                    Icon(Icons.schedule_rounded, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('${p.dueDays}${'d due'.tr}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: color, fontSize: 12)),
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.diamond_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No purchases yet'.tr,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('Tap + to add your first purchase'.tr,
              style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _backdrop() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE7EEFF), Color(0xFFF9FBFF)],
        ),
      ),
    );
  }
}
