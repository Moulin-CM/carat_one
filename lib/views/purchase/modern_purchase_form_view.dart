import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/purchase_form_viewmodel.dart';
import '../../services/ads_service.dart';
import '../../constants/app_translations.dart';

/// Modern UI surface for the Add / Edit Purchase form.
///
/// Functionally identical to the classic [PurchaseFormView]: same fields,
/// same validation, same VM updates, same save flow. Only the visuals
/// change — dark navy backdrop, glass sections, gradient hero card and
/// save button.
class ModernPurchaseFormContent extends StatefulWidget {
  const ModernPurchaseFormContent({super.key});

  @override
  State<ModernPurchaseFormContent> createState() =>
      _ModernPurchaseFormContentState();
}

class _ModernPurchaseFormContentState extends State<ModernPurchaseFormContent> {
  final _formKey = GlobalKey<FormState>();

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
    _netAmountCtrl = TextEditingController(
        text: p.totalAmount > 0 ? p.totalAmount.toStringAsFixed(0) : '');
    _totalCaratCtrl = TextEditingController(
        text: p.totalCarat > 0 ? p.totalCarat.toString() : '');
    _amtPerCaratCtrl = TextEditingController(
        text: p.amountPerCarat > 0 ? p.amountPerCarat.toString() : '');
    _discountCtrl = TextEditingController(
        text: p.discount > 0 ? p.discount.toString() : '');
    _dueDaysCtrl = TextEditingController(
        text: p.dueDays > 0 ? p.dueDays.toString() : '');
    _sellerCtrl = TextEditingController(text: p.sellerName);
    _brokerCtrl = TextEditingController(text: p.brokerName);
    _brokerChargeCtrl = TextEditingController(
        text: p.brokerChargeRate > 0 ? p.brokerChargeRate.toString() : '');
    _sizeCtrl =
        TextEditingController(text: p.size.isNotEmpty ? p.size : '');
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

    // Keep net-amount controller in sync with the VM-computed total.
    final formattedTotal =
        vm.item.totalAmount > 0 ? vm.item.totalAmount.toStringAsFixed(0) : '';
    if (_netAmountCtrl.text != formattedTotal) {
      _netAmountCtrl.text = formattedTotal;
    }

    return Scaffold(
      backgroundColor: _bg0,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, vm),
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFinancialSection(vm),
                    const SizedBox(height: 16),
                    _buildPartySection(vm),
                    const SizedBox(height: 16),
                    _buildSizeDatesSection(vm, dateFormat, context),
                    const SizedBox(height: 16),
                    _buildForOtherToggle(vm),
                    const SizedBox(height: 16),
                    _buildLiveSummary(vm),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingSaveButton(context, vm),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ─────────────────────────────  APP BAR  ────────────────────────────────

  PreferredSizeWidget _buildAppBar(
      BuildContext context, PurchaseFormViewModel vm) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () {
          FocusScope.of(context).unfocus();
          Future.microtask(() {
            if (mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          });
        },
      ),
      title: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1)],
        ).createShader(rect),
        child: Text(
          vm.isEditing ? 'Edit Purchase'.tr : 'Add Purchase'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
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
            top: 220,
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

  // ─────────────────────────────  SECTIONS  ───────────────────────────────

  Widget _buildFinancialSection(PurchaseFormViewModel vm) {
    return _glassSection(
      title: 'Financial Details'.tr,
      icon: Icons.attach_money_rounded,
      gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
      children: [
        _row([
          _textField(
            label: 'Net Amount'.tr,
            controller: _netAmountCtrl,
            hint: 'Auto-calculated'.tr,
            readOnly: true,
            keyboardType: TextInputType.number,
          ),
          _textField(
            label: 'Total Carat'.tr,
            controller: _totalCaratCtrl,
            hint: 'Enter carats (e.g. 10)'.tr,
            onChanged: vm.updateTotalCarat,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Required'.tr : null,
          ),
        ]),
        const SizedBox(height: 16),
        _row([
          _textField(
            label: 'Amt per Carat'.tr,
            controller: _amtPerCaratCtrl,
            hint: 'Price per carat (e.g. 5000)'.tr,
            onChanged: vm.updateAmountPerCarat,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
          ),
          _textField(
            label: 'Discount (%)'.tr,
            controller: _discountCtrl,
            hint: 'Enter % (e.g. 1)'.tr,
            onChanged: vm.updateDiscount,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            suffixText: '%',
          ),
        ]),
        const SizedBox(height: 16),
        _textField(
          label: 'Due Days'.tr,
          controller: _dueDaysCtrl,
          hint: 'Payment due in days (e.g. 10)'.tr,
          onChanged: vm.updateDueDays,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildPartySection(PurchaseFormViewModel vm) {
    return _glassSection(
      title: 'Party Details'.tr,
      icon: Icons.people_rounded,
      gradient: const [_primary, _accent],
      children: [
        _textField(
          label: 'Seller Name'.tr,
          controller: _sellerCtrl,
          hint: 'Enter seller name'.tr,
          onChanged: vm.updateSellerName,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Required'.tr : null,
        ),
        const SizedBox(height: 16),
        _textField(
          label: 'Broker Name'.tr,
          controller: _brokerCtrl,
          hint: 'Enter broker name'.tr,
          onChanged: vm.updateBrokerName,
        ),
        const SizedBox(height: 16),
        _textField(
          label: 'Broker Charge (%)'.tr,
          controller: _brokerChargeCtrl,
          hint: 'Enter % (e.g. 1)'.tr,
          onChanged: vm.updateBrokerChargeRate,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          suffixText: '%',
        ),
      ],
    );
  }

  Widget _buildSizeDatesSection(PurchaseFormViewModel vm,
      DateFormat dateFormat, BuildContext context) {
    return _glassSection(
      title: 'Size & Dates'.tr,
      icon: Icons.straighten_rounded,
      gradient: const [_accent, _violet],
      children: [
        _textField(
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
          _datePicker('Buy Date'.tr, vm.item.buyDate, dateFormat,
              vm.updateBuyDate, context),
          _datePicker('Payment Date'.tr, vm.item.paymentDate, dateFormat,
              vm.updatePaymentDate, context),
        ]),
      ],
    );
  }

  Widget _buildForOtherToggle(PurchaseFormViewModel vm) {
    final isOn = vm.item.isForOther;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOn ? _accent.withOpacity(0.5) : Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primary, _accent],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.group_outlined,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'For Other'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Records only — excluded from Opening totals, Sales Profit and Net Profit.'
                      .tr,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
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

  Widget _buildLiveSummary(PurchaseFormViewModel vm) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final p = vm.item;
    return Container(
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Live Summary'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
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
              _sumItem('Total Carat'.tr,
                  '${p.totalCarat.toStringAsFixed(2)} ct'),
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
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────  SAVE BAR  ───────────────────────────────

  Widget _buildFloatingSaveButton(
      BuildContext context, PurchaseFormViewModel vm) {
    // Slightly less than full width so the pill has a visible margin
    // from the screen edges — that gives it the "floating" feel rather
    // than a docked bar look.
    final pillWidth = MediaQuery.of(context).size.width - 32;

    return SizedBox(
      width: pillWidth,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: vm.isSaving ? null : () => _save(context, vm),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: vm.isSaving ? null : _grad,
              color: vm.isSaving ? Colors.white.withOpacity(0.10) : null,
              borderRadius: BorderRadius.circular(20),
              boxShadow: vm.isSaving
                  ? null
                  : [
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
                if (vm.isSaving)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  const Icon(Icons.check_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    vm.isEditing
                        ? 'Update Purchase'.tr
                        : 'Save Purchase'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────  HELPERS  ────────────────────────────────

  Widget _glassSection({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
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
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
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

  Widget _textField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? suffixText,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          validator: validator,
          style: TextStyle(
            color: readOnly
                ? Colors.white.withOpacity(0.75)
                : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: _accent,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.40),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            suffixText: suffixText,
            suffixStyle: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontWeight: FontWeight.w700,
            ),
            filled: true,
            fillColor: readOnly
                ? Colors.white.withOpacity(0.02)
                : Colors.white.withOpacity(0.06),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            errorStyle: const TextStyle(
              color: Color(0xFFFCA5A5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
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
          ),
        ),
      ],
    );
  }

  Widget _datePicker(String label, DateTime value, DateFormat fmt,
      Function(DateTime) onPick, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: value,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (d != null) onPick(d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 18, color: _accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      fmt.format(value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────  SAVE  ──────────────────────────────────

  Future<void> _save(BuildContext context, PurchaseFormViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await vm.save();
    if (context.mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.isEditing
                ? 'Purchase updated!'.tr
                : 'Purchase saved!'.tr),
            backgroundColor: Colors.green,
          ),
        );
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
}
