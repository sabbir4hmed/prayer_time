import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  NotificationService();
  
  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings androidInitSettings = 
      AndroidInitializationSettings('@mipmap/ic_launcher');
      
    const DarwinInitializationSettings iosInitSettings = 
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );
    
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped with payload: ${response.payload}');
      },
    );
  }
  
  Future<void> requestPermissions() async {
    // Fix for Android permissions - get the specific implementation
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
      _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
        
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
    
    // For iOS permissions
    final IOSFlutterLocalNotificationsPlugin? iosPlugin = 
      _notificationsPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
        
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }  
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? sound,
    String? payload,
  }) async {
    // Create Android notification details
    AndroidNotificationDetails androidDetails = const AndroidNotificationDetails(
      'prayer_channel',
      'Prayer Times',
      channelDescription: 'Notifications for prayer times',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    
    // Add sound if provided
    if (sound != null) {
      androidDetails = AndroidNotificationDetails(
        'prayer_channel',
        'Prayer Times',
        channelDescription: 'Notifications for prayer times',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound(sound),
      );
    }
    
    // Create iOS notification details
    DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    // Add sound if provided
    if (sound != null) {
      iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: sound,
      );
    }
    
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Schedule the notification
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }    Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
  
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}