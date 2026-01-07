import 'package:shared_preferences/shared_preferences.dart';

class InvoiceNumberService {
  static const String _lastInvoiceNumberKey = 'last_invoice_number';

  static Future<int> getNextInvoiceNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final lastNumber = prefs.getInt(_lastInvoiceNumberKey) ?? 0;
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
}

