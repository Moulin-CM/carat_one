import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/payment_installment.dart';
import '../../models/purchase_model.dart';
import '../../services/purchase_storage_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_section.dart';
import '../../widgets/custom_info_row.dart';
import '../../widgets/app_bar_factory.dart';
import '../../constants/app_translations.dart';
import 'purchase_form_view.dart';


import 'package:invoice_generator/constants/app_translations.dart';

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
  final _dateFmt = DateFormat('dd MMM yyyy'.tr);
  final _caratFmt = NumberFormat('#,##0.00');
  // Payment-to-seller tracking
  final _paymentAmountController = TextEditingController();
  final _paymentFormKey = GlobalKey<FormState>();
  String _paidThroughMode = 'cash'.tr;
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
        title: 'Purchase Details'.tr,
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
            tooltip: 'Edit'.tr,
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
            _purchase.sellerName.isNotEmpty ? _purchase.sellerName : 'Unknown Seller'.tr,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          if (_purchase.brokerName.isNotEmpty)
            Text('${'Broker'.tr}: ${_purchase.brokerName}',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _whiteChip('Size'.tr, _purchase.size.isNotEmpty ? _purchase.size : '-'),
              _whiteChip('Buy Date'.tr, _dateFmt.format(_purchase.buyDate)),
              _whiteChip('Pay Date'.tr, _dateFmt.format(_purchase.paymentDate)),
              _whiteChip('Due Days'.tr, '${_purchase.dueDays}d'),
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
      title: 'Party & Dates'.tr,
      icon: Icons.people_rounded,
      children: [
        CustomInfoRow(label: 'Seller'.tr, value: _purchase.sellerName),
        CustomInfoRow(label: 'Broker'.tr, value: _purchase.brokerName.isNotEmpty ? _purchase.brokerName : '-'),
        CustomInfoRow(label: 'Size'.tr, value: _purchase.size.isNotEmpty ? _purchase.size : '-'),
        CustomInfoRow(label: 'Buy Date'.tr, value: _dateFmt.format(_purchase.buyDate)),
        CustomInfoRow(label: 'Payment Date'.tr, value: _dateFmt.format(_purchase.paymentDate)),
        CustomInfoRow(label: 'Due Days'.tr, value: '${_purchase.dueDays} ${'days'.tr}'),
      ],
    );
  }

  Widget _financialSection() {
    return CustomSection(
      title: 'Financial Summary'.tr,
      icon: Icons.attach_money_rounded,
      children: [
        CustomInfoRow(label: 'Total Amount'.tr, value: _currencyFmt.format(_purchase.grossAmount)),
        CustomInfoRow(label: 'Discount Amt'.tr, value: _currencyFmt.format(_purchase.discountValue)),
        CustomInfoRow(label: 'Net Amount'.tr, value: _currencyFmt.format(_purchase.netAmount), isBold: true, valueColor: _deep),
        CustomInfoRow(label: 'Total Carat'.tr, value: '${_caratFmt.format(_purchase.totalCarat)} ct'),
        CustomInfoRow(label: 'Rate per Carat'.tr, value: _currencyFmt.format(_purchase.amountPerCarat)),
        CustomInfoRow(label: 'Discount (%)'.tr, value: '${_purchase.discount}%'),
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
      title: 'Payment'.tr,
      icon: Icons.payments_rounded,
      children: [
        _paidRow(
          icon: Icons.payments_outlined,
          label: 'Cash'.tr,
          carat: _purchase.cashPaidCarat,
          amount: _purchase.cashPaidAmount,
          color: Colors.green,
        ),
        const SizedBox(height: 8),
        _paidRow(
          icon: Icons.account_balance_outlined,
          label: 'In Account'.tr,
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
              Expanded(
                child: Text(
                  'Remaining'.tr,
                  style: const TextStyle(
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
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This purchase is fully paid.'.tr,
                    style: const TextStyle(
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
                Text(
                  'Paid Payment Through:'.tr,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: _deep),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _paidModeTile(
                        value: 'cash'.tr,
                        label: 'Cash'.tr,
                        icon: Icons.payments_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _paidModeTile(
                        value: 'account'.tr,
                        label: 'In Account'.tr,
                        icon: Icons.account_balance_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '${'Amount Paid'.tr} (${'max'.tr} ${_currencyFmt.format(remainingAmount)})',
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
                    hintText: 'Enter amount paid'.tr,
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
                      return 'Enter amount paid'.tr;
                    }
                    final value = double.tryParse(v.trim());
                    if (value == null) return 'Invalid number'.tr;
                    if (value <= 0) return 'Must be greater than 0'.tr;
                    if (value > remainingAmount + 0.005) {
                      return '${'Cannot exceed remaining'.tr} (${_currencyFmt.format(remainingAmount)})';
                    }
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
                    label: Text(_savingPayment ? 'Saving…'.tr : 'Save'.tr),
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
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _savingPayment ? null : _markAsPaid,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text('Mark as Paid'.tr),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      side: BorderSide(color: Colors.green.shade400, width: 1.4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _markAsPaid() async {
    final original = _purchase.originalAmount;
    final currentPaid = _purchase.totalPaidAmount;
    // Pre-fill with the actual entered amount if any, else with the full
    // bill so a one-tap Mark-as-Paid still works.
    final initial = currentPaid > 0 ? currentPaid : original;
    final controller = TextEditingController(
      text: initial.toStringAsFixed(0),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final entered =
                double.tryParse(controller.text.trim()) ?? 0;
            final diff = original - entered;
            return AlertDialog(
              title: Text('Mark as Paid?'.tr),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'Original Amount'.tr}: ${_currencyFmt.format(original)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  Text('Paid Amount'.tr,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 10),
                  if (diff > 0.005)
                    Text(
                      '${'Difference of'.tr} ${_currencyFmt.format(diff)} ${'will be absorbed.'.tr}',
                      style: TextStyle(
                          color: Colors.orange.shade800, fontSize: 12),
                    )
                  else if (diff < -0.005)
                    Text(
                      '${'Overpaid by'.tr} ${_currencyFmt.format(-diff)}',
                      style: const TextStyle(
                          color: Colors.red, fontSize: 12),
                    ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel'.tr)),
                ElevatedButton(
                  onPressed: entered > 0
                      ? () => Navigator.pop(ctx, entered)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Mark Paid'.tr),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() => _savingPayment = true);
    try {
      // Mark-as-Paid settles ALL carats of the lot at the user-entered
      // amount, regardless of the back-calculated rate × carat figure.
      // The carat split between Cash / Account is preserved if any
      // payments were already recorded; otherwise everything is parked
      // under Cash.
      final currentCarat = _purchase.totalPaidCarat;
      if (currentCarat > 0) {
        final cashRatio = _purchase.cashPaidCarat / currentCarat;
        _purchase.cashPaidCarat = _purchase.totalCarat * cashRatio;
        _purchase.accountPaidCarat = _purchase.totalCarat * (1 - cashRatio);
      } else {
        _purchase.cashPaidCarat = _purchase.totalCarat;
        _purchase.accountPaidCarat = 0;
      }
      _purchase.manuallyPaidAmount = result;
      _purchase.isManuallyMarkedPaid = true;
      await PurchaseStorageService.savePurchase(_purchase);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked as Paid'.tr),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${'Error saving payment'.tr}: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _savingPayment = false);
    }
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
          Text('${_caratFmt.format(carat)} ct · ${_currencyFmt.format(amount)}'.tr,
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

    final isCash = _paidThroughMode == 'cash'.tr;
    final mode = isCash ? 'cash' : 'account';

    setState(() => _savingPayment = true);
    try {
      _purchase.installments.add(PaymentInstallment(
        mode: mode,
        amount: enteredAmount,
        carat: enteredCarat,
      ));
      if (isCash) {
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
            '${'Payment of'.tr} ${_currencyFmt.format(enteredAmount)} ${'saved'.tr} '
            '(${_paidThroughMode == 'cash'.tr ? 'Cash'.tr : 'In Account'.tr})',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${'Error saving payment'.tr}: $e'),
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
