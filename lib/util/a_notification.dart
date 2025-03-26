import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ANotification {

  static const _channelId   = 'moval_id';
  static const _channelName = 'moval_name';
  static const _channelDesc = 'moval_desc';
  static const _id          = 0;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  ANotification() {

    const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_stat_push'));

    _notificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse);
  }

  _onDidReceiveNotificationResponse(value) {}

  _getAndroidNotificationDetail() async {
    return const AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );
  }


  Future onNotification(value) async {

    log("On Notification $value");

    if(value == null) return;

    _handleNotification(value);

  }


  _handleNotification(RemoteMessage message) async {

    final data = message.data;

    final androidNotificationDetail = await _getAndroidNotificationDetail();

    final notificationDetail = NotificationDetails(
      android: androidNotificationDetail
    );

    _notificationsPlugin.show(
        _id,
        data['title'] ?? '',
        data['body'] ?? '',
        notificationDetail,
        payload: '');

  }

  showTextNotification(String title, String msg) {

  }

}