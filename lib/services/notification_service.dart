import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_reminder_model.dart';

// Conditional import: mobile gets real notifications, web gets a stub
import 'notification_service_mobile.dart'
    if (dart.library.html) 'notification_service_stub.dart' as _platform;

class NotificationService {
  static bool _initialized = false;
  static const String _remindersKey = 'invoice_reminders';

  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (_initialized) return;
    try {
      await _platform.initializeNotifications();
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService initialization failed: $e');
      _initialized = false;
    }
  }

  static Future<bool> scheduleReminder(InvoiceReminder reminder) async {
    if (kIsWeb || !_initialized) return false;
    try {
      await _platform.scheduleNotification(reminder);
      await _saveReminder(reminder);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> cancelReminder(int notificationId) async {
    if (!kIsWeb && _initialized) {
      await _platform.cancelNotification(notificationId);
    }
    await _removeReminder(notificationId);
  }

  static Future<void> cancelInvoiceReminders(String invoiceId) async {
    final reminders = await getAllReminders();
    final invoiceReminders =
        reminders.where((r) => r.invoiceId == invoiceId && r.isActive);
    for (final reminder in invoiceReminders) {
      if (!kIsWeb && _initialized) {
        await _platform.cancelNotification(reminder.notificationId);
      }
    }
    await _updateRemindersStatus(invoiceId, false);
  }

  static Future<List<InvoiceReminder>> getAllReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getString(_remindersKey);
    if (remindersJson == null) return [];
    final List<dynamic> decoded = jsonDecode(remindersJson);
    return decoded
        .map((json) => InvoiceReminder.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<InvoiceReminder>> getInvoiceReminders(
      String invoiceId) async {
    final allReminders = await getAllReminders();
    return allReminders.where((r) => r.invoiceId == invoiceId).toList();
  }

  static Future<void> _saveReminder(InvoiceReminder reminder) async {
    final reminders = await getAllReminders();
    reminders.removeWhere((r) => r.notificationId == reminder.notificationId);
    reminders.add(reminder);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _remindersKey, jsonEncode(reminders.map((r) => r.toJson()).toList()));
  }

  static Future<void> _removeReminder(int notificationId) async {
    final reminders = await getAllReminders();
    reminders.removeWhere((r) => r.notificationId == notificationId);
    final prefs = await SharedPreferences.getInstance();
    if (reminders.isEmpty) {
      await prefs.remove(_remindersKey);
    } else {
      await prefs.setString(_remindersKey,
          jsonEncode(reminders.map((r) => r.toJson()).toList()));
    }
  }

  static Future<void> _updateRemindersStatus(
      String invoiceId, bool isActive) async {
    final reminders = await getAllReminders();
    for (int i = 0; i < reminders.length; i++) {
      if (reminders[i].invoiceId == invoiceId) {
        reminders[i] = reminders[i].copyWith(isActive: isActive);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _remindersKey, jsonEncode(reminders.map((r) => r.toJson()).toList()));
  }

  static int generateNotificationId(String invoiceId) =>
      invoiceId.hashCode.abs() % 2147483647;
}
