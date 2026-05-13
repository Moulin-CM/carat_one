import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/invoice_model.dart';
import '../../viewmodels/invoice_form_viewmodel.dart';
import '../../services/email_service.dart';
import '../../widgets/custom_section.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_info_row.dart';
import '../../widgets/app_bar_factory.dart';
import '../../services/ads_service.dart';
import '../../constants/app_translations.dart';
import 'package:flutter/foundation.dart';


import 'package:invoice_generator/constants/app_translations.dart';

class InvoiceFormView extends StatelessWidget {
  final InvoiceModel? invoice;
  final String? purchaseId;
  final double? maxCarat;
  final String? paymentType;
  final double? initialCarat;
  final bool isCashSell;

  const InvoiceFormView({
    super.key,
    this.invoice,
    this.purchaseId,
    this.maxCarat,
    this.paymentType,
    this.initialCarat,
    this.isCashSell = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InvoiceFormViewModel(
          invoice: invoice,
          purchaseId: purchaseId,
          maxCaratFromPurchase: maxCarat,
          paymentTypeFromPurchase: paymentType,
          initialCarat: initialCarat,
          isCashSell: isCashSell),
      child: const _InvoiceFormViewContent(),
    );
  }
}

class _InvoiceFormViewContent extends StatefulWidget {
  const _InvoiceFormViewContent();

  @override
  State<_InvoiceFormViewContent> createState() => _InvoiceFormViewContentState();
}

class _InvoiceFormViewContentState extends State<_InvoiceFormViewContent> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  static const _accent = Color(0xFF4F8AF4);
  static const _deep = Color(0xFF1E3C72);
  
  // Buyer Details Controllers
  final _buyerNameController = TextEditingController();
  final _buyerContactPersonController = TextEditingController();
  final _buyerContactNoController = TextEditingController();
  final _buyerEmailController = TextEditingController();
  final _buyerAddressController = TextEditingController();
  final _buyerGstNoController = TextEditingController();
  final _buyerPanNoController = TextEditingController();
  final _buyerVatNoController = TextEditingController();
  final _buyerCstNoController = TextEditingController();
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
    final inv = viewModel.invoice;
    _updateControllersFromInvoice(inv);
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
    _buyerVatNoController.dispose();
    _buyerCstNoController.dispose();
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
    _buyerVatNoController.text = inv.buyerVatNo;
    _buyerCstNoController.text = inv.buyerCstNo;
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
    final isEditing = viewModel.isEditing;
    final isCashSell = viewModel.isCashSell;

    // Pick up the auto-generated Entry/Invoice No once the viewmodel resolves
    // it. Only sync when the field hasn't been touched, so we never overwrite
    // the user'.trs manual edits.
    if (_invoiceNoController.text.isEmpty && invoice.invoiceNo.isNotEmpty) {
      _invoiceNoController.text = invoice.invoiceNo;
    }

    if (viewModel.isLoadingProfile || viewModel.isLoadingInventory) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
      extendBodyBehindAppBar: true,
      appBar: AppBarFactory.build(
        title: isCashSell
            ? (isEditing ? 'Edit Cash Sell'.tr : 'New Cash Sell'.tr)
            : (isEditing ? 'Edit Invoice'.tr : 'Invoice Generator'.tr),
        onBackPress: () {
          FocusScope.of(context).unfocus();

          Future.microtask(() {
            if (mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop(
                isEditing ? true : null,
              );
            }
          });
        },
        actions: [
          if (isEditing && !isCashSell) ...[
            IconButton(
              icon: const Icon(Icons.email_rounded),
              onPressed: () => _emailInvoice(context, viewModel.invoice),
              tooltip: 'Email Invoice'.tr,
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          _backdrop(),
          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heroCard(invoice, viewModel),
                    const SizedBox(height: 16),
                    CustomSection(
                      title: 'Buyer Details'.tr,
                      icon: Icons.person_outline_rounded,
                      children: [
                        _buyerNameField(viewModel),
                        const SizedBox(height: 16),
                        _row([
                          CustomTextField(label: 'Contact Person'.tr, controller: _buyerContactPersonController, hint: 'Contact / broker name'.tr, onChanged: viewModel.updateBuyerContactPerson),
                          CustomTextField(label: 'Contact No'.tr, controller: _buyerContactNoController, hint: 'Mobile number'.tr, onChanged: viewModel.updateBuyerContactNo, keyboardType: TextInputType.phone),
                        ]),
                        const SizedBox(height: 16),
                        CustomTextField(label: 'Email'.tr, controller: _buyerEmailController, hint: 'example@mail.com'.tr, onChanged: viewModel.updateBuyerEmail, keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        CustomTextField(label: 'Buyer Address'.tr, controller: _buyerAddressController, onChanged: viewModel.updateBuyerAddress, hint: 'Full office/home address...'.tr),
                        if (!isCashSell) ...[
                          const SizedBox(height: 16),
                          _row([
                            CustomTextField(label: 'GST NO'.tr, controller: _buyerGstNoController, hint: '24XXXXX...'.tr, onChanged: viewModel.updateBuyerGstNo),
                            CustomTextField(label: 'PAN NO'.tr, controller: _buyerPanNoController, hint: 'ABCDE1234F'.tr, onChanged: viewModel.updateBuyerPanNo),
                          ]),
                          const SizedBox(height: 16),
                          _row([
                            CustomTextField(label: 'State Name'.tr, controller: _buyerStateNameController, hint: 'Gujarat'.tr, onChanged: viewModel.updateBuyerStateName),
                            CustomTextField(label: 'State Code'.tr, controller: _buyerStateCodeController, hint: '24', onChanged: viewModel.updateBuyerStateCode, keyboardType: TextInputType.number),
                          ]),
                          const SizedBox(height: 16),
                          CustomTextField(label: 'Place of Supply'.tr, controller: _placeOfSupplyController, hint: 'City name'.tr, onChanged: viewModel.updatePlaceOfSupply),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomSection(
                      title: isCashSell ? 'Cash Sell Details'.tr : 'Invoice Details'.tr,
                      icon: Icons.event_note_rounded,
                      children: [
                        _row([
                          CustomTextField(
                            label: isCashSell ? 'Entry No'.tr : 'Invoice No'.tr,
                            controller: _invoiceNoController,
                            hint: isCashSell ? 'CASH-001'.tr : 'INV-001'.tr,
                            onChanged: viewModel.updateInvoiceNo,
                          ),
                          _datePicker(isCashSell ? 'Sell Date'.tr : 'Invoice Date'.tr, invoice.invoiceDate, (d) => viewModel.updateInvoiceDate(d), context),
                        ]),
                        const SizedBox(height: 16),
                        _row([
                          CustomTextField(label: 'Terms'.tr, controller: _termsController, hint: 'Net 30'.tr, onChanged: viewModel.updateTerms),
                          _datePicker('Due Date'.tr, invoice.dueDate, (d) => viewModel.updateDueDate(d), context, firstDate: invoice.invoiceDate),
                        ]),
                        if (!isCashSell) ...[
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tax Type'.tr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _deep)),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          viewModel.updateIsIgst(false);
                                          _triggerTotalsUpdate();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: !invoice.isIgst ? Colors.white : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: !invoice.isIgst ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
                                          ),
                                          child: Column(
                                            children: [
                                              Text('SGST (Intra-State)'.tr, style: TextStyle(fontWeight: !invoice.isIgst ? FontWeight.bold : FontWeight.normal, color: !invoice.isIgst ? _deep : Colors.grey[600], fontSize: 13)),
                                              Text('CGST 0.75% + SGST 0.75%'.tr, style: TextStyle(fontSize: 10, color: !invoice.isIgst ? _accent : Colors.grey[500])),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          viewModel.updateIsIgst(true);
                                          _triggerTotalsUpdate();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: invoice.isIgst ? Colors.white : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: invoice.isIgst ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
                                          ),
                                          child: Column(
                                            children: [
                                              Text('IGST (Inter-State)'.tr, style: TextStyle(fontWeight: invoice.isIgst ? FontWeight.bold : FontWeight.normal, color: invoice.isIgst ? _deep : Colors.grey[600], fontSize: 13)),
                                              Text('IGST 1.5%'.tr, style: TextStyle(fontSize: 10, color: invoice.isIgst ? _accent : Colors.grey[500])),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomSection(
                      title: 'Items'.tr,
                      icon: Icons.diamond_outlined,
                      trailing: _addItemButton(viewModel),
                      children: [
                        ...invoice.items.asMap().entries.map((entry) {
                          return _itemCard(entry.value, entry.key, viewModel);
                        }),
                      ],
                    ),
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: CustomButton(
          label: isCashSell
              ? (viewModel.isEditing ? 'Update Cash Sell'.tr : 'Save Cash Sell'.tr)
              : (viewModel.isEditing ? 'Update & Generate'.tr : 'Generate Invoice'.tr),
          isLoading: viewModel.isGeneratingPdf || viewModel.isSaving,
          icon: isCashSell ? Icons.save_rounded : Icons.picture_as_pdf_rounded,
          onPressed: () => _generatePDF(context, viewModel),
        ),
      ),
    );
  }

  Widget _heroCard(InvoiceModel invoice, InvoiceFormViewModel viewModel) {
    final limit = viewModel.remainingTotalCarat;
    return CustomCard(
      padding: const EdgeInsets.all(18),
      gradient: const LinearGradient(colors: [_deep, _accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  viewModel.isCashSell
                      ? (viewModel.isEditing ? 'Update Cash Sell'.tr : 'Create Cash Sell'.tr)
                      : (viewModel.isEditing ? 'Update Invoice'.tr : 'Create New Invoice'.tr),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(invoice.invoiceNo.isNotEmpty ? invoice.invoiceNo : 'Draft'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _heroInfo('Stock Available'.tr, '${limit.toStringAsFixed(2)} ct'),
              _heroInfo('Items'.tr, '${invoice.items.length}'),
              _heroInfo('Current Carat'.tr, '${invoice.totalCarat.toStringAsFixed(2)} ct'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroInfo(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buyerNameField(InvoiceFormViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'Buyer Name'.tr,
          controller: _buyerNameController,
          hint: 'Search or enter buyer name'.tr,
          onChanged: viewModel.updateBuyerName,
          validator: (v) => (v == null || v.isEmpty) ? 'Required'.tr : null,
        ),
        if (viewModel.suggestedBuyers.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: viewModel.suggestedBuyers.length,
              itemBuilder: (context, index) {
                final buyer = viewModel.suggestedBuyers[index];
                return ListTile(
                  title: Text(buyer.buyerName),
                  onTap: () {
                    viewModel.selectSuggestedBuyer(buyer);
                    _updateControllersFromInvoice(viewModel.invoice);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _itemCard(InvoiceItem item, int index, InvoiceFormViewModel viewModel) {
    final caratController = _getCaratController(index, item);
    final rateController = _getRateController(index, item);
    final hsnController = _getHsnController(index, item);
    
    // Global remaining limit for ENTIRE stock
    final maxLimit = viewModel.remainingTotalCarat;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            children: [
              Text('${'Item'.tr} ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700, color: _deep)),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
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
              if (viewModel.invoice.items.length > 1)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red, size: 20),
                  onPressed: () => viewModel.removeItem(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
            ],
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'HSN Code'.tr, 
            controller: hsnController, 
            hint: '71049120', 
            fillColor: Colors.white,
            onChanged: (v) => viewModel.updateItemHsnCode(index, v),
          ),
          const SizedBox(height: 16),
          _row([
            CustomTextField(
              label: 'Carat'.tr,
              controller: caratController,
              hint: '0.00',
              fillColor: Colors.white,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (v) {
                // Temporary web-only stock bypass
                if (kIsWeb) {
                  viewModel.updateItemCarat(index, v);
                  _triggerTotalsUpdate();
                  return;
                }

                double currentVal = double.tryParse(v) ?? 0;
                double othersTotal = 0;

                for (int i = 0; i < viewModel.invoice.items.length; i++) {
                  if (i != index) {
                    othersTotal += viewModel.invoice.items[i].carat;
                  }
                }

                if (currentVal + othersTotal > maxLimit + 0.001) {
                  final allowed = (maxLimit - othersTotal).clamp(0.0, maxLimit);

                  caratController.text = allowed.toStringAsFixed(2);

                  caratController.selection = TextSelection.fromPosition(
                    TextPosition(offset: caratController.text.length),
                  );

                  viewModel.updateItemCarat(index, caratController.text);
                } else {
                  viewModel.updateItemCarat(index, v);
                }

                _triggerTotalsUpdate();
              },
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required'.tr;

                final val = double.tryParse(v) ?? 0;

                if (val <= 0) return 'Must be > 0'.tr;

                // Temporary web-only stock bypass
                if (!kIsWeb &&
                    viewModel.totalInvoiceCarat > (maxLimit + 0.001)) {
                  return 'Stock exceeded'.tr;
                }

                return null;
              },
            ),
            CustomTextField(
              label: 'Rate'.tr,
              controller: rateController,
              hint: '0.00',
              fillColor: Colors.white,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) {
                viewModel.updateItemRate(index, v);
                _triggerTotalsUpdate();
              },
              validator: (v) => (v == null || v.isEmpty) ? 'Required'.tr : null,
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Amount'.tr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('₹${(item.carat * item.rate).toStringAsFixed(2)}'.tr, style: const TextStyle(fontWeight: FontWeight.w800, color: _accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _forOtherToggle(InvoiceFormViewModel viewModel) {
    final isOn = viewModel.invoice.isForOther;
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
                    'Records only — no stock impact, excluded from Opening totals, Sales Profit and Net Profit.'.tr,
                    style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          Switch.adaptive(
            value: isOn,
            activeColor: _accent,
            onChanged: viewModel.updateIsForOther,
          ),
        ],
      ),
    );
  }

  Widget _totalsSection(InvoiceModel invoice, InvoiceFormViewModel viewModel) {
    return ValueListenableBuilder<int>(
      valueListenable: _totalsUpdateNotifier,
      builder: (context, _, __) {
        final totals = _calculateTotalsFromControllers(invoice);
        final isCashSell = viewModel.isCashSell;
        return CustomSection(
          title: 'Summary'.tr,
          icon: Icons.summarize_rounded,
          children: [
            _row([
              CustomTextField(
                label: 'Discount (%)'.tr,
                controller: _discountController,
                hint: '0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (v) {
                  viewModel.updateDiscountRate(v);
                  _triggerTotalsUpdate();
                },
              ),
              CustomTextField(
                label: 'Broker Charge (%)'.tr,
                controller: _brokerChargeController,
                hint: '0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (v) {
                  viewModel.updateBrokerChargeRate(v);
                  _triggerTotalsUpdate();
                },
              ),
            ]),
            const SizedBox(height: 12),
            CustomInfoRow(label: 'Sub Total'.tr, value: '₹${totals['totalAmount'.tr]!.toStringAsFixed(2)}'),
            if (invoice.discountRate > 0)
              CustomInfoRow(
                label: '${'Discount'.tr} (${invoice.discountRate}%)',
                value: '- ₹${totals['discountAmount'.tr]!.toStringAsFixed(2)}',
              ),
            if (invoice.discountRate > 0)
              CustomInfoRow(
                label: 'Taxable Amount'.tr,
                value: '₹${totals['taxableAmount'.tr]!.toStringAsFixed(2)}',
              ),
            if (!isCashSell) ...[
              if (!invoice.isIgst) ...[
                CustomInfoRow(label: 'CGST (${invoice.cgstRate}%)', value: '₹${totals['cgstAmount'.tr]!.toStringAsFixed(2)}'),
                CustomInfoRow(label: 'SGST (${invoice.sgstRate}%)', value: '₹${totals['sgstAmount'.tr]!.toStringAsFixed(2)}'),
              ] else ...[
                CustomInfoRow(label: 'IGST (${invoice.igstRate}%)', value: '₹${totals['igstAmount'.tr]!.toStringAsFixed(2)}'),
              ],
            ],
            if (invoice.brokerChargeRate > 0)
              CustomInfoRow(
                label: '${'Broker Charge'.tr} (${invoice.brokerChargeRate}%)',
                value: '- ₹${totals['brokerChargeAmount'.tr]!.toStringAsFixed(2)}',
              ),
            const Divider(height: 24),
            CustomInfoRow(label: 'Grand Total'.tr, value: '₹${totals['grandTotal'.tr]!.toStringAsFixed(2)}', isBold: true, fontSize: 16, valueColor: _deep),
          ],
        );
      },
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

  Widget _datePicker(String label, DateTime value, Function(DateTime) onPick, BuildContext context, {DateTime? firstDate}) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: value, firstDate: firstDate ?? DateTime(2020), lastDate: DateTime(2030));
        if (d != null) onPick(d);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _deep)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB), width: 1)),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: _accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('dd MMM yyyy'.tr).format(value), 
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addItemButton(InvoiceFormViewModel viewModel) {
    return TextButton.icon(
      onPressed: viewModel.addItem,
      icon: const Icon(Icons.add_circle_outline, size: 20),
      label: Text('Add Item'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Map<String, double> _calculateTotalsFromControllers(InvoiceModel invoice) {
    double totalCarat = 0.0;
    double totalAmount = 0.0;
    for (int i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final carat = double.tryParse(_caratControllers[i]?.text ?? '') ?? item.carat;
      final rate = double.tryParse(_rateControllers[i]?.text ?? '') ?? item.rate;
      totalCarat += carat;
      totalAmount += carat * rate;
    }
    final discount = totalAmount * (invoice.discountRate / 100);
    final taxable = totalAmount - discount;
    final brokerCharge = taxable * (invoice.brokerChargeRate / 100);
    final cgst = invoice.isIgst ? 0.0 : taxable * (invoice.cgstRate / 100);
    final sgst = invoice.isIgst ? 0.0 : taxable * (invoice.sgstRate / 100);
    final igst = invoice.isIgst ? taxable * (invoice.igstRate / 100) : 0.0;
    return {
      'totalCarat'.tr: totalCarat,
      'totalAmount'.tr: totalAmount,
      'discountAmount'.tr: discount,
      'taxableAmount'.tr: taxable,
      'brokerChargeAmount'.tr: brokerCharge,
      'cgstAmount'.tr: cgst,
      'sgstAmount'.tr: sgst,
      'igstAmount'.tr: igst,
      'grandTotal'.tr: taxable + cgst + sgst + igst - brokerCharge,
    };
  }

  TextEditingController _getCaratController(int index, InvoiceItem item) {
    if (!_caratControllers.containsKey(index)) {
      _caratControllers[index] = TextEditingController(text: item.carat > 0 ? item.carat.toString() : '');
    }
    return _caratControllers[index]!;
  }

  TextEditingController _getRateController(int index, InvoiceItem item) {
    if (!_rateControllers.containsKey(index)) {
      _rateControllers[index] = TextEditingController(text: item.rate > 0 ? item.rate.toString() : '');
    }
    return _rateControllers[index]!;
  }

  TextEditingController _getHsnController(int index, InvoiceItem item) {
    if (!_hsnControllers.containsKey(index)) {
      _hsnControllers[index] = TextEditingController(text: item.hsnCode);
    }
    return _hsnControllers[index]!;
  }

  Future<void> _generatePDF(BuildContext context, InvoiceFormViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;
    
    // Hard-block check
    if (viewModel.totalInvoiceCarat > (viewModel.remainingTotalCarat + 0.001)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'Total carat exceeds global stock'.tr} (${viewModel.remainingTotalCarat.toStringAsFixed(2)})'),
          backgroundColor: Colors.red
        )
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
        // Save complete = natural transition. Show an interstitial (subject
        // to the AdsService frequency cap) THEN pop. We don't await the ad'.trs
        // dismissal — pop immediately so the user sees the updated list, and
        // the ad surfaces over it. This is the AdMob-recommended pattern for
        // post-action interstitials.
        AdsService.instance.maybeShowInterstitial();
        Navigator.pop(context, true);
      } else if (viewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.errorMessage!), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _emailInvoice(BuildContext context, InvoiceModel invoice) async {
    await EmailService.shareInvoiceViaEmail(invoice);
  }

  Widget _backdrop() {
    return Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE7EEFF), Color(0xFFF9FBFF)])));
  }
}
