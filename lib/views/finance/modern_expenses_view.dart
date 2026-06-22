import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/expense_model.dart';
import '../../services/expense_storage_service.dart';
import '../../viewmodels/purchase_viewmodel.dart';
import '../../widgets/list_skeleton.dart';
import '../../constants/app_translations.dart';
import 'expense_report_view.dart';

/// Modern UI surface for the Expenses screen.
///
/// Same `PurchaseViewModel`, same opening-amount edit flow, same kind
/// picker, same add-entry form, same swipe-to-delete + statement
/// navigation. Only the visual layer is restyled.
class ModernExpensesContent extends StatefulWidget {
  const ModernExpensesContent({super.key});

  @override
  State<ModernExpensesContent> createState() => _ModernExpensesContentState();
}

class _ModernExpensesContentState extends State<ModernExpensesContent> {
  // Website tokens
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

  final _dateFmt = DateFormat('dd MMM yyyy'.tr);
  final _currencyFmt =
      NumberFormat.currency(symbol: '₹', decimalDigits: 0);
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
      backgroundColor: _bg0,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, vm),
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _buildSummaryCard(context, vm),
                _buildSearchBar(),
                Expanded(
                  child: vm.isLoading
                      ? const ListSkeleton(dark: true)
                      : _buildExpensesList(context, vm),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingAddButton(context, vm),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  // ─────────────────────────────  APP BAR  ────────────────────────────────

  PreferredSizeWidget _buildAppBar(
      BuildContext context, PurchaseViewModel vm) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1)],
        ).createShader(rect),
        child: Text(
          'Expenses'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.description_rounded, color: Colors.white),
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
            child: _glow(280, _primary.withOpacity(0.25)),
          ),
          Positioned(
            top: 240,
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

  // ─────────────────────────────  SUMMARY  ────────────────────────────────

  Widget _buildSummaryCard(
      BuildContext context, PurchaseViewModel vm) {
    final debits = vm.ledgerDebitsPaid;
    final credits = vm.ledgerCreditsPaid;
    final balance = vm.ledgerFinalAmount;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                    size: 20),
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
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_rounded,
                              color: Colors.white54, size: 10),
                        ],
                      ),
                      Text(
                        _currencyFmt
                            .format(vm.manualOpeningExpenseAmount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child:
                Container(height: 1, color: Colors.white.withOpacity(0.24)),
          ),
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  'Credits'.tr,
                  '+ ${_currencyFmt.format(credits)}',
                  Icons.north_east_rounded,
                  valueColor: const Color(0xFF34D399),
                ),
              ),
              Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withOpacity(0.24)),
              Expanded(
                child: _summaryTile(
                  'Debits'.tr,
                  '- ${_currencyFmt.format(debits)}',
                  Icons.south_west_rounded,
                  valueColor: const Color(0xFFFCA5A5),
                ),
              ),
              Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withOpacity(0.24)),
              Expanded(
                child: _summaryTile(
                  'Available'.tr,
                  _currencyFmt.format(balance),
                  balance >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  valueColor: balance >= 0
                      ? const Color(0xFF34D399)
                      : const Color(0xFFFCA5A5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.85), size: 14),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _editOpeningExpenseAmount(
      BuildContext context, PurchaseViewModel vm) async {
    final controller = TextEditingController(
        text: vm.manualOpeningExpenseAmount.toString());
    final result = await showDialog<double>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_bg1, Color(0xFF11173B), _bg1],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.22),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Opening Amount'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Enter opening expense amount.'.tr,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                cursorColor: _accent,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.10)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.10)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: _accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _outlinedBtn('Cancel'.tr, () => Navigator.pop(ctx))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _gradientBtn(
                      'Save'.tr,
                      () {
                        final v =
                            double.tryParse(controller.text.trim()) ?? 0.0;
                        Navigator.pop(ctx, v);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) {
      await vm.setManualOpeningExpenseAmount(result);
    }
  }

  // ─────────────────────────────  SEARCH BAR  ─────────────────────────────

  Widget _buildSearchBar() {
    final hasText = _searchController.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (v) =>
            setState(() => _searchQuery = v.trim().toLowerCase()),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: _accent,
        decoration: InputDecoration(
          hintText: 'Search by name, invoice no, size...'.tr,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon:
              const Icon(Icons.search_rounded, color: _accent, size: 20),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 44, minHeight: 0),
          suffixIcon: hasText
              ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      color: Colors.white.withOpacity(0.65), size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────  LIST  ───────────────────────────────────

  Widget _buildExpensesList(
      BuildContext context, PurchaseViewModel vm) {
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
      color: _accent,
      backgroundColor: _bg1,
      onRefresh: () => vm.loadPurchases(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
        itemCount: items.length,
        itemBuilder: (ctx, i) => _expenseRow(context, items[i], vm),
      ),
    );
  }

  Widget _expenseRow(BuildContext context, LedgerEntry entry,
      PurchaseViewModel vm) {
    final expenseId = entry.id.replaceFirst('expense_', '');
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFF87171)],
          ),
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
                    child: Text('Cancel'.tr),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.red),
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
    final color =
        isDebit ? const Color(0xFFF87171) : const Color(0xFF34D399);
    final gradient = isDebit
        ? const [Color(0xFFEF4444), Color(0xFFF87171)]
        : const [Color(0xFF10B981), Color(0xFF34D399)];
    final sign = isDebit ? '-' : '+';
    final icon =
        isDebit ? Icons.south_west_rounded : Icons.north_east_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(10),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.subtitle.isNotEmpty
                      ? '${entry.subtitle} • ${_dateFmt.format(entry.date)}'
                      : '${isDebit ? 'Debit'.tr : 'Credit'.tr} • ${_dateFmt.format(entry.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign ${_currencyFmt.format(entry.amount)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({bool noMatch = false}) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: _grad,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.35),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              noMatch
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_outlined,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            noMatch ? 'No matching entries'.tr : 'No entries yet'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            noMatch
                ? 'Try a different search term.'.tr
                : 'Tap "Add Entry".tr to record a Credit or Debit. Debits cannot exceed the Available Balance.'
                    .tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.55)),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────  FAB  ────────────────────────────────────

  Widget _buildFloatingAddButton(
      BuildContext context, PurchaseViewModel vm) {
    final pillWidth = MediaQuery.of(context).size.width - 32;
    return SizedBox(
      width: pillWidth,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openAddFlow(context, vm),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: _grad,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.45),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: _violet.withOpacity(0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Add Entry'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
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

  // ─────────────────────────────  ADD FLOW  ───────────────────────────────

  Future<void> _openAddFlow(
      BuildContext context, PurchaseViewModel vm) async {
    final balance = vm.ledgerFinalAmount;
    final isCredit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModernPickKindSheet(availableBalance: balance),
    );
    if (isCredit == null || !mounted) return;

    if (!isCredit && balance <= 0) {
      _showBalanceError(
          'Insufficient balance. Add a Credit entry before recording a Debit.'
              .tr);
      return;
    }

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModernAddExpenseSheet(
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

  // ─────────────────────────────  DIALOG HELPERS  ─────────────────────────

  Widget _outlinedBtn(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gradientBtn(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: _grad,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.40),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//                          PICK KIND SHEET (Credit / Debit)
// ─────────────────────────────────────────────────────────────────────────────

class _ModernPickKindSheet extends StatelessWidget {
  const _ModernPickKindSheet({required this.availableBalance});

  final double availableBalance;

  static const _bg1 = Color(0xFF0C1230);
  static const _accent = Color(0xFF38BDF8);
  static const _violet = Color(0xFFA78BFA);

  @override
  Widget build(BuildContext context) {
    final currencyFmt =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final debitDisabled = availableBalance <= 0;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bg1, Color(0xFF11173B), _bg1],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.22),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: _violet.withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 4),
            ),
          ],
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
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1)],
              ).createShader(rect),
              child: Text(
                'Choose Type'.tr,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Credits add money in. Debits can only spend what Credits have made available.'
                  .tr,
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      color: _accent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Available Balance'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    currencyFmt.format(availableBalance),
                    style: TextStyle(
                      color: availableBalance > 0
                          ? const Color(0xFF34D399)
                          : const Color(0xFFFCA5A5),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
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
                    gradient: const [
                      Color(0xFF10B981),
                      Color(0xFF34D399),
                    ],
                    accent: const Color(0xFF34D399),
                    onTap: () => Navigator.pop(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _kindTile(
                    label: 'Debit'.tr,
                    icon: Icons.south_west_rounded,
                    gradient: const [
                      Color(0xFFEF4444),
                      Color(0xFFF87171),
                    ],
                    accent: const Color(0xFFF87171),
                    disabled: debitDisabled,
                    subLabel:
                        debitDisabled ? 'Insufficient balance'.tr : null,
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
    required List<Color> gradient,
    required Color accent,
    required VoidCallback? onTap,
    bool disabled = false,
    String? subLabel,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
          decoration: BoxDecoration(
            color: accent.withOpacity(disabled ? 0.06 : 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withOpacity(disabled ? 0.20 : 0.45),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: disabled
                      ? null
                      : [
                          BoxShadow(
                            color: gradient.first.withOpacity(0.40),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: disabled ? Colors.white.withOpacity(0.55) : accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              if (subLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  subLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//                          ADD EXPENSE SHEET (Form)
// ─────────────────────────────────────────────────────────────────────────────

class _ModernAddExpenseSheet extends StatefulWidget {
  const _ModernAddExpenseSheet({
    required this.isCredit,
    required this.availableBalance,
  });

  final bool isCredit;
  final double availableBalance;

  @override
  State<_ModernAddExpenseSheet> createState() =>
      _ModernAddExpenseSheetState();
}

class _ModernAddExpenseSheetState extends State<_ModernAddExpenseSheet> {
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

  final _formKey = GlobalKey<FormState>();
  final _personCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  final _dateFmt = DateFormat('dd MMM yyyy'.tr);
  final _balanceFmt =
      NumberFormat.currency(symbol: '₹', decimalDigits: 0);

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
        ..expenseDate = _date;
      await ExpenseStorageService.saveExpense(exp);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'Failed to save'.tr}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isCredit = widget.isCredit;
    final kindColor = isCredit
        ? const Color(0xFF34D399)
        : const Color(0xFFF87171);
    final kindGradient = isCredit
        ? const [Color(0xFF10B981), Color(0xFF34D399)]
        : const [Color(0xFFEF4444), Color(0xFFF87171)];
    final kindLabel = isCredit ? 'Credit'.tr : 'Debit'.tr;
    final kindIcon = isCredit
        ? Icons.north_east_rounded
        : Icons.south_west_rounded;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_bg1, Color(0xFF11173B), _bg1],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.22),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
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
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: kindGradient,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(kindIcon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add Entry'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kindColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: kindColor.withOpacity(0.45)),
                      ),
                      child: Text(
                        kindLabel,
                        style: TextStyle(
                          color: kindColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isCredit) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: _accent,
                            size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Available Balance'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _balanceFmt.format(widget.availableBalance),
                          style: TextStyle(
                            color: widget.availableBalance > 0
                                ? const Color(0xFF34D399)
                                : const Color(0xFFFCA5A5),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _label('Person Name'.tr),
                TextFormField(
                  controller: _personCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: _accent,
                  decoration: _decoration('e.g. Ramesh, Suresh'.tr),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Required'.tr
                      : null,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: _accent,
                  decoration: _decoration('0', prefix: '₹ '),
                  validator: _validateAmount,
                ),
                const SizedBox(height: 12),
                _label('Date'.tr),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _date = d);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.10)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: _accent, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            _dateFmt.format(_date),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _saving ? null : _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: _saving ? null : _grad,
                        color: _saving
                            ? Colors.white.withOpacity(0.10)
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _saving
                            ? null
                            : [
                                BoxShadow(
                                  color: _accent.withOpacity(0.45),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_saving)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else ...[
                            const Icon(Icons.save_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _saving ? 'Saving…'.tr : 'Save'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ],
                      ),
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
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  InputDecoration _decoration(String hint, {String? prefix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.40),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixText: prefix,
        prefixStyle: const TextStyle(
          color: _accent,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        errorStyle: const TextStyle(
          color: Color(0xFFFCA5A5),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      );
}
