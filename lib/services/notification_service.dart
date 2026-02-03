import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_reminder_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const String _remindersKey = 'invoice_reminders';

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // Default to IST, can be made configurable

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == false) {
        // Plugin initialization failed, but don't crash the app
        return;
      }

      // Request permissions for Android 13+
      try {
        await _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } catch (_) {
        // Permission request failed, continue anyway
      }

      _initialized = true;
    } catch (e) {
      // If notification initialization fails, log but don't crash
      // The app can still function without notifications
      print('NotificationService initialization failed: $e');
      _initialized = false;
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to invoice details
    // This will be handled by the app's navigation system
  }

  /// Schedule a reminder notification
  static Future<bool> scheduleReminder(InvoiceReminder reminder) async {
    try {
      await initialize();
      
      if (!_initialized) {
        // Notifications not available
        return false;
      }

      const androidDetails = AndroidNotificationDetails(
        'invoice_reminders',
        'Invoice Reminders',
        channelDescription: 'Notifications for invoice due dates',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule notification
      await _notifications.zonedSchedule(
        reminder.notificationId,
        'Invoice Due Reminder',
        'Invoice ${reminder.invoiceNo} for ${reminder.buyerName} is due on ${_formatDate(reminder.dueDate)}',
        tz.TZDateTime.from(reminder.reminderDate, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode({
          'invoiceId': reminder.invoiceId,
          'type': 'invoice_reminder',
        }),
      );

      // Save reminder to local storage
      await _saveReminder(reminder);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cancel a reminder notification
  static Future<void> cancelReminder(int notificationId) async {
    await _notifications.cancel(notificationId);
    await _removeReminder(notificationId);
  }

  /// Cancel all reminders for an invoice
  static Future<void> cancelInvoiceReminders(String invoiceId) async {
    final reminders = await getAllReminders();
    final invoiceReminders = reminders.where((r) => r.invoiceId == invoiceId && r.isActive);
    
    for (final reminder in invoiceReminders) {
      await _notifications.cancel(reminder.notificationId);
    }
    
    await _updateRemindersStatus(invoiceId, false);
  }

  /// Get all active reminders
  static Future<List<InvoiceReminder>> getAllReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getString(_remindersKey);
    
    if (remindersJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(remindersJson);
    return decoded.map((json) => InvoiceReminder.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get reminders for a specific invoice
  static Future<List<InvoiceReminder>> getInvoiceReminders(String invoiceId) async {
    final allReminders = await getAllReminders();
    return allReminders.where((r) => r.invoiceId == invoiceId).toList();
  }

  /// Save reminder to local storage
  static Future<void> _saveReminder(InvoiceReminder reminder) async {
    final reminders = await getAllReminders();
    reminders.removeWhere((r) => r.notificationId == reminder.notificationId);
    reminders.add(reminder);
    
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = jsonEncode(reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_remindersKey, remindersJson);
  }

  /// Remove reminder from local storage
  static Future<void> _removeReminder(int notificationId) async {
    final reminders = await getAllReminders();
    reminders.removeWhere((r) => r.notificationId == notificationId);
    
    final prefs = await SharedPreferences.getInstance();
    if (reminders.isEmpty) {
      await prefs.remove(_remindersKey);
    } else {
      final remindersJson = jsonEncode(reminders.map((r) => r.toJson()).toList());
      await prefs.setString(_remindersKey, remindersJson);
    }
  }

  /// Update reminder status
  static Future<void> _updateRemindersStatus(String invoiceId, bool isActive) async {
    final reminders = await getAllReminders();
    for (int i = 0; i < reminders.length; i++) {
      if (reminders[i].invoiceId == invoiceId) {
        reminders[i] = reminders[i].copyWith(isActive: isActive);
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = jsonEncode(reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_remindersKey, remindersJson);
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Generate unique notification ID from invoice ID
  static int generateNotificationId(String invoiceId) {
    return invoiceId.hashCode.abs() % 2147483647; // Max int value for notification ID
  }
}

