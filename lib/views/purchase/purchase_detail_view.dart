import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/purchase_model.dart';
import '../../services/purchase_storage_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_section.dart';
import '../../widgets/custom_info_row.dart';
import '../../widgets/app_bar_factory.dart';
import 'purchase_form_view.dart';

class PurchaseDetailView extends StatefulWidget {
  final PurchaseModel purchase;
  const PurchaseDetailView({super.key, required this.purchase});

  @override
  State<PurchaseDetailView> createState() => _PurchaseDetailViewState();
}

class _PurchaseDetailViewState extends State<PurchaseDetailView> {
  late PurchaseModel _purchase;
  static const _accent = Color(0xFF4F8AF4);
  static const _deep = Color(0xFF1E3C72);
  final _currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  final _dateFmt = DateFormat('dd MMM yyyy');
  final _caratFmt = NumberFormat('#,##0.00');
  // Payment-to-seller tracking
  final _paymentAmountController = TextEditingController();
  final _paymentFormKey = GlobalKey<FormState>();
  String _paidThroughMode = 'cash';
  bool _savingPayment = false;

  @override
  void initState() {
    super.initState();
    _purchase = widget.purchase;
  }

  @override
  void dispose() {
    _paymentAmountController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final fresh = await PurchaseStorageService.getPurchaseById(_purchase.id);
    if (fresh != null && mounted) {
      setState(() {
        _purchase = fresh;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBarFactory.build(
        title: 'Purchase Details',
        onBackPress: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PurchaseFormView(purchase: _purchase)),
              );
              if (result == true) _reload();
            },
            tooltip: 'Edit',
          ),
        ],
      ),
      body: Stack(
        children: [
          _backdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerCard(),
                  const SizedBox(height: 16),
                  _detailsSection(),
                  const SizedBox(height: 16),
                  _financialSection(),
                  const SizedBox(height: 16),
                  _paymentSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return CustomCard(
      padding: const EdgeInsets.all(18),
      gradient: const LinearGradient(
        colors: [_deep, _accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _purchase.sellerName.isNotEmpty ? _purchase.sellerName : 'Unknown Seller',
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          if (_purchase.brokerName.isNotEmpty)
            Text('Broker: ${_purchase.brokerName}',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _whiteChip('Size', _purchase.size.isNotEmpty ? _purchase.size : '-'),
              _whiteChip('Buy Date', _dateFmt.format(_purchase.buyDate)),
              _whiteChip('Pay Date', _dateFmt.format(_purchase.paymentDate)),
              _whiteChip('Due Days', '${_purchase.dueDays}d'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _whiteChip(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _detailsSection() {
    return CustomSection(
      title: 'Party & Dates',
      icon: Icons.people_rounded,
      children: [
        CustomInfoRow(label: 'Seller', value: _purchase.sellerName),
        CustomInfoRow(label: 'Broker', value: _purchase.brokerName.isNotEmpty ? _purchase.brokerName : '-'),
        CustomInfoRow(label: 'Size', value: _purchase.size.isNotEmpty ? _purchase.size : '-'),
        CustomInfoRow(label: 'Buy Date', value: _dateFmt.format(_purchase.buyDate)),
        CustomInfoRow(label: 'Payment Date', value: _dateFmt.format(_purchase.paymentDate)),
        CustomInfoRow(label: 'Due Days', value: '${_purchase.dueDays} days'),
      ],
    );
  }

  Widget _financialSection() {
    return CustomSection(
      title: 'Financial Summary',
      icon: Icons.attach_money_rounded,
      children: [
        CustomInfoRow(label: 'Total Amount', value: _currencyFmt.format(_purchase.grossAmount)),
        CustomInfoRow(label: 'Discount Amt', value: _currencyFmt.format(_purchase.discountValue)),
        CustomInfoRow(label: 'Net Amount', value: _currencyFmt.format(_purchase.netAmount), isBold: true, valueColor: _deep),
        CustomInfoRow(label: 'Total Carat', value: '${_caratFmt.format(_purchase.totalCarat)} ct'),
        CustomInfoRow(label: 'Rate per Carat', value: _currencyFmt.format(_purchase.amountPerCarat)),
        CustomInfoRow(label: 'Discount (%)', value: '${_purchase.discount}%'),
      ],
    );
  }

  // ──────────── Payment-to-seller section (like invoice's payment UI) ────────────

  Widget _paymentSection() {
    final remaining = _purchase.remainingPaymentCarat;
    final rate = _purchase.effectivePurchaseRate;
    final remainingAmount = remaining * rate;
    final fullyPaid = _purchase.isFullyPaid;

    return CustomSection(
      title: 'Payment',
      icon: Icons.payments_rounded,
      children: [
        _paidRow(
          icon: Icons.payments_outlined,
          label: 'Cash',
          carat: _purchase.cashPaidCarat,
          amount: _purchase.cashPaidAmount,
          color: Colors.green,
        ),
        const SizedBox(height: 8),
        _paidRow(
          icon: Icons.account_balance_outlined,
          label: 'In Account',
          carat: _purchase.accountPaidCarat,
          amount: _purchase.accountPaidAmount,
          color: _accent,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _deep.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.timelapse_rounded, color: _deep, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Remaining',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: _deep),
                ),
              ),
              Text(
                '${_caratFmt.format(remaining)} ct · '
                '${_currencyFmt.format(remaining * _purchase.effectivePurchaseRate)}',
                style: const TextStyle(
                    color: _deep, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (fullyPaid)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This purchase is fully paid.',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          )
        else
          Form(
            key: _paymentFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paid Payment Through:',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: _deep),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _paidModeTile(
                        value: 'cash',
                        label: 'Cash',
                        icon: Icons.payments_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _paidModeTile(
                        value: 'account',
                        label: 'In Account',
                        icon: Icons.account_balance_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Amount Paid (max ${_currencyFmt.format(remainingAmount)})',
                  style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _paymentAmountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter amount paid',
                    filled: true,
                    fillColor: const Color(0xFFF4F7FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixText: '₹ ',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter amount paid';
                    }
                    final value = double.tryParse(v.trim());
                    if (value == null) return 'Invalid number';
                    if (value <= 0) return 'Must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _savingPayment ? null : _savePayment,
                    icon: _savingPayment
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_savingPayment ? 'Saving…' : 'Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _paidRow({
    required IconData icon,
    required String label,
    required double carat,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style:
                    TextStyle(color: color, fontWeight: FontWeight.w700)),
          ),
          Text(
            '${_caratFmt.format(carat)} ct · ${_currencyFmt.format(amount)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _paidModeTile({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final selected = _paidThroughMode == value;
    return InkWell(
      onTap: () => setState(() => _paidThroughMode = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color:
              selected ? _accent.withOpacity(0.12) : const Color(0xFFF4F7FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _accent : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? _accent : Colors.grey[700], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? _accent : Colors.grey[800],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: _accent, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _savePayment() async {
    if (!(_paymentFormKey.currentState?.validate() ?? false)) return;
    final enteredAmount =
        double.tryParse(_paymentAmountController.text.trim()) ?? 0;
    if (enteredAmount <= 0) return;
    final rate = _purchase.effectivePurchaseRate;
    if (rate <= 0) return;
    final enteredCarat = enteredAmount / rate;

    setState(() => _savingPayment = true);
    try {
      if (_paidThroughMode == 'cash') {
        _purchase.cashPaidCarat += enteredCarat;
      } else {
        _purchase.accountPaidCarat += enteredCarat;
      }
      await PurchaseStorageService.savePurchase(_purchase);
      if (!mounted) return;
      _paymentAmountController.clear();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment of ${_currencyFmt.format(enteredAmount)} saved '
            '(${_paidThroughMode == 'cash' ? 'Cash' : 'In Account'})',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error saving payment: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _savingPayment = false);
    }
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
