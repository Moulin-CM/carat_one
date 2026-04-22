import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/purchase_model.dart';
import '../../viewmodels/purchase_viewmodel.dart';
import '../finance/expenses_view.dart';
import '../finance/withdrawals_view.dart';
import '../finance/buy_sell_report_view.dart';
import 'purchase_form_view.dart';
import 'purchase_detail_view.dart';

class PurchaseListView extends StatelessWidget {
  const PurchaseListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PurchaseViewModel()..loadPurchases(),
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
    final grossProfit = vm.totalProfitOrLoss;
    final expenses = vm.totalExpenses;
    final outstanding = vm.outstandingWithdrawals;
    final net = vm.netProfitOrLoss;
    final netColor = net >= 0 ? Colors.green : Colors.red;

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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _editOpeningCarat(context, vm),
                              borderRadius: BorderRadius.circular(12),
                              child: _summaryTile('Opening Carats',
                                  '${caratFmt.format(vm.openingTotalCarat)} ct', Icons.diamond_rounded,
                                  editable: true),
                            ),
                          ),
                          Container(width: 1, height: 30, color: Colors.white24),
                          Expanded(
                            child: InkWell(
                              onTap: () => _editOpeningAmount(context, vm),
                              borderRadius: BorderRadius.circular(12),
                              child: _summaryTile('Opening Amount',
                                  fmt.format(vm.openingTotalAmount), Icons.currency_rupee_rounded,
                                  editable: true),
                            ),
                          ),
                          Container(width: 1, height: 30, color: Colors.white24),
                          Expanded(
                            child: _summaryTile('Remaining',
                                '${caratFmt.format(vm.totalRemainingCarat)} ct',
                                Icons.balance_rounded),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                        child: Divider(color: Colors.white24, height: 12),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _summaryTile('Sales Profit',
                                (grossProfit >= 0 ? '+' : '') + fmt.format(grossProfit),
                                grossProfit >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded),
                          ),
                          Container(width: 1, height: 30, color: Colors.white24),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ExpensesView()),
                                );
                                if (context.mounted) {
                                  context.read<PurchaseViewModel>().loadPurchases();
                                }
                              },
                              child: _summaryTile('Expenses',
                                  '- ${fmt.format(expenses)}', Icons.receipt_rounded),
                            ),
                          ),
                          Container(width: 1, height: 30, color: Colors.white24),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const WithdrawalsView()),
                                );
                                if (context.mounted) {
                                  context.read<PurchaseViewModel>().loadPurchases();
                                }
                              },
                              child: _summaryTile('Withdrawals',
                                  '- ${fmt.format(outstanding)}', Icons.account_balance_wallet_rounded),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                        child: Divider(color: Colors.white24, height: 12),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            net >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                            color: net >= 0 ? Colors.greenAccent : Colors.redAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            net >= 0 ? 'Net Profit: ' : 'Net Loss: ',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            (net >= 0 ? '+' : '') + fmt.format(net),
                            style: TextStyle(
                              color: netColor == Colors.green ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
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
                      label: const Text('Buy / Sell Report'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _accent,
                        side: const BorderSide(color: _accent),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => context.read<PurchaseViewModel>().setSearchQuery(v),
                    decoration: InputDecoration(
                      hintText: 'Search by seller, broker, size…',
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
                      ? const Center(child: CircularProgressIndicator())
                      : vm.isEmpty
                          ? _emptyState()
                          : RefreshIndicator(
                              onRefresh: () => context.read<PurchaseViewModel>().loadPurchases(),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                                itemCount: vm.purchases.length,
                                itemBuilder: (ctx, i) =>
                                    _purchaseCard(ctx, vm.purchases[i], vm, fmt, caratFmt),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PurchaseFormView()),
          );
          if (result == true && context.mounted) {
            context.read<PurchaseViewModel>().loadPurchases();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Purchase'),
        backgroundColor: _accent,
      ),
    );
  }

  Widget _summaryTile(String label, String value, IconData icon,
      {bool editable = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            if (editable) ...[
              const SizedBox(width: 3),
              const Icon(Icons.edit_rounded, color: Colors.white54, size: 11),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
            textAlign: TextAlign.center),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 9),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _yearEndBadge(BuildContext context, PurchaseViewModel vm) {
    final end = vm.yearEndDate;
    final label = end == null
        ? 'Set Year End'
        : 'FY End: ${DateFormat('dd MMM yyyy').format(end)}';
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
      helpText: 'Select Financial Year End',
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
        title: const Text('Clear Year End?'),
        content: const Text(
            'This removes the financial year filter. All-time totals will be shown.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear')),
        ],
      ),
    );
    if (confirm == true) {
      await vm.setYearEndDate(null);
    }
  }

  Future<void> _editOpeningCarat(
      BuildContext context, PurchaseViewModel vm) async {
    final controller =
        TextEditingController(text: vm.manualOpeningCarat.toString());
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Opening Carats'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Enter a carry-forward carat value. This is added to the carats purchased inside the current financial year.',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Carry-forward carats',
                suffixText: 'ct',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim()) ?? 0.0;
              Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      await vm.setManualOpeningCarat(result);
    }
  }

  Future<void> _editOpeningAmount(
      BuildContext context, PurchaseViewModel vm) async {
    final controller =
        TextEditingController(text: vm.manualOpeningAmount.toString());
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Opening Amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Enter a carry-forward amount. This is added to the amount purchased inside the current financial year.',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Carry-forward amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim()) ?? 0.0;
              Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      await vm.setManualOpeningAmount(result);
    }
  }

  Widget _purchaseCard(BuildContext context, PurchaseModel p,
      PurchaseViewModel vm, NumberFormat fmt, NumberFormat caratFmt) {
    final dateFormat = DateFormat('dd MMM yy');
    final paid = p.isFullyPaid;
    final partial = p.totalPaidCarat > 0 && !paid;
    final statusLabel = paid ? 'Paid' : partial ? 'Partial' : 'Unpaid';
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
            title: const Text('Confirm Delete'),
            content: const Text('Are you sure you want to delete this purchase? This will also remove its sale tracking data.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (dir) {
        vm.deletePurchase(p.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase from ${p.sellerName} deleted')),
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
                            p.sellerName.isNotEmpty ? p.sellerName : 'Unknown Seller',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          Text(
                            'Broker: ${p.brokerName.isNotEmpty ? p.brokerName : "-"}  •  Size: ${p.size.isNotEmpty ? p.size : "-"}',
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
                            child: const Text(
                              'For Other',
                              style: TextStyle(
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
                      _infoChip('Net Amt', fmt.format(p.netAmount), Colors.orange),
                      _infoChip('Carat', '${caratFmt.format(p.totalCarat)} ct', _accent),
                      _infoChip('Remaining',
                          '${caratFmt.format(p.remainingCarat)} ct',
                          p.remainingCarat > 0 ? Colors.green : Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('Buy: ${dateFormat.format(p.buyDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(width: 12),
                    Icon(Icons.payment_rounded, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('Pay: ${dateFormat.format(p.paymentDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const Spacer(),
                    Icon(Icons.schedule_rounded, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('${p.dueDays}d due',
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
                fontWeight: FontWeight.w700, color: color, fontSize: 13)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
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
          Text('No purchases yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('Tap + to add your first purchase',
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
