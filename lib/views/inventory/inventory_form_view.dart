import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/inventory_model.dart';
import '../../services/ads_service.dart';
import '../../viewmodels/inventory_form_viewmodel.dart';

class InventoryFormView extends StatelessWidget {
  final InventoryModel? item;

  const InventoryFormView({super.key, this.item});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InventoryFormViewModel(item: item),
      child: const _InventoryFormViewContent(),
    );
  }
}

class _InventoryFormViewContent extends StatefulWidget {
  const _InventoryFormViewContent();

  @override
  State<_InventoryFormViewContent> createState() => _InventoryFormViewContentState();
}

class _InventoryFormViewContentState extends State<_InventoryFormViewContent> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final Color _accent = const Color(0xFF4F8AF4);
  final Color _deepAccent = const Color(0xFF1E3C72);
  final Color _cardColor = Colors.white;
  final _invoiceNumberController = TextEditingController();
  final _caratController = TextEditingController();
  final _pricePerCaratController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedInvoiceDate;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<InventoryFormViewModel>();
    _invoiceNumberController.text = viewModel.item.invoiceNumber;
    _selectedInvoiceDate = viewModel.item.invoiceDate;
    _caratController.text = viewModel.item.carat.toString();
    _pricePerCaratController.text = viewModel.item.pricePerCarat.toString();
    _descriptionController.text = viewModel.item.description ?? '';
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _caratController.dispose();
    _pricePerCaratController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryFormViewModel>(
      builder: (context, viewModel, _) {
        final item = viewModel.item;
        final isEditing = viewModel.isEditing;
        final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
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
                    Icons.diamond_rounded,
                    color: _accent,
                  ),
                ),
                const SizedBox(width: 10),
                Text(isEditing ? 'Edit Inventory' : 'Add Inventory'),
              ],
            ),
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
                        _buildHeroCard(item, isEditing, currencyFormat),
                        const SizedBox(height: 16),
                        _buildSection(
                          title: 'Invoice Details',
                          icon: Icons.receipt_long_rounded,
                          children: [
                            _buildTextField(
                              'Invoice Number',
                              item.invoiceNumber,
                              (value) {
                                viewModel.updateInvoiceNumber(value);
                                _invoiceNumberController.text = value;
                              },
                              controller: _invoiceNumberController,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter invoice number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildDateField(
                              'Invoice Date',
                              _selectedInvoiceDate ?? item.invoiceDate,
                              (date) {
                                setState(() {
                                  _selectedInvoiceDate = date;
                                });
                                viewModel.updateInvoiceDate(date);
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    'Carat',
                                    item.carat.toString(),
                                    (value) {
                                      viewModel.updateCarat(value);
                                      _caratController.text = value;
                                    },
                                    controller: _caratController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      final carat = double.tryParse(value);
                                      if (carat == null || carat <= 0) {
                                        return 'Invalid carat';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    'Price/Carat (₹)',
                                    item.pricePerCarat.toString(),
                                    (value) {
                                      viewModel.updatePricePerCarat(value);
                                      _pricePerCaratController.text = value;
                                    },
                                    controller: _pricePerCaratController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      final price = double.tryParse(value);
                                      if (price == null || price < 0) {
                                        return 'Invalid price';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              'Description (Optional)',
                              item.description ?? '',
                              (value) {
                                viewModel.updateDescription(value);
                                _descriptionController.text = value;
                              },
                              controller: _descriptionController,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            _buildTotalCard(item, currencyFormat),
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
                  onPressed: viewModel.isSaving
                      ? null
                      : () => _saveItem(context, viewModel),
                  icon: viewModel.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(isEditing ? Icons.save_rounded : Icons.add_rounded),
                  label: Text(
                    viewModel.isSaving
                        ? 'Saving...'
                        : isEditing
                            ? 'Update Inventory'
                            : 'Add to Inventory',
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
      },
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

  Widget _buildHeroCard(InventoryModel item, bool isEditing, NumberFormat currencyFormat) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent,
            _deepAccent,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.diamond_rounded,
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
                      isEditing ? 'Edit Inventory Item' : 'New Inventory Item',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEditing
                          ? 'Added: ${dateFormat.format(item.addedDate)}'
                          : 'Add new diamond stock',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _accent, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
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

  Widget _buildTextField(
    String label,
    String value,
    Function(String) onChanged, {
    TextEditingController? controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Enter $label',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accent, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F7FB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildDateField(
    String label,
    DateTime initialDate,
    Function(DateTime) onDateSelected,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: _accent,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: _deepAccent,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: _accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(initialDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3C72),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(InventoryModel item, NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.green.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalRow('Total Price', currencyFormat.format(item.totalPrice), false),
          const SizedBox(height: 8),
          _buildTotalRow('CGST @ ${item.cgstRate.toStringAsFixed(2)}%', currencyFormat.format(item.cgstAmount), false),
          const SizedBox(height: 8),
          _buildTotalRow('SGST @ ${item.sgstRate.toStringAsFixed(2)}%', currencyFormat.format(item.sgstAmount), false),
          const Divider(height: 20),
          _buildTotalRow('Total with CGST & SGST', currencyFormat.format(item.totalWithGst), true),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.currency_rupee_rounded,
                color: Colors.green.shade800,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            color: Colors.grey[700],
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 22 : 16,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: Colors.green.shade800,
          ),
        ),
      ],
    );
  }

  Future<void> _saveItem(BuildContext context, InventoryFormViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await viewModel.saveItem();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.isEditing
              ? 'Inventory item updated successfully'
              : 'Inventory item added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // Frequency-capped interstitial on a natural transition.
      AdsService.instance.maybeShowInterstitial();
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${viewModel.errorMessage ?? 'Failed to save'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

