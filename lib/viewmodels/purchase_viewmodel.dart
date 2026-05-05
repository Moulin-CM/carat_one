import 'package:flutter/foundation.dart';
import '../models/purchase_model.dart';
import '../models/expense_model.dart';
import '../models/withdrawal_model.dart';
import '../models/invoice_model.dart';
import '../models/app_settings_model.dart';
import '../models/stock_valuation_item.dart';
import '../services/purchase_storage_service.dart';
import '../services/expense_storage_service.dart';
import '../services/withdrawal_storage_service.dart';
import '../services/invoice_storage_service.dart';
import '../services/settings_service.dart';

enum LedgerEntryKind { expense, purchase, sale }

enum LedgerPaymentStatus { notApplicable, paid, partial, unpaid }

class LedgerEntry {
  final String id;
  final LedgerEntryKind kind;
  final String title;
  final String subtitle;
  final DateTime date;
  final double amount;
  final double settledAmount;
  final LedgerPaymentStatus paymentStatus;
  final bool isDebit;
  final bool isCashMode;

  const LedgerEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.settledAmount,
    required this.paymentStatus,
    required this.isDebit,
    required this.isCashMode,
  });
}

class PurchaseViewModel extends ChangeNotifier {
  List<PurchaseModel> _purchases = [];
  List<ExpenseModel> _expenses = [];
  List<WithdrawalModel> _withdrawals = [];
  List<InvoiceModel> _invoices = [];
  AppSettingsModel _settings = AppSettingsModel();
  bool _isLoading = false;
  bool _isSyncing = false;
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

  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => purchases.isEmpty;

  AppSettingsModel get settings => _settings;
  DateTime? get yearEndDate => _settings.yearEndDate;
  DateTime? get currentYearStart => _settings.currentYearStart();
  double get manualOpeningCarat => _settings.manualOpeningCarat;
  double get manualOpeningAmount => _settings.manualOpeningAmount;

  double get manualOpeningExpenseAmount => _settings.manualOpeningExpenseAmount;

  List<StockValuationItem> get stockValuationItems =>
      List.unmodifiable(_settings.stockValuationItems);
  double get stockValuationTotal => _settings.stockValuationItems
      .fold(0.0, (sum, item) => sum + item.totalValue);
  double get stockValuationCarats => _settings.stockValuationItems
      .fold(0.0, (sum, item) => sum + item.carats);

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
        .fold(0.0, (sum, p) => sum + p.netAmount);
    return sum + manualOpeningAmount;
  }

  double get totalRemainingCarat =>
      _purchasesInCurrentYear.fold(0.0, (sum, p) => sum + p.remainingCarat);

  /// Total carats sold out of this year's purchase lots. Computed from the
  /// purchase side (as opposed to summing invoice carats) so the figure
  /// lines up with [totalRemainingCarat] — i.e. opening = sold + remaining.
  double get totalSoldCarat =>
      _purchasesInCurrentYear.fold(0.0, (sum, p) => sum + p.totalSoldCarat);

  /// Total sell amount in the current year = manual carry-forward + grand
  /// totals of invoices in this year. Matches the Opening Amount tile on
  /// the Invoice tab. "For Other" invoices are excluded.
  double get totalSellAmount =>
      _settings.manualOpeningSellAmount +
      _sellInvoicesInCurrentYear.fold(0.0, (sum, inv) => sum + inv.grandTotal);

  /// Sales Profit = (sell amount + stock valuation) − (buy amount) for the current year.
  /// Including stock valuation (unsold inventory) is essential for an accurate
  /// profit/loss picture at the end of a period.
  double get totalProfitOrLoss =>
      (totalSellAmount + stockValuationTotal) - openingTotalAmount;

  double get outstandingWithdrawals => _withdrawals
      .where((w) => !w.isReturned)
      .fold(0.0, (sum, w) => sum + w.amount);

  /// Net Profit = sales profit − money still out on pre-mature withdrawals.
  /// Expenses are intentionally excluded — they only affect the Expenses
  /// screen's Final Amount and never roll up into business profitability.
  double get netProfitOrLoss => totalProfitOrLoss - outstandingWithdrawals;

  /// Entries shown on the Expenses screen. Only expense records are listed —
  /// purchases and sell invoices are NOT included. Each expense is either a
  /// Credit (money in) or a Debit (money out), and only moves the Final
  /// Amount on the Expenses screen itself.
  List<LedgerEntry> get ledgerEntries {
    final entries = <LedgerEntry>[];
    for (final e in _expenses) {
      entries.add(LedgerEntry(
        id: 'expense_${e.id}',
        kind: LedgerEntryKind.expense,
        title: e.personName.isNotEmpty ? e.personName : 'Expense',
        subtitle: '',
        date: e.expenseDate,
        amount: e.amount,
        settledAmount: e.amount,
        paymentStatus: LedgerPaymentStatus.notApplicable,
        isDebit: !e.isCredit,
        isCashMode: true,
      ));
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  double get ledgerDebitsPaid =>
      _expenses.where((e) => !e.isCredit).fold(0.0, (sum, e) => sum + e.amount);

  double get ledgerCreditsPaid =>
      _expenses.where((e) => e.isCredit).fold(0.0, (sum, e) => sum + e.amount);

  /// Banking-style available balance: every Debit must be backed by a Credit.
  /// Opening Amount is shown for reference only and is intentionally NOT
  /// part of this calculation — Debits cannot exceed the cash that has
  /// actually been received as Credits.
  double get ledgerFinalAmount =>
      ledgerCreditsPaid - ledgerDebitsPaid;

  /// Whether [amount] can be debited right now without overdrawing the
  /// available balance. A zero amount is always allowed (form-level
  /// validation rejects it separately).
  bool canDebit(double amount) =>
      amount <= 0 || amount <= ledgerFinalAmount;

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

  /// Recalculates the distribution of sales across purchase lots.
  /// This is useful when data becomes inconsistent (e.g. invoices added
  /// before purchases).
  Future<void> syncInventory() async {
    _isSyncing = true;
    notifyListeners();

    try {
      // 1. Load fresh data
      final purchases = await PurchaseStorageService.getAllPurchases();
      final invoices = await InvoiceStorageService.getAllInvoices();

      // 2. Reset sold fields for all purchases
      for (var p in purchases) {
        p.cashSoldCarat = 0.0;
        p.billSoldCarat = 0.0;
        p.cashSoldAmount = 0.0;
        p.billSoldAmount = 0.0;
      }

      // 3. Sort invoices by date to ensure FIFO consistency
      invoices.sort((a, b) => a.invoiceDate.compareTo(b.invoiceDate));
      // Sort purchases by added date as per distribution logic
      purchases.sort((a, b) => a.addedDate.compareTo(b.addedDate));

      // 4. Re-distribute each invoice
      for (var inv in invoices) {
        if (inv.isForOther) continue;

        double remainingToDeduct = inv.totalCarat;
        double totalAmount = inv.totalAmount;
        bool isCash = inv.isCashSell;

        for (var p in purchases) {
          if (remainingToDeduct <= 0) break;
          if (p.remainingCarat <= 0) continue;

          double deduct = remainingToDeduct > p.remainingCarat
              ? p.remainingCarat
              : remainingToDeduct;
          double portionAmount = (deduct / inv.totalCarat) * totalAmount;

          if (isCash) {
            p.cashSoldCarat += deduct;
            p.cashSoldAmount += portionAmount;
          } else {
            p.billSoldCarat += deduct;
            p.billSoldAmount += portionAmount;
          }
          remainingToDeduct -= deduct;
        }
      }

      // 5. Save all updated purchases
      for (var p in purchases) {
        await PurchaseStorageService.savePurchase(p);
      }

      await loadPurchases();
    } catch (e) {
      _errorMessage = "Sync Error: $e";
    } finally {
      _isSyncing = false;
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

  Future<void> deleteExpense(String id) async {
    try {
      await ExpenseStorageService.deleteExpense(id);
      await loadPurchases();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
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

  Future<void> setManualOpeningExpenseAmount(double value) async {
    _settings = _settings.copyWith(manualOpeningExpenseAmount: value);
    await SettingsService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setStockValuationItems(List<StockValuationItem> items) async {
    _settings = _settings.copyWith(stockValuationItems: List.of(items));
    await SettingsService.saveSettings(_settings);
    notifyListeners();
  }

}
