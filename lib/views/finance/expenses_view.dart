import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/expense_model.dart';
import '../../services/expense_storage_service.dart';
import '../../viewmodels/purchase_viewmodel.dart';
import '../../widgets/app_bar_factory.dart';
import 'expense_report_view.dart';

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

  final _dateFmt = DateFormat('dd MMM yyyy');
  final _currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PurchaseViewModel>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBarFactory.build(
        title: 'Expenses',
        onBackPress: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_rounded),
            tooltip: 'Statement',
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
                Expanded(
                  child: vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
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
        label: const Text('Add Entry'),
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
                        children: const [
                          Text('Opening Amount',
                              style: TextStyle(
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
                child: _summaryTile('Credits',
                    '+ ${_currencyFmt.format(credits)}',
                    Icons.north_east_rounded,
                    valueColor: Colors.greenAccent),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: _summaryTile('Debits',
                    '- ${_currencyFmt.format(debits)}',
                    Icons.south_west_rounded,
                    valueColor: Colors.redAccent),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: _summaryTile('Available',
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
        title: const Text('Opening Amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter opening expense amount.',
                style: TextStyle(fontSize: 12)),
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

  Widget _expensesList(BuildContext context, PurchaseViewModel vm) {
    final items = vm.ledgerEntries;
    if (items.isEmpty) return _emptyState();

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
                title: const Text('Delete Entry'),
                content: const Text('Remove this entry?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
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
                Text(entry.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _deep)),
                const SizedBox(height: 2),
                Text(
                  '${isDebit ? 'Debit' : 'Credit'} • ${_dateFmt.format(entry.date)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('$sign ${_currencyFmt.format(entry.amount)}',
              style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Center(
          child: Text('No entries yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
              'Tap "Add Entry" to record a Credit or Debit. Debits cannot exceed the Available Balance.',
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
          'Insufficient balance. Add a Credit entry before recording a Debit.');
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
            const Text('Choose Type',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _deep)),
            const SizedBox(height: 4),
            Text(
                'Credits add money in. Debits can only spend what Credits have made available.',
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
                  const Text('Available Balance',
                      style: TextStyle(
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
                    label: 'Credit',
                    icon: Icons.north_east_rounded,
                    color: Colors.green,
                    onTap: () => Navigator.pop(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _kindTile(
                    label: 'Debit',
                    icon: Icons.south_west_rounded,
                    color: Colors.red,
                    disabled: debitDisabled,
                    subLabel: debitDisabled ? 'Insufficient balance' : null,
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

  final _dateFmt = DateFormat('dd MMM yyyy');
  final _balanceFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  void dispose() {
    _personCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  String? _validateAmount(String? raw) {
    final n = double.tryParse(raw?.trim() ?? '');
    if (n == null || n <= 0) return 'Enter valid amount';
    if (!widget.isCredit && n > widget.availableBalance) {
      return 'Exceeds available balance (${_balanceFmt.format(widget.availableBalance)})';
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
              'Insufficient balance. Available: ${_balanceFmt.format(widget.availableBalance)}'),
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
        ..expenseDate = _date;
      await ExpenseStorageService.saveExpense(exp);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to save: $e'),
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
    final kindLabel = widget.isCredit ? 'Credit' : 'Debit';
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
                    const Text('Add Entry',
                        style: TextStyle(
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
                        const Text('Available Balance',
                            style: TextStyle(
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
                ],
                const SizedBox(height: 16),
                _label('Person Name'),
                TextFormField(
                  controller: _personCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('e.g. Ramesh, Suresh'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _label('Amount'),
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
                _label('Date'),
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
                    label: Text(_saving ? 'Saving…' : 'Save'),
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
