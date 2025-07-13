import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import './notification_service.dart';
import './local_notification_service.dart';

class NotificationTriggerService {
  static final Logger _logger = Logger();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static StreamSubscription<QuerySnapshot>? _eventosSubscription;
  static StreamSubscription<QuerySnapshot>? _donacionesSubscription;
  static Timer? _upcomingEventsTimer;

  static void initialize() {
    _setupEventosListener();
    _setupDonacionesListener();
    _setupUpcomingEventsChecker();
    _logger.i('NotificationTriggerService initialized');
  }

  static void dispose() {
    _eventosSubscription?.cancel();
    _donacionesSubscription?.cancel();
    _upcomingEventsTimer?.cancel();
    _logger.i('NotificationTriggerService disposed');
  }

  static void _setupEventosListener() {
    _eventosSubscription = _firestore
        .collection('eventos')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final eventoId = change.doc.id;
          final titulo = data['titulo'] as String? ?? 'Nuevo Evento';
          
          final createdAt = data['createdAt'] as String?;
          if (createdAt != null) {
            try {
              final createdDate = DateTime.parse(createdAt);
              final now = DateTime.now();
              final difference = now.difference(createdDate);
              
              if (difference.inMinutes <= 5) {
                _logger.i('Nuevo evento detectado: $titulo ($eventoId)');
                
                NotificationService.notifyNewEvent(eventoId, titulo);
                
                LocalNotificationService.showNewEventNotification(
                  eventTitle: titulo,
                  eventId: eventoId,
                );
              }
            } catch (e) {
              _logger.w('Error parsing created date for event $eventoId: $e');
            }
          }
        }
      }
    }, onError: (error) {
      _logger.e('Error in eventos listener: $error');
    });
  }

  static void _setupDonacionesListener() {
    _donacionesSubscription = _firestore
        .collection('donaciones')
        .where('estado', isEqualTo: 'verificada')
        .snapshots()
        .listen((snapshot) {
      
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data() as Map<String, dynamic>;
          final donacionId = change.doc.id;
          final userId = data['idUsuario'] as String?;
          final monto = data['monto']?.toString() ?? '0';
          
          if (userId != null) {
            _logger.i('Donación verificada detectada: $donacionId para usuario $userId');
            
            NotificationService.notifyDonationVerified(userId, donacionId, monto);
            
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            if (currentUserId == userId) {
              LocalNotificationService.showDonationVerifiedNotification(
                donationAmount: monto,
              );
            }
          }
        }
      }
    }, onError: (error) {
      _logger.e('Error in donaciones listener: $error');
    });
  }

  static void _setupUpcomingEventsChecker() {
    _upcomingEventsTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkUpcomingEvents(),
    );
    
    _checkUpcomingEvents();
  }

  static Future<void> _checkUpcomingEvents() async {
    try {
      _logger.d('Checking upcoming events...');
      await NotificationService.checkUpcomingEvents();
    } catch (e) {
      _logger.e('Error checking upcoming events: $e');
    }
  }

  static Future<void> notifyEventRegistration(String eventoId, String eventoTitulo) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await NotificationService.createNotification(
        userId: userId,
        titulo: '✅ Inscripción Confirmada',
        mensaje: 'Te has inscrito exitosamente al evento "$eventoTitulo"',
        tipo: NotificationType.inscripcionEvento,
        eventoId: eventoId,
      );

      await LocalNotificationService.showInstantNotification(
        id: 'registration_$eventoId'.hashCode,
        title: '✅ Inscripción Confirmada',
        body: 'Te has inscrito exitosamente al evento "$eventoTitulo"',
        payload: '/evento_detalle?id=$eventoId',
        priority: NotificationPriority.high,
      );

      _logger.i('Notificación de inscripción enviada para evento $eventoId');
    } catch (e) {
      _logger.e('Error notifying event registration: $e');
    }
  }

  static Future<void> scheduleEventReminder(String eventoId, String eventoTitulo, DateTime fechaEvento) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final now = DateTime.now();
      final reminderTime = fechaEvento.subtract(const Duration(hours: 24));
      
      if (reminderTime.isAfter(now)) {
        final delay = reminderTime.difference(now);
        
        Timer(delay, () async {
          await NotificationService.createNotification(
            userId: userId,
            titulo: '⏰ Recordatorio de Evento',
            mensaje: 'El evento "$eventoTitulo" es mañana. ¡Prepárate!',
            tipo: NotificationType.recordatorioEvento,
            eventoId: eventoId,
          );
          
          await LocalNotificationService.showInstantNotification(
            id: 'reminder_$eventoId'.hashCode,
            title: '⏰ Recordatorio de Evento',
            body: 'El evento "$eventoTitulo" es mañana. ¡Prepárate!',
            payload: '/evento_detalle?id=$eventoId',
            priority: NotificationPriority.high,
          );
        });
        
        _logger.i('Recordatorio programado para evento $eventoId en ${delay.inHours} horas');
      }
    } catch (e) {
      _logger.e('Error scheduling event reminder: $e');
    }
  }

  static Future<void> manualCheckUpcomingEvents() async {
    await _checkUpcomingEvents();
  }
}
