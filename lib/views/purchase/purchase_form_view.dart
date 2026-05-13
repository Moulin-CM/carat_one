import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/purchase_model.dart';
import '../../viewmodels/purchase_form_viewmodel.dart';
import '../../widgets/app_bar_factory.dart';
import '../../widgets/custom_section.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../services/ads_service.dart';
import '../../constants/app_translations.dart';


class PurchaseFormView extends StatelessWidget {
  final PurchaseModel? purchase;
  const PurchaseFormView({super.key, this.purchase});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PurchaseFormViewModel(item: purchase),
      child: const _PurchaseFormContent(),
    );
  }
}

class _PurchaseFormContent extends StatefulWidget {
  const _PurchaseFormContent();
  @override
  State<_PurchaseFormContent> createState() => _PurchaseFormContentState();
}

class _PurchaseFormContentState extends State<_PurchaseFormContent> {
  final _formKey = GlobalKey<FormState>();
  static const _accent = Color(0xFF4F8AF4);
  static const _deep = Color(0xFF1E3C72);

  late TextEditingController _netAmountCtrl;
  late TextEditingController _totalCaratCtrl;
  late TextEditingController _amtPerCaratCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _dueDaysCtrl;
  late TextEditingController _sellerCtrl;
  late TextEditingController _brokerCtrl;
  late TextEditingController _brokerChargeCtrl;
  late TextEditingController _sizeCtrl;

  @override
  void initState() {
    super.initState();
    final vm = context.read<PurchaseFormViewModel>();
    final p = vm.item;
    _netAmountCtrl   = TextEditingController(text: p.totalAmount > 0 ? p.totalAmount.toString() : '');
    _totalCaratCtrl  = TextEditingController(text: p.totalCarat > 0 ? p.totalCarat.toString() : '');
    _amtPerCaratCtrl = TextEditingController(text: p.amountPerCarat > 0 ? p.amountPerCarat.toString() : '');
    _discountCtrl    = TextEditingController(text: p.discount > 0 ? p.discount.toString() : '');
    _dueDaysCtrl     = TextEditingController(text: p.dueDays > 0 ? p.dueDays.toString() : '');
    _sellerCtrl      = TextEditingController(text: p.sellerName);
    _brokerCtrl      = TextEditingController(text: p.brokerName);
    _brokerChargeCtrl = TextEditingController(
        text: p.brokerChargeRate > 0 ? p.brokerChargeRate.toString() : '');
    _sizeCtrl        = TextEditingController(text: p.size.isNotEmpty ? p.size : '');
  }

  @override
  void dispose() {
    _netAmountCtrl.dispose();
    _totalCaratCtrl.dispose();
    _amtPerCaratCtrl.dispose();
    _discountCtrl.dispose();
    _dueDaysCtrl.dispose();
    _sellerCtrl.dispose();
    _brokerCtrl.dispose();
    _brokerChargeCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PurchaseFormViewModel>();
    final dateFormat = DateFormat('dd MMM yyyy'.tr);

    // Update net amount controller when values change
    if (_netAmountCtrl.text != vm.item.totalAmount.toString()) {
       _netAmountCtrl.text = vm.item.totalAmount > 0 ? vm.item.totalAmount.toString() : '';
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBarFactory.build(
        title: vm.isEditing ? 'Edit Purchase'.tr : 'Add Purchase'.tr,
          onBackPress: () {
            FocusScope.of(context).unfocus();

            Future.microtask(() {
              if (mounted && Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }
            });
          },
      ),
      body: Stack(
        children: [
          _backdrop(),
          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomSection(
                      title: 'Financial Details'.tr,
                      icon: Icons.attach_money_rounded,
                      children: [
                        _row([
                          CustomTextField(
                            label: 'Net Amount'.tr,
                            controller: _netAmountCtrl,
                            hint: 'Auto-calculated'.tr,
                            readOnly: true,
                            keyboardType: TextInputType.number,
                          ),
                          CustomTextField(
                            label: 'Total Carat'.tr,
                            controller: _totalCaratCtrl,
                            hint: 'Enter carats (e.g. 10)'.tr,
                            onChanged: vm.updateTotalCarat,
                            keyboardType: TextInputType.number,
                            validator: (v) => (v == null || v.isEmpty) ? 'Required'.tr : null,
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _row([
                          CustomTextField(
                            label: 'Amt per Carat'.tr,
                            controller: _amtPerCaratCtrl,
                            hint: 'Price per carat (e.g. 5000)'.tr,
                            onChanged: vm.updateAmountPerCarat,
                            keyboardType: TextInputType.number,
                          ),
                          CustomTextField(
                            label: 'Discount (%)'.tr,
                            controller: _discountCtrl,
                            hint: 'Enter % (e.g. 1)'.tr,
                            onChanged: vm.updateDiscount,
                            keyboardType: TextInputType.number,
                            suffixText: '%',
                          ),
                        ]),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Due Days'.tr,
                          controller: _dueDaysCtrl,
                          hint: 'Payment due in days (e.g. 10)'.tr,
                          onChanged: vm.updateDueDays,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomSection(
                      title: 'Party Details'.tr,
                      icon: Icons.people_rounded,
                      children: [
                        CustomTextField(
                          label: 'Seller Name'.tr,
                          controller: _sellerCtrl,
                          hint: 'Enter seller name'.tr,
                          onChanged: vm.updateSellerName,
                          validator: (v) => (v == null || v.isEmpty) ? 'Required'.tr : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Broker Name'.tr,
                          controller: _brokerCtrl,
                          hint: 'Enter broker name'.tr,
                          onChanged: vm.updateBrokerName,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Broker Charge (%)'.tr,
                          controller: _brokerChargeCtrl,
                          hint: 'Enter % (e.g. 1)'.tr,
                          onChanged: vm.updateBrokerChargeRate,
                          keyboardType: TextInputType.number,
                          suffixText: '%',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomSection(
                      title: 'Size & Dates'.tr,
                      icon: Icons.straighten_rounded,
                      children: [
                        CustomTextField(
                          label: 'Size'.tr,
                          controller: _sizeCtrl,
                          onChanged: vm.updateSize,
                          hint: 'e.g. C3, AB12'.tr,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                            LengthLimitingTextInputFormatter(6),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _row([
                          _datePicker('Buy Date'.tr, vm.item.buyDate, dateFormat, vm.updateBuyDate, context),
                          _datePicker('Payment Date'.tr, vm.item.paymentDate, dateFormat, vm.updatePaymentDate, context),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _forOtherToggle(vm),
                    const SizedBox(height: 16),
                    _liveSummary(vm),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: CustomButton(
          label: vm.isEditing ? 'Update Purchase'.tr : 'Save Purchase'.tr,
          isLoading: vm.isSaving,
          onPressed: () => _save(context, vm),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, PurchaseFormViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await vm.save();
    if (context.mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.isEditing ? 'Purchase updated!'.tr : 'Purchase saved!'.tr),
            backgroundColor: Colors.green,
          ),
        );
        // Natural transition after a save — try to show an interstitial.
        // Frequency-capped inside AdsService so it never feels spammy.
        AdsService.instance.maybeShowInterstitial();
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage ?? 'Error saving purchase'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _row(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: e.key > 0 ? 12 : 0),
            child: e.value,
          ),
        );
      }).toList(),
    );
  }

  Widget _datePicker(String label, DateTime value, DateFormat fmt, Function(DateTime) onPick, BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (d != null) onPick(d);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3C72),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 18, color: _accent),
                const SizedBox(width: 10),
                Text(fmt.format(value),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _forOtherToggle(PurchaseFormViewModel vm) {
    final isOn = vm.item.isForOther;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isOn ? _accent.withOpacity(0.5) : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.group_outlined, color: _accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('For Other'.tr,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _deep,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                    'Records only — excluded from Opening totals, Sales Profit and Net Profit.'.tr,
                    style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          Switch.adaptive(
            value: isOn,
            activeColor: _accent,
            onChanged: vm.updateIsForOther,
          ),
        ],
      ),
    );
  }

  Widget _liveSummary(PurchaseFormViewModel vm) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final p = vm.item;
    return CustomCard(
      padding: const EdgeInsets.all(16),
      gradient: const LinearGradient(
        colors: [Color(0xFF1E3C72), Color(0xFF4F8AF4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live Summary'.tr,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sumItem('Total Amount'.tr, fmt.format(vm.grossAmount)),
              _sumItem('Discount Amt'.tr, fmt.format(vm.discountAmount)),
              _sumItem('Net Amount'.tr, fmt.format(vm.netAmount)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sumItem('Total Carat'.tr, '${p.totalCarat.toStringAsFixed(2)} ct'),
              _sumItem('Rate/Carat'.tr, fmt.format(p.amountPerCarat)),
              _sumItem('Discount'.tr, '${p.discount}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sumItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
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
