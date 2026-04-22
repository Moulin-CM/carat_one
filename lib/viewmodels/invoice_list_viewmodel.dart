import 'package:flutter/foundation.dart';
import '../models/invoice_model.dart';
import '../models/app_settings_model.dart';
import '../services/invoice_storage_service.dart';
import '../services/settings_service.dart';
import '../services/auth_service.dart';
import 'invoice_form_viewmodel.dart';

class InvoiceListViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  List<InvoiceModel> _invoices = [];
  List<InvoiceModel> _filteredInvoices = [];
  AppSettingsModel _settings = AppSettingsModel();
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  List<InvoiceModel> get invoices =>
      _filteredInvoices.isEmpty &&
          _searchQuery.isEmpty &&
          _startDate == null &&
          _endDate == null
          ? _invoices
          : _filteredInvoices;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => invoices.isEmpty;
  String get searchQuery => _searchQuery;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  AppSettingsModel get settings => _settings;
  DateTime? get yearEndDate => _settings.yearEndDate;
  DateTime? get currentYearStart => _settings.currentYearStart();
  double get manualOpeningSellCarat => _settings.manualOpeningSellCarat;
  double get manualOpeningSellAmount => _settings.manualOpeningSellAmount;

  /// Invoices that contribute to financial totals — "For Other" records
  /// are excluded and only current-FY invoices are included when a year
  /// end is configured.
  List<InvoiceModel> get _invoicesInCurrentYear {
    final start = currentYearStart;
    final base = _invoices.where((inv) => !inv.isForOther);
    if (start == null) return base.toList();
    return base.where((inv) => !inv.invoiceDate.isBefore(start)).toList();
  }

  double get openingSellCarat =>
      manualOpeningSellCarat +
      _invoicesInCurrentYear.fold(0.0, (sum, inv) => sum + inv.totalCarat);

  double get openingSellAmount =>
      manualOpeningSellAmount +
      _invoicesInCurrentYear.fold(0.0, (sum, inv) => sum + inv.grandTotal);

  double get totalPaidCarat =>
      _invoicesInCurrentYear.fold(0.0, (sum, inv) => sum + inv.totalPaidCarat);

  double get outstandingSellCarat {
    final diff = openingSellCarat - totalPaidCarat;
    return diff < 0 ? 0 : diff;
  }

  Future<void> loadInvoices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // _getUser() inside InvoiceStorageService waits for auth automatically
      final results = await Future.wait([
        InvoiceStorageService.getAllInvoices(),
        SettingsService.getSettings(),
      ]);
      _invoices = results[0] as List<InvoiceModel>;
      _settings = results[1] as AppSettingsModel;
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

    if (_searchQuery.isNotEmpty) {
      _filteredInvoices = _filteredInvoices.where((invoice) {
        return invoice.buyerName.toLowerCase().contains(_searchQuery) ||
            invoice.invoiceNo.toLowerCase().contains(_searchQuery) ||
            invoice.buyerEmail.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    if (_startDate != null || _endDate != null) {
      _filteredInvoices = _filteredInvoices.where((invoice) {
        final invoiceDate = DateTime(invoice.invoiceDate.year,
            invoice.invoiceDate.month, invoice.invoiceDate.day);
        if (_startDate != null && _endDate != null) {
          final start =
          DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
          final end =
          DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
          return invoiceDate
              .isAfter(start.subtract(const Duration(days: 1))) &&
              invoiceDate.isBefore(end.add(const Duration(days: 1)));
        } else if (_startDate != null) {
          final start =
          DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
          return invoiceDate.isAfter(start.subtract(const Duration(days: 1)));
        } else if (_endDate != null) {
          final end =
          DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
          return invoiceDate.isBefore(end.add(const Duration(days: 1)));
        }
        return true;
      }).toList();
    }
  }

  Future<bool> deleteInvoice(String invoiceId) async {
    try {
      await InvoiceFormViewModel.restoreInventoryOnDelete(invoiceId);
      await InvoiceStorageService.deleteInvoice(invoiceId);
      await loadInvoices();
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

  Future<void> setManualOpeningSellCarat(double value) async {
    _settings = _settings.copyWith(manualOpeningSellCarat: value);
    await SettingsService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setManualOpeningSellAmount(double value) async {
    _settings = _settings.copyWith(manualOpeningSellAmount: value);
    await SettingsService.saveSettings(_settings);
    notifyListeners();
  }
}
