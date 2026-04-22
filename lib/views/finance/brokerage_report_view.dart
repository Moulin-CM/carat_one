import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/invoice_model.dart';
import '../../models/purchase_model.dart';
import '../../services/brokerage_report_pdf_service.dart';
import '../../services/invoice_storage_service.dart';
import '../../services/purchase_storage_service.dart';
import '../../viewmodels/brokerage_report_data.dart';
import '../../widgets/app_bar_factory.dart';

enum _PeriodMode { monthly, yearly, custom }

class BrokerageReportView extends StatefulWidget {
  const BrokerageReportView({super.key});

  @override
  State<BrokerageReportView> createState() => _BrokerageReportViewState();
}

class _BrokerageReportViewState extends State<BrokerageReportView> {
  static const _accent = Color(0xFF4F8AF4);
  static const _deep = Color(0xFF1E3C72);

  final _currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  final _caratFmt = NumberFormat('#,##0.00');
  final _dateFmt = DateFormat('dd MMM yyyy');
  final _monthFmt = DateFormat('MMMM yyyy');
  final _yearFmt = DateFormat('yyyy');

  _PeriodMode _mode = _PeriodMode.yearly;
  DateTime _monthAnchor = DateTime.now();
  int _yearAnchor = DateTime.now().year;
  DateTime _customStart =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _customEnd = DateTime.now();

  List<PurchaseModel> _allBuys = [];
  List<InvoiceModel> _allSells = [];
  List<BrokerAggregate> _aggregates = [];
  bool _loading = true;
  bool _busy = false;

  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        PurchaseStorageService.getAllPurchases(),
        InvoiceStorageService.getAllInvoices(),
      ]);
      if (!mounted) return;
      _allBuys = results[0] as List<PurchaseModel>;
      _allSells = results[1] as List<InvoiceModel>;
      _recompute();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Rebuilds [_aggregates] from the cached data + current period.
  /// Keep this the single source of truth so rebuilds never see a
  /// stale or partially-computed list.
  void _recompute() {
    _aggregates = BrokerageReportBuilder.build(
      purchases: _allBuys,
      invoices: _allSells,
      start: _rangeStart,
      end: _rangeEnd,
    );
  }

  void _setMode(_PeriodMode mode) {
    setState(() {
      _mode = mode;
      _recompute();
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

  double get _grandTotal =>
      _aggregates.fold(0.0, (s, b) => s + b.totalCharge);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBarFactory.build(
        title: 'Brokerage Report',
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
                              if (_aggregates.isEmpty)
                                _emptyPanel()
                              else
                                ..._aggregates
                                    .map((b) => _brokerCard(b)),
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

  Widget _emptyPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(Icons.handshake_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text('No brokerage entries in this period',
              style: TextStyle(
                  color: _deep, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Widen the date range above, or add a Broker Name / Broker Charge % to existing purchases or invoices so they appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final brokerCount = _aggregates.length;
    final entryCount =
        _aggregates.fold<int>(0, (s, b) => s + b.entries.length);
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
                  label: 'BROKERS',
                  value: brokerCount.toString(),
                  color: Colors.white,
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(
                child: _summaryBlock(
                  label: 'ENTRIES',
                  value: entryCount.toString(),
                  color: Colors.white,
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(
                child: _summaryBlock(
                  label: 'TOTAL',
                  value: _currencyFmt.format(_grandTotal),
                  color: Colors.amberAccent,
                ),
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
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: color.withOpacity(0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _brokerCard(BrokerAggregate b) {
    final open = _expanded.contains(b.name);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() {
              if (open) {
                _expanded.remove(b.name);
              } else {
                _expanded.add(b.name);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.handshake_rounded,
                        color: _accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.name,
                            style: const TextStyle(
                                color: _deep,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          '${b.entries.length} ${b.entries.length == 1 ? 'entry' : 'entries'} · '
                          '${b.buyCount} buy · ${b.sellCount} sell · ${_caratFmt.format(b.totalCarat)} ct',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_currencyFmt.format(b.totalCharge),
                          style: const TextStyle(
                              color: _accent,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      Icon(
                        open
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: Colors.grey[500],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  const Divider(height: 0),
                  const SizedBox(height: 8),
                  ...b.entries.map(_entryRow),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _entryRow(BrokerEntry e) {
    final isBuy = e.side == BrokerSide.buy;
    final sideColor = isBuy ? Colors.orange : Colors.green;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: sideColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: sideColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isBuy ? 'BUY' : 'SELL',
              style: TextStyle(
                  color: sideColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.personName.isNotEmpty ? e.personName : '-',
                  style: const TextStyle(
                      color: _deep,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_dateFmt.format(e.date)} · ${e.itemLabel} · ${_caratFmt.format(e.carat)} ct',
                  style:
                      TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          Text(_currencyFmt.format(e.charge),
              style: TextStyle(
                  color: sideColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ],
      ),
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
          onTap: () => _setMode(mode),
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
            onPressed: () => setState(() {
              _monthAnchor = DateTime(
                  _monthAnchor.year, _monthAnchor.month - 1, 1);
              _recompute();
            }),
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
                setState(() {
                  _monthAnchor = next;
                  _recompute();
                });
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
            onPressed: () => setState(() {
              _yearAnchor--;
              _recompute();
            }),
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
                setState(() {
                  _yearAnchor++;
                  _recompute();
                });
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
              _recompute();
            });
          }),
          const SizedBox(width: 10),
          field('To', _customEnd, (d) => setState(() {
                _customEnd = d;
                _recompute();
              }),
              firstDate: _customStart),
        ],
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
    final pdf = await BrokerageReportPdfService.build(
      brokers: _aggregates,
      periodLabel: _periodLabel,
      start: _rangeStart,
      end: _rangeEnd,
    );
    return pdf.save();
  }

  Future<void> _viewReport() async {
    if (_busy) return;
    if (_aggregates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nothing to preview for this period')));
      return;
    }

    setState(() => _busy = true);
    Uint8List? bytes;
    try {
      bytes = await _buildPdfBytes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('PDF failed: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      // Always re-enable the buttons, even if anything above threw or
      // the widget was briefly unmounted.
      if (mounted) setState(() => _busy = false);
    }
    if (bytes == null) return;

    try {
      await Printing.layoutPdf(onLayout: (_) async => bytes!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Preview failed: $e'),
            backgroundColor: Colors.red));
      }
    }

    // Returning from the preview route on some platforms resets the
    // list's compute state — reload so the data + aggregates are
    // always in sync with what's on disk.
    if (mounted) await _load();
  }

  Future<void> _downloadPdf() async {
    if (_busy) return;
    if (_aggregates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nothing to download for this period')));
      return;
    }

    setState(() => _busy = true);
    File? file;
    try {
      final bytes = await _buildPdfBytes();
      final dir = await getApplicationDocumentsDirectory();
      final safeLabel = _periodLabel
          .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final stamp = DateTime.now().millisecondsSinceEpoch;
      file = File(
          '${dir.path}/Brokerage_Report_${safeLabel}_$stamp.pdf');
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('PDF failed: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (file == null) return;

    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Brokerage Report – $_periodLabel',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Share failed: $e'),
            backgroundColor: Colors.red));
      }
    }

    if (mounted) await _load();
  }
}
