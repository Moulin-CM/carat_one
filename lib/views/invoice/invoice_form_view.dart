import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/invoice_model.dart';
import '../../viewmodels/invoice_form_viewmodel.dart';
import '../../viewmodels/reminder_viewmodel.dart';
import '../../services/email_service.dart';
import '../../services/notification_service.dart';

class InvoiceFormView extends StatelessWidget {
  final InvoiceModel? invoice;

  const InvoiceFormView({super.key, this.invoice});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InvoiceFormViewModel(invoice: invoice),
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
  final Color _accent = const Color(0xFF4F8AF4);
  final Color _deepAccent = const Color(0xFF1E3C72);
  final Color _cardColor = Colors.white;
  final Color _surfaceTint = const Color(0xFFF5F7FB);
  final Map<int, TextEditingController> _caratControllers = {};
  final Map<int, TextEditingController> _hsnControllers = {};
  final ValueNotifier<int> _totalsUpdateNotifier = ValueNotifier<int>(0);

  @override
  void dispose() {
    for (var controller in _caratControllers.values) {
      controller.dispose();
    }
    for (var controller in _hsnControllers.values) {
      controller.dispose();
    }
    _totalsUpdateNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  // Trigger totals update
  void _triggerTotalsUpdate() {
    _totalsUpdateNotifier.value = _totalsUpdateNotifier.value + 1;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InvoiceFormViewModel>();
    final invoice = viewModel.invoice;
    final isEditing = viewModel.isEditing;

    if (viewModel.isLoadingProfile || viewModel.isLoadingInventory) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    // Ensure controllers exist for all items and trigger initial totals update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        for (int i = 0; i < invoice.items.length; i++) {
          final item = invoice.items[i];
          _getCaratController(i, item, item.inventoryItemId);
        }
        _triggerTotalsUpdate();
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context, isEditing ? true : null),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cardColor.withOpacity(0.7),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: _accent,
              ),
            ),
            const SizedBox(width: 10),
            Text(isEditing ? 'Edit Invoice' : 'Invoice Generator'),
          ],
        ),
        actions: [
          if (isEditing) ...[
            IconButton(
              icon: const Icon(Icons.notifications_rounded),
              onPressed: () => _showReminderDialog(context, viewModel),
              tooltip: 'Set Reminder',
            ),
            IconButton(
              icon: const Icon(Icons.email_rounded),
              onPressed: () => _emailInvoice(context, viewModel.invoice),
              tooltip: 'Email Invoice',
            ),
            IconButton(
              icon: const Icon(Icons.list_rounded),
              onPressed: () => Navigator.pop(context, true),
              tooltip: 'Back to List',
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCard(invoice, isEditing),
                    const SizedBox(height: 16),
                    _buildSection(
                      title: 'Buyer Details',
                      icon: Icons.person_outline_rounded,
                      children: [
                        _buildResponsiveGrid([
                          _buildTextField('Buyer Name', invoice.buyerName, viewModel.updateBuyerName),
                          _buildTextField('Contact Person', invoice.buyerContactPerson, viewModel.updateBuyerContactPerson),
                          _buildTextField('Contact No', invoice.buyerContactNo, viewModel.updateBuyerContactNo, keyboardType: TextInputType.phone),
                          _buildTextField('Email', invoice.buyerEmail, viewModel.updateBuyerEmail, keyboardType: TextInputType.emailAddress),
                        ]),
                        const SizedBox(height: 12),
                        _buildTextField('Buyer Address', invoice.buyerAddress, viewModel.updateBuyerAddress, maxLines: 3),
                        const SizedBox(height: 12),
                        _buildResponsiveGrid([
                          _buildTextField('GST NO', invoice.buyerGstNo, viewModel.updateBuyerGstNo),
                          _buildTextField('PAN NO', invoice.buyerPanNo, viewModel.updateBuyerPanNo),
                          _buildTextField('VAT NO', invoice.buyerVatNo, viewModel.updateBuyerVatNo),
                          _buildTextField('CST NO', invoice.buyerCstNo, viewModel.updateBuyerCstNo),
                        ]),
                        const SizedBox(height: 12),
                        _buildResponsiveGrid([
                          _buildTextField('State Name', invoice.buyerStateName, viewModel.updateBuyerStateName),
                          _buildTextField('State Code', invoice.buyerStateCode, viewModel.updateBuyerStateCode, keyboardType: TextInputType.number),
                          _buildTextField('Place of Supply', invoice.placeOfSupply, viewModel.updatePlaceOfSupply),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildSection(
                      title: 'Invoice Details',
                      icon: Icons.event_note_rounded,
                      children: [
                        _buildResponsiveGrid([
                          _buildTextField('Invoice No', invoice.invoiceNo, viewModel.updateInvoiceNo),
                          _buildDateField('Invoice Date', invoice.invoiceDate, viewModel.updateInvoiceDate),
                          _buildTextField('Terms', invoice.terms, viewModel.updateTerms),
                          _buildDateField('Due Date', invoice.dueDate, viewModel.updateDueDate),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildSection(
                      title: 'Items',
                      icon: Icons.widgets_outlined,
                      trailing: _buildAddItemButton(viewModel),
                      children: [
                        ...invoice.items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return _buildItemCard(item, index, viewModel);
                        }),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildSection(
                      title: 'Totals',
                      icon: Icons.summarize_rounded,
                      children: [
                        _buildTotalCard(invoice, viewModel),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: viewModel.isGeneratingPdf || viewModel.isSaving
                  ? null
                  : () => _generatePDF(context, viewModel),
              icon: viewModel.isGeneratingPdf || viewModel.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded),
              label: Text(
                viewModel.isGeneratingPdf || viewModel.isSaving
                    ? 'Generating...'
                    : 'Generate PDF Invoice',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                elevation: 6,
                shadowColor: _accent.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackdrop() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE7EEFF),
            Color(0xFFF9FBFF),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _blurredCircle(size: 220, color: _accent.withOpacity(0.25)),
          ),
          Positioned(
            top: 160,
            left: -100,
            child: _blurredCircle(size: 200, color: _deepAccent.withOpacity(0.15)),
          ),
        ],
      ),
    );
  }

  Widget _blurredCircle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildHeroCard(InvoiceModel invoice, bool isEditing) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [_deepAccent, _accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 360;

              final leading = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flash_on_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Continue editing' : 'Create invoice',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEditing ? 'Update and regenerate' : 'Start with buyer details',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final badge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_outlined, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      invoice.invoiceNo.isNotEmpty ? invoice.invoiceNo : 'Draft',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leading,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: badge),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: leading),
                  const SizedBox(width: 8),
                  badge,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroPill('Invoice Date', DateFormat('dd MMM yyyy').format(invoice.invoiceDate)),
              _heroPill('Due', DateFormat('dd MMM yyyy').format(invoice.dueDate)),
              _heroPill('Items', '${invoice.items.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.24)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    List<Widget> children = const [],
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _surfaceTint,
                ),
                child: Icon(icon, color: _accent),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildResponsiveGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 560;
        final itemWidth = isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children.map((child) => SizedBox(width: itemWidth, child: child)).toList(),
        );
      },
    );
  }

  Widget _buildTextField(
    String label,
    String value,
    Function(String) onChanged, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: value,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: _surfaceTint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _accent.withOpacity(0.9), width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime value, Function(DateTime) onChanged) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: _surfaceTint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _accent.withOpacity(0.9), width: 1.4),
          ),
          suffixIcon: Icon(Icons.calendar_today_rounded, color: _accent),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        ),
        child: Text(DateFormat('dd MMM yyyy').format(value)),
      ),
    );
  }

  Widget _buildItemCard(InvoiceItem item, int index, InvoiceFormViewModel viewModel) {
    final invoice = viewModel.invoice;
    // Get the carat controller for this item to use in ValueListenableBuilder
    final caratController = _getCaratController(index, item, item.inventoryItemId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Item ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
              if (invoice.items.length > 1)
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.red),
                  onPressed: () {
                    viewModel.removeItem(index);
                    // Trigger totals update when item is removed
                    _triggerTotalsUpdate();
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          _buildInventoryDropdown(index, viewModel),
          const SizedBox(height: 10),
          _buildResponsiveGrid([
            _buildTextField('HSN Code', item.hsnCode, (v) => viewModel.updateItemHsnCode(index, v)),
            _buildCaratField(index, item, viewModel),
            _buildRateField(index, item, viewModel),
          ]),
          const SizedBox(height: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: caratController,
            builder: (context, value, child) {
              // Calculate amount in real-time from controller value
              final caratValue = double.tryParse(value.text) ?? item.carat;
              final calculatedAmount = caratValue * item.rate;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '₹${calculatedAmount.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.w700, color: _deepAccent),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Calculate totals from controllers in real-time
  Map<String, double> _calculateTotalsFromControllers(InvoiceModel invoice) {
    double totalCarat = 0.0;
    double totalAmount = 0.0;

    for (int i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final controller = _caratControllers[i];
      
      // Use controller value if available, otherwise use item.carat
      double carat = item.carat;
      if (controller != null) {
        if (controller.text.isNotEmpty && controller.text.trim().isNotEmpty) {
          final parsedCarat = double.tryParse(controller.text);
          if (parsedCarat != null && parsedCarat >= 0) {
            carat = parsedCarat;
          }
        } else if (controller.text.isEmpty) {
          carat = 0.0;
        }
      }
      
      // Only calculate if rate is valid
      if (item.rate > 0) {
        totalCarat += carat;
        totalAmount += carat * item.rate;
      }
    }

    final cgstAmount = totalAmount * (invoice.cgstRate / 100);
    final sgstAmount = totalAmount * (invoice.sgstRate / 100);
    final igstAmount = totalAmount * (invoice.igstRate / 100);
    final grandTotal = totalAmount + cgstAmount + sgstAmount + igstAmount;

    return {
      'totalCarat': totalCarat,
      'totalAmount': totalAmount,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'igstAmount': igstAmount,
      'grandTotal': grandTotal,
    };
  }

  Widget _buildTotalCard(InvoiceModel invoice, InvoiceFormViewModel viewModel) {
    // Use ValueListenableBuilder to listen to totals update notifier
    // This will rebuild totals whenever any carat field changes
    return ValueListenableBuilder<int>(
      valueListenable: _totalsUpdateNotifier,
      builder: (context, updateCount, child) {
        final totals = _calculateTotalsFromControllers(invoice);
        final grandTotal = totals['grandTotal']!;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, _surfaceTint],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTotalRow('Total Carat', totals['totalCarat']!.toStringAsFixed(2)),
              _buildTotalRow('Total Amount', '₹${totals['totalAmount']!.toStringAsFixed(2)}'),
              _buildTotalRow('CGST @ ${invoice.cgstRate}%', '₹${totals['cgstAmount']!.toStringAsFixed(2)}'),
              _buildTotalRow('SGST @ ${invoice.sgstRate}%', '₹${totals['sgstAmount']!.toStringAsFixed(2)}'),
              _buildTotalRow('IGST @ ${invoice.igstRate}%', '₹${totals['igstAmount']!.toStringAsFixed(2)}'),
              const Divider(),
              _buildTotalRow('Grand Total', '₹${grandTotal.toStringAsFixed(2)}', isBold: true),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surfaceTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'In words: ${_numberToWords(grandTotal.toInt())}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Helper method to convert number to words (same as in InvoiceModel)
  String _numberToWords(int number) {
    if (number == 0) return 'Zero Only';

    final ones = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
      'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    final tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

    String convert(int n) {
      if (n < 20) return ones[n];
      if (n < 100) return '${tens[n ~/ 10]} ${ones[n % 10]}'.trim();
      if (n < 1000) {
        final hundred = n ~/ 100;
        final remainder = n % 100;
        return '${ones[hundred]} Hundred${remainder > 0 ? ' ${convert(remainder)}' : ''}';
      }
      if (n < 100000) {
        final thousand = n ~/ 1000;
        final remainder = n % 1000;
        return '${convert(thousand)} Thousand${remainder > 0 ? ' ${convert(remainder)}' : ''}';
      }
      if (n < 10000000) {
        final lac = n ~/ 100000;
        final remainder = n % 100000;
        return '${convert(lac)} Lac${remainder > 0 ? ' ${convert(remainder)}' : ''}';
      }
      return '';
    }

    return '${convert(number)} Only';
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildInventoryDropdown(int index, InvoiceFormViewModel viewModel) {
    final availableItems = viewModel.getAvailableInventoryItems(index);
    final selectedInventory = viewModel.getSelectedInventoryItem(index);
    final currentItem = viewModel.invoice.items[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stock (Particular)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _surfaceTint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonFormField<String>(
            value: currentItem.inventoryItemId,
            decoration: InputDecoration(
              filled: true,
              fillColor: _surfaceTint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _accent.withOpacity(0.9), width: 1.4),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            hint: Text(availableItems.isEmpty ? 'No stocks available' : 'Select Stock'),
            isExpanded: true, // Important: prevents overflow
            items: availableItems.isEmpty
                ? null
                : availableItems.map((inventoryItem) {
                    return DropdownMenuItem<String>(
                      value: inventoryItem.id,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 50),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              inventoryItem.diamondName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${inventoryItem.carat.toStringAsFixed(2)} ct • ₹${inventoryItem.pricePerCarat.toStringAsFixed(2)}/ct',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            selectedItemBuilder: (BuildContext context) {
              // Custom display for selected item to prevent overflow
              return availableItems.map((inventoryItem) {
                return Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    inventoryItem.diamondName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                );
              }).toList();
            },
            onChanged: availableItems.isEmpty
                ? null
                : (value) {
                    viewModel.selectInventoryItem(index, value);
                    // Trigger totals update when stock is selected (rate changes)
                    _triggerTotalsUpdate();
                  },
          ),
        ),
        if (availableItems.isEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No stocks available. Please add stocks in Inventory first.',
                    style: TextStyle(fontSize: 12, color: Colors.orange[700], fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (selectedInventory != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _accent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: _accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Max available: ${viewModel.getMaxCaratForItem(index).toStringAsFixed(2)} ct',
                    style: TextStyle(fontSize: 12, color: _accent, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  TextEditingController _getCaratController(int index, InvoiceItem item, String? inventoryItemId) {
    final controllerKey = '${index}_${inventoryItemId ?? 'none'}';
    
    // Create new controller if index or inventory item changed
    if (!_caratControllers.containsKey(index) || 
        _caratControllers[index]!.text.isEmpty ||
        (inventoryItemId != null && !_caratControllers.containsKey(index))) {
      final currentCarat = item.carat.toStringAsFixed(item.carat == item.carat.roundToDouble() ? 0 : 2);
      _caratControllers[index]?.dispose(); // Dispose old controller if exists
      _caratControllers[index] = TextEditingController(text: currentCarat);
    } else {
      // Update controller value only if item carat changed externally (e.g., from stock selection)
      // but only if controller text doesn't match and we're not currently editing
      final currentCarat = item.carat.toStringAsFixed(item.carat == item.carat.roundToDouble() ? 0 : 2);
      final controller = _caratControllers[index]!;
      // Only update if the values are significantly different (not just formatting)
      final controllerValue = double.tryParse(controller.text) ?? 0.0;
      final itemValue = item.carat;
      if ((controllerValue - itemValue).abs() > 0.001 && !controller.selection.isValid) {
        controller.text = currentCarat;
      }
    }
    return _caratControllers[index]!;
  }

  Widget _buildCaratField(int index, InvoiceItem item, InvoiceFormViewModel viewModel) {
    final maxCarat = viewModel.getMaxCaratForItem(index);
    final selectedInventory = viewModel.getSelectedInventoryItem(index);
    final caratController = _getCaratController(index, item, item.inventoryItemId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: ValueKey('carat_field_${index}_${item.inventoryItemId ?? 'none'}'), // Stable key - only changes when stock changes
          controller: caratController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          enabled: selectedInventory != null,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (v) {
            // Update viewModel - it updates the value without notifying listeners
            // This prevents keyboard dismissal on every keystroke
            viewModel.updateItemCarat(index, v);
            
            // Trigger totals update in real-time
            _triggerTotalsUpdate();
            
            // Handle clamping if value exceeds max
            final carat = double.tryParse(v) ?? 0.0;
            if (selectedInventory != null && carat > maxCarat) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _caratControllers.containsKey(index)) {
                  final clampedValue = maxCarat.toStringAsFixed(2);
                  if (caratController.text != clampedValue) {
                    final cursorPos = caratController.selection.base.offset;
                    caratController.text = clampedValue;
                    final newCursorPos = (cursorPos - 1).clamp(0, clampedValue.length);
                    caratController.selection = TextSelection.collapsed(offset: newCursorPos);
                    viewModel.updateItemCarat(index, clampedValue);
                    _triggerTotalsUpdate();
                  }
                }
              });
            }
          },
          onEditingComplete: () {
            // Finalize when user finishes editing (e.g., presses done)
            viewModel.finalizeItemCarat(index);
          },
          onFieldSubmitted: (_) {
            // Finalize when user submits field
            viewModel.finalizeItemCarat(index);
          },
          decoration: InputDecoration(
            labelText: 'Carat${selectedInventory != null ? ' (Max: ${maxCarat.toStringAsFixed(2)})' : ''}',
            filled: true,
            fillColor: selectedInventory != null ? _surfaceTint : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _accent.withOpacity(0.9), width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1.4),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            suffixIcon: selectedInventory != null && item.carat > 0
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      caratController.text = '0';
                      caratController.selection = TextSelection.collapsed(offset: 1);
                      viewModel.updateItemCarat(index, '0');
                      _triggerTotalsUpdate();
                    },
                    tooltip: 'Clear',
                  )
                : null,
            helperText: selectedInventory != null && maxCarat > 0
                ? 'Enter carat (0 - ${maxCarat.toStringAsFixed(2)})'
                : 'Select a stock first',
            helperStyle: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          validator: (value) {
            if (selectedInventory == null) {
              return 'Please select a stock first';
            }
            if (value == null || value.isEmpty || value.trim().isEmpty) {
              return 'Please enter carat';
            }
            final carat = double.tryParse(value) ?? 0;
            if (carat <= 0) {
              return 'Carat must be greater than 0';
            }
            if (carat > maxCarat) {
              return 'Carat cannot exceed ${maxCarat.toStringAsFixed(2)} ct';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRateField(int index, InvoiceItem item, InvoiceFormViewModel viewModel) {
    final selectedInventory = viewModel.getSelectedInventoryItem(index);
    final rate = item.rate > 0 ? item.rate : (selectedInventory?.pricePerCarat ?? 0.0);
    
    // Use a key to force rebuild when rate or inventoryItemId changes
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: ValueKey('rate_${index}_${rate}_${item.inventoryItemId}'),
          initialValue: rate.toStringAsFixed(2),
          enabled: false, // Read-only
          style: TextStyle(
            color: rate > 0 ? Colors.grey[800] : Colors.grey[400],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            labelText: 'Rate (Rs/Carat)',
            filled: true,
            fillColor: rate > 0 ? Colors.grey[100] : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            prefixIcon: Icon(
              Icons.currency_rupee_rounded,
              size: 20,
              color: rate > 0 ? Colors.grey[700] : Colors.grey[400],
            ),
            helperText: rate > 0 ? 'Auto-filled from inventory' : 'Select a stock to see rate',
            helperStyle: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  double _calculateAmountFromCarat(String caratText, double rate) {
    final carat = double.tryParse(caratText) ?? 0.0;
    return carat * rate;
  }

  Widget _buildAddItemButton(InvoiceFormViewModel viewModel) {
    return TextButton.icon(
      onPressed: () {
        viewModel.addItem();
        // Trigger totals update when item is added
        _triggerTotalsUpdate();
      },
      icon: Icon(Icons.add_circle_rounded, color: _accent),
      label: Text(
        'Add Item',
        style: TextStyle(color: _accent, fontWeight: FontWeight.w700),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        backgroundColor: _surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _generatePDF(BuildContext context, InvoiceFormViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final success = await viewModel.generateAndSaveInvoice();

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated and saved successfully!')),
        );
        
        // Ask if user wants to email the invoice
        final currentInvoice = viewModel.invoice;
        if (currentInvoice.buyerEmail.isNotEmpty) {
          final emailInvoice = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Email Invoice?'),
              content: Text(
                'Would you like to email this invoice to ${currentInvoice.buyerEmail}?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Later'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: _accent),
                  child: const Text('Email Now'),
                ),
              ],
            ),
          );
          
          if (emailInvoice == true && context.mounted) {
            await _emailInvoice(context, currentInvoice);
          }
        }
        
        if (!viewModel.isEditing) {
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Error generating PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _emailInvoice(BuildContext context, InvoiceModel invoice) async {
    try {
      await EmailService.shareInvoiceViaEmail(invoice);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening email client...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showReminderDialog(BuildContext context, InvoiceFormViewModel viewModel) async {
    final invoice = viewModel.invoice;
    final reminderViewModel = ReminderViewModel();
    final existingReminders = await reminderViewModel.getInvoiceReminders(invoice.id!);
    
    DateTime selectedDate = invoice.dueDate.subtract(const Duration(days: 1));
    if (selectedDate.isBefore(DateTime.now())) {
      selectedDate = DateTime.now().add(const Duration(hours: 1));
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notifications_active_rounded, color: Color(0xFF4F8AF4)),
              SizedBox(width: 8),
              Text('Set Reminder'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (existingReminders.isNotEmpty) ...[
                  const Text(
                    'Active Reminders:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...existingReminders.map((reminder) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reminder: ${DateFormat('dd MMM yyyy, hh:mm a').format(reminder.reminderDate)}',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () async {
                            await reminderViewModel.cancelReminder(reminder.notificationId);
                            final updated = await reminderViewModel.getInvoiceReminders(invoice.id!);
                            setState(() {
                              // Refresh dialog
                            });
                            if (context.mounted) {
                              Navigator.pop(context);
                              _showReminderDialog(context, viewModel);
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Reminder Date & Time:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: invoice.dueDate,
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (time != null) {
                        setState(() {
                          selectedDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(selectedDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Due Date: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await reminderViewModel.setReminder(invoice, selectedDate);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Reminder set successfully!'
                            : reminderViewModel.errorMessage ?? 'Failed to set reminder',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F8AF4)),
              child: const Text('Set Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}

