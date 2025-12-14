import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Initialize the notification settings
  Future<void> init() async {
    // Android settings
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Ensure app icon exists

    // iOS settings
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Create notification channels for Android 8.0+
    await _createNotificationChannels();
  }

  // Create notification channels (required for Android 8.0+)
  Future<void> _createNotificationChannels() async {
    // Critical channel
    const AndroidNotificationChannel criticalChannel = AndroidNotificationChannel(
      'critical_channel',
      'Critical Alerts',
      description: 'Critical notifications for sensor alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFFFF0000),
    );

    // Normal channel
    const AndroidNotificationChannel normalChannel = AndroidNotificationChannel(
      'normal_channel',
      'General Notifications',
      description: 'General notifications for sensor alerts',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Create channels
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(criticalChannel);
    
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(normalChannel);
  }

  // Function to show a notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    bool isCritical = false, // Severity flag
  }) async {
    // Define Notification Details
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      isCritical ? 'critical_channel' : 'normal_channel',
      isCritical ? 'Critical Alerts' : 'General Notifications',
      channelDescription: 'Notifications for sensor alerts',
      importance: isCritical ? Importance.max : Importance.high,
      priority: isCritical ? Priority.high : Priority.defaultPriority,
      color: isCritical ? Colors.red : Colors.blue,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(id, title, body, details);
  }
}