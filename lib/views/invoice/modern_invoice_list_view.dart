import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
import '../../constants/app_translations.dart';
import 'invoice_form_view.dart';
import 'invoice_details_view.dart';

/// Modern UI surface for the Sells (invoice) tab.
///
/// Expects an [InvoiceListViewModel] provided above it. Same behaviour
/// as the classic [InvoiceListView] — search, filter, year-end picker,
/// PDF/email/share actions, swipe / popup-menu delete, native ads —
/// only the visuals change.
class ModernInvoiceListContent extends StatefulWidget {
  const ModernInvoiceListContent({super.key});

  @override
  State<ModernInvoiceListContent> createState() =>
      _ModernInvoiceListContentState();
}

class _ModernInvoiceListContentState extends State<ModernInvoiceListContent> {
  final _searchController = TextEditingController();

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

  static const int _adInterval = 7;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InvoiceListViewModel>();

    // Keep search controller in sync with VM (e.g. cleared from elsewhere).
    if (_searchController.text != vm.searchQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _searchController.text != vm.searchQuery) {
          _searchController.text = vm.searchQuery;
        }
      });
    }

    return Scaffold(
      backgroundColor: _bg0,
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _buildOpeningSummary(context, vm),
                _buildSearchAndFilter(context, vm),
                Expanded(
                  child: vm.isLoading
                      ? const ListSkeleton(dark: true)
                      : vm.isEmpty
                          ? _emptyState()
                          : RefreshIndicator(
                              color: _accent,
                              backgroundColor: _bg1,
                              onRefresh: () => vm.loadInvoices(),
                              child: _buildListWithAds(context, vm),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingSellButton(context, vm),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
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
            child: _glow(280, _primary.withOpacity(0.28)),
          ),
          Positioned(
            top: 200,
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

  // ─────────────────────────  OPENING SUMMARY  ────────────────────────────

  Widget _buildOpeningSummary(
      BuildContext context, InvoiceListViewModel vm) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final caratFmt = NumberFormat('#,##0.00');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
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
        children: [
          _buildYearEndBadge(context, vm),
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  'Opening Carats'.tr,
                  '${caratFmt.format(vm.openingSellCarat)} ct',
                  Icons.diamond_rounded,
                ),
              ),
              _divider(),
              Expanded(
                child: _summaryTile(
                  'Opening Amount'.tr,
                  fmt.format(vm.openingSellAmount),
                  Icons.currency_rupee_rounded,
                ),
              ),
              _divider(),
              Expanded(
                child: _summaryTile(
                  'Outstanding'.tr,
                  '${caratFmt.format(vm.outstandingSellCarat)} ct',
                  Icons.balance_rounded,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Container(height: 1, color: Colors.white.withOpacity(0.24)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                '${'Pending Payment'.tr}: ',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                fmt.format(vm.totalUnreceivedAmount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 30, color: Colors.white24);

  Widget _summaryTile(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.85), size: 16),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildYearEndBadge(
      BuildContext context, InvoiceListViewModel vm) {
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
              onTap: () => _clearYearEnd(context, vm),
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
    final initial = vm.yearEndDate ?? DateTime(DateTime.now().year, 3, 31);
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

  Future<void> _clearYearEnd(
      BuildContext context, InvoiceListViewModel vm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear Year End?'.tr),
        content: Text(
            'This removes the financial year filter. All-time totals will be shown.'
                .tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Clear'.tr),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await vm.setYearEndDate(null);
    }
  }

  // ──────────────────────────  SEARCH + FILTER  ───────────────────────────

  Widget _buildSearchAndFilter(
      BuildContext context, InvoiceListViewModel vm) {
    final hasFilters = vm.searchQuery.isNotEmpty ||
        vm.startDate != null ||
        vm.endDate != null;
    final hasSearchText = vm.searchQuery.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSearchField(vm, hasSearchText)),
              const SizedBox(width: 10),
              _buildFilterButton(context, vm),
            ],
          ),
          if (hasFilters) ...[
            const SizedBox(height: 10),
            _buildActiveFiltersRow(vm),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField(InvoiceListViewModel vm, bool hasSearchText) {
    return TextField(
      controller: _searchController,
      onChanged: (v) => vm.setSearchQuery(v),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: _accent,
      decoration: InputDecoration(
        hintText: 'Search invoices...'.tr,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.45),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(Icons.search_rounded,
            color: _accent, size: 20),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 0),
        suffixIcon: hasSearchText
            ? IconButton(
                icon: Icon(Icons.clear_rounded,
                    color: Colors.white.withOpacity(0.65), size: 20),
                onPressed: () {
                  _searchController.clear();
                  vm.setSearchQuery('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilterButton(
      BuildContext context, InvoiceListViewModel vm) {
    final hasDateFilter = vm.startDate != null || vm.endDate != null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showFilterDialog(context, vm),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasDateFilter
                ? _accent.withOpacity(0.18)
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasDateFilter
                  ? _accent.withOpacity(0.55)
                  : Colors.white.withOpacity(0.10),
            ),
          ),
          child: Icon(
            Icons.filter_list_rounded,
            color: hasDateFilter ? _accent : Colors.white.withOpacity(0.75),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersRow(InvoiceListViewModel vm) {
    return Row(
      children: [
        if (vm.startDate != null || vm.endDate != null)
          _filterChip(vm),
        const Spacer(),
        TextButton.icon(
          onPressed: () {
            _searchController.clear();
            vm.clearFilters();
          },
          icon: Icon(Icons.clear_all_rounded,
              size: 16, color: Colors.white.withOpacity(0.75)),
          label: Text(
            'Clear all'.tr,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(InvoiceListViewModel vm) {
    final start = vm.startDate;
    final end = vm.endDate;
    final label = start != null && end != null
        ? '${DateFormat('dd MMM'.tr).format(start)} - ${DateFormat('dd MMM'.tr).format(end)}'
        : start != null
            ? '${'From'.tr} ${DateFormat('dd MMM'.tr).format(start)}'
            : end != null
                ? '${'Until'.tr} ${DateFormat('dd MMM'.tr).format(end)}'
                : '';
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withOpacity(0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded,
              size: 14, color: _accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => vm.setDateRange(null, null),
            child: const Icon(Icons.close_rounded,
                size: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ────────────────────────  FILTER DIALOG  ───────────────────────────────

  Future<void> _showFilterDialog(
      BuildContext context, InvoiceListViewModel vm) async {
    DateTime? startDate = vm.startDate;
    DateTime? endDate = vm.endDate;

    final result = await showDialog<Map<String, DateTime?>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (context) {
        return StatefulBuilder(builder: (ctx, setSt) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_bg1, Color(0xFF11173B), _bg1],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withOpacity(0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: _grad,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.filter_list_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Filter by Date Range'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _dateRowTile(
                    label: 'Start Date'.tr,
                    value: startDate,
                    onPick: (d) => setSt(() => startDate = d),
                  ),
                  const SizedBox(height: 10),
                  _dateRowTile(
                    label: 'End Date'.tr,
                    value: endDate,
                    onPick: (d) => setSt(() => endDate = d),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _dialogCancelButton(
                          label: 'Clear'.tr,
                          onTap: () => Navigator.pop(
                              context, {'start': null, 'end': null}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _dialogPrimaryButton(
                          label: 'Apply'.tr,
                          onTap: () => Navigator.pop(context,
                              {'start': startDate, 'end': endDate}),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );

    if (result != null) {
      vm.setDateRange(result['start'], result['end']);
    }
  }

  Widget _dateRowTile({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onPick,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (d != null) onPick(d);
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 18, color: _accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value != null
                          ? DateFormat('dd MMM yyyy'.tr).format(value)
                          : 'Not set'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.45), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogCancelButton(
      {required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogPrimaryButton(
      {required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: _grad,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.40),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────  LIST + CARDS  ────────────────────────────

  Widget _buildListWithAds(BuildContext context, InvoiceListViewModel vm) {
    final invoices = vm.invoices;
    final adCount = invoices.length ~/ _adInterval;
    final totalSlots = invoices.length + adCount;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        const groupSize = _adInterval + 1;
        final positionInGroup = index % groupSize;
        if (positionInGroup == _adInterval) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: NativeAdCard(),
          );
        }
        final invoiceIndex =
            (index ~/ groupSize) * _adInterval + positionInGroup;
        if (invoiceIndex >= invoices.length) {
          return const SizedBox.shrink();
        }
        return _invoiceCard(context, invoices[invoiceIndex], vm);
      },
    );
  }

  Widget _invoiceCard(
      BuildContext context, InvoiceModel invoice, InvoiceListViewModel vm) {
    final dateFormat = DateFormat('dd MMM yyyy'.tr);
    final paid = invoice.isFullyPaid;
    final partial = invoice.totalPaidCarat > 0 && !paid;
    final statusLabel = paid
        ? 'Paid'.tr
        : partial
            ? 'Partial'.tr
            : 'Unpaid'.tr;
    final statusColor = paid
        ? const Color(0xFF34D399)
        : partial
            ? const Color(0xFFFBBF24)
            : const Color(0xFFF87171);
    final isCashSell = invoice.isCashSell;
    final modeLabel = isCashSell ? 'Cash'.tr : 'Invoice'.tr;
    final modeIcon = isCashSell
        ? Icons.payments_rounded
        : Icons.receipt_long_rounded;
    final modeGradient = isCashSell
        ? const [Color(0xFF10B981), Color(0xFF34D399)]
        : const [_primary, _accent];
    final modeColor =
        isCashSell ? const Color(0xFF34D399) : _accent;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openDetails(invoice, vm),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: modeGradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: modeGradient.first.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(modeIcon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.buyerName.isNotEmpty
                          ? invoice.buyerName
                          : 'Unnamed Buyer'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isCashSell ? 'Entry No'.tr : 'Invoice No'.tr}: ${invoice.invoiceNo}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 11.5,
                      ),
                    ),
                    Text(
                      '${'Date'.tr}: ${dateFormat.format(invoice.invoiceDate)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${'Total'.tr}: ₹${invoice.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _smallPill(modeLabel, modeColor),
                  const SizedBox(height: 4),
                  _smallPill(statusLabel, statusColor),
                  if (invoice.isForOther) ...[
                    const SizedBox(height: 4),
                    _smallPill('For Other'.tr, _accent),
                  ],
                  _buildPopupMenu(context, invoice, vm, isCashSell),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, InvoiceModel invoice,
      InvoiceListViewModel vm, bool isCashSell) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded,
          color: Colors.white.withOpacity(0.75)),
      color: const Color(0xFF11173B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      itemBuilder: (context) => [
        if (!isCashSell) ...[
          _menuItem('view', Icons.picture_as_pdf_rounded,
              'View Invoice'.tr),
          _menuItem('email', Icons.email_rounded, 'Email Invoice'.tr),
          _menuItem('share', Icons.share_rounded, 'Share'.tr),
        ],
        _menuItem('edit', Icons.edit_rounded, 'Edit'.tr),
        _menuItem('delete', Icons.delete_rounded, 'Delete'.tr,
            destructive: true),
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
            vm.loadInvoices();
          }
        } else if (value == 'delete') {
          await _handleDelete(context, invoice, vm);
        }
      },
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label,
      {bool destructive = false}) {
    final color =
        destructive ? const Color(0xFFFCA5A5) : Colors.white;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: _grad,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.35),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.description_outlined,
                size: 44, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Text(
            'No sell entries yet'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap Sell to record a cash sell or generate an invoice'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.55)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────  FLOATING FAB  ───────────────────────────

  Widget _buildFloatingSellButton(
      BuildContext context, InvoiceListViewModel vm) {
    final pillWidth = MediaQuery.of(context).size.width - 32;
    return SizedBox(
      width: pillWidth,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _startNewSell(context, vm),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: _grad,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
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
                const Icon(Icons.add_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Sell'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────  ACTIONS  ────────────────────────────────

  Future<void> _startNewSell(
      BuildContext context, InvoiceListViewModel vm) async {
    final canAdd = await QuotaService().canAddEntry(false);
    if (!canAdd && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => PaywallDialog(
          message:
              'You have reached your monthly limit for adding sells. Please upgrade your plan to continue adding unlimited entries.'
                  .tr,
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
      vm.loadInvoices();
    }
  }

  Future<void> _openDetails(
      InvoiceModel invoice, InvoiceListViewModel vm) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailsView(invoice: invoice),
      ),
    );
    if (mounted) {
      vm.loadInvoices();
    }
  }

  Future<String?> _getPdfFilePath(InvoiceModel invoice) async {
    try {
      final file = await PdfService.writeInvoicePdf(invoice);
      return file.path;
    } catch (e) {
      debugPrint('Error generating PDF: $e');
    }
    return null;
  }

  Future<void> _checkPdfQuotaAndExecute(
      BuildContext context, Future<void> Function() action) async {
    final canPrint = await QuotaService().canPrintPdf();
    if (!canPrint && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => PaywallDialog(
          message:
              'You have reached your monthly limit for PDF generation. Please upgrade your plan for unlimited PDF prints and shares.'
                  .tr,
        ),
      );
      return;
    }
    await action();
    await QuotaService().incrementPdfUsage();
  }

  Future<void> _openPdf(InvoiceModel invoice) async {
    await _checkPdfQuotaAndExecute(context, () async {
      try {
        if (kIsWeb) {
          final pdf = await PdfService.generatePdfDocument(invoice);
          final bytes = await pdf.save();
          await Printing.layoutPdf(
            onLayout: (format) async => bytes,
            name: PdfService.buildInvoiceFileName(invoice),
          );
          return;
        }

        final filePath = await _getPdfFilePath(invoice);
        if (filePath == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Could not generate PDF for this invoice.'.tr),
              ),
            );
          }
          return;
        }
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

  Future<void> _emailInvoice(
      BuildContext context, InvoiceModel invoice) async {
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

  Future<void> _handleDelete(BuildContext context, InvoiceModel invoice,
      InvoiceListViewModel vm) async {
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
      final success = await vm.deleteInvoice(invoice.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice deleted'.tr)),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(vm.errorMessage ?? 'Error deleting invoice'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
