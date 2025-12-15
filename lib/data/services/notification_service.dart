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

    // Warning channel
    const AndroidNotificationChannel warningChannel = AndroidNotificationChannel(
      'warning_channel',
      'Warning Alerts',
      description: 'Warning notifications for sensor alerts',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Info channel
    const AndroidNotificationChannel infoChannel = AndroidNotificationChannel(
      'info_channel',
      'Info Notifications',
      description: 'Informational notifications for sensor alerts',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    // Create channels
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(criticalChannel);
    
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(warningChannel);
    
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(infoChannel);
  }

  // Function to show a notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String severity = 'info', // Severity: 'critical', 'warning', or 'info'
  }) async {
    // Determine channel and settings based on severity
    String channelId;
    String channelName;
    Importance importance;
    Priority priority;
    Color color;
    
    switch (severity.toLowerCase()) {
      case 'critical':
        channelId = 'critical_channel';
        channelName = 'Critical Alerts';
        importance = Importance.max;
        priority = Priority.high;
        color = Colors.red;
        break;
      case 'warning':
        channelId = 'warning_channel';
        channelName = 'Warning Alerts';
        importance = Importance.high;
        priority = Priority.defaultPriority;
        color = Colors.orange;
        break;
      case 'info':
      default:
        channelId = 'info_channel';
        channelName = 'Info Notifications';
        importance = Importance.defaultImportance;
        priority = Priority.defaultPriority;
        color = Colors.blue;
        break;
    }
    
    // Define Notification Details
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notifications for sensor alerts',
      importance: importance,
      priority: priority,
      color: color,
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