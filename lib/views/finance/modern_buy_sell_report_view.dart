import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/invoice_model.dart';
import '../../models/purchase_model.dart';
import '../../models/subscription_plan.dart';
import '../../services/buy_sell_report_pdf_service.dart';
import '../../services/invoice_storage_service.dart';
import '../../services/purchase_storage_service.dart';
import '../../services/subscription_service.dart';
import '../../widgets/list_skeleton.dart';
import '../subscription/subscription_plans_view.dart';
import '../../constants/app_translations.dart';

enum _PeriodMode { monthly, yearly, custom }

/// Modern UI surface for the Buy / Sell Report screen.
///
/// Same state, same period logic, same PDF actions as the classic view.
/// Only the visuals change — dark navy backdrop, gradient hero summary,
/// glass list rows, and two floating gradient action pills at the bottom.
class ModernBuySellReportView extends StatefulWidget {
  const ModernBuySellReportView({super.key});

  @override
  State<ModernBuySellReportView> createState() =>
      _ModernBuySellReportViewState();
}

class _ModernBuySellReportViewState extends State<ModernBuySellReportView> {
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

  final _currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  final _caratFmt = NumberFormat('#,##0.00');
  final _dateFmt = DateFormat('dd MMM yyyy'.tr);
  final _monthFmt = DateFormat('MMMM yyyy'.tr);
  final _yearFmt = DateFormat('yyyy'.tr);

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

  final _subService = SubscriptionService();

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
                              const SizedBox(height: 20),
                              _buildSectionHeader(
                                  'Buy Entries'.tr,
                                  _buys.length,
                                  const Color(0xFFFBBF24),
                                  Icons.shopping_bag_rounded),
                              const SizedBox(height: 10),
                              if (_buys.isEmpty)
                                _emptyRow('No purchases in this period'.tr),
                              ..._buys.map(_buyRow),
                              const SizedBox(height: 20),
                              _buildSectionHeader(
                                  'Sell Entries'.tr,
                                  _sells.length,
                                  const Color(0xFF34D399),
                                  Icons.sell_rounded),
                              const SizedBox(height: 10),
                              if (_sells.isEmpty)
                                _emptyRow('No sells in this period'.tr),
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
          'Buy / Sell Report'.tr,
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
      final status = _subService.currentStatus;
      final isLocked =
          (mode == _PeriodMode.yearly || mode == _PeriodMode.custom) &&
              status.plan == SubscriptionTier.starter;

      return Expanded(
        child: GestureDetector(
          onTap: () {
            if (isLocked) {
              _showUpgradeDialog(
                  'Yearly and Custom reports are available in Pro and Business plans.'
                      .tr);
              return;
            }
            setState(() => _mode = mode);
          },
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLocked)
                  Icon(Icons.lock_outline_rounded,
                      size: 12,
                      color: Colors.white.withOpacity(0.45)),
                if (isLocked) const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isLocked
                        ? Colors.white.withOpacity(0.45)
                        : (selected
                            ? Colors.white
                            : Colors.white.withOpacity(0.65)),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
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

  void _showUpgradeDialog(String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
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
                color: _accent.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: _violet.withOpacity(0.18),
                blurRadius: 22,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium icon medallion
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFBBF24).withOpacity(0.45),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              // Title with gradient text
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1)],
                ).createShader(rect),
                child: Text(
                  'Upgrade Plan'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.70),
                  fontSize: 13.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              // Actions
              Row(
                children: [
                  Expanded(child: _dialogCancelButton(context)),
                  const SizedBox(width: 12),
                  Expanded(child: _dialogViewPlansButton(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogCancelButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Center(
            child: Text(
              'Cancel'.tr,
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

  Widget _dialogViewPlansButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const SubscriptionPlansView()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: _grad,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.40),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                'View Plans'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
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
      onPrev: () => setState(() => _monthAnchor =
          DateTime(_monthAnchor.year, _monthAnchor.month - 1, 1)),
      onNext: () {
        final now = DateTime.now();
        final next =
            DateTime(_monthAnchor.year, _monthAnchor.month + 1, 1);
        if (!next.isAfter(DateTime(now.year, now.month, 1))) {
          setState(() => _monthAnchor = next);
        }
      },
    );
  }

  Widget _buildYearPicker() {
    return _stepperPill(
      label: _yearAnchor.toString(),
      onPrev: () => setState(() => _yearAnchor--),
      onNext: () {
        if (_yearAnchor < DateTime.now().year) {
          setState(() => _yearAnchor++);
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
            icon: const Icon(Icons.chevron_left_rounded,
                color: _accent),
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
            icon: const Icon(Icons.chevron_right_rounded,
                color: _accent),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomPicker() {
    Widget field(String label, DateTime value, ValueChanged<DateTime> onPick,
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
                border: Border.all(color: Colors.white.withOpacity(0.10)),
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

  // ─────────────────────────────  SUMMARY CARD  ───────────────────────────

  Widget _buildSummaryCard() {
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
                child: const Icon(Icons.analytics_rounded,
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
                  label: 'BUY'.tr,
                  value: _currencyFmt.format(_totalBuyAmount),
                  sub:
                      '${_buys.length} · ${_caratFmt.format(_totalBuyCarat)} ct',
                  color: const Color(0xFFFBBF24),
                ),
              ),
              Container(
                  width: 1,
                  height: 44,
                  color: Colors.white.withOpacity(0.24)),
              Expanded(
                child: _summaryBlock(
                  label: 'SELL'.tr,
                  value: _currencyFmt.format(_totalSellAmount),
                  sub:
                      '${_sells.length} · ${_caratFmt.format(_totalSellCarat)} ct',
                  color: const Color(0xFF34D399),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Container(
                height: 1, color: Colors.white.withOpacity(0.24)),
          ),
          Row(
            children: [
              Icon(
                _net >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: _net >= 0
                    ? const Color(0xFF34D399)
                    : const Color(0xFFFCA5A5),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Net (Sell − Buy):'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '${_net >= 0 ? '+' : '-'} ${_currencyFmt.format(_net.abs())}',
                style: TextStyle(
                  color: _net >= 0
                      ? const Color(0xFF34D399)
                      : const Color(0xFFFCA5A5),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
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
    required String sub,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────  SECTION + ROWS  ─────────────────────────

  Widget _buildSectionHeader(
      String title, int count, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.30)),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buyRow(PurchaseModel p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shopping_bag_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.sellerName.isNotEmpty
                      ? p.sellerName
                      : 'Unknown Seller'.tr,
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
                  '${_dateFmt.format(p.buyDate)} · ${_caratFmt.format(p.totalCarat)} ct${p.size.isNotEmpty ? ' · ${p.size}' : ''}',
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
            _currencyFmt.format(p.netAmount),
            style: const TextStyle(
              color: Color(0xFFFBBF24),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sellRow(InvoiceModel i) {
    final tagColor =
        i.isCashSell ? const Color(0xFF34D399) : _accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              i.isCashSell
                  ? Icons.payments_rounded
                  : Icons.receipt_long_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i.buyerName.isNotEmpty
                      ? i.buyerName
                      : 'Unnamed Buyer'.tr,
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
                  '${_dateFmt.format(i.invoiceDate)} · ${i.invoiceNo} · ${_caratFmt.format(i.totalCarat)} ct',
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
          const SizedBox(width: 10),
          // Cash/Bill pill stacks above the amount on the right so it
          // never crowds or overlaps the price for short buyer names.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: tagColor.withOpacity(0.40)),
                ),
                child: Text(
                  i.isCashSell ? 'Cash'.tr : 'Bill'.tr,
                  style: TextStyle(
                    color: tagColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currencyFmt.format(i.grandTotal),
                style: const TextStyle(
                  color: Color(0xFF34D399),
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

  Widget _emptyRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 12,
          ),
        ),
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
              if ((loading || icon != null)) const SizedBox(width: 8),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Nothing to preview for this period'.tr)));
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
          content: Text('${'PDF failed'.tr}: $e'),
          backgroundColor: Colors.red));
      return;
    }
    if (mounted) setState(() => _busy = false);
    try {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${'Preview failed'.tr}: $e'),
          backgroundColor: Colors.red));
    }
  }

  Future<void> _downloadPdf() async {
    if (_busy) return;
    if (_buys.isEmpty && _sells.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Nothing to download for this period'.tr)));
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
      file = File('${dir.path}/BuySell_Report_${safeLabel}_$stamp.pdf');
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${'PDF failed'.tr}: $e'),
          backgroundColor: Colors.red));
      return;
    }
    if (mounted) setState(() => _busy = false);
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${'Buy / Sell Report'.tr} – $_periodLabel',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${'Share failed'.tr}: $e'),
          backgroundColor: Colors.red));
    }
  }
}
