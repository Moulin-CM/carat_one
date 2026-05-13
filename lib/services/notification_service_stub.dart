// Web stub — notifications are not supported on web
import '../models/invoice_reminder_model.dart';


Future<void> initializeNotifications() async {
  // No-op on web
}

Future<void> scheduleNotification(InvoiceReminder reminder) async {
  // No-op on web
}

Future<void> cancelNotification(int notificationId) async {
  // No-op on web
}
