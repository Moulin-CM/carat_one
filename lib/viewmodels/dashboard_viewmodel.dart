import 'package:flutter/foundation.dart';
import '../models/invoice_model.dart';
import '../models/purchase_model.dart';
import '../models/withdrawal_model.dart';
import '../models/expense_model.dart';
import '../models/app_settings_model.dart';
import '../models/user_profile_model.dart';
import '../services/invoice_storage_service.dart';
import '../services/purchase_storage_service.dart';
import '../services/withdrawal_storage_service.dart';
import '../services/expense_storage_service.dart';
import '../services/settings_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  List<InvoiceModel> _invoices = [];
  List<PurchaseModel> _purchases = [];
  List<WithdrawalModel> _withdrawals = [];
  List<ExpenseModel> _expenses = [];
  AppSettingsModel _settings = AppSettingsModel();
  UserProfileModel? _userProfile;
  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  String? _errorMessage;

  List<InvoiceModel> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserProfileModel? get userProfile => _userProfile;

  /// Number of sell entries (formerly "Total Invoices"). Includes every
  /// invoice record regardless of cash/bill mode or financial year.
  int get totalSells => _invoices.length;

  /// Number of purchase entries across all time.
  int get totalPurchases => _purchases.length;

  /// Carats still on hand for the current FY. Mirrors the Purchase tab's
  /// Remaining tile: opening carats (in-FY purchases + manual carry-forward)
  /// minus sold carats (in-FY invoices + manual carry-forward), so the two
  /// screens never disagree even when sales draw from prior-year stock.
  double get totalRemainingCarat {
    final opening = _settings.manualOpeningCarat +
        _purchasesInCurrentYear.fold(0.0, (sum, p) => sum + p.totalCarat);
    final sold = _settings.manualOpeningSellCarat +
        _invoicesInCurrentYear.fold(0.0, (sum, inv) => sum + inv.totalCarat);
    final diff = opening - sold;
    return diff < 0 ? 0 : diff;
  }

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
  double get netProfitOrLoss => totalSalesProfit - outstandingWithdrawals;

  /// Value of unsold inventory as manually valued on the Purchase tab.
  /// Mirrors the Purchase header's Stock Valuation tile.
  double get stockValuationTotal => _settings.stockValuationItems
      .fold(0.0, (sum, item) => sum + item.totalValue);

  /// Roj mel debits the user tagged as business expenses. Ordinary day-book
  /// debits are ignored here — only tagged entries hit profitability.
  double get businessExpensesTotal => _expenses
      .where((e) => !e.isCredit && e.isBusinessExpense)
      .fold(0.0, (sum, e) => sum + e.amount);

  /// Net Profit including unsold stock = Stock Valuation + Net Profit/Loss
  /// − tagged business expenses. A running loss is subtracted from the stock
  /// value, a running profit is added on top, and business expenses come off
  /// the result, so this is the true bottom line once inventory is counted.
  double get netProfitWithStock =>
      stockValuationTotal + netProfitOrLoss - businessExpensesTotal;

  /// Money still receivable from buyers across all in-FY invoices.
  /// Each invoice's outstanding amount uses its own average rate, so mixed
  /// invoices sum exactly. Mirrors the [pendingInvoices] filter so the
  /// header total never includes invoices the list already hides.
  double get pendingSellAmount => _invoicesInCurrentYear
      .where((inv) => !inv.isFullyPaid)
      .fold(0.0, (sum, inv) => sum + (inv.remainingCarat * inv.averageRate));

  /// Money still owed to sellers across all in-FY purchase lots. Each lot is
  /// priced at its own effective purchase rate so mixed-rate inventory sums
  /// accurately. Mirrors the [pendingPurchases] filter so the header total
  /// never includes lots the list already hides.
  double get pendingPurchaseAmount => _purchasesInCurrentYear
      .where((p) => !p.isFullyPaid)
      .fold(
        0.0,
        (sum, p) => sum + (p.remainingPaymentCarat * p.effectivePurchaseRate),
      );

  /// In-FY invoices that still have an outstanding receivable from the buyer,
  /// oldest invoice first. Drives the "Pending from Buyers" detail screen.
  /// Uses [InvoiceModel.isFullyPaid] so that Mark-as-Paid entries and
  /// installment-settled entries (within the 0.0001 ct tolerance) drop out.
  List<InvoiceModel> get pendingInvoices {
    final list = _invoicesInCurrentYear
        .where((inv) => !inv.isFullyPaid)
        .toList();
    list.sort((a, b) => a.invoiceDate.compareTo(b.invoiceDate));
    return list;
  }

  /// In-FY purchase lots that still owe money to the seller, oldest lot
  /// first. Drives the "Pending to Sellers" detail screen. Uses
  /// [PurchaseModel.isFullyPaid] so that Mark-as-Paid lots and
  /// installment-settled lots (within the 0.0001 ct tolerance) drop out.
  List<PurchaseModel> get pendingPurchases {
    final list = _purchasesInCurrentYear
        .where((p) => !p.isFullyPaid)
        .toList();
    list.sort((a, b) => a.buyDate.compareTo(b.buyDate));
    return list;
  }

  /// Cash sitting in the Roj mel day-book: Credits received minus Debits
  /// paid out. Mirrors the "Available" tile on the Roj mel screen, so the
  /// two never disagree. The Opening Amount is reference-only and is
  /// deliberately excluded here as well.
  double get ledgerAvailableAmount {
    final credits = _expenses
        .where((e) => e.isCredit)
        .fold(0.0, (sum, e) => sum + e.amount);
    final debits = _expenses
        .where((e) => !e.isCredit)
        .fold(0.0, (sum, e) => sum + e.amount);
    return credits - debits;
  }

  /// Net pending position: Pending from Buyers − Pending to Sellers +
  /// Available. Positive means receivables plus cash on hand cover what is
  /// owed to sellers; negative means more is owed to sellers than is
  /// receivable from buyers and held in the day-book combined.
  double get netPositionAmount =>
      pendingSellAmount - pendingPurchaseAmount + ledgerAvailableAmount;

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
    // Only show the full skeleton shimmer on the very first load.
    // Subsequent refreshes (e.g. after returning from InvoiceFormView or
    // pull-to-refresh) update data silently so the shimmer doesn't flash.
    if (!_hasLoadedOnce) {
      _isLoading = true;
      notifyListeners();
    }
    _errorMessage = null;

    try {
      final uid = _authService.currentUser?.uid;

      // On first load, fetch the user profile alongside invoice data.
      final futures = <Future>[
        InvoiceStorageService.getAllInvoices(),
        PurchaseStorageService.getAllPurchases(),
        WithdrawalStorageService.getAllWithdrawals(),
        SettingsService.getSettings(),
        ExpenseStorageService.getAllExpenses(),
        if (!_hasLoadedOnce && uid != null) _userService.getUserProfile(uid),
      ];

      final results = await Future.wait(futures);
      _invoices = results[0] as List<InvoiceModel>;
      _purchases = results[1] as List<PurchaseModel>;
      _withdrawals = results[2] as List<WithdrawalModel>;
      _settings = results[3] as AppSettingsModel;
      _expenses = results[4] as List<ExpenseModel>;
      if (!_hasLoadedOnce && uid != null) {
        _userProfile = results[5] as UserProfileModel?;
      }
      _isLoading = false;
      _hasLoadedOnce = true;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasLoadedOnce = true;
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
