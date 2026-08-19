import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/expense_model.dart';
import '../../services/expense_storage_service.dart';
import '../../viewmodels/purchase_viewmodel.dart';
import '../../widgets/app_bar_factory.dart';

import '../../widgets/list_skeleton.dart';
import 'expense_report_view.dart';
import '../../constants/app_translations.dart';


import 'package:invoice_generator/constants/app_translations.dart';

class ExpensesView extends StatelessWidget {
  const ExpensesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PurchaseViewModel()..loadPurchases(),
      child: const _ExpensesContent(),
    );
  }
}

class _ExpensesContent extends StatefulWidget {
  const _ExpensesContent();

  @override
  State<_ExpensesContent> createState() => _ExpensesContentState();
}

class _ExpensesContentState extends State<_ExpensesContent> {
  static const _accent = Color(0xFF4F8AF4);
  static const _deep = Color(0xFF1E3C72);

  final _dateFmt = DateFormat('dd MMM yyyy'.tr);
  final _currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PurchaseViewModel>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBarFactory.build(
        title: 'Roj mel'.tr,
        onBackPress: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_rounded),
            tooltip: 'Statement'.tr,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ExpenseReportView()),
              );
              if (mounted) vm.loadPurchases();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _backdrop(),
          SafeArea(
            child: Column(
              children: [
                _summaryBar(context, vm),
                _searchBar(),
                Expanded(
                  child: vm.isLoading
                      ? const ListSkeleton()
                      : _expensesList(context, vm),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddFlow(context, vm),
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Entry'.tr),
        backgroundColor: _accent,
      ),

    );
  }

  Widget _summaryBar(BuildContext context, PurchaseViewModel vm) {
    final debits = vm.ledgerDebitsPaid;
    final credits = vm.ledgerCreditsPaid;
    final balance = vm.ledgerFinalAmount;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_deep, _accent]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _editOpeningExpenseAmount(context, vm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Opening Amount'.tr,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          SizedBox(width: 4),
                          Icon(Icons.edit_rounded,
                              color: Colors.white54, size: 10),
                        ],
                      ),
                      Text(_currencyFmt.format(vm.manualOpeningExpenseAmount),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white24, height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: _summaryTile('Credits'.tr,
                    '+ ${_currencyFmt.format(credits)}',
                    Icons.north_east_rounded,
                    valueColor: Colors.greenAccent),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: _summaryTile('Debits'.tr,
                    '- ${_currencyFmt.format(debits)}',
                    Icons.south_west_rounded,
                    valueColor: Colors.redAccent),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: _summaryTile('Available'.tr,
                    _currencyFmt.format(balance),
                    balance >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    valueColor:
                        balance >= 0 ? Colors.greenAccent : Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editOpeningExpenseAmount(
      BuildContext context, PurchaseViewModel vm) async {
    final controller =
        TextEditingController(text: vm.manualOpeningExpenseAmount.toString());
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Opening Amount'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter opening expense amount.'.tr,
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel'.tr)),
          TextButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim()) ?? 0.0;
              Navigator.pop(ctx, v);
            },
            child: Text('Save'.tr),
          ),
        ],
      ),
    );
    if (result != null) {
      await vm.setManualOpeningExpenseAmount(result);
    }
  }

  Widget _summaryTile(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14)),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search by name, invoice no, size...'.tr,
          prefixIcon: const Icon(Icons.search_rounded, color: _accent),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
      ),
    );
  }

  Widget _expensesList(BuildContext context, PurchaseViewModel vm) {
    final all = vm.ledgerEntries;
    final items = _searchQuery.isEmpty
        ? all
        : all.where((e) {
            final q = _searchQuery;
            return e.title.toLowerCase().contains(q) ||
                e.subtitle.toLowerCase().contains(q);
          }).toList();
    if (items.isEmpty) {
      return _emptyState(noMatch: _searchQuery.isNotEmpty);
    }

    return RefreshIndicator(
      onRefresh: () => vm.loadPurchases(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: items.length,
        itemBuilder: (ctx, i) => _expenseRow(context, items[i], vm),
      ),
    );
  }

  Widget _expenseRow(
      BuildContext context, LedgerEntry entry, PurchaseViewModel vm) {
    final expenseId = entry.id.replaceFirst('expense_', '');
    return Dismissible(
      key: Key(entry.id),
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
                title: Text('Delete Entry'.tr),
                content: Text('Remove this entry?'.tr),
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
        await vm.deleteExpense(expenseId);
      },
      child: _entryCard(entry),
    );
  }

  Widget _entryCard(LedgerEntry entry) {
    final isDebit = entry.isDebit;
    final accent = isDebit ? Colors.red : Colors.green;
    final sign = isDebit ? '-' : '+';
    final icon = isDebit ? Icons.south_west_rounded : Icons.north_east_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: _deep)),
                    ),
                    if (entry.isBusinessExpense) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.deepOrange.withOpacity(0.4)),
                        ),
                        child: Text('Expense'.tr,
                            style: const TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.w700,
                                fontSize: 9)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.subtitle.isNotEmpty
                      ? '${entry.subtitle} • ${_dateFmt.format(entry.date)}'
                      : '${isDebit ? 'Debit'.tr : 'Credit'.tr} • ${_dateFmt.format(entry.date)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('$sign ${_currencyFmt.format(entry.amount)}'.tr,
              style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
        ],
      ),
    );
  }

  Widget _emptyState({bool noMatch = false}) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(
          noMatch
              ? Icons.search_off_rounded
              : Icons.receipt_long_outlined,
          size: 64,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(noMatch ? 'No matching entries'.tr : 'No entries yet'.tr,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
              noMatch
                  ? 'Try a different search term.'.tr
                  : 'Tap "Add Entry".tr to record a Credit or Debit. Debits cannot exceed the Available Balance.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500])),
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

  Future<void> _openAddFlow(
      BuildContext context, PurchaseViewModel vm) async {
    final balance = vm.ledgerFinalAmount;
    final isCredit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickKindSheet(availableBalance: balance),
    );
    if (isCredit == null || !mounted) return;

    if (!isCredit && balance <= 0) {
      _showBalanceError(
          'Insufficient balance. Add a Credit entry before recording a Debit.'.tr);
      return;
    }

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddExpenseSheet(
        isCredit: isCredit,
        availableBalance: balance,
      ),
    );
    if (added == true) {
      await vm.loadPurchases();
    }
  }

  void _showBalanceError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _PickKindSheet extends StatelessWidget {
  const _PickKindSheet({required this.availableBalance});

  final double availableBalance;

  static const _deep = Color(0xFF1E3C72);

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final debitDisabled = availableBalance <= 0;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Choose Type'.tr,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _deep)),
            const SizedBox(height: 4),
            Text(
                'Credits add money in. Debits can only spend what Credits have made available.'.tr,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      color: _deep, size: 18),
                  const SizedBox(width: 8),
                  Text('Available Balance'.tr,
                      style: const TextStyle(
                          color: _deep,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(currencyFmt.format(availableBalance),
                      style: TextStyle(
                          color: availableBalance > 0
                              ? Colors.green.shade700
                              : Colors.red,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _kindTile(
                    label: 'Credit'.tr,
                    icon: Icons.north_east_rounded,
                    color: Colors.green,
                    onTap: () => Navigator.pop(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _kindTile(
                    label: 'Debit'.tr,
                    icon: Icons.south_west_rounded,
                    color: Colors.red,
                    disabled: debitDisabled,
                    subLabel: debitDisabled ? 'Insufficient balance'.tr : null,
                    onTap: debitDisabled
                        ? null
                        : () => Navigator.pop(context, false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kindTile({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    bool disabled = false,
    String? subLabel,
  }) {
    final effectiveColor = disabled ? Colors.grey : color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
        decoration: BoxDecoration(
          color: effectiveColor.withOpacity(disabled ? 0.06 : 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: effectiveColor.withOpacity(0.4), width: 1.2),
        ),
        child: Column(
          children: [
            Icon(icon, color: effectiveColor, size: 30),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: effectiveColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            if (subLabel != null) ...[
              const SizedBox(height: 4),
              Text(subLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: effectiveColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10)),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet({
    required this.isCredit,
    required this.availableBalance,
  });

  final bool isCredit;
  final double availableBalance;

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  static const _accent = Color(0xFF4F8AF4);
  static const _deep = Color(0xFF1E3C72);

  final _formKey = GlobalKey<FormState>();
  final _personCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;
  /// Debits only: true when the user tags this row as a business expense.
  bool _isBusinessExpense = false;

  final _dateFmt = DateFormat('dd MMM yyyy'.tr);
  final _balanceFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  void dispose() {
    _personCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  String? _validateAmount(String? raw) {
    final n = double.tryParse(raw?.trim() ?? '');
    if (n == null || n <= 0) return 'Enter valid amount'.tr;
    if (!widget.isCredit && n > widget.availableBalance) {
      return '${'Exceeds available balance'.tr} (${_balanceFmt.format(widget.availableBalance)})';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    if (!widget.isCredit && amount > widget.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${'Insufficient balance. Available'.tr}: ${_balanceFmt.format(widget.availableBalance)}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final exp = ExpenseModel()
        ..personName = _personCtrl.text.trim()
        ..amount = amount
        ..isCredit = widget.isCredit
        ..isBusinessExpense = !widget.isCredit && _isBusinessExpense
        ..expenseDate = _date;
      await ExpenseStorageService.saveExpense(exp);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${'Failed to save'.tr}: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final kindColor = widget.isCredit ? Colors.green : Colors.red;
    final kindLabel = widget.isCredit ? 'Credit'.tr : 'Debit'.tr;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Add Entry'.tr,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _deep)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kindColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kindColor.withOpacity(0.4)),
                      ),
                      child: Text(kindLabel,
                          style: TextStyle(
                              color: kindColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11)),
                    ),
                  ],
                ),
                if (!widget.isCredit) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined,
                            color: _deep, size: 18),
                        const SizedBox(width: 8),
                        Text('Available Balance'.tr,
                            style: const TextStyle(
                                color: _deep,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(_balanceFmt.format(widget.availableBalance),
                            style: TextStyle(
                                color: widget.availableBalance > 0
                                    ? Colors.green.shade700
                                    : Colors.red,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _label('Debit Type'.tr),
                  Row(
                    children: [
                      Expanded(
                        child: _debitTypeTile(
                          label: 'Normal Debit'.tr,
                          helper: 'Day-book only'.tr,
                          icon: Icons.receipt_long_rounded,
                          color: _deep,
                          selected: !_isBusinessExpense,
                          onTap: () =>
                              setState(() => _isBusinessExpense = false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _debitTypeTile(
                          label: 'Expense'.tr,
                          helper: 'Reduces Net Profit'.tr,
                          icon: Icons.trending_down_rounded,
                          color: Colors.deepOrange,
                          selected: _isBusinessExpense,
                          onTap: () =>
                              setState(() => _isBusinessExpense = true),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                _label('Person Name'.tr),
                TextFormField(
                  controller: _personCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('e.g. Ramesh, Suresh'.tr),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required'.tr : null,
                ),
                const SizedBox(height: 12),
                _label('Amount'.tr),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: _decoration('0', prefix: '₹ '),
                  validator: _validateAmount,
                ),
                const SizedBox(height: 12),
                _label('Date'.tr),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: _accent, size: 18),
                        const SizedBox(width: 10),
                        Text(_dateFmt.format(_date),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _deep)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded),
                    label: Text(_saving ? 'Saving…'.tr : 'Save'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                color: _deep, fontSize: 13, fontWeight: FontWeight.w700)),
      );

  Widget _debitTypeTile({
    required String label,
    required String helper,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.10) : const Color(0xFFF4F7FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color.withOpacity(0.6) : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 18,
                    color: selected ? color : Colors.grey.shade500),
                const Spacer(),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: selected ? color : Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: selected ? color : _deep,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(helper,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint, {String? prefix}) =>
      InputDecoration(
        hintText: hint,
        prefixText: prefix,
        filled: true,
        fillColor: const Color(0xFFF4F7FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}
