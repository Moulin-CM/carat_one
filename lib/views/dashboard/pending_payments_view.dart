import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/invoice_model.dart';
import '../../models/purchase_model.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../invoice/invoice_details_view.dart';
import '../purchase/purchase_detail_view.dart';
import '../../constants/app_translations.dart';

enum PendingPaymentsMode { fromBuyers, toSellers }

class PendingPaymentsView extends StatelessWidget {
  final PendingPaymentsMode mode;
  final DashboardViewModel dashboardViewModel;

  const PendingPaymentsView({
    super.key,
    required this.mode,
    required this.dashboardViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardViewModel>.value(
      value: dashboardViewModel,
      child: _PendingPaymentsContent(mode: mode),
    );
  }
}

class _PendingPaymentsContent extends StatelessWidget {
  final PendingPaymentsMode mode;
  const _PendingPaymentsContent({required this.mode});

  static const _accent = Color(0xFF4F8AF4);
  static const _deepAccent = Color(0xFF1E3C72);

  Color get _tone =>
      mode == PendingPaymentsMode.fromBuyers ? Colors.orange : Colors.red;

  IconData get _icon => mode == PendingPaymentsMode.fromBuyers
      ? Icons.south_west_rounded
      : Icons.north_east_rounded;

  String get _title => mode == PendingPaymentsMode.fromBuyers
      ? 'Pending from Buyers'.tr
      : 'Pending to Sellers'.tr;

  String get _subtitle => mode == PendingPaymentsMode.fromBuyers
      ? 'Receivable (Sell)'.tr
      : 'Payable (Purchase)'.tr;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    final invoices = mode == PendingPaymentsMode.fromBuyers
        ? vm.pendingInvoices
        : const <InvoiceModel>[];
    final purchases = mode == PendingPaymentsMode.toSellers
        ? vm.pendingPurchases
        : const <PurchaseModel>[];

    final totalPending = mode == PendingPaymentsMode.fromBuyers
        ? vm.pendingSellAmount
        : vm.pendingPurchaseAmount;
    final entryCount = mode == PendingPaymentsMode.fromBuyers
        ? invoices.length
        : purchases.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.8),
              ),
              child: Icon(_icon, color: _tone, size: 20),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _buildSummaryHeader(
                  currencyFmt: currencyFmt,
                  totalPending: totalPending,
                  entryCount: entryCount,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => vm.loadInvoices(),
                    child: entryCount == 0
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: entryCount,
                            itemBuilder: (context, index) {
                              if (mode == PendingPaymentsMode.fromBuyers) {
                                return _buildInvoiceCard(
                                    context, invoices[index], vm, currencyFmt);
                              }
                              return _buildPurchaseCard(
                                  context, purchases[index], vm, currencyFmt);
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildSummaryHeader({
    required NumberFormat currencyFmt,
    required double totalPending,
    required int entryCount,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(18),
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
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _tone.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon, color: _tone, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    currencyFmt.format(totalPending),
                    style: TextStyle(
                      color: _tone,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$entryCount ${entryCount == 1 ? 'entry'.tr : 'entries'.tr}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
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
                child:
                    Icon(Icons.check_circle_outline, size: 54, color: _tone),
              ),
              const SizedBox(height: 16),
              Text(
                mode == PendingPaymentsMode.fromBuyers
                    ? 'No pending receivables'.tr
                    : 'No pending payables'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _deepAccent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                mode == PendingPaymentsMode.fromBuyers
                    ? 'All buyers have settled their dues.'.tr
                    : 'All seller payments are settled.'.tr,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(
    BuildContext context,
    InvoiceModel invoice,
    DashboardViewModel vm,
    NumberFormat currencyFmt,
  ) {
    final dateFmt = DateFormat('dd MMM yyyy'.tr);
    final caratFmt = NumberFormat('#,##0.00');
    final pendingAmount = invoice.remainingCarat * invoice.averageRate;
    final isCash = invoice.isCashSell;

    return _buildEntryCard(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceDetailsView(invoice: invoice),
          ),
        );
        await vm.loadInvoices();
      },
      leadingIcon:
          isCash ? Icons.payments_rounded : Icons.receipt_long_rounded,
      title: invoice.buyerName.isNotEmpty
          ? invoice.buyerName
          : 'Unnamed Buyer'.tr,
      subtitleLines: [
        '${isCash ? 'Entry No'.tr : 'Invoice No'.tr}: ${invoice.invoiceNo}',
        '${'Date'.tr}: ${dateFmt.format(invoice.invoiceDate)}',
        '${'Pending'.tr}: ${caratFmt.format(invoice.remainingCarat)} ct',
      ],
      pendingAmount: pendingAmount,
      currencyFmt: currencyFmt,
    );
  }

  Widget _buildPurchaseCard(
    BuildContext context,
    PurchaseModel purchase,
    DashboardViewModel vm,
    NumberFormat currencyFmt,
  ) {
    final dateFmt = DateFormat('dd MMM yyyy'.tr);
    final caratFmt = NumberFormat('#,##0.00');
    final pendingAmount =
        purchase.remainingPaymentCarat * purchase.effectivePurchaseRate;

    return _buildEntryCard(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PurchaseDetailView(purchase: purchase),
          ),
        );
        await vm.loadInvoices();
      },
      leadingIcon: Icons.diamond_rounded,
      title:
          purchase.sellerName.isNotEmpty ? purchase.sellerName : 'Unnamed Seller'.tr,
      subtitleLines: [
        if (purchase.size.isNotEmpty) '${'Size'.tr}: ${purchase.size}',
        '${'Buy Date'.tr}: ${dateFmt.format(purchase.buyDate)}',
        '${'Pending'.tr}: ${caratFmt.format(purchase.remainingPaymentCarat)} ct',
      ],
      pendingAmount: pendingAmount,
      currencyFmt: currencyFmt,
    );
  }

  Widget _buildEntryCard({
    required VoidCallback onTap,
    required IconData leadingIcon,
    required String title,
    required List<String> subtitleLines,
    required double pendingAmount,
    required NumberFormat currencyFmt,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _tone.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(leadingIcon, color: _tone),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      for (final line in subtitleLines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            line,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Pending'.tr,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        currencyFmt.format(pendingAmount),
                        style: TextStyle(
                          color: _tone,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _tone.withOpacity(0.7),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
