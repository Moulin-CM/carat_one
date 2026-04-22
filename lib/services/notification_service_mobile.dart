// Mobile (Android/iOS) notification implementation
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:convert';
import '../models/invoice_reminder_model.dart';

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings =
      InitializationSettings(android: androidSettings, iOS: iosSettings);

  await _notifications.initialize(initSettings);

  try {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  } catch (_) {}
}

Future<void> scheduleNotification(InvoiceReminder reminder) async {
  const androidDetails = AndroidNotificationDetails(
    'invoice_reminders',
    'Invoice Reminders',
    channelDescription: 'Notifications for invoice due dates',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  const notificationDetails =
      NotificationDetails(android: androidDetails, iOS: iosDetails);

  await _notifications.zonedSchedule(
    reminder.notificationId,
    'Invoice Due Reminder',
    'Invoice ${reminder.invoiceNo} for ${reminder.buyerName} is due on ${reminder.dueDate.day}/${reminder.dueDate.month}/${reminder.dueDate.year}',
    tz.TZDateTime.from(reminder.reminderDate, tz.local),
    notificationDetails,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    payload: jsonEncode({
      'invoiceId': reminder.invoiceId,
      'type': 'invoice_reminder',
    }),
  );
}

Future<void> cancelNotification(int notificationId) async {
  await _notifications.cancel(notificationId);
}
