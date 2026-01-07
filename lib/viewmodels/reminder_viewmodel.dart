import 'package:flutter/foundation.dart';
import '../models/invoice_model.dart';
import '../models/invoice_reminder_model.dart';
import '../services/notification_service.dart';

class ReminderViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<InvoiceReminder> _reminders = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<InvoiceReminder> get reminders => _reminders;

  ReminderViewModel() {
    loadReminders();
  }

  Future<void> loadReminders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reminders = await NotificationService.getAllReminders();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> setReminder(InvoiceModel invoice, DateTime reminderDate) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final notificationId = NotificationService.generateNotificationId(invoice.id!);
      final reminder = InvoiceReminder(
        invoiceId: invoice.id!,
        invoiceNo: invoice.invoiceNo,
        buyerName: invoice.buyerName,
        dueDate: invoice.dueDate,
        reminderDate: reminderDate,
        notificationId: notificationId,
      );

      final success = await NotificationService.scheduleReminder(reminder);
      if (success) {
        await loadReminders();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Failed to set reminder';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelReminder(int notificationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await NotificationService.cancelReminder(notificationId);
      await loadReminders();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelInvoiceReminders(String invoiceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await NotificationService.cancelInvoiceReminders(invoiceId);
      await loadReminders();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<InvoiceReminder>> getInvoiceReminders(String invoiceId) async {
    try {
      return await NotificationService.getInvoiceReminders(invoiceId);
    } catch (e) {
      return [];
    }
  }
}

