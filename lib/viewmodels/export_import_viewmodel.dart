import 'package:flutter/foundation.dart';
import '../services/export_import_service.dart';

class ExportImportViewModel extends ChangeNotifier {
  bool _isExporting = false;
  bool _isImporting = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isExporting => _isExporting;
  bool get isImporting => _isImporting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<bool> exportInvoices() async {
    _isExporting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await ExportImportService.exportAndShareInvoices();
      _isExporting = false;
      _successMessage = 'Invoices exported successfully!';
      notifyListeners();
      return true;
    } catch (e) {
      _isExporting = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<ImportResult?> importInvoices(String filePath) async {
    _isImporting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await ExportImportService.importInvoicesFromFile(filePath);
      _isImporting = false;
      _successMessage = result.summary;
      notifyListeners();
      return result;
    } catch (e) {
      _isImporting = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}

