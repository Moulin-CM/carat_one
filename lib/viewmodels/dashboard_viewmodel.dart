import 'package:flutter/foundation.dart';
import '../models/invoice_model.dart';
import '../models/purchase_model.dart';
import '../models/withdrawal_model.dart';
import '../models/app_settings_model.dart';
import '../services/invoice_storage_service.dart';
import '../services/purchase_storage_service.dart';
import '../services/withdrawal_storage_service.dart';
import '../services/settings_service.dart';
import '../services/auth_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  List<InvoiceModel> _invoices = [];
  List<PurchaseModel> _purchases = [];
  List<WithdrawalModel> _withdrawals = [];
  AppSettingsModel _settings = AppSettingsModel();
  bool _isLoading = false;
  String? _errorMessage;

  List<InvoiceModel> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Number of sell entries (formerly "Total Invoices"). Includes every
  /// invoice record regardless of cash/bill mode or financial year.
  int get totalSells => _invoices.length;

  /// Number of purchase entries across all time.
  int get totalPurchases => _purchases.length;

  /// Remaining (unsold) carat in stock for the current financial year.
  /// Mirrors the figure on the Purchase tab. "For Other" purchases are
  /// excluded.
  double get totalRemainingCarat => _purchasesInCurrentYear
      .fold(0.0, (sum, p) => sum + p.remainingCarat);

  DateTime? get _yearStart => _settings.currentYearStart();

  List<PurchaseModel> get _purchasesInCurrentYear {
    final start = _yearStart;
    final base = _purchases.where((p) => !p.isForOther);
    if (start == null) return base.toList();
    return base.where((p) => !p.buyDate.isBefore(start)).toList();
  }

  List<InvoiceModel> get _invoicesInCurrentYear {
    final start = _yearStart;
    final base = _invoices.where((inv) => !inv.isForOther);
    if (start == null) return base.toList();
    return base.where((inv) => !inv.invoiceDate.isBefore(start)).toList();
  }

  double get totalRevenue =>
      _invoices.fold(0.0, (sum, invoice) => sum + invoice.grandTotal);

  /// Buy total for the current FY plus any manual carry-forward entered on
  /// the Purchase tab. Mirrors the Opening Amount shown there.
  double get totalBuyAmount =>
      _settings.manualOpeningAmount +
      _purchasesInCurrentYear.fold(0.0, (sum, p) => sum + p.netAmount);

  /// Sell total for the current FY plus any manual carry-forward entered on
  /// the Invoice tab. Mirrors the Opening Amount shown there.
  double get totalSellAmount =>
      _settings.manualOpeningSellAmount +
      _invoicesInCurrentYear.fold(0.0, (sum, inv) => sum + inv.grandTotal);

  /// Sales Profit = Sell − Buy for the current year. Aligned with the
  /// Purchase tab so the Dashboard and Purchase summary never disagree.
  double get totalSalesProfit => totalSellAmount - totalBuyAmount;

  double get outstandingWithdrawals => _withdrawals
      .where((w) => !w.isReturned)
      .fold(0.0, (sum, w) => sum + w.amount);

  /// Net Profit = Sales Profit − Outstanding Withdrawals. Expenses are
  /// intentionally excluded — they only affect the Expenses screen itself.
  double get netProfitOrLoss =>
      totalSalesProfit - outstandingWithdrawals;

  double get thisMonthRevenue {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    return _invoices
        .where((invoice) => invoice.invoiceDate
        .isAfter(firstDayOfMonth.subtract(const Duration(days: 1))))
        .fold(0.0, (sum, invoice) => sum + invoice.grandTotal);
  }

  int get thisMonthInvoices {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    return _invoices
        .where((invoice) => invoice.invoiceDate
        .isAfter(firstDayOfMonth.subtract(const Duration(days: 1))))
        .length;
  }

  List<InvoiceModel> get recentInvoices {
    final sorted = List<InvoiceModel>.from(_invoices);
    sorted.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
    return sorted.take(5).toList();
  }

  Map<String, double> get monthlyRevenue {
    final Map<String, double> monthly = {};
    for (var invoice in _invoices) {
      final monthKey =
          '${invoice.invoiceDate.year}-${invoice.invoiceDate.month.toString().padLeft(2, '0')}';
      monthly[monthKey] = (monthly[monthKey] ?? 0.0) + invoice.grandTotal;
    }
    return monthly;
  }

  Future<void> loadInvoices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        InvoiceStorageService.getAllInvoices(),
        PurchaseStorageService.getAllPurchases(),
        WithdrawalStorageService.getAllWithdrawals(),
        SettingsService.getSettings(),
      ]);
      _invoices = results[0] as List<InvoiceModel>;
      _purchases = results[1] as List<PurchaseModel>;
      _withdrawals = results[2] as List<WithdrawalModel>;
      _settings = results[3] as AppSettingsModel;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _authService.signOut();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
