import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/withdrawal_model.dart';
import '../../services/withdrawal_storage_service.dart';
import '../../widgets/app_bar_factory.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/list_skeleton.dart';

class WithdrawalsView extends StatefulWidget {
  const WithdrawalsView({super.key});

  @override
  State<WithdrawalsView> createState() => _WithdrawalsViewState();
}

class _WithdrawalsViewState extends State<WithdrawalsView> {
  static const _accent = Color(0xFF4F8AF4);
  static const _deep = Color(0xFF1E3C72);

  List<WithdrawalModel> _items = [];
  bool _loading = true;

  final _dateFmt = DateFormat('dd MMM yyyy');
  final _currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await WithdrawalStorageService.getAllWithdrawals();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  List<WithdrawalModel> get _active =>
      _items.where((w) => !w.isReturned).toList();
  List<WithdrawalModel> get _returned =>
      _items.where((w) => w.isReturned).toList();

  double get _outstanding =>
      _active.fold(0.0, (sum, w) => sum + w.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBarFactory.build(
        title: 'Pre-mature Withdrawals',
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
                      : (_items.isEmpty
                          ? _emptyState()
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 8, 16, 100),
                                children: [
                                  if (_active.isNotEmpty) ...[
                                    _sectionTitle('Outstanding'),
                                    ..._active.map(_row),
                                  ],
                                  if (_returned.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _sectionTitle('Returned'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Withdrawal'),
        backgroundColor: _accent,
      ),
      bottomNavigationBar: const BottomBannerAd(),
    );
  }

  Widget _totalCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_deep, _accent]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Outstanding',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('Out until marked returned',
                    style: TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          Text(
            '- ${_currencyFmt.format(_outstanding)}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
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
                title: const Text('Delete Withdrawal'),
                content: const Text('Remove this withdrawal entry?'),
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
                              : 'Unknown',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: _deep)),
                      const SizedBox(height: 2),
                      Text(
                        'Taken ${_dateFmt.format(w.takenDate)} · Return ${_dateFmt.format(w.returnDate)}',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text('- ${_currencyFmt.format(w.amount)}',
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
                  label: const Text('Mark Returned'),
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
                      ? 'Returned on ${_dateFmt.format(w.returnedAt!)}'
                      : 'Returned',
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
        Icon(Icons.account_balance_wallet_outlined,
            size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Center(
          child: Text('No withdrawals yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('Tap Add Withdrawal to record a pre-mature payout',
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

  Future<void> _openAddSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddWithdrawalSheet(),
    );
    if (added == true) {
      await _load();
    }
  }
}

class _AddWithdrawalSheet extends StatefulWidget {
  const _AddWithdrawalSheet();

  @override
  State<_AddWithdrawalSheet> createState() => _AddWithdrawalSheetState();
}

class _AddWithdrawalSheetState extends State<_AddWithdrawalSheet> {
  static const _accent = Color(0xFF4F8AF4);
  static const _deep = Color(0xFF1E3C72);

  final _formKey = GlobalKey<FormState>();
  final _personCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _taken = DateTime.now();
  DateTime _return = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;

  final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  void dispose() {
    _personCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final w = WithdrawalModel()
        ..personName = _personCtrl.text.trim()
        ..amount = double.tryParse(_amountCtrl.text.trim()) ?? 0
        ..takenDate = _taken
        ..returnDate = _return;
      await WithdrawalStorageService.saveWithdrawal(w);
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
                const Text('Pre-mature Withdrawal',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _deep)),
                const SizedBox(height: 4),
                Text(
                    'Deducted from Net Profit until you mark it returned.',
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 16),
                _label('Person Name'),
                TextFormField(
                  controller: _personCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('e.g. Rohan'),
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
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0) return 'Enter valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Taken Date'),
                          _datePicker(_taken, (d) => setState(() {
                                _taken = d;
                                if (_return.isBefore(_taken)) _return = _taken;
                              })),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Return Date'),
                          _datePicker(_return, (d) => setState(() => _return = d),
                              firstDate: _taken),
                        ],
                      ),
                    ),
                  ],
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

  Widget _datePicker(DateTime value, void Function(DateTime) onPick,
      {DateTime? firstDate}) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: firstDate ?? DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (d != null) onPick(d);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: _accent, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_dateFmt.format(value),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _deep),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
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

  InputDecoration _decoration(String hint, {String? prefix}) => InputDecoration(
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
