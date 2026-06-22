import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/invoice_model.dart';
import '../../viewmodels/invoice_form_viewmodel.dart';
import '../../services/ads_service.dart';
import '../../services/email_service.dart';
import '../../constants/app_translations.dart';

/// Modern UI surface for the Sell form (Cash + Invoice).
///
/// Functionally identical to the classic content widget: same VM, same
/// controllers, same validation, same generate/save flow. Only the
/// visuals change — dark navy backdrop, gradient hero, glass sections,
/// dark text fields, and a floating gradient save pill.
class ModernInvoiceFormContent extends StatefulWidget {
  const ModernInvoiceFormContent({super.key});

  @override
  State<ModernInvoiceFormContent> createState() =>
      _ModernInvoiceFormContentState();
}

class _ModernInvoiceFormContentState extends State<ModernInvoiceFormContent> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

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

  // Buyer Details Controllers
  final _buyerNameController = TextEditingController();
  final _buyerContactPersonController = TextEditingController();
  final _buyerContactNoController = TextEditingController();
  final _buyerEmailController = TextEditingController();
  final _buyerAddressController = TextEditingController();
  final _buyerGstNoController = TextEditingController();
  final _buyerPanNoController = TextEditingController();
  final _buyerStateNameController = TextEditingController();
  final _buyerStateCodeController = TextEditingController();
  final _placeOfSupplyController = TextEditingController();

  // Invoice Details Controllers
  final _invoiceNoController = TextEditingController();
  final _termsController = TextEditingController();
  final _brokerChargeController = TextEditingController();
  final _discountController = TextEditingController();

  final Map<int, TextEditingController> _caratControllers = {};
  final Map<int, TextEditingController> _rateControllers = {};
  final Map<int, TextEditingController> _hsnControllers = {};
  final ValueNotifier<int> _totalsUpdateNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<InvoiceFormViewModel>();
    _updateControllersFromInvoice(viewModel.invoice);
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _buyerContactPersonController.dispose();
    _buyerContactNoController.dispose();
    _buyerEmailController.dispose();
    _buyerAddressController.dispose();
    _buyerGstNoController.dispose();
    _buyerPanNoController.dispose();
    _buyerStateNameController.dispose();
    _buyerStateCodeController.dispose();
    _placeOfSupplyController.dispose();
    _invoiceNoController.dispose();
    _termsController.dispose();
    _brokerChargeController.dispose();
    _discountController.dispose();

    for (var controller in _caratControllers.values) {
      controller.dispose();
    }
    for (var controller in _rateControllers.values) {
      controller.dispose();
    }
    for (var controller in _hsnControllers.values) {
      controller.dispose();
    }
    _totalsUpdateNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateControllersFromInvoice(InvoiceModel inv) {
    _buyerNameController.text = inv.buyerName;
    _buyerContactPersonController.text = inv.buyerContactPerson;
    _buyerContactNoController.text = inv.buyerContactNo;
    _buyerEmailController.text = inv.buyerEmail;
    _buyerAddressController.text = inv.buyerAddress;
    _buyerGstNoController.text = inv.buyerGstNo;
    _buyerPanNoController.text = inv.buyerPanNo;
    _buyerStateNameController.text = inv.buyerStateName;
    _buyerStateCodeController.text = inv.buyerStateCode;
    _placeOfSupplyController.text = inv.placeOfSupply;
    _invoiceNoController.text = inv.invoiceNo;
    _termsController.text = inv.terms;
    _brokerChargeController.text =
        inv.brokerChargeRate > 0 ? inv.brokerChargeRate.toString() : '';
    _discountController.text =
        inv.discountRate > 0 ? inv.discountRate.toString() : '';
  }

  void _triggerTotalsUpdate() {
    _totalsUpdateNotifier.value = _totalsUpdateNotifier.value + 1;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InvoiceFormViewModel>();
    final invoice = viewModel.invoice;
    final isCashSell = viewModel.isCashSell;

    if (_invoiceNoController.text.isEmpty && invoice.invoiceNo.isNotEmpty) {
      _invoiceNoController.text = invoice.invoiceNo;
    }

    if (viewModel.isLoadingProfile || viewModel.isLoadingInventory) {
      return Scaffold(
        backgroundColor: _bg0,
        body: const Center(
            child: CircularProgressIndicator(color: _accent)),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        for (int i = 0; i < invoice.items.length; i++) {
          final item = invoice.items[i];
          _getCaratController(i, item);
          _getHsnController(i, item);
        }
        _triggerTotalsUpdate();
      }
    });

    return Scaffold(
      backgroundColor: _bg0,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, viewModel),
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heroCard(invoice, viewModel),
                    const SizedBox(height: 16),
                    _buyerDetailsSection(viewModel, isCashSell),
                    const SizedBox(height: 16),
                    _invoiceDetailsSection(
                        context, invoice, viewModel, isCashSell),
                    const SizedBox(height: 16),
                    _itemsSection(viewModel),
                    const SizedBox(height: 16),
                    _forOtherToggle(viewModel),
                    const SizedBox(height: 16),
                    _totalsSection(invoice, viewModel),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          _buildFloatingSaveButton(context, viewModel),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  // ─────────────────────────────  APP BAR  ────────────────────────────────

  PreferredSizeWidget _buildAppBar(
      BuildContext context, InvoiceFormViewModel vm) {
    final isCashSell = vm.isCashSell;
    final isEditing = vm.isEditing;
    final title = isCashSell
        ? (isEditing ? 'Edit Cash Sell'.tr : 'New Cash Sell'.tr)
        : (isEditing ? 'Edit Invoice'.tr : 'Invoice Generator'.tr);

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
              Navigator.of(context).pop(isEditing ? true : null);
            }
          });
        },
      ),
      title: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1)],
        ).createShader(rect),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
      actions: [
        if (isEditing && !isCashSell)
          IconButton(
            icon: const Icon(Icons.email_rounded, color: Colors.white),
            tooltip: 'Email Invoice'.tr,
            onPressed: () => _emailInvoice(context, vm.invoice),
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

  // ─────────────────────────────  HERO  ───────────────────────────────────

  Widget _heroCard(InvoiceModel invoice, InvoiceFormViewModel vm) {
    final limit = vm.remainingTotalCarat;
    final caratFmt = NumberFormat('#,##0.00');
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flash_on_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  vm.isCashSell
                      ? (vm.isEditing
                          ? 'Update Cash Sell'.tr
                          : 'Create Cash Sell'.tr)
                      : (vm.isEditing
                          ? 'Update Invoice'.tr
                          : 'Create New Invoice'.tr),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.30)),
                ),
                child: Text(
                  invoice.invoiceNo.isNotEmpty
                      ? invoice.invoiceNo
                      : 'Draft'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _heroInfo('Stock Available'.tr,
                  '${caratFmt.format(limit)} ct'),
              _heroInfo('Items'.tr, '${invoice.items.length}'),
              _heroInfo('Current Carat'.tr,
                  '${caratFmt.format(invoice.totalCarat)} ct'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.80),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────  BUYER  ──────────────────────────────────

  Widget _buyerDetailsSection(
      InvoiceFormViewModel vm, bool isCashSell) {
    return _glassSection(
      title: 'Buyer Details'.tr,
      icon: Icons.person_outline_rounded,
      gradient: const [_primary, _accent],
      children: [
        _buyerNameField(vm),
        const SizedBox(height: 16),
        _row([
          _textField(
            label: 'Contact Person'.tr,
            controller: _buyerContactPersonController,
            hint: 'Contact / broker name'.tr,
            onChanged: vm.updateBuyerContactPerson,
          ),
          _textField(
            label: 'Contact No'.tr,
            controller: _buyerContactNoController,
            hint: 'Mobile number'.tr,
            onChanged: vm.updateBuyerContactNo,
            keyboardType: TextInputType.phone,
          ),
        ]),
        const SizedBox(height: 16),
        _textField(
          label: 'Email'.tr,
          controller: _buyerEmailController,
          hint: 'example@mail.com'.tr,
          onChanged: vm.updateBuyerEmail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _textField(
          label: 'Buyer Address'.tr,
          controller: _buyerAddressController,
          hint: 'Full office/home address...'.tr,
          onChanged: vm.updateBuyerAddress,
        ),
        if (!isCashSell) ...[
          const SizedBox(height: 16),
          _row([
            _textField(
              label: 'GST NO'.tr,
              controller: _buyerGstNoController,
              hint: '24XXXXX...'.tr,
              onChanged: vm.updateBuyerGstNo,
            ),
            _textField(
              label: 'PAN NO'.tr,
              controller: _buyerPanNoController,
              hint: 'ABCDE1234F'.tr,
              onChanged: vm.updateBuyerPanNo,
            ),
          ]),
          const SizedBox(height: 16),
          _row([
            _textField(
              label: 'State Name'.tr,
              controller: _buyerStateNameController,
              hint: 'Gujarat'.tr,
              onChanged: vm.updateBuyerStateName,
            ),
            _textField(
              label: 'State Code'.tr,
              controller: _buyerStateCodeController,
              hint: '24',
              onChanged: vm.updateBuyerStateCode,
              keyboardType: TextInputType.number,
            ),
          ]),
          const SizedBox(height: 16),
          _textField(
            label: 'Place of Supply'.tr,
            controller: _placeOfSupplyController,
            hint: 'City name'.tr,
            onChanged: vm.updatePlaceOfSupply,
          ),
        ],
      ],
    );
  }

  Widget _buyerNameField(InvoiceFormViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _textField(
          label: 'Buyer Name'.tr,
          controller: _buyerNameController,
          hint: 'Search or enter buyer name'.tr,
          onChanged: vm.updateBuyerName,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Required'.tr : null,
        ),
        if (vm.suggestedBuyers.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: const Color(0xFF11173B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.40),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: vm.suggestedBuyers.length,
              itemBuilder: (context, index) {
                final buyer = vm.suggestedBuyers[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      vm.selectSuggestedBuyer(buyer);
                      _updateControllersFromInvoice(vm.invoice);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              color: _accent, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              buyer.buyerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────  INVOICE DETAILS  ────────────────────────

  Widget _invoiceDetailsSection(
      BuildContext context,
      InvoiceModel invoice,
      InvoiceFormViewModel vm,
      bool isCashSell) {
    return _glassSection(
      title: isCashSell ? 'Cash Sell Details'.tr : 'Invoice Details'.tr,
      icon: Icons.event_note_rounded,
      gradient: const [_accent, _violet],
      children: [
        _row([
          _textField(
            label: isCashSell ? 'Entry No'.tr : 'Invoice No'.tr,
            controller: _invoiceNoController,
            hint: isCashSell ? 'CASH-001'.tr : 'INV-001'.tr,
            onChanged: vm.updateInvoiceNo,
          ),
          _datePicker(
            label: isCashSell ? 'Sell Date'.tr : 'Invoice Date'.tr,
            value: invoice.invoiceDate,
            onPick: (d) => vm.updateInvoiceDate(d),
            context: context,
          ),
        ]),
        const SizedBox(height: 16),
        _row([
          _textField(
            label: 'Terms'.tr,
            controller: _termsController,
            hint: 'Net 30'.tr,
            onChanged: vm.updateTerms,
          ),
          _datePicker(
            label: 'Due Date'.tr,
            value: invoice.dueDate,
            onPick: (d) => vm.updateDueDate(d),
            context: context,
            firstDate: invoice.invoiceDate,
          ),
        ]),
        if (!isCashSell) ...[
          const SizedBox(height: 16),
          _taxTypeToggle(invoice, vm),
        ],
      ],
    );
  }

  Widget _taxTypeToggle(InvoiceModel invoice, InvoiceFormViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tax Type'.tr,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _taxOption(
                  selected: !invoice.isIgst,
                  title: 'SGST (Intra-State)'.tr,
                  subtitle: 'CGST 0.75% + SGST 0.75%'.tr,
                  onTap: () {
                    vm.updateIsIgst(false);
                    _triggerTotalsUpdate();
                  },
                ),
              ),
              Expanded(
                child: _taxOption(
                  selected: invoice.isIgst,
                  title: 'IGST (Inter-State)'.tr,
                  subtitle: 'IGST 1.5%'.tr,
                  onTap: () {
                    vm.updateIsIgst(true);
                    _triggerTotalsUpdate();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _taxOption({
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          gradient: selected ? _grad : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _accent.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected
                    ? Colors.white
                    : Colors.white.withOpacity(0.65),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: selected
                    ? Colors.white.withOpacity(0.85)
                    : Colors.white.withOpacity(0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────  ITEMS  ──────────────────────────────────

  Widget _itemsSection(InvoiceFormViewModel vm) {
    return _glassSection(
      title: 'Items'.tr,
      icon: Icons.diamond_outlined,
      gradient: const [Color(0xFF6366F1), _violet],
      trailing: _addItemButton(vm),
      children: [
        for (var i = 0; i < vm.invoice.items.length; i++)
          _itemCard(vm.invoice.items[i], i, vm),
      ],
    );
  }

  Widget _addItemButton(InvoiceFormViewModel vm) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: vm.addItem,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _accent.withOpacity(0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_circle_outline,
                  size: 16, color: _accent),
              const SizedBox(width: 6),
              Text(
                'Add Item'.tr,
                style: const TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemCard(
      InvoiceItem item, int index, InvoiceFormViewModel vm) {
    final caratController = _getCaratController(index, item);
    final rateController = _getRateController(index, item);
    final hsnController = _getHsnController(index, item);
    final maxLimit = vm.remainingTotalCarat;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${'Item'.tr} ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _accent.withOpacity(0.40)),
                  ),
                  child: Text(
                    '${'Stock'.tr}: ${maxLimit.toStringAsFixed(2)} ct',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (vm.invoice.items.length > 1)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded,
                      color: Color(0xFFFCA5A5), size: 20),
                  onPressed: () => vm.removeItem(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 28, minHeight: 28),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _textField(
            label: 'HSN Code'.tr,
            controller: hsnController,
            hint: '71049120',
            onChanged: (v) => vm.updateItemHsnCode(index, v),
          ),
          const SizedBox(height: 16),
          _row([
            _textField(
              label: 'Carat'.tr,
              controller: caratController,
              hint: '0.00',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (v) {
                if (kIsWeb) {
                  vm.updateItemCarat(index, v);
                  _triggerTotalsUpdate();
                  return;
                }

                double currentVal = double.tryParse(v) ?? 0;
                double othersTotal = 0;
                for (int i = 0; i < vm.invoice.items.length; i++) {
                  if (i != index) {
                    othersTotal += vm.invoice.items[i].carat;
                  }
                }

                if (currentVal + othersTotal > maxLimit + 0.001) {
                  final allowed =
                      (maxLimit - othersTotal).clamp(0.0, maxLimit);
                  caratController.text = allowed.toStringAsFixed(2);
                  caratController.selection =
                      TextSelection.fromPosition(
                    TextPosition(offset: caratController.text.length),
                  );
                  vm.updateItemCarat(index, caratController.text);
                } else {
                  vm.updateItemCarat(index, v);
                }
                _triggerTotalsUpdate();
              },
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required'.tr;
                final val = double.tryParse(v) ?? 0;
                if (val <= 0) return 'Must be > 0'.tr;
                if (!kIsWeb &&
                    vm.totalInvoiceCarat > (maxLimit + 0.001)) {
                  return 'Stock exceeded'.tr;
                }
                return null;
              },
            ),
            _textField(
              label: 'Rate'.tr,
              controller: rateController,
              hint: '0.00',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) {
                vm.updateItemRate(index, v);
                _triggerTotalsUpdate();
              },
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required'.tr : null,
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
                Text(
                  '₹${item.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _accent,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────  FOR OTHER  ──────────────────────────────

  Widget _forOtherToggle(InvoiceFormViewModel vm) {
    final isOn = vm.invoice.isForOther;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOn
              ? _accent.withOpacity(0.5)
              : Colors.white.withOpacity(0.08),
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
            child:
                const Icon(Icons.group_outlined, color: Colors.white, size: 18),
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
                  'Records only — no stock impact, excluded from Opening totals, Sales Profit and Net Profit.'
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

  // ─────────────────────────────  TOTALS  ─────────────────────────────────

  Widget _totalsSection(InvoiceModel invoice, InvoiceFormViewModel vm) {
    return ValueListenableBuilder<int>(
      valueListenable: _totalsUpdateNotifier,
      builder: (context, _, __) {
        final totals = _calculateTotalsFromControllers(invoice);
        final isCashSell = vm.isCashSell;
        return _glassSection(
          title: 'Summary'.tr,
          icon: Icons.summarize_rounded,
          gradient: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          children: [
            _row([
              _textField(
                label: 'Discount (%)'.tr,
                controller: _discountController,
                hint: '0',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (v) {
                  vm.updateDiscountRate(v);
                  _triggerTotalsUpdate();
                },
              ),
              _textField(
                label: 'Broker Charge (%)'.tr,
                controller: _brokerChargeController,
                hint: '0',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (v) {
                  vm.updateBrokerChargeRate(v);
                  _triggerTotalsUpdate();
                },
              ),
            ]),
            const SizedBox(height: 14),
            _infoRow('Sub Total'.tr,
                '₹${totals['totalAmount']!.toStringAsFixed(2)}'),
            if (invoice.discountRate > 0)
              _infoRow(
                '${'Discount'.tr} (${invoice.discountRate}%)',
                '- ₹${totals['discountAmount']!.toStringAsFixed(2)}',
              ),
            if (invoice.discountRate > 0)
              _infoRow(
                'Taxable Amount'.tr,
                '₹${totals['taxableAmount']!.toStringAsFixed(2)}',
              ),
            if (!isCashSell) ...[
              if (!invoice.isIgst) ...[
                _infoRow(
                  'CGST (${invoice.cgstRate}%)',
                  '₹${totals['cgstAmount']!.toStringAsFixed(2)}',
                ),
                _infoRow(
                  'SGST (${invoice.sgstRate}%)',
                  '₹${totals['sgstAmount']!.toStringAsFixed(2)}',
                ),
              ] else ...[
                _infoRow(
                  'IGST (${invoice.igstRate}%)',
                  '₹${totals['igstAmount']!.toStringAsFixed(2)}',
                ),
              ],
            ],
            if (invoice.brokerChargeRate > 0)
              _infoRow(
                '${'Broker Charge'.tr} (${invoice.brokerChargeRate}%)',
                '- ₹${totals['brokerChargeAmount']!.toStringAsFixed(2)}',
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                  height: 1, color: Colors.white.withOpacity(0.10)),
            ),
            _infoRow(
              'Grand Total'.tr,
              '₹${totals['grandTotal']!.toStringAsFixed(2)}',
              isBold: true,
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold
                  ? Colors.white
                  : Colors.white.withOpacity(0.65),
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              fontSize: isBold ? 15 : 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isBold ? _accent : Colors.white,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              fontSize: isBold ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────  SAVE BAR  ───────────────────────────────

  Widget _buildFloatingSaveButton(
      BuildContext context, InvoiceFormViewModel vm) {
    final pillWidth = MediaQuery.of(context).size.width - 32;
    final isCashSell = vm.isCashSell;
    final label = isCashSell
        ? (vm.isEditing
            ? 'Update Cash Sell'.tr
            : 'Save Cash Sell'.tr)
        : (vm.isEditing
            ? 'Update & Generate'.tr
            : 'Generate Invoice'.tr);
    final icon =
        isCashSell ? Icons.save_rounded : Icons.picture_as_pdf_rounded;
    final busy = vm.isGeneratingPdf || vm.isSaving;

    return SizedBox(
      width: pillWidth,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: busy ? null : () => _generatePDF(context, vm),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: busy ? null : _grad,
              color: busy ? Colors.white.withOpacity(0.10) : null,
              borderRadius: BorderRadius.circular(20),
              boxShadow: busy
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
                if (busy)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
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
    Widget? trailing,
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              if (trailing != null) trailing,
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
            padding: EdgeInsets.only(left: e.key > 0 ? 8 : 0),
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

  Widget _datePicker({
    required String label,
    required DateTime value,
    required Function(DateTime) onPick,
    required BuildContext context,
    DateTime? firstDate,
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: value,
                firstDate: firstDate ?? DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (d != null) onPick(d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 16, color: _accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat('dd MMM yyyy'.tr).format(value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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

  // ─────────────────────────────  CONTROLLERS + TOTALS  ───────────────────

  Map<String, double> _calculateTotalsFromControllers(InvoiceModel invoice) {
    double totalCarat = 0.0;
    double totalAmount = 0.0;
    for (int i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final carat =
          double.tryParse(_caratControllers[i]?.text ?? '') ?? item.carat;
      final rate =
          double.tryParse(_rateControllers[i]?.text ?? '') ?? item.rate;
      totalCarat += carat;
      totalAmount += ((carat * rate) / 10).roundToDouble() * 10;
    }
    final discount = totalAmount * (invoice.discountRate / 100);
    final taxable = totalAmount - discount;
    final brokerCharge = taxable * (invoice.brokerChargeRate / 100);
    final cgst = invoice.isIgst ? 0.0 : taxable * (invoice.cgstRate / 100);
    final sgst = invoice.isIgst ? 0.0 : taxable * (invoice.sgstRate / 100);
    final igst =
        invoice.isIgst ? taxable * (invoice.igstRate / 100) : 0.0;
    return {
      'totalCarat': totalCarat,
      'totalAmount': totalAmount,
      'discountAmount': discount,
      'taxableAmount': taxable,
      'brokerChargeAmount': brokerCharge,
      'cgstAmount': cgst,
      'sgstAmount': sgst,
      'igstAmount': igst,
      'grandTotal': taxable + cgst + sgst + igst - brokerCharge,
    };
  }

  TextEditingController _getCaratController(int index, InvoiceItem item) {
    return _caratControllers.putIfAbsent(
      index,
      () => TextEditingController(
          text: item.carat > 0 ? item.carat.toString() : ''),
    );
  }

  TextEditingController _getRateController(int index, InvoiceItem item) {
    return _rateControllers.putIfAbsent(
      index,
      () => TextEditingController(
          text: item.rate > 0 ? item.rate.toString() : ''),
    );
  }

  TextEditingController _getHsnController(int index, InvoiceItem item) {
    return _hsnControllers.putIfAbsent(
      index,
      () => TextEditingController(text: item.hsnCode),
    );
  }

  // ─────────────────────────────  SAVE  ──────────────────────────────────

  Future<void> _generatePDF(
      BuildContext context, InvoiceFormViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    if (!kIsWeb &&
        viewModel.totalInvoiceCarat >
            (viewModel.remainingTotalCarat + 0.001)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${'Total carat exceeds global stock'.tr} (${viewModel.remainingTotalCarat.toStringAsFixed(2)})'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await viewModel.generateAndSaveInvoice();
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(viewModel.isCashSell
              ? 'Cash sell entry saved!'.tr
              : 'Invoice generated successfully!'.tr),
          backgroundColor: Colors.green,
        ));
        AdsService.instance.maybeShowInterstitial();
        Navigator.pop(context, true);
      } else if (viewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(viewModel.errorMessage!),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _emailInvoice(
      BuildContext context, InvoiceModel invoice) async {
    await EmailService.shareInvoiceViaEmail(invoice);
  }
}
