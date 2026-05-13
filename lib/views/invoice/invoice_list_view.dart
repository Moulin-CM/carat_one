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
import '../../services/quota_service.dart';
import '../../widgets/ads/native_ad_card.dart';
import '../../widgets/sell_options_sheet.dart';
import '../../widgets/list_skeleton.dart';
import '../../widgets/paywall_dialog.dart';
import '../subscription/subscription_plans_view.dart';
import 'invoice_form_view.dart';
import 'invoice_details_view.dart';
import '../../constants/app_translations.dart';


class InvoiceListView extends StatefulWidget {
  const InvoiceListView({super.key});

  @override
  State<InvoiceListView> createState() => _InvoiceListViewState();
}

class _InvoiceListViewState extends State<InvoiceListView>
    with AutomaticKeepAliveClientMixin {

  late final InvoiceListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = InvoiceListViewModel()..loadInvoices();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ChangeNotifierProvider<InvoiceListViewModel>.value(
      value: _viewModel,
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
              Text('Generated Invoices'.tr),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => viewModel.loadInvoices(),
            tooltip: 'Refresh'.tr,
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
                      ? const ListSkeleton()
                      : viewModel.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: () => viewModel.loadInvoices(),
                              child: _buildInvoiceListWithAds(context, viewModel),
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
          height: 56, // Fixed height for consistency
          child: ElevatedButton.icon(
            onPressed: () => _startNewSell(context, viewModel),
            icon: const Icon(Icons.add_rounded),
            label: Text('Sell'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
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
                  'Opening Carats'.tr,
                  '${caratFmt.format(viewModel.openingSellCarat)} ct',
                  Icons.diamond_rounded,
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: _summaryTile(
                  'Opening Amount'.tr,
                  fmt.format(viewModel.openingSellAmount),
                  Icons.currency_rupee_rounded,
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: _summaryTile(
                  'Outstanding'.tr,
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
        ? 'Set Year End'.tr
        : '${'FY End: '.tr}${DateFormat('dd MMM yyyy'.tr).format(end)}';
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
                    title: Text('Clear Year End?'.tr),
                    content: Text(
                        'This removes the financial year filter. All-time totals will be shown.'.tr),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel'.tr)),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red),
                          child: Text('Clear'.tr)),
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
      helpText: 'Select Financial Year End'.tr,
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
                      hintText: 'Search invoices...'.tr,
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.only(left: 8, right: 8),
                        child: Container(
                          padding: const EdgeInsets.all(14),
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
                              ? '${DateFormat('dd MMM'.tr).format(viewModel.startDate!)} - ${DateFormat('dd MMM'.tr).format(viewModel.endDate!)}'
                              : viewModel.startDate != null
                                  ? '${'From'.tr} ${DateFormat('dd MMM'.tr).format(viewModel.startDate!)}'
                                  : viewModel.endDate != null
                                      ? '${'Until'.tr} ${DateFormat('dd MMM'.tr).format(viewModel.endDate!)}'
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
                    label: Text('Clear all'.tr, style: const TextStyle(fontSize: 12)),
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
        title: Text('Filter by Date Range'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Start Date'.tr),
              subtitle: Text(startDate != null ? DateFormat('dd MMM yyyy'.tr).format(startDate!) : 'Not set'.tr),
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
              title: Text('End Date'.tr),
              subtitle: Text(endDate != null ? DateFormat('dd MMM yyyy'.tr).format(endDate!) : 'Not set'.tr),
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
            onPressed: () => Navigator.pop(context, {'start'.tr: null, 'end'.tr: null}),
            child: Text('Clear'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {'start'.tr: startDate, 'end'.tr: endDate}),
            child: Text('Apply'.tr),
          ),
        ],
      ),
    );

    if (result != null) {
      viewModel.setDateRange(result['start'.tr], result['end'.tr]);
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
          Text('No sell entries yet'.tr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _deepAccent)),
          const SizedBox(height: 6),
          Text('Tap Sell to record a cash sell or generate an invoice'.tr, style: TextStyle(color: Colors.grey[600])),
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
    final canAdd = await QuotaService().canAddEntry(false);
    if (!canAdd && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => PaywallDialog(
          message: 'You have reached your monthly limit for adding sells. Please upgrade your plan to continue adding unlimited entries.'.tr,
        ),
      );
      return;
    }

    if (!context.mounted) return;
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

  Future<void> _checkPdfQuotaAndExecute(BuildContext context, Future<void> Function() action) async {
    final canPrint = await QuotaService().canPrintPdf();
    if (!canPrint && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => PaywallDialog(
          message: 'You have reached your monthly limit for PDF generation. Please upgrade your plan for unlimited PDF prints and shares.'.tr,
        ),
      );
      return;
    }

    await action();
    await QuotaService().incrementPdfUsage();
  }

  Future<void> _openPdf(InvoiceModel invoice) async {
    await _checkPdfQuotaAndExecute(context, () async {
      final filePath = await _getPdfFilePath(invoice);
      if (filePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not generate PDF for this invoice.'.tr)),
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
            SnackBar(content: Text('${'Could not open PDF'.tr}: $e')),
          );
        }
      }
    });
  }

  Future<void> _emailInvoice(BuildContext context, InvoiceModel invoice) async {
    await _checkPdfQuotaAndExecute(context, () async {
      try {
        await EmailService.shareInvoiceViaEmail(invoice);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening email client...'.tr),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'Error'.tr}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  Future<void> _sharePdf(InvoiceModel invoice) async {
    await _checkPdfQuotaAndExecute(context, () async {
      final filePath = await _getPdfFilePath(invoice);
      if (filePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not generate PDF for sharing.'.tr)),
          );
        }
        return;
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        text: '${'Invoice'.tr} ${invoice.invoiceNo}',
      );
    });
  }

  /// AdMob native ads interleaved into the invoice list.
  ///
  /// Pattern: one ad after every [_adInterval] invoices. We use a constant
  /// frequency rather than ad-density-based heuristics so layout is
  /// predictable and we never place two ads adjacent (a common policy
  /// violation).
  static const int _adInterval = 7;

  Widget _buildInvoiceListWithAds(
      BuildContext context, InvoiceListViewModel viewModel) {
    final invoices = viewModel.invoices;
    // Total slots = invoices + one ad after every _adInterval invoices.
    // We only add an ad slot AFTER a full group, so a list of 6 has 0 ads,
    // 7 has 1, 14 has 2, etc.
    final adCount = invoices.length ~/ _adInterval;
    final totalSlots = invoices.length + adCount;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        // Compute group of (_adInterval + 1) slots: N invoices then 1 ad.
        const groupSize = _adInterval + 1;
        final positionInGroup = index % groupSize;
        if (positionInGroup == _adInterval) {
          // Ad slot.
          return const NativeAdCard();
        }
        final invoiceIndex = (index ~/ groupSize) * _adInterval + positionInGroup;
        if (invoiceIndex >= invoices.length) {
          return const SizedBox.shrink();
        }
        return _buildInvoiceCard(context, invoices[invoiceIndex], viewModel);
      },
    );
  }

  Widget _buildInvoiceCard(BuildContext context, InvoiceModel invoice, InvoiceListViewModel viewModel) {
    final dateFormat = DateFormat('dd MMM yyyy'.tr);
    final paid = invoice.isFullyPaid;
    final partial = invoice.totalPaidCarat > 0 && !paid;
    final statusLabel = paid ? 'Paid'.tr : partial ? 'Partial'.tr : 'Unpaid'.tr;
    final statusColor =
        paid ? Colors.green : partial ? Colors.orange : Colors.red;
    final isCashSell = invoice.isCashSell;
    final modeColor = isCashSell ? const Color(0xFF2E7D32) : _accent;
    final modeLabel = isCashSell ? 'Cash'.tr : 'Invoice'.tr;
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
                    invoice.buyerName.isNotEmpty ? invoice.buyerName : 'Unnamed Buyer'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text('${isCashSell ? 'Entry No'.tr : 'Invoice No'.tr}: ${invoice.invoiceNo}', style: TextStyle(color: Colors.grey[700])),
                  Text('${'Date'.tr}: ${dateFormat.format(invoice.invoiceDate)}', style: TextStyle(color: Colors.grey[700])),
                  Text('${'Total'.tr}: ₹${invoice.grandTotal.toStringAsFixed(2)}', style: TextStyle(color: _deepAccent, fontWeight: FontWeight.w700)),
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
                      'For Other'.tr,
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
                      PopupMenuItem(
                        value: 'view'.tr,
                        child: Row(
                          children: [const Icon(Icons.picture_as_pdf_rounded, size: 20), const SizedBox(width: 8), Text('View Invoice'.tr)],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'email',
                        child: Row(
                          children: [const Icon(Icons.email_rounded, size: 20), const SizedBox(width: 8), Text('Email Invoice'.tr)],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share'.tr,
                        child: Row(
                          children: [const Icon(Icons.share, size: 20), const SizedBox(width: 8), Text('Share'.tr)],
                        ),
                      ),
                    ],
                    PopupMenuItem(
                      value: 'edit'.tr,
                      child: Row(
                        children: [const Icon(Icons.edit, size: 20), const SizedBox(width: 8), Text('Edit'.tr)],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete'.tr,
                      child: Row(
                        children: [const Icon(Icons.delete, size: 20, color: Colors.red), const SizedBox(width: 8), Text('Delete'.tr, style: const TextStyle(color: Colors.red))],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'view'.tr) {
                      await _openPdf(invoice);
                    } else if (value == 'email') {
                      await _emailInvoice(context, invoice);
                    } else if (value == 'share'.tr) {
                      await _sharePdf(invoice);
                    } else if (value == 'edit'.tr) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvoiceFormView(invoice: invoice),
                        ),
                      );
                      if (result == true && context.mounted) {
                        viewModel.loadInvoices();
                      }
                    } else if (value == 'delete'.tr) {
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
        title: Text('Delete Invoice'.tr),
        content: Text('Are you sure you want to delete this invoice?'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'.tr),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await viewModel.deleteInvoice(invoice.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice deleted'.tr)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Error deleting invoice'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}
