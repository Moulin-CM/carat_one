import 'package:flutter/foundation.dart';
import '../models/invoice_model.dart';
import '../services/invoice_storage_service.dart';
import '../services/auth_service.dart';

class InvoiceListViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  List<InvoiceModel> _invoices = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<InvoiceModel> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _invoices.isEmpty;

  Future<void> loadInvoices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _invoices = await InvoiceStorageService.getAllInvoices();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> deleteInvoice(String invoiceId) async {
    try {
      await InvoiceStorageService.deleteInvoice(invoiceId);
      await loadInvoices(); // Reload list after deletion
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
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

