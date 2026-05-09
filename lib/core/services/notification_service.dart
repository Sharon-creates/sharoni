import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:sharoni/core/models/medication.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return;

    // 1. Initialize Timezones
    tz.initializeTimeZones();
    try {
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).toString();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Error initializing timezone: $e');
    }

    // 2. Android Settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS Settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 4. Initialize Plugin
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
  }

  Future<void> scheduleMedicationNotifications(Medication med) async {
    if (kIsWeb) return;

    for (int i = 0; i < med.scheduledTimes.length; i++) {
      final time = med.scheduledTimes[i];
      final id = med.id.hashCode + i; // Unique ID for each time slot

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: 'Medication Reminder: ${med.name}',
        body: 'Time to take your ${med.dosagePerIntake}.',
        scheduledDate: _nextInstanceOfTime(time),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_reminders',
            'Medication Reminders',
            channelDescription: 'Notifications for scheduled medication doses',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelMedicationNotifications(Medication med) async {
    if (kIsWeb) return;

    for (int i = 0; i < med.scheduledTimes.length; i++) {
      await _notificationsPlugin.cancel(id: med.id.hashCode + i);
    }
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    if (kIsWeb) return tz.TZDateTime.now(tz.local); // Dummy for web

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> showWarning(String title, String body) async {
    if (kIsWeb) return;

    await _notificationsPlugin.show(
      id: 999,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_warnings',
          'Health Warnings',
          channelDescription: 'Alerts for missed doses and health suggestions',
          importance: Importance.max,
          priority: Priority.high,
          color: Colors.red,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
