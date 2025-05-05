import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ANotification {
  static const _channelId   = 'moval_channel_id';
  static const _channelName = 'Moval Notifications';
  static const _channelDesc = 'Notifications for Moval app';
  static const _id          = 0;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  Function(String)? onNotificationTap;
  
  // Add a static instance for easy access
  static final ANotification _instance = ANotification._internal();
  
  // Factory constructor
  factory ANotification({Function(String)? onNotificationTap}) {
    _instance.onNotificationTap = onNotificationTap;
    return _instance;
  }
  
  // Private constructor
  ANotification._internal() {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    // Initialize Android settings - use a transparent icon for notifications
    const androidSettings = AndroidInitializationSettings('ic_notification');
    
    // Initialize iOS settings
    const iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // Complete initialization
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    // Initialize the plugin and set up notification tap handler
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Request permissions for iOS
    if (!kIsWeb) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    // Create the notification channel on Android
    await _createNotificationChannel();
    
    // Set up foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("Foreground message received in ANotification: ${message.messageId}");
      onNotification(message);
    });
  }

  Future<void> _createNotificationChannel() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
        playSound: true,
        showBadge: true,
        enableVibration: true,
      ),
    );
    
    log("Notification channel created: $_channelId");
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    // Handle notification tap
    log("Notification tapped with payload: ${response.payload}");
    if (response.payload != null && onNotificationTap != null) {
      onNotificationTap!(response.payload!);
    }
  }

  Future<AndroidNotificationDetails> _getAndroidNotificationDetail() async {
    return const AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'New Moval notification',
      icon: 'ic_notification',
      playSound: true,
      enableVibration: true,
      color: Colors.blue,
    );
  }

  Future<DarwinNotificationDetails> _getIOSNotificationDetail() async {
    return const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
  }

  Future<void> onNotification(RemoteMessage? message) async {
    log("On Notification: ${message?.messageId}");
    log("Notification data: ${message?.data}");
    log("Notification content: ${message?.notification?.title} - ${message?.notification?.body}");
    
    if (message == null) return;
    _handleNotification(message);
  }

  Future<void> _handleNotification(RemoteMessage message) async {
    try {
      final data = message.data;
      final notification = message.notification;
      final title = notification?.title ?? data['title'] ?? 'Moval Notification';
      final body = notification?.body ?? data['body'] ?? '';
      final payload = data['payload'] ?? data.toString();

      log("Showing notification: $title - $body");
      
      final androidNotificationDetail = await _getAndroidNotificationDetail();
      final iOSNotificationDetail = await _getIOSNotificationDetail();

      final notificationDetail = NotificationDetails(
        android: androidNotificationDetail,
        iOS: iOSNotificationDetail,
      );

      await _notificationsPlugin.show(
        message.hashCode % 1000, // Use a unique ID based on the message
        title,
        body,
        notificationDetail,
        payload: payload,
      );
      
      log("Notification displayed successfully");
    } catch (e) {
      log("Error showing notification: $e");
    }
  }

  Future<void> showTextNotification(String title, String body, {String? payload}) async {
    final androidNotificationDetail = await _getAndroidNotificationDetail();
    final iOSNotificationDetail = await _getIOSNotificationDetail();

    final notificationDetail = NotificationDetails(
      android: androidNotificationDetail,
      iOS: iOSNotificationDetail,
    );

    await _notificationsPlugin.show(
      _id,
      title,
      body,
      notificationDetail,
      payload: payload,
    );
  }

  Future<void> requestPermissions() async {
    // Request permission for Firebase Messaging
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  // Test function to send a local notification
  Future<void> sendTestNotification() async {
    log("Sending test notification");
    await showTextNotification(
      "Test Notification",
      "This is a test notification from Moval",
      payload: "test_notification"
    );
  }
}