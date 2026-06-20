import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/ledger_entry.dart';
import '../../services/expense_report_pdf_service.dart';
import '../../viewmodels/purchase_viewmodel.dart';
import '../../widgets/app_bar_factory.dart';
import '../../constants/app_translations.dart';

import '../../widgets/list_skeleton.dart';


import 'package:invoice_generator/constants/app_translations.dart';

enum _PeriodMode { monthly, yearly, custom }

class ExpenseReportView extends StatelessWidget {
  const ExpenseReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PurchaseViewModel()..loadPurchases(),
      child: const _ExpenseReportContent(),
    );
  }
}

class _ExpenseReportContent extends StatefulWidget {
  const _ExpenseReportContent();

  @override
  State<_ExpenseReportContent> createState() => _ExpenseReportContentState();
}

class _ExpenseReportContentState extends State<_ExpenseReportContent> {
  static const _accent = Color(0xFF4F8AF4);
  static const _deep = Color(0xFF1E3C72);

  final _currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  final _dateFmt = DateFormat('dd MMM yyyy'.tr);
  final _monthFmt = DateFormat('MMMM yyyy'.tr);
  final _yearFmt = DateFormat('yyyy'.tr);
  final _dayLabelFmt = DateFormat('EEE, dd MMM yyyy'.tr);

  _PeriodMode _mode = _PeriodMode.monthly;
  DateTime _monthAnchor = DateTime.now();
  int _yearAnchor = DateTime.now().year;
  DateTime _customStart =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _customEnd = DateTime.now();

  bool _exporting = false;

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

  List<LedgerEntry> _filteredFor(PurchaseViewModel vm) {
    final start = _rangeStart;
    final end = _rangeEnd;
    return vm.ledgerEntries
        .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double _creditTotalOf(List<LedgerEntry> items) => items
      .where((e) => !e.isDebit)
      .fold(0.0, (s, e) => s + e.amount);

  double _debitTotalOf(List<LedgerEntry> items) => items
      .where((e) => e.isDebit)
      .fold(0.0, (s, e) => s + e.amount);

  Map<String, List<LedgerEntry>> _groupByDay(List<LedgerEntry> items) {
    final map = <String, List<LedgerEntry>>{};
    for (final e in items) {
      final key = _dayLabelFmt.format(e.date);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PurchaseViewModel>();
    final filtered = _filteredFor(vm);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBarFactory.build(
        title: 'Expense Statement'.tr,
        onBackPress: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'View / Print PDF'.tr,
            onPressed: _exporting ? null : () => _printPdf(filtered),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share PDF'.tr,
            onPressed: _exporting ? null : () => _sharePdf(filtered),
          ),
        ],
      ),
      body: Stack(
        children: [
          _backdrop(),
          SafeArea(
            child: Column(
              children: [
                _periodTabs(),
                _periodSelector(),
                _summaryCard(filtered),
                Expanded(
                  child: vm.isLoading
                      ? const ListSkeleton()
                      : (filtered.isEmpty
                          ? _emptyState()
                          : _transactionList(filtered, vm)),
                ),
              ],
            ),
          ),
        ],
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
          tab('Monthly'.tr, _PeriodMode.monthly),
          tab('Yearly'.tr, _PeriodMode.yearly),
          tab('Custom'.tr, _PeriodMode.custom),
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
            onPressed: () {
              setState(() {
                _monthAnchor = DateTime(
                    _monthAnchor.year, _monthAnchor.month - 1, 1);
              });
            },
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
          field('From'.tr, _customStart, (d) {
            setState(() {
              _customStart = d;
              if (_customEnd.isBefore(_customStart)) _customEnd = _customStart;
            });
          }),
          const SizedBox(width: 10),
          field('To'.tr, _customEnd, (d) => setState(() => _customEnd = d),
              firstDate: _customStart),
        ],
      ),
    );
  }

  Widget _summaryCard(List<LedgerEntry> filtered) {
    final count = filtered.length;
    final creditTotal = _creditTotalOf(filtered);
    final debitTotal = _debitTotalOf(filtered);
    final net = creditTotal - debitTotal;
    final netStr =
        '${net >= 0 ? '+' : '-'} ${_currencyFmt.format(net.abs())}';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_deep, _accent]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_periodLabel,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _summaryStat(
                    'Credits'.tr,
                    '+ ${_currencyFmt.format(creditTotal)}',
                    Colors.greenAccent),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: _summaryStat(
                    'Debits'.tr,
                    '- ${_currencyFmt.format(debitTotal)}',
                    Colors.redAccent),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: _summaryStat(
                    'Net'.tr,
                    netStr,
                    net >= 0 ? Colors.greenAccent : Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('$count ${count == 1 ? 'entry'.tr : 'entries'.tr}',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w800,
                fontSize: 14)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _transactionList(List<LedgerEntry> filtered, PurchaseViewModel vm) {
    final grouped = _groupByDay(filtered);
    final sectionKeys = grouped.keys.toList();
    return RefreshIndicator(
      onRefresh: () => vm.loadPurchases(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: sectionKeys.length,
        itemBuilder: (ctx, i) {
          final key = sectionKeys[i];
          final entries = grouped[key]!;
          final subtotal = entries.fold<double>(
              0.0, (s, e) => s + (e.isDebit ? -e.amount : e.amount));
          final subColor = subtotal >= 0 ? Colors.green : Colors.red;
          final subStr =
              '${subtotal >= 0 ? '+' : '-'} ${_currencyFmt.format(subtotal.abs())}';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(key,
                          style: const TextStyle(
                              color: _deep,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                    ),
                    Text(subStr,
                        style: TextStyle(
                            color: subColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              ...entries.map(_entryRow),
            ],
          );
        },
      ),
    );
  }

  Widget _entryRow(LedgerEntry e) {
    final color = e.isDebit ? Colors.red : Colors.green;
    final icon = e.isDebit
        ? Icons.trending_down_rounded
        : Icons.trending_up_rounded;
    final sign = e.isDebit ? '-' : '+';
    final name = e.title.isNotEmpty ? e.title : 'Entry'.tr;
    final source = e.subtitle.isNotEmpty
        ? e.subtitle
        : (e.isDebit ? 'Debit'.tr : 'Credit'.tr);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _deep),
                ),
                const SizedBox(height: 2),
                Text(
                  source,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          Text('$sign ${_currencyFmt.format(e.amount)}'.tr,
            style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      children: [
        const SizedBox(height: 60),
        Icon(Icons.description_outlined,
            size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Center(
          child: Text('No entries in this period'.tr,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey)),
        ),
      ],
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

  Future<Uint8List> _buildPdfBytes(List<LedgerEntry> filtered) async {
    final pdf = await ExpenseReportPdfService.build(
      items: filtered,
      periodLabel: _periodLabel,
      start: _rangeStart,
      end: _rangeEnd,
    );
    return pdf.save();
  }

  Future<File> _buildPdfFile(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeLabel = _periodLabel
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file =
        File('${dir.path}/Expense_Statement_${safeLabel}_$stamp.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _printPdf(List<LedgerEntry> filtered) async {
    if (_exporting) return;
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Nothing to print for this period'.tr)));
      return;
    }
    setState(() => _exporting = true);

    Uint8List bytes;
    try {
      bytes = await _buildPdfBytes(filtered);
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${'PDF failed'.tr}: $e'), backgroundColor: Colors.red));
      return;
    }

    if (mounted) setState(() => _exporting = false);

    try {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${'Preview failed'.tr}: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _sharePdf(List<LedgerEntry> filtered) async {
    if (_exporting) return;
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Nothing to share for this period'.tr)));
      return;
    }
    setState(() => _exporting = true);

    File file;
    try {
      final bytes = await _buildPdfBytes(filtered);
      file = await _buildPdfFile(bytes);
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${'PDF failed'.tr}: $e'), backgroundColor: Colors.red));
      return;
    }

    if (mounted) setState(() => _exporting = false);

    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${'Expense Statement'.tr} – $_periodLabel',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${'Share failed'.tr}: $e'), backgroundColor: Colors.red));
    }
  }
}
