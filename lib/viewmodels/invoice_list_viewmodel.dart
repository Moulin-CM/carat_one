import 'package:flutter/foundation.dart';
import '../models/invoice_model.dart';
import '../services/invoice_storage_service.dart';
import '../services/auth_service.dart';
import 'invoice_form_viewmodel.dart';

class InvoiceListViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  List<InvoiceModel> _invoices = [];
  List<InvoiceModel> _filteredInvoices = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  List<InvoiceModel> get invoices => _filteredInvoices.isEmpty && _searchQuery.isEmpty && _startDate == null && _endDate == null
      ? _invoices
      : _filteredInvoices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => invoices.isEmpty;
  String get searchQuery => _searchQuery;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  Future<void> loadInvoices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _invoices = await InvoiceStorageService.getAllInvoices();
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _startDate = null;
    _endDate = null;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredInvoices = List<InvoiceModel>.from(_invoices);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredInvoices = _filteredInvoices.where((invoice) {
        return invoice.buyerName.toLowerCase().contains(_searchQuery) ||
            invoice.invoiceNo.toLowerCase().contains(_searchQuery) ||
            invoice.buyerEmail.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Apply date range filter
    if (_startDate != null || _endDate != null) {
      _filteredInvoices = _filteredInvoices.where((invoice) {
        final invoiceDate = DateTime(invoice.invoiceDate.year, invoice.invoiceDate.month, invoice.invoiceDate.day);
        if (_startDate != null && _endDate != null) {
          final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
          final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
          return invoiceDate.isAfter(start.subtract(const Duration(days: 1))) &&
              invoiceDate.isBefore(end.add(const Duration(days: 1)));
        } else if (_startDate != null) {
          final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
          return invoiceDate.isAfter(start.subtract(const Duration(days: 1)));
        } else if (_endDate != null) {
          final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
          return invoiceDate.isBefore(end.add(const Duration(days: 1)));
        }
        return true;
      }).toList();
    }
  }

  Future<bool> deleteInvoice(String invoiceId) async {
    try {
      // Restore inventory before deleting invoice
      await InvoiceFormViewModel.restoreInventoryOnDelete(invoiceId);
      
      // Delete invoice
      await InvoiceStorageService.deleteInvoice(invoiceId);
      await loadInvoices(); // Reload list after deletion
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

