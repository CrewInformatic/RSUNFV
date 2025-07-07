import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../core/constants/app_routes.dart';

/// Servicio para manejar notificaciones locales (flotantes) del sistema
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;
  static Function(String?)? _onNotificationTap;

  /// Inicializa el servicio de notificaciones locales
  static Future<void> initialize({Function(String?)? onNotificationTap}) async {
    if (_isInitialized) return;

    _onNotificationTap = onNotificationTap;

    // Inicializar timezone
    tz.initializeTimeZones();

    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configuración para Linux
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    // Configuración general
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      linux: initializationSettingsLinux,
    );

    // Inicializar plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _isInitialized = true;
  }

  /// Maneja el tap en notificaciones
  static void _onNotificationResponse(NotificationResponse response) {
    if (_onNotificationTap != null) {
      _onNotificationTap!(response.payload);
    }
  }

  /// Solicita permisos de notificación (especialmente importante en iOS)
  static Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      final bool? result = await androidImplementation?.requestNotificationsPermission();
      return result ?? false;
    }
    return true;
  }

  /// Muestra una notificación inmediata
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.defaultPriority,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'rsunfv_channel',
      'RSUNFV Notificaciones',
      channelDescription: 'Notificaciones de eventos y donaciones de RSUNFV',
      importance: _getImportance(priority),
      priority: _getPriority(priority),
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Programa una notificación para el futuro
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationPriority priority = NotificationPriority.defaultPriority,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'rsunfv_scheduled_channel',
      'RSUNFV Recordatorios',
      channelDescription: 'Recordatorios programados de eventos',
      importance: _getImportance(priority),
      priority: _getPriority(priority),
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancela una notificación programada
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancela todas las notificaciones
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Obtiene todas las notificaciones pendientes
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Convierte prioridad personalizada a Android Importance
  static Importance _getImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.max:
        return Importance.max;
      case NotificationPriority.defaultPriority:
        return Importance.defaultImportance;
    }
  }

  /// Convierte prioridad personalizada a Android Priority
  static Priority _getPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.max:
        return Priority.max;
      case NotificationPriority.defaultPriority:
        return Priority.defaultPriority;
    }
  }

  /// Notificaciones específicas para tipos de eventos RSUNFV
  
  /// Notificación para nuevo evento
  static Future<void> showNewEventNotification({
    required String eventTitle,
    required String eventId,
  }) async {
    await showInstantNotification(
      id: eventId.hashCode,
      title: '🎉 Nuevo Evento Disponible',
      body: 'Se ha creado el evento: $eventTitle',
      payload: '${AppRoutes.eventoDetalle}?id=$eventId',
      priority: NotificationPriority.high,
    );
  }

  /// Notificación para evento próximo
  static Future<void> showUpcomingEventNotification({
    required String eventTitle,
    required String eventId,
    required DateTime eventDate,
  }) async {
    final timeUntil = eventDate.difference(DateTime.now());
    final timeText = timeUntil.inHours < 24 
        ? '${timeUntil.inHours} horas'
        : '${timeUntil.inDays} días';

    await showInstantNotification(
      id: 'upcoming_$eventId'.hashCode,
      title: '⏰ Evento Próximo',
      body: '$eventTitle comienza en $timeText',
      payload: '${AppRoutes.eventoDetalle}?id=$eventId',
      priority: NotificationPriority.high,
    );
  }

  /// Notificación para donación verificada
  static Future<void> showDonationVerifiedNotification({
    required String donationAmount,
  }) async {
    await showInstantNotification(
      id: 'donation_${DateTime.now().millisecondsSinceEpoch}'.hashCode,
      title: '✅ Donación Verificada',
      body: 'Tu donación de S/ $donationAmount ha sido verificada exitosamente',
      payload: AppRoutes.donaciones,
      priority: NotificationPriority.high,
    );
  }

  /// Programa recordatorio de evento
  static Future<void> scheduleEventReminder({
    required String eventTitle,
    required String eventId,
    required DateTime reminderDate,
  }) async {
    await scheduleNotification(
      id: 'reminder_$eventId'.hashCode,
      title: '🔔 Recordatorio de Evento',
      body: 'El evento "$eventTitle" es mañana. ¡No te lo pierdas!',
      scheduledDate: reminderDate,
      payload: '${AppRoutes.eventoDetalle}?id=$eventId',
      priority: NotificationPriority.high,
    );
  }
}

/// Niveles de prioridad para notificaciones
enum NotificationPriority {
  low,
  defaultPriority,
  high,
  max,
}
