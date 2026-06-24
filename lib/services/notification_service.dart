import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  static Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // Notifica "nuove proposte disponibili"
  static Future<void> notifyNewProposals(int count) async {
    await init();
    await _plugin.show(
      1,
      '🌿 IM Editorial — Nuove proposte',
      '$count nuove proposte editoriali pronte per la revisione.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'im_editorial_channel',
          'IM Editorial',
          channelDescription: 'Notifiche proposte editoriali Innovation Machine',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF3b82f6),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // Notifica "salvataggio completato"
  static Future<void> notifySaved() async {
    await init();
    await _plugin.show(
      2,
      '✅ File salvato',
      'Le modifiche sono state salvate nel file Excel.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'im_editorial_channel',
          'IM Editorial',
          channelDescription: 'Notifiche proposte editoriali Innovation Machine',
          importance: Importance.low,
          priority: Priority.low,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(presentAlert: false, presentBadge: false),
      ),
    );
  }

  // Notifica "contenuto generato"
  static Future<void> notifyGenerated(String type) async {
    await init();
    final labels = {
      'newsletter': '📧 Newsletter pronta',
      'youtube': '▶ Script YouTube pronto',
      'social': '📱 Post Social pronti',
    };
    await _plugin.show(
      3,
      labels[type] ?? '✅ Contenuto generato',
      'Il testo è pronto. Aprilo per copiarlo o condividerlo.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'im_editorial_channel',
          'IM Editorial',
          channelDescription: 'Notifiche proposte editoriali Innovation Machine',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF3b82f6),
        ),
        iOS: DarwinNotificationDetails(presentAlert: true),
      ),
    );
  }
}

