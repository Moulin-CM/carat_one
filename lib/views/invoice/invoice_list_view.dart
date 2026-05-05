import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/invoice_model.dart';
import '../../viewmodels/invoice_list_viewmodel.dart';
import '../../services/email_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/sell_options_sheet.dart';
import 'invoice_form_view.dart';
import 'invoice_details_view.dart';

class InvoiceListView extends StatelessWidget {
  const InvoiceListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InvoiceListViewModel()..loadInvoices(),
      child: const _InvoiceListViewContent(),
    );
  }
}

class _InvoiceListViewContent extends StatefulWidget {
  const _InvoiceListViewContent();

  @override
  State<_InvoiceListViewContent> createState() => _InvoiceListViewContentState();
}

class _InvoiceListViewContentState extends State<_InvoiceListViewContent> {
  final Color _accent = const Color(0xFF4F8AF4);
  final Color _deepAccent = const Color(0xFF1E3C72);
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InvoiceListViewModel>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.8),
                ),
                child: Icon(Icons.receipt_long_rounded, color: _accent),
              ),
              const SizedBox(width: 10),
              const Text('Generated Invoices'),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => viewModel.loadInvoices(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _buildOpeningSummary(context, viewModel),
                _buildSearchAndFilter(context, viewModel),
                Expanded(
                  child: viewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : viewModel.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: () => viewModel.loadInvoices(),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                                itemCount: viewModel.invoices.length,
                                itemBuilder: (context, index) => _buildInvoiceCard(context, viewModel.invoices[index], viewModel),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startNewSell(context, viewModel),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Sell', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 8,
              shadowColor: _accent.withOpacity(0.4),
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
            top: -100,
            right: -80,
            child: _blurredCircle(220, _accent.withOpacity(0.22)),
          ),
          Positioned(
            top: 140,
            left: -90,
            child: _blurredCircle(200, _deepAccent.withOpacity(0.12)),
          ),
        ],
      ),
    );
  }

  Widget _blurredCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildOpeningSummary(
      BuildContext context, InvoiceListViewModel viewModel) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final caratFmt = NumberFormat('#,##0.00');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF4F8AF4)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _yearEndBadge(context, viewModel),
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  'Opening Carats',
                  '${caratFmt.format(viewModel.openingSellCarat)} ct',
                  Icons.diamond_rounded,
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: _summaryTile(
                  'Opening Amount',
                  fmt.format(viewModel.openingSellAmount),
                  Icons.currency_rupee_rounded,
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: _summaryTile(
                  'Outstanding',
                  '${caratFmt.format(viewModel.outstandingSellCarat)} ct',
                  Icons.balance_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value, IconData icon,
      {bool editable = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            if (editable) ...[
              const SizedBox(width: 3),
              const Icon(Icons.edit_rounded, color: Colors.white54, size: 11),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
            textAlign: TextAlign.center),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 9),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _yearEndBadge(BuildContext context, InvoiceListViewModel vm) {
    final end = vm.yearEndDate;
    final label = end == null
        ? 'Set Year End'
        : 'FY End: ${DateFormat('dd MMM yyyy').format(end)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => _pickYearEnd(context, vm),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_rounded,
                      color: Colors.white, size: 13),
                  const SizedBox(width: 6),
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_rounded,
                      color: Colors.white70, size: 11),
                ],
              ),
            ),
          ),
          if (end != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Year End?'),
                    content: const Text(
                        'This removes the financial year filter. All-time totals will be shown.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red),
                          child: const Text('Clear')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await vm.setYearEndDate(null);
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white70, size: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickYearEnd(
      BuildContext context, InvoiceListViewModel vm) async {
    final initial =
        vm.yearEndDate ?? DateTime(DateTime.now().year, 3, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select Financial Year End',
    );
    if (picked != null) {
      await vm.setYearEndDate(picked);
    }
  }

  Widget _buildSearchAndFilter(BuildContext context, InvoiceListViewModel viewModel) {
    final hasFilters = viewModel.searchQuery.isNotEmpty || viewModel.startDate != null || viewModel.endDate != null;
    final hasSearchText = viewModel.searchQuery.isNotEmpty;

    // Sync search controller with viewModel
    if (_searchController.text != viewModel.searchQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _searchController.text != viewModel.searchQuery) {
          _searchController.text = viewModel.searchQuery;
        }
      });
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.transparent,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => viewModel.setSearchQuery(value),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E3C72),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search invoices...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.only(left: 4, right: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: _accent,
                            size: 20,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 56,
                        minHeight: 48,
                      ),
                      suffixIcon: hasSearchText
                          ? Container(
                              margin: const EdgeInsets.only(right: 4),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    _searchController.clear();
                                    viewModel.setSearchQuery('');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : null,
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
                      filled: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showFilterDialog(context, viewModel),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.filter_list_rounded,
                        color: (viewModel.startDate != null || viewModel.endDate != null)
                            ? _accent
                            : Colors.grey[600],
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasFilters)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  if (viewModel.startDate != null || viewModel.endDate != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Chip(
                        avatar: Icon(Icons.calendar_today_rounded, size: 16, color: _accent),
                        label: Text(
                          viewModel.startDate != null && viewModel.endDate != null
                              ? '${DateFormat('dd MMM').format(viewModel.startDate!)} - ${DateFormat('dd MMM').format(viewModel.endDate!)}'
                              : viewModel.startDate != null
                                  ? 'From ${DateFormat('dd MMM').format(viewModel.startDate!)}'
                                  : viewModel.endDate != null
                                      ? 'Until ${DateFormat('dd MMM').format(viewModel.endDate!)}'
                                      : '',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        onDeleted: () => viewModel.setDateRange(null, null),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        backgroundColor: _accent.withOpacity(0.1),
                      ),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      viewModel.clearFilters();
                    },
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: const Text('Clear all', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showFilterDialog(BuildContext context, InvoiceListViewModel viewModel) async {
    DateTime? startDate = viewModel.startDate;
    DateTime? endDate = viewModel.endDate;

    final result = await showDialog<Map<String, DateTime?>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Date Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(startDate != null ? DateFormat('dd MMM yyyy').format(startDate!) : 'Not set'),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today_rounded),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null && context.mounted) {
                    startDate = date;
                    Navigator.pop(context);
                    if (context.mounted) {
                      _showFilterDialog(context, viewModel);
                    }
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('End Date'),
              subtitle: Text(endDate != null ? DateFormat('dd MMM yyyy').format(endDate!) : 'Not set'),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today_rounded),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null && context.mounted) {
                    endDate = date;
                    Navigator.pop(context);
                    if (context.mounted) {
                      _showFilterDialog(context, viewModel);
                    }
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, {'start': null, 'end': null}),
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {'start': startDate, 'end': endDate}),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (result != null) {
      viewModel.setDateRange(result['start'], result['end']);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(Icons.description_outlined, size: 54, color: _accent),
          ),
          const SizedBox(height: 16),
          Text('No sell entries yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _deepAccent)),
          const SizedBox(height: 6),
          Text('Tap Sell to record a cash sell or generate an invoice', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<String?> _getPdfFilePath(InvoiceModel invoice) async {
    try {
      // Always regenerate from the current invoice so edits are reflected
      // immediately (the cached PDF would otherwise go stale).
      final file = await PdfService.writeInvoicePdf(invoice);
      return file.path;
    } catch (e) {
      debugPrint('Error generating PDF: $e');
    }
    return null;
  }

  Future<void> _startNewSell(
      BuildContext context, InvoiceListViewModel viewModel) async {
    final isCash = await showSellOptionsSheet(context);
    if (isCash == null || !context.mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceFormView(isCashSell: isCash),
      ),
    );
    if (result == true && context.mounted) {
      viewModel.loadInvoices();
    }
  }

  Future<void> _openDetails(
      InvoiceModel invoice, InvoiceListViewModel viewModel) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailsView(invoice: invoice),
      ),
    );
    if (mounted) {
      viewModel.loadInvoices();
    }
  }

  Future<void> _openPdf(InvoiceModel invoice) async {
    final filePath = await _getPdfFilePath(invoice);
    if (filePath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate PDF for this invoice.')),
        );
      }
      return;
    }

    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: file.uri.pathSegments.last,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open PDF: $e')),
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

  Future<void> _sharePdf(InvoiceModel invoice) async {
    final filePath = await _getPdfFilePath(invoice);
    if (filePath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate PDF for sharing.')),
        );
      }
      return;
    }

    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Invoice ${invoice.invoiceNo}',
    );
  }

  Widget _buildInvoiceCard(BuildContext context, InvoiceModel invoice, InvoiceListViewModel viewModel) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final paid = invoice.isFullyPaid;
    final partial = invoice.totalPaidCarat > 0 && !paid;
    final statusLabel = paid ? 'Paid' : partial ? 'Partial' : 'Unpaid';
    final statusColor =
        paid ? Colors.green : partial ? Colors.orange : Colors.red;
    final isCashSell = invoice.isCashSell;
    final modeColor = isCashSell ? const Color(0xFF2E7D32) : _accent;
    final modeLabel = isCashSell ? 'Cash' : 'Invoice';
    final modeIcon =
        isCashSell ? Icons.payments_rounded : Icons.receipt_long_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDetails(invoice, viewModel),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: modeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(modeIcon, color: modeColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.buyerName.isNotEmpty ? invoice.buyerName : 'Unnamed Buyer',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text('${isCashSell ? 'Entry No' : 'Invoice No'}: ${invoice.invoiceNo}', style: TextStyle(color: Colors.grey[700])),
                  Text('Date: ${dateFormat.format(invoice.invoiceDate)}', style: TextStyle(color: Colors.grey[700])),
                  Text('Total: ₹${invoice.grandTotal.toStringAsFixed(2)}', style: TextStyle(color: _deepAccent, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: modeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: modeColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    modeLabel,
                    style: TextStyle(
                        color: modeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11),
                  ),
                ),
                if (invoice.isForOther) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _accent.withOpacity(0.4)),
                    ),
                    child: Text(
                      'For Other',
                      style: TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 10),
                    ),
                  ),
                ],
                PopupMenuButton(
                  itemBuilder: (context) => [
                    if (!isCashSell) ...[
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [Icon(Icons.picture_as_pdf_rounded, size: 20), SizedBox(width: 8), Text('View Invoice')],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'email',
                        child: Row(
                          children: [Icon(Icons.email_rounded, size: 20), SizedBox(width: 8), Text('Email Invoice')],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [Icon(Icons.share, size: 20), SizedBox(width: 8), Text('Share')],
                        ),
                      ),
                    ],
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'view') {
                      await _openPdf(invoice);
                    } else if (value == 'email') {
                      await _emailInvoice(context, invoice);
                    } else if (value == 'share') {
                      await _sharePdf(invoice);
                    } else if (value == 'edit') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvoiceFormView(invoice: invoice),
                        ),
                      );
                      if (result == true && context.mounted) {
                        viewModel.loadInvoices();
                      }
                    } else if (value == 'delete') {
                      await _handleDeleteInvoice(context, invoice, viewModel);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeleteInvoice(BuildContext context, InvoiceModel invoice, InvoiceListViewModel viewModel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text('Are you sure you want to delete this invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await viewModel.deleteInvoice(invoice.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Error deleting invoice'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}
