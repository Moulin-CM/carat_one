import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/invoice_model.dart';
import '../../viewmodels/invoice_form_viewmodel.dart';

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

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InvoiceFormViewModel>();
    final invoice = viewModel.invoice;
    final isEditing = viewModel.isEditing;

    if (viewModel.isLoadingProfile) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.list_rounded),
              onPressed: () => Navigator.pop(context, true),
              tooltip: 'Back to List',
            ),
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
                        _buildTotalCard(invoice),
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
                  onPressed: () => viewModel.removeItem(index),
                ),
            ],
          ),
          const SizedBox(height: 4),
          _buildTextField('Particular', item.particular, (v) => viewModel.updateItemParticular(index, v)),
          const SizedBox(height: 10),
          _buildResponsiveGrid([
            _buildTextField('HSN Code', item.hsnCode, (v) => viewModel.updateItemHsnCode(index, v)),
            _buildTextField(
              'Carat',
              item.carat.toString(),
              (v) => viewModel.updateItemCarat(index, v),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            _buildTextField(
              'Rate (Rs)',
              item.rate.toString(),
              (v) => viewModel.updateItemRate(index, v),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Amount', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('₹${item.amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w700, color: _deepAccent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(InvoiceModel invoice) {
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
          _buildTotalRow('Total Carat', invoice.totalCarat.toStringAsFixed(2)),
          _buildTotalRow('Total Amount', '₹${invoice.totalAmount.toStringAsFixed(2)}'),
          _buildTotalRow('CGST @ ${invoice.cgstRate}%', '₹${invoice.cgstAmount.toStringAsFixed(2)}'),
          _buildTotalRow('SGST @ ${invoice.sgstRate}%', '₹${invoice.sgstAmount.toStringAsFixed(2)}'),
          _buildTotalRow('IGST @ ${invoice.igstRate}%', '₹${invoice.igstAmount.toStringAsFixed(2)}'),
          const Divider(),
          _buildTotalRow('Grand Total', '₹${invoice.grandTotal.toStringAsFixed(2)}', isBold: true),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surfaceTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'In words: ${invoice.amountInWords}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildAddItemButton(InvoiceFormViewModel viewModel) {
    return TextButton.icon(
      onPressed: viewModel.addItem,
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
}

