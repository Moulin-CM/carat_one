import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_storage_service.dart';
import '../../widgets/app_bar_factory.dart';
import '../../constants/app_translations.dart';


import 'package:invoice_generator/constants/app_translations.dart';

class InvoiceDetailsView extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoiceDetailsView({super.key, required this.invoice});

  @override
  State<InvoiceDetailsView> createState() => _InvoiceDetailsViewState();
}

class _InvoiceDetailsViewState extends State<InvoiceDetailsView> {
  static const _accent = Color(0xFF4F8AF4);
  static const _deep = Color(0xFF1E3C72);

  late InvoiceModel _invoice;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
  }

  double get _remaining => _invoice.remainingCarat;
  double get _remainingAmount => _remaining * _invoice.averageRate;

  Future<void> _markReceived() async {
    final remainingCarat = _remaining;
    if (remainingCarat <= 0) return;

    setState(() => _saving = true);
    try {
      // Settle the entire outstanding balance into the channel matching
      // this sell's mode — cash for cash sells, in-account for invoices.
      if (_invoice.isCashSell) {
        _invoice.cashPaidCarat += remainingCarat;
      } else {
        _invoice.accountPaidCarat += remainingCarat;
      }
      await InvoiceStorageService.saveInvoice(_invoice);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked as Paid'.tr),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'Error'.tr}: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCashSell = _invoice.isCashSell;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBarFactory.build(
        title: isCashSell ? 'Cash Sell Details'.tr : 'Invoice Details'.tr,
        onBackPress: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInvoiceHeader(),
                  const SizedBox(height: 14),
                  _buildSellerCard(),
                  const SizedBox(height: 14),
                  _buildBuyerCard(),
                  const SizedBox(height: 14),
                  _buildItemsCard(),
                  const SizedBox(height: 14),
                  _buildTotalsCard(),
                  if (!isCashSell) ...[
                    const SizedBox(height: 14),
                    _buildBankCard(),
                  ],
                  const SizedBox(height: 14),
                  _buildPaymentCard(),
                ],
              ),
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
          colors: [Color(0xFFE7EEFF), Color(0xFFF9FBFF)],
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
            child: _blurredCircle(200, _deep.withOpacity(0.12)),
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

  // ────────────────────── Sections ──────────────────────

  Widget _buildInvoiceHeader() {
    final dateFormat = DateFormat('dd MMM yyyy'.tr);
    final isCashSell = _invoice.isCashSell;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCashSell
                      ? Icons.payments_rounded
                      : Icons.receipt_long_rounded,
                  color: _deep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${isCashSell ? 'Cash Sell'.tr : 'Invoice'.tr} #${_invoice.invoiceNo}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _deep),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${'Date'.tr}: ${dateFormat.format(_invoice.invoiceDate)}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    if (_invoice.terms.isNotEmpty)
                      Text('${'Terms'.tr}: ${_invoice.terms}',
                          style: TextStyle(color: Colors.grey[700])),
                    Text('${'Due'.tr}: ${dateFormat.format(_invoice.dueDate)}',
                        style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ),
              _statusChip(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip() {
    final paid = _invoice.isFullyPaid;
    final partial = _invoice.totalPaidCarat > 0 && !paid;
    final label = paid ? 'Paid'.tr : partial ? 'Partial'.tr : 'Unpaid'.tr;
    final color = paid
        ? Colors.green
        : partial
            ? Colors.orange
            : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  Widget _buildSellerCard() {
    return _sectionCard(
      icon: Icons.storefront_rounded,
      title: 'Seller'.tr,
      rows: [
        _kv('Name'.tr, _invoice.sellerName),
        _kv('Address'.tr, _invoice.sellerAddress),
        _kv('Mobile'.tr, _invoice.sellerMobile),
        _kv('Email'.tr, _invoice.sellerEmail),
        if (_invoice.sellerGstNo.isNotEmpty) _kv('GST No'.tr, _invoice.sellerGstNo),
        if (_invoice.sellerPanNo.isNotEmpty) _kv('PAN No'.tr, _invoice.sellerPanNo),
      ],
    );
  }

  Widget _buildBuyerCard() {
    return _sectionCard(
      icon: Icons.person_rounded,
      title: 'Buyer'.tr,
      rows: [
        _kv('Name'.tr, _invoice.buyerName.isEmpty ? '-' : _invoice.buyerName),
        if (_invoice.buyerContactPerson.isNotEmpty)
          _kv('Contact Person'.tr, _invoice.buyerContactPerson),
        if (_invoice.buyerContactNo.isNotEmpty)
          _kv('Contact No'.tr, _invoice.buyerContactNo),
        if (_invoice.buyerEmail.isNotEmpty) _kv('Email'.tr, _invoice.buyerEmail),
        if (_invoice.buyerAddress.isNotEmpty)
          _kv('Address'.tr, _invoice.buyerAddress),
        if (_invoice.buyerGstNo.isNotEmpty) _kv('GST No'.tr, _invoice.buyerGstNo),
        if (_invoice.buyerPanNo.isNotEmpty) _kv('PAN No'.tr, _invoice.buyerPanNo),
        if (_invoice.buyerStateName.isNotEmpty)
          _kv('State'.tr, '${_invoice.buyerStateName} (${_invoice.buyerStateCode})'),
        if (_invoice.placeOfSupply.isNotEmpty)
          _kv('Place of Supply'.tr, _invoice.placeOfSupply),
      ],
    );
  }

  Widget _buildItemsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.list_alt_rounded, 'Items'.tr),
          const SizedBox(height: 10),
          ..._invoice.items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}. ${item.particular}'.tr,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: _deep)),
                  const SizedBox(height: 4),
                  Text('HSN: ${item.hsnCode}'.tr,
                      style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _itemStat(
                            'Carat'.tr, '${item.carat.toStringAsFixed(2)} ct'),
                      ),
                      Expanded(
                        child: _itemStat(
                            'Rate'.tr, '₹${item.rate.toStringAsFixed(2)}'),
                      ),
                      Expanded(
                        child: _itemStat(
                            'Amount'.tr, '₹${item.amount.toStringAsFixed(2)}',
                            alignRight: true),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotalsCard() {
    return _card(
      child: Column(
        children: [
          _sectionHeader(Icons.calculate_rounded, 'Totals'.tr),
          const SizedBox(height: 10),
          _kv('Total Carat'.tr, '${_invoice.totalCarat.toStringAsFixed(2)} ct'),
          _kv('Sub Total'.tr, '₹${_invoice.totalAmount.toStringAsFixed(2)}'),
          if (_invoice.discountRate > 0) ...[
            _kv('${'Discount'.tr} (${_invoice.discountRate}%)',
                '- ₹${_invoice.discountAmount.toStringAsFixed(2)}'),
            _kv('Taxable Amount'.tr,
                '₹${_invoice.taxableAmount.toStringAsFixed(2)}'),
          ],
          if (!_invoice.isCashSell) ...[
            if (!_invoice.isIgst) ...[
              _kv('CGST (${_invoice.cgstRate}%)',
                  '₹${_invoice.cgstAmount.toStringAsFixed(2)}'),
              _kv('SGST (${_invoice.sgstRate}%)',
                  '₹${_invoice.sgstAmount.toStringAsFixed(2)}'),
            ] else
              _kv('IGST (${_invoice.igstRate}%)',
                  '₹${_invoice.igstAmount.toStringAsFixed(2)}'),
          ],
          if (_invoice.brokerChargeRate > 0)
            _kv('Broker Charge (${_invoice.brokerChargeRate}%)',
                '- ₹${_invoice.brokerChargeAmount.toStringAsFixed(2)}'),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: Text('Grand Total'.tr,
                    style:
                        const TextStyle(fontWeight: FontWeight.w800, color: _deep)),
              ),
              Text('₹${_invoice.grandTotal.toStringAsFixed(2)}'.tr,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _deep)),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _invoice.amountInWords,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontStyle: FontStyle.italic, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard() {
    return _sectionCard(
      icon: Icons.account_balance_rounded,
      title: 'Bank Details'.tr,
      rows: [
        _kv('Bank'.tr, _invoice.bankName),
        _kv('Branch'.tr, _invoice.branch),
        _kv('A/C No'.tr, _invoice.accountNo),
        _kv('IFSC'.tr, _invoice.ifscCode),
      ],
    );
  }

  // ────────────────────── Payment section ──────────────────────

  Widget _buildPaymentCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.payments_rounded, 'Payment'.tr),
          const SizedBox(height: 12),
          _paymentSummary(),
          const SizedBox(height: 16),
          if (_invoice.isFullyPaid)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This sell is fully paid.'.tr,
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _markReceived,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_rounded),
                label: Text(_saving
                    ? 'Saving…'.tr
                    : '${'Received'.tr}  (₹${_remainingAmount.toStringAsFixed(2)})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _paymentSummary() {
    return Column(
      children: [
        if (_invoice.isCashSell)
          _paymentRow(
            icon: Icons.payments_outlined,
            label: 'Cash'.tr,
            carat: _invoice.cashPaidCarat,
            amount: _invoice.cashPaidAmount,
            color: const Color(0xFF2E7D32),
          )
        else
          _paymentRow(
            icon: Icons.account_balance_outlined,
            label: 'In Account'.tr,
            carat: _invoice.accountPaidCarat,
            amount: _invoice.accountPaidAmount,
            color: _accent,
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _deep.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.timelapse_rounded, color: _deep, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Remaining'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _deep,
                  ),
                ),
              ),
              Text(
                '${_remaining.toStringAsFixed(2)} ct'
                ' · ₹${(_remaining * _invoice.averageRate).toStringAsFixed(2)}',
                style: const TextStyle(
                    color: _deep, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentRow({
    required IconData icon,
    required String label,
    required double carat,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ),
          Text('${carat.toStringAsFixed(2)} ct · ₹${amount.toStringAsFixed(2)}'.tr,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ────────────────────── Shared helpers ──────────────────────

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> rows,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(icon, title),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _deep, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: _deep, fontSize: 15)),
      ],
    );
  }

  Widget _itemStat(String label, String value, {bool alignRight = false}) {
    final align =
        alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignRight ? TextAlign.end : TextAlign.start;
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: textAlign,
          style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: _deep, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              key,
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: _deep, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
