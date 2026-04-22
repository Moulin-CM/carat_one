import 'package:flutter/foundation.dart';
import '../models/purchase_model.dart';
import '../models/expense_model.dart';
import '../models/withdrawal_model.dart';
import '../models/invoice_model.dart';
import '../models/app_settings_model.dart';
import '../services/purchase_storage_service.dart';
import '../services/expense_storage_service.dart';
import '../services/withdrawal_storage_service.dart';
import '../services/invoice_storage_service.dart';
import '../services/settings_service.dart';

class PurchaseViewModel extends ChangeNotifier {
  List<PurchaseModel> _purchases = [];
  List<ExpenseModel> _expenses = [];
  List<WithdrawalModel> _withdrawals = [];
  List<InvoiceModel> _invoices = [];
  AppSettingsModel _settings = AppSettingsModel();
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<PurchaseModel> get purchases {
    if (_searchQuery.isEmpty) return _purchases;
    return _purchases.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.sellerName.toLowerCase().contains(q) ||
          p.brokerName.toLowerCase().contains(q) ||
          p.size.toLowerCase().contains(q);
    }).toList();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => purchases.isEmpty;

  AppSettingsModel get settings => _settings;
  DateTime? get yearEndDate => _settings.yearEndDate;
  DateTime? get currentYearStart => _settings.currentYearStart();
  double get manualOpeningCarat => _settings.manualOpeningCarat;
  double get manualOpeningAmount => _settings.manualOpeningAmount;

  /// Purchases that fall inside the currently active financial year and
  /// participate in financial totals. "For Other" entries are always
  /// excluded — they are kept for records only.
  List<PurchaseModel> get _purchasesInCurrentYear {
    final start = currentYearStart;
    final base = _purchases.where((p) => !p.isForOther);
    if (start == null) return base.toList();
    return base.where((p) => !p.buyDate.isBefore(start)).toList();
  }

  List<InvoiceModel> get _sellInvoicesInCurrentYear {
    final start = currentYearStart;
    final base = _invoices.where((inv) => !inv.isForOther);
    if (start == null) return base.toList();
    return base.where((inv) => !inv.invoiceDate.isBefore(start)).toList();
  }

  double get openingTotalCarat {
    final sum = _purchasesInCurrentYear
        .fold(0.0, (sum, p) => sum + p.totalCarat);
    return sum + manualOpeningCarat;
  }

  double get openingTotalAmount {
    final sum = _purchasesInCurrentYear
        .fold(0.0, (sum, p) => sum + p.totalAmount);
    return sum + manualOpeningAmount;
  }

  double get totalRemainingCarat =>
      _purchasesInCurrentYear.fold(0.0, (sum, p) => sum + p.remainingCarat);

  /// Total sell amount in the current year = manual carry-forward + grand
  /// totals of invoices in this year. Matches the Opening Amount tile on
  /// the Invoice tab. "For Other" invoices are excluded.
  double get totalSellAmount =>
      _settings.manualOpeningSellAmount +
      _sellInvoicesInCurrentYear.fold(0.0, (sum, inv) => sum + inv.grandTotal);

  /// Sales Profit = (sell amount) − (buy amount) for the current year.
  /// Previously this summed [PurchaseModel.profitOrLoss] which only sees
  /// per-purchase cash/bill sold amounts — it ignored invoice-side sales
  /// and produced a number disconnected from the Opening Amount tiles.
  double get totalProfitOrLoss => totalSellAmount - openingTotalAmount;

  double get totalExpenses =>
      _expenses.fold(0.0, (sum, e) => sum + e.amount);

  double get outstandingWithdrawals => _withdrawals
      .where((w) => !w.isReturned)
      .fold(0.0, (sum, w) => sum + w.amount);

  /// Net Profit = sales profit − expenses − money still out on pre-mature
  /// withdrawals. Can be negative (shown as Loss).
  double get netProfitOrLoss =>
      totalProfitOrLoss - totalExpenses - outstandingWithdrawals;

  Future<void> loadPurchases() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        PurchaseStorageService.getAllPurchases(),
        ExpenseStorageService.getAllExpenses(),
        WithdrawalStorageService.getAllWithdrawals(),
        InvoiceStorageService.getAllInvoices(),
        SettingsService.getSettings(),
      ]);
      _purchases = results[0] as List<PurchaseModel>;
      _expenses = results[1] as List<ExpenseModel>;
      _withdrawals = results[2] as List<WithdrawalModel>;
      _invoices = results[3] as List<InvoiceModel>;
      _settings = results[4] as AppSettingsModel;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void setSearchQuery(String q) {
    _searchQuery = q.toLowerCase();
    notifyListeners();
  }

  Future<bool> deletePurchase(String id) async {
    try {
      await PurchaseStorageService.deletePurchase(id);
      await loadPurchases();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> setYearEndDate(DateTime? date) async {
    _settings = _settings.copyWith(
      yearEndDate: date,
      clearYearEndDate: date == null,
    );
    await SettingsService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setManualOpeningCarat(double value) async {
    _settings = _settings.copyWith(manualOpeningCarat: value);
    await SettingsService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setManualOpeningAmount(double value) async {
    _settings = _settings.copyWith(manualOpeningAmount: value);
    await SettingsService.saveSettings(_settings);
    notifyListeners();
  }
}
