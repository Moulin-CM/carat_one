import 'package:flutter/foundation.dart';
import '../models/app_settings_model.dart';
import '../services/settings_service.dart';
import '../services/invoice_number_service.dart';

class SettingsViewModel extends ChangeNotifier {
  AppSettingsModel _settings = AppSettingsModel();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  AppSettingsModel get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await SettingsService.getSettings();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void updateCgstRate(double value) {
    _settings = _settings.copyWith(cgstRate: value);
    notifyListeners();
  }

  void updateSgstRate(double value) {
    _settings = _settings.copyWith(sgstRate: value);
    notifyListeners();
  }

  void updateIgstRate(double value) {
    _settings = _settings.copyWith(igstRate: value);
    notifyListeners();
  }

  void updateInvoiceNumberPrefix(String value) {
    _settings = _settings.copyWith(invoiceNumberPrefix: value);
    notifyListeners();
  }

  void updateStartingInvoiceNumber(int value) {
    _settings = _settings.copyWith(startingInvoiceNumber: value);
    notifyListeners();
  }

  void updateDefaultTerms(String value) {
    _settings = _settings.copyWith(defaultTerms: value);
    notifyListeners();
  }

  void updateEnableNotifications(bool value) {
    _settings = _settings.copyWith(enableNotifications: value);
    notifyListeners();
  }

  void updateAutoSaveDraft(bool value) {
    _settings = _settings.copyWith(autoSaveDraft: value);
    notifyListeners();
  }

  Future<bool> saveSettings() async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await SettingsService.saveSettings(_settings);
      _isSaving = false;
      _successMessage = 'Settings saved successfully!';
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetSettings() async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await SettingsService.resetSettings();
      _settings = AppSettingsModel();
      _isSaving = false;
      _successMessage = 'Settings reset to default!';
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetInvoiceNumbering() async {
    try {
      await InvoiceNumberService.resetInvoiceNumber();
      _successMessage = 'Invoice numbering reset successfully!';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}

