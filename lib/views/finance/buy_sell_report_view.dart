import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/invoice_model.dart';
import '../../models/purchase_model.dart';
import '../../services/buy_sell_report_pdf_service.dart';
import '../../services/invoice_storage_service.dart';
import '../../services/purchase_storage_service.dart';
import '../../widgets/app_bar_factory.dart';

enum _PeriodMode { monthly, yearly, custom }

class BuySellReportView extends StatefulWidget {
  const BuySellReportView({super.key});

  @override
  State<BuySellReportView> createState() => _BuySellReportViewState();
}

class _BuySellReportViewState extends State<BuySellReportView> {
  static const _accent = Color(0xFF4F8AF4);
  static const _deep = Color(0xFF1E3C72);

  final _currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  final _caratFmt = NumberFormat('#,##0.00');
  final _dateFmt = DateFormat('dd MMM yyyy');
  final _monthFmt = DateFormat('MMMM yyyy');
  final _yearFmt = DateFormat('yyyy');

  _PeriodMode _mode = _PeriodMode.monthly;
  DateTime _monthAnchor = DateTime.now();
  int _yearAnchor = DateTime.now().year;
  DateTime _customStart =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _customEnd = DateTime.now();

  List<PurchaseModel> _allBuys = [];
  List<InvoiceModel> _allSells = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      PurchaseStorageService.getAllPurchases(),
      InvoiceStorageService.getAllInvoices(),
    ]);
    if (!mounted) return;
    setState(() {
      _allBuys = results[0] as List<PurchaseModel>;
      _allSells = results[1] as List<InvoiceModel>;
      _loading = false;
    });
  }

  DateTime get _rangeStart {
    switch (_mode) {
      case _PeriodMode.monthly:
        return DateTime(_monthAnchor.year, _monthAnchor.month, 1);
      case _PeriodMode.yearly:
        return DateTime(_yearAnchor, 1, 1);
      case _PeriodMode.custom:
        return DateTime(
            _customStart.year, _customStart.month, _customStart.day);
    }
  }

  DateTime get _rangeEnd {
    switch (_mode) {
      case _PeriodMode.monthly:
        return DateTime(_monthAnchor.year, _monthAnchor.month + 1, 0,
            23, 59, 59);
      case _PeriodMode.yearly:
        return DateTime(_yearAnchor, 12, 31, 23, 59, 59);
      case _PeriodMode.custom:
        return DateTime(_customEnd.year, _customEnd.month, _customEnd.day,
            23, 59, 59);
    }
  }

  String get _periodLabel {
    switch (_mode) {
      case _PeriodMode.monthly:
        return _monthFmt.format(_monthAnchor);
      case _PeriodMode.yearly:
        return _yearFmt.format(DateTime(_yearAnchor));
      case _PeriodMode.custom:
        return '${_dateFmt.format(_customStart)} → ${_dateFmt.format(_customEnd)}';
    }
  }

  List<PurchaseModel> get _buys {
    final s = _rangeStart;
    final e = _rangeEnd;
    final list = _allBuys
        .where((p) => !p.buyDate.isBefore(s) && !p.buyDate.isAfter(e))
        .toList();
    list.sort((a, b) => b.buyDate.compareTo(a.buyDate));
    return list;
  }

  List<InvoiceModel> get _sells {
    final s = _rangeStart;
    final e = _rangeEnd;
    final list = _allSells
        .where((i) =>
            !i.invoiceDate.isBefore(s) && !i.invoiceDate.isAfter(e))
        .toList();
    list.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
    return list;
  }

  double get _totalBuyCarat =>
      _buys.fold(0.0, (s, p) => s + p.totalCarat);
  double get _totalBuyAmount =>
      _buys.fold(0.0, (s, p) => s + p.netAmount);
  double get _totalSellCarat =>
      _sells.fold(0.0, (s, i) => s + i.totalCarat);
  double get _totalSellAmount =>
      _sells.fold(0.0, (s, i) => s + i.grandTotal);
  double get _net => _totalSellAmount - _totalBuyAmount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBarFactory.build(
        title: 'Buy / Sell Report',
        onBackPress: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          _backdrop(),
          SafeArea(
            child: Column(
              children: [
                _periodTabs(),
                _periodSelector(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(
                                16, 8, 16, 120),
                            children: [
                              _summaryCard(),
                              const SizedBox(height: 16),
                              _sectionHeader(
                                  'Buy Entries',
                                  _buys.length,
                                  Colors.orange,
                                  Icons.shopping_bag_rounded),
                              const SizedBox(height: 8),
                              if (_buys.isEmpty)
                                _emptyRow('No purchases in this period'),
                              ..._buys.map(_buyRow),
                              const SizedBox(height: 16),
                              _sectionHeader(
                                  'Sell Entries',
                                  _sells.length,
                                  Colors.green,
                                  Icons.sell_rounded),
                              const SizedBox(height: 8),
                              if (_sells.isEmpty)
                                _emptyRow('No sells in this period'),
                              ..._sells.map(_sellRow),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _actionBar(),
    );
  }

  Widget _actionBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _viewReport,
                icon: const Icon(Icons.remove_red_eye_rounded),
                label: const Text('View Report'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accent,
                  side: const BorderSide(color: _accent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _downloadPdf,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download_rounded),
                label: Text(_busy ? 'Preparing…' : 'Download PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodTabs() {
    Widget tab(String label, _PeriodMode mode) {
      final selected = _mode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _mode = mode),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? _deep : Colors.grey[600],
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          tab('Monthly', _PeriodMode.monthly),
          tab('Yearly', _PeriodMode.yearly),
          tab('Custom', _PeriodMode.custom),
        ],
      ),
    );
  }

  Widget _periodSelector() {
    switch (_mode) {
      case _PeriodMode.monthly:
        return _monthPicker();
      case _PeriodMode.yearly:
        return _yearPicker();
      case _PeriodMode.custom:
        return _customPicker();
    }
  }

  Widget _monthPicker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => setState(() => _monthAnchor = DateTime(
                _monthAnchor.year, _monthAnchor.month - 1, 1)),
          ),
          Expanded(
            child: Center(
              child: Text(
                _monthFmt.format(_monthAnchor),
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _deep,
                    fontSize: 15),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              final now = DateTime.now();
              final next = DateTime(
                  _monthAnchor.year, _monthAnchor.month + 1, 1);
              if (!next.isAfter(DateTime(now.year, now.month, 1))) {
                setState(() => _monthAnchor = next);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _yearPicker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => setState(() => _yearAnchor--),
          ),
          Expanded(
            child: Center(
              child: Text(
                _yearAnchor.toString(),
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _deep,
                    fontSize: 15),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              if (_yearAnchor < DateTime.now().year) {
                setState(() => _yearAnchor++);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _customPicker() {
    Widget field(String label, DateTime value, ValueChanged<DateTime> onPick,
        {DateTime? firstDate}) {
      return Expanded(
        child: InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: firstDate ?? DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (d != null) onPick(d);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: _accent),
                    const SizedBox(width: 6),
                    Text(_dateFmt.format(value),
                        style: const TextStyle(
                            fontSize: 13,
                            color: _deep,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          field('From', _customStart, (d) {
            setState(() {
              _customStart = d;
              if (_customEnd.isBefore(_customStart)) _customEnd = _customStart;
            });
          }),
          const SizedBox(width: 10),
          field('To', _customEnd, (d) => setState(() => _customEnd = d),
              firstDate: _customStart),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_deep, _accent]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_periodLabel,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _summaryBlock(
                  label: 'BUY',
                  value: _currencyFmt.format(_totalBuyAmount),
                  sub: '${_buys.length} · ${_caratFmt.format(_totalBuyCarat)} ct',
                  color: Colors.orangeAccent,
                ),
              ),
              Container(width: 1, height: 44, color: Colors.white24),
              Expanded(
                child: _summaryBlock(
                  label: 'SELL',
                  value: _currencyFmt.format(_totalSellAmount),
                  sub: '${_sells.length} · ${_caratFmt.format(_totalSellCarat)} ct',
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            children: [
              Icon(
                _net >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: _net >= 0 ? Colors.greenAccent : Colors.redAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text('Net (Sell − Buy):',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              Text(
                '${_net >= 0 ? '+' : '-'} ${_currencyFmt.format(_net.abs())}',
                style: TextStyle(
                    color:
                        _net >= 0 ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryBlock({
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _sectionHeader(
      String title, int count, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                color: _deep,
                fontSize: 14,
                fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buyRow(PurchaseModel p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag_rounded,
                color: Colors.orange, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    p.sellerName.isNotEmpty
                        ? p.sellerName
                        : 'Unknown Seller',
                    style: const TextStyle(
                        color: _deep,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${_dateFmt.format(p.buyDate)} · ${_caratFmt.format(p.totalCarat)} ct${p.size.isNotEmpty ? ' · ${p.size}' : ''}',
                  style:
                      TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          Text(_currencyFmt.format(p.netAmount),
              style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _sellRow(InvoiceModel i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
                i.isCashSell
                    ? Icons.payments_rounded
                    : Icons.receipt_long_rounded,
                color: Colors.green,
                size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          i.buyerName.isNotEmpty
                              ? i.buyerName
                              : 'Unnamed Buyer',
                          style: const TextStyle(
                              color: _deep,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: (i.isCashSell
                                ? const Color(0xFF2E7D32)
                                : _accent)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        i.isCashSell ? 'Cash' : 'Bill',
                        style: TextStyle(
                            color: i.isCashSell
                                ? const Color(0xFF2E7D32)
                                : _accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_dateFmt.format(i.invoiceDate)} · ${i.invoiceNo} · ${_caratFmt.format(i.totalCarat)} ct',
                  style:
                      TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          Text(_currencyFmt.format(i.grandTotal),
              style: const TextStyle(
                  color: Colors.green,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _emptyRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(text,
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ),
    );
  }

  Widget _backdrop() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE7EEFF), Color(0xFFF9FBFF)],
        ),
      ),
    );
  }

  Future<Uint8List> _buildPdfBytes() async {
    final pdf = await BuySellReportPdfService.build(
      purchases: _buys,
      sells: _sells,
      periodLabel: _periodLabel,
      start: _rangeStart,
      end: _rangeEnd,
    );
    return pdf.save();
  }

  Future<void> _viewReport() async {
    if (_busy) return;
    if (_buys.isEmpty && _sells.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nothing to preview for this period')));
      return;
    }
    setState(() => _busy = true);
    Uint8List bytes;
    try {
      bytes = await _buildPdfBytes();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PDF failed: $e'), backgroundColor: Colors.red));
      return;
    }
    if (mounted) setState(() => _busy = false);
    try {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Preview failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _downloadPdf() async {
    if (_busy) return;
    if (_buys.isEmpty && _sells.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nothing to download for this period')));
      return;
    }
    setState(() => _busy = true);
    File file;
    try {
      final bytes = await _buildPdfBytes();
      final dir = await getApplicationDocumentsDirectory();
      final safeLabel = _periodLabel
          .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final stamp = DateTime.now().millisecondsSinceEpoch;
      file = File(
          '${dir.path}/BuySell_Report_${safeLabel}_$stamp.pdf');
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PDF failed: $e'), backgroundColor: Colors.red));
      return;
    }
    if (mounted) setState(() => _busy = false);
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Buy / Sell Report – $_periodLabel',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Share failed: $e'), backgroundColor: Colors.red));
    }
  }
}
