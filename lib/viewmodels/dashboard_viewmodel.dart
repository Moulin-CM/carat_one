import 'package:flutter/foundation.dart';
import '../models/invoice_model.dart';
import '../services/invoice_storage_service.dart';
import '../services/auth_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  List<InvoiceModel> _invoices = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<InvoiceModel> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalInvoices => _invoices.length;

  double get totalRevenue =>
      _invoices.fold(0.0, (sum, invoice) => sum + invoice.grandTotal);

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
      // _getUser() inside InvoiceStorageService waits for auth automatically
      _invoices = await InvoiceStorageService.getAllInvoices();
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