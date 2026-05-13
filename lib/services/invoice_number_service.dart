import 'package:shared_preferences/shared_preferences.dart';
import 'settings_service.dart';


class InvoiceNumberService {
  static const String _lastInvoiceNumberKey = 'last_invoice_number';
  static const String _lastCashEntryNumberKey = 'last_cash_entry_number';

  static Future<int> getNextInvoiceNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = await SettingsService.getSettings();
    final lastNumber = prefs.getInt(_lastInvoiceNumberKey) ?? 0;

    // Use starting number from settings if it's higher than current
    if (settings.startingInvoiceNumber > lastNumber) {
      return settings.startingInvoiceNumber;
    }

    return lastNumber + 1;
  }

  static Future<void> saveInvoiceNumber(int number) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastInvoiceNumberKey, number);
  }

  static Future<int> getCurrentInvoiceNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastInvoiceNumberKey) ?? 0;
  }

  static Future<void> resetInvoiceNumber() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastInvoiceNumberKey);
  }

  /// Cash sells get their own counter so their Entry No is always
  /// "count of existing cash entries + 1".tr — independent of bill invoices.
  static Future<int> getNextCashEntryNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final lastNumber = prefs.getInt(_lastCashEntryNumberKey) ?? 0;
    return lastNumber + 1;
  }

  static Future<int> getCurrentCashEntryNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastCashEntryNumberKey) ?? 0;
  }

  static Future<void> saveCashEntryNumber(int number) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCashEntryNumberKey, number);
  }

  static Future<void> resetCashEntryNumber() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastCashEntryNumberKey);
  }
}

