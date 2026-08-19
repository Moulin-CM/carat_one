import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/withdrawal_model.dart';
import '../../models/expense_model.dart';
import '../../services/withdrawal_storage_service.dart';
import '../../services/expense_storage_service.dart';
import '../../widgets/app_bar_factory.dart';

import '../../widgets/list_skeleton.dart';
import '../../constants/app_translations.dart';


import 'package:invoice_generator/constants/app_translations.dart';

class WithdrawalsView extends StatefulWidget {
  const WithdrawalsView({super.key});

  @override
  State<WithdrawalsView> createState() => _WithdrawalsViewState();
}

class _WithdrawalsViewState extends State<WithdrawalsView> {
  static const _accent = Color(0xFF4F8AF4);
  static const _deep = Color(0xFF1E3C72);

  List<WithdrawalModel> _items = [];
  /// Roj mel debits tagged as business expenses. Mirrored here read-only —
  /// they are created, edited and deleted on the Roj mel screen.
  List<ExpenseModel> _businessExpenses = [];
  bool _loading = true;

  final _dateFmt = DateFormat('dd MMM yyyy'.tr);
  final _currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      WithdrawalStorageService.getAllWithdrawals(),
      ExpenseStorageService.getAllExpenses(),
    ]);
    if (!mounted) return;
    final expenses = (results[1] as List<ExpenseModel>)
        .where((e) => !e.isCredit && e.isBusinessExpense)
        .toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    setState(() {
      _items = results[0] as List<WithdrawalModel>;
      _businessExpenses = expenses;
      _loading = false;
    });
  }

  List<WithdrawalModel> get _active =>
      _items.where((w) => !w.isReturned).toList();
  List<WithdrawalModel> get _returned =>
      _items.where((w) => w.isReturned).toList();

  double get _outstanding =>
      _active.fold(0.0, (sum, w) => sum + w.amount);

  double get _businessExpenseTotal =>
      _businessExpenses.fold(0.0, (sum, e) => sum + e.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBarFactory.build(
        title: 'Expenses'.tr,
        onBackPress: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          _backdrop(),
          SafeArea(
            child: Column(
              children: [
                _totalCard(),
                Expanded(
                  child: _loading
                      ? const ListSkeleton()
                      : (_items.isEmpty && _businessExpenses.isEmpty
                          ? _emptyState()
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 8, 16, 24),
                                children: [
                                  if (_businessExpenses.isNotEmpty) ...[
                                    _sectionTitle('Business Expenses'.tr),
                                    ..._businessExpenses.map(_expenseRow),
                                  ],
                                  if (_active.isNotEmpty) ...[
                                    if (_businessExpenses.isNotEmpty)
                                      const SizedBox(height: 12),
                                    _sectionTitle('Outstanding'.tr),
                                    ..._active.map(_row),
                                  ],
                                  if (_returned.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _sectionTitle('Returned'.tr),
                                    ..._returned.map(_row),
                                  ],
                                ],
                              ),
                            )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalCard() {
    final hasWithdrawals = _outstanding > 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_deep, _accent]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cardRow(
            icon: Icons.trending_down_rounded,
            label: 'Total Expenses'.tr,
            helper: hasWithdrawals
                ? 'Tagged Debits + outstanding withdrawals'.tr
                : 'Tagged Debits from Roj mel'.tr,
            amount: _businessExpenseTotal + _outstanding,
          ),
          // Withdrawals can no longer be created, but historical entries still
          // count toward the total — broken out so the figure reconciles.
          if (hasWithdrawals) ...[
            const SizedBox(height: 10),
            Divider(color: Colors.white.withOpacity(0.25), height: 1),
            const SizedBox(height: 10),
            _cardRow(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Withdrawals Outstanding'.tr,
              helper: 'Out until marked returned'.tr,
              amount: _outstanding,
              dense: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _cardRow({
    required IconData icon,
    required String label,
    required String helper,
    required double amount,
    bool dense = false,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(dense ? 8 : 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: dense ? 18 : 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white70, fontSize: dense ? 11 : 12)),
              Text(helper,
                  style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('- ${_currencyFmt.format(amount)}',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: dense ? 15 : 18)),
        ),
      ],
    );
  }

  /// Read-only mirror of a Roj mel debit tagged as a business expense.
  /// Editing and deleting stay on the Roj mel screen so there is one source
  /// of truth for the day book.
  Widget _expenseRow(ExpenseModel e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.trending_down_rounded,
                color: Colors.deepOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.personName.isNotEmpty ? e.personName : 'Expense'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _deep)),
                const SizedBox(height: 2),
                Text(
                  '${'Roj mel'.tr} · ${_dateFmt.format(e.expenseDate)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          Text('- ${_currencyFmt.format(e.amount)}',
              style: const TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
            color: _deep, fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _row(WithdrawalModel w) {
    final returned = w.isReturned;
    final accentColor = returned ? Colors.green : Colors.orange;
    return Dismissible(
      key: Key(w.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Delete Withdrawal'.tr),
                content: Text('Remove this withdrawal entry?'.tr),
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
            ) ??
            false;
      },
      onDismissed: (_) async {
        await WithdrawalStorageService.deleteWithdrawal(w.id);
        await _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    returned
                        ? Icons.check_circle_rounded
                        : Icons.schedule_rounded,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          w.personName.isNotEmpty
                              ? w.personName
                              : 'Unknown'.tr,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: _deep)),
                      const SizedBox(height: 2),
                      Text(
                        '${'Taken'.tr} ${_dateFmt.format(w.takenDate)} · ${'Return'.tr} ${_dateFmt.format(w.returnDate)}',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text('- ${_currencyFmt.format(w.amount)}'.tr,
                    style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ],
            ),
            const SizedBox(height: 10),
            if (!returned)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await WithdrawalStorageService.markReturned(w.id);
                    await _load();
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded,
                      size: 18),
                  label: Text('Mark Returned'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  w.returnedAt != null
                      ? '${'Returned on'.tr} ${_dateFmt.format(w.returnedAt!)}'
                      : 'Returned'.tr,
                  style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.trending_down_rounded,
            size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Center(
          child: Text('No expenses yet'.tr,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
                'Open Roj mel, add a Debit and tag it as Expense to see it here'
                    .tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500])),
          ),
        ),
      ],
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
