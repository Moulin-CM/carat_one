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
import '../../widgets/list_skeleton.dart';
import '../../constants/app_translations.dart';

enum _PeriodMode { monthly, yearly, custom }

/// Modern UI surface for the Brokerage Report screen.
///
/// Same data sources + builder + period logic + PDF view/download flows
/// as the classic view. Only the visual layer is restyled — dark navy
/// backdrop, gradient hero summary, glass broker cards with animated
/// expand, and two floating gradient action pills at the bottom.
class ModernBrokerageReportView extends StatefulWidget {
  const ModernBrokerageReportView({super.key});

  @override
  State<ModernBrokerageReportView> createState() =>
      _ModernBrokerageReportViewState();
}

class _ModernBrokerageReportViewState
    extends State<ModernBrokerageReportView> {
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

  final _currencyFmt =
      NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  final _caratFmt = NumberFormat('#,##0.00');
  final _dateFmt = DateFormat('dd MMM yyyy'.tr);
  final _monthFmt = DateFormat('MMMM yyyy'.tr);
  final _yearFmt = DateFormat('yyyy'.tr);

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
      backgroundColor: _bg0,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _buildPeriodTabs(),
                _buildPeriodSelector(),
                Expanded(
                  child: _loading
                      ? const ListSkeleton(dark: true)
                      : RefreshIndicator(
                          color: _accent,
                          backgroundColor: _bg1,
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(
                                16, 8, 16, 140),
                            children: [
                              _buildSummaryCard(),
                              const SizedBox(height: 16),
                              if (_aggregates.isEmpty)
                                _emptyPanel()
                              else
                                ..._aggregates.map(_brokerCard),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActions(context),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  // ─────────────────────────────  APP BAR  ────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1)],
        ).createShader(rect),
        child: Text(
          'Brokerage Report'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
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
            child: _glow(280, _primary.withOpacity(0.25)),
          ),
          Positioned(
            top: 240,
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

  // ─────────────────────────────  PERIOD TABS  ────────────────────────────

  Widget _buildPeriodTabs() {
    Widget tab(String label, _PeriodMode mode) {
      final selected = _mode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => _setMode(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: selected ? _grad : null,
              color: selected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _accent.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.white.withOpacity(0.65),
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
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
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

  // ─────────────────────────────  PERIOD SELECTOR  ────────────────────────

  Widget _buildPeriodSelector() {
    switch (_mode) {
      case _PeriodMode.monthly:
        return _buildMonthPicker();
      case _PeriodMode.yearly:
        return _buildYearPicker();
      case _PeriodMode.custom:
        return _buildCustomPicker();
    }
  }

  Widget _buildMonthPicker() {
    return _stepperPill(
      label: _monthFmt.format(_monthAnchor),
      onPrev: () => setState(() {
        _monthAnchor =
            DateTime(_monthAnchor.year, _monthAnchor.month - 1, 1);
        _recompute();
      }),
      onNext: () {
        final now = DateTime.now();
        final next =
            DateTime(_monthAnchor.year, _monthAnchor.month + 1, 1);
        if (!next.isAfter(DateTime(now.year, now.month, 1))) {
          setState(() {
            _monthAnchor = next;
            _recompute();
          });
        }
      },
    );
  }

  Widget _buildYearPicker() {
    return _stepperPill(
      label: _yearAnchor.toString(),
      onPrev: () => setState(() {
        _yearAnchor--;
        _recompute();
      }),
      onNext: () {
        if (_yearAnchor < DateTime.now().year) {
          setState(() {
            _yearAnchor++;
            _recompute();
          });
        }
      },
    );
  }

  Widget _stepperPill({
    required String label,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          IconButton(
            icon:
                const Icon(Icons.chevron_left_rounded, color: _accent),
            onPressed: onPrev,
          ),
          Expanded(
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.chevron_right_rounded, color: _accent),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomPicker() {
    Widget field(String label, DateTime value,
        ValueChanged<DateTime> onPick,
        {DateTime? firstDate}) {
      return Expanded(
        child: Material(
          color: Colors.transparent,
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
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 14, color: _accent),
                      const SizedBox(width: 6),
                      Text(
                        _dateFmt.format(value),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          field('From'.tr, _customStart, (d) {
            setState(() {
              _customStart = d;
              if (_customEnd.isBefore(_customStart)) {
                _customEnd = _customStart;
              }
              _recompute();
            });
          }),
          const SizedBox(width: 10),
          field('To'.tr, _customEnd, (d) {
            setState(() {
              _customEnd = d;
              _recompute();
            });
          }, firstDate: _customStart),
        ],
      ),
    );
  }

  // ─────────────────────────────  SUMMARY  ────────────────────────────────

  Widget _buildSummaryCard() {
    final brokerCount = _aggregates.length;
    final entryCount =
        _aggregates.fold<int>(0, (s, b) => s + b.entries.length);
    return Container(
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.handshake_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _periodLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summaryBlock(
                  label: 'BROKERS'.tr,
                  value: brokerCount.toString(),
                  color: Colors.white,
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withOpacity(0.24)),
              Expanded(
                child: _summaryBlock(
                  label: 'ENTRIES'.tr,
                  value: entryCount.toString(),
                  color: Colors.white,
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withOpacity(0.24)),
              Expanded(
                child: _summaryBlock(
                  label: 'TOTAL'.tr,
                  value: _currencyFmt.format(_grandTotal),
                  color: const Color(0xFFFBBF24),
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
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.85),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────  EMPTY  ──────────────────────────────────

  Widget _emptyPanel() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: _grad,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.handshake_outlined,
                size: 36, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            'No brokerage entries in this period'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Widen the date range above, or add a Broker Name / Broker Charge % to existing purchases or invoices so they appear here.'
                .tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────  BROKER CARD  ────────────────────────────

  Widget _brokerCard(BrokerAggregate b) {
    final open = _expanded.contains(b.name);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
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
                        gradient: _grad,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.handshake_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${b.entries.length} ${b.entries.length == 1 ? 'entry'.tr : 'entries'.tr} · '
                            '${b.buyCount} ${'buy'.tr} · ${b.sellCount} ${'sell'.tr} · ${_caratFmt.format(b.totalCarat)} ct',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currencyFmt.format(b.totalCharge),
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: open ? 0.5 : 0,
                          child: Icon(
                            Icons.expand_more_rounded,
                            color: Colors.white.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (open)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.08),
                    margin: const EdgeInsets.only(bottom: 10),
                  ),
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
    final sideColor = isBuy
        ? const Color(0xFFFBBF24)
        : const Color(0xFF34D399);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: sideColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: sideColor.withOpacity(0.30)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: sideColor.withOpacity(0.20),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: sideColor.withOpacity(0.45)),
            ),
            child: Text(
              isBuy ? 'BUY'.tr : 'SELL'.tr,
              style: TextStyle(
                color: sideColor,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.personName.isNotEmpty ? e.personName : '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_dateFmt.format(e.date)} · ${e.itemLabel} · ${_caratFmt.format(e.carat)} ct',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _currencyFmt.format(e.charge),
            style: TextStyle(
              color: sideColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────  FLOATING ACTIONS  ───────────────────────

  Widget _buildFloatingActions(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 32;
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Expanded(
            child: _floatingPill(
              icon: Icons.remove_red_eye_rounded,
              label: 'View Report'.tr,
              filled: false,
              onTap: _busy ? null : _viewReport,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _floatingPill(
              icon: _busy ? null : Icons.download_rounded,
              label: _busy ? 'Preparing…'.tr : 'Download PDF'.tr,
              filled: true,
              loading: _busy,
              onTap: _busy ? null : _downloadPdf,
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingPill({
    required IconData? icon,
    required String label,
    required bool filled,
    bool loading = false,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            gradient: filled && enabled ? _grad : null,
            color: filled
                ? (enabled ? null : Colors.white.withOpacity(0.10))
                : _bg1.withOpacity(0.85),
            borderRadius: BorderRadius.circular(18),
            border: filled
                ? null
                : Border.all(
                    color: _accent.withOpacity(enabled ? 0.65 : 0.25),
                    width: 1.5,
                  ),
            boxShadow: filled && enabled
                ? [
                    BoxShadow(
                      color: _primary.withOpacity(0.45),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: _violet.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: 18,
                  color: filled ? Colors.white : _accent,
                ),
              if (loading || icon != null) const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: filled ? Colors.white : _accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────  PDF ACTIONS  ────────────────────────────

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Nothing to preview for this period'.tr)));
      return;
    }

    setState(() => _busy = true);
    Uint8List? bytes;
    try {
      bytes = await _buildPdfBytes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${'PDF failed'.tr}: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (bytes == null) return;

    try {
      await Printing.layoutPdf(onLayout: (_) async => bytes!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${'Preview failed'.tr}: $e'),
            backgroundColor: Colors.red));
      }
    }

    if (mounted) await _load();
  }

  Future<void> _downloadPdf() async {
    if (_busy) return;
    if (_aggregates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Nothing to download for this period'.tr)));
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
            content: Text('${'PDF failed'.tr}: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (file == null) return;

    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${'Brokerage Report'.tr} – $_periodLabel',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${'Share failed'.tr}: $e'),
            backgroundColor: Colors.red));
      }
    }

    if (mounted) await _load();
  }
}
