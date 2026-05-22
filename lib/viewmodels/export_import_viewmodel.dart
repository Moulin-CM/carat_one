import 'package:flutter/foundation.dart';
import '../services/export_import_service.dart';
import '../services/import/data_import_service.dart';

class ExportImportViewModel extends ChangeNotifier {
  bool _isExporting = false;
  bool _isImporting = false;
  String? _errorMessage;
  String? _successMessage;
  ImportDataKind _selectedKind = ImportDataKind.purchase;

  bool get isExporting => _isExporting;
  bool get isImporting => _isImporting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  ImportDataKind get selectedKind => _selectedKind;

  void setSelectedKind(ImportDataKind kind) {
    _selectedKind = kind;
    notifyListeners();
  }

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

  /// Multi-format import for either Purchase or Sell data. Auto-detects the
  /// file format from the extension, auto-maps column headers, and persists
  /// each row through the matching storage service.
  Future<DataImportResult?> importData(
    String filePath,
    ImportDataKind kind,
  ) async {
    _isImporting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await DataImportService.importFromFile(
        filePath: filePath,
        kind: kind,
      );
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
