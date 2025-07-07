import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import './local_notification_service.dart';

/// Tipos de notificaciones disponibles en la aplicación
enum NotificationType {
  eventoProximo,      // Evento próximo (1 día o menos)
  eventoNuevo,        // Nuevo evento creado
  donacionVerificada, // Donación verificada/confirmada
  recordatorioEvento, // Recordatorio de evento
  inscripcionEvento,  // Confirmación de inscripción
}

/// Modelo de notificación
class NotificationData {
  final String id;
  final String titulo;
  final String mensaje;
  final NotificationType tipo;
  final DateTime fechaCreacion;
  final bool leida;
  final String? eventoId;
  final String? donacionId;
  final Map<String, dynamic>? datosAdicionales;

  NotificationData({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.fechaCreacion,
    this.leida = false,
    this.eventoId,
    this.donacionId,
    this.datosAdicionales,
  });

  factory NotificationData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationData(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      mensaje: data['mensaje'] ?? '',
      tipo: NotificationType.values.firstWhere(
        (e) => e.toString() == data['tipo'],
        orElse: () => NotificationType.eventoNuevo,
      ),
      fechaCreacion: (data['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      leida: data['leida'] ?? false,
      eventoId: data['eventoId'],
      donacionId: data['donacionId'],
      datosAdicionales: data['datosAdicionales'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo.toString(),
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'leida': leida,
      'eventoId': eventoId,
      'donacionId': donacionId,
      'datosAdicionales': datosAdicionales,
    };
  }
}

/// Servicio de gestión de notificaciones
class NotificationService {
  static final Logger _logger = Logger();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crear una nueva notificación
  static Future<void> createNotification({
    required String userId,
    required String titulo,
    required String mensaje,
    required NotificationType tipo,
    String? eventoId,
    String? donacionId,
    Map<String, dynamic>? datosAdicionales,
  }) async {
    try {
      final notification = NotificationData(
        id: '',
        titulo: titulo,
        mensaje: mensaje,
        tipo: tipo,
        fechaCreacion: DateTime.now(),
        eventoId: eventoId,
        donacionId: donacionId,
        datosAdicionales: datosAdicionales,
      );

      await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('notificaciones')
          .add(notification.toFirestore());

      _logger.i('Notificación creada: $titulo para usuario $userId');
    } catch (e) {
      _logger.e('Error creando notificación: $e');
    }
  }

  /// Obtener notificaciones del usuario actual
  static Stream<List<NotificationData>> getUserNotifications({
    bool soloNoLeidas = false,
    int limite = 50,
  }) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    Query query = _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('notificaciones')
        .orderBy('fechaCreacion', descending: true)
        .limit(limite);

    if (soloNoLeidas) {
      query = query.where('leida', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationData.fromFirestore(doc))
          .toList();
    });
  }

  /// Marcar notificación como leída
  static Future<void> markAsRead(String notificationId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('notificaciones')
          .doc(notificationId)
          .update({'leida': true});

      _logger.d('Notificación marcada como leída: $notificationId');
    } catch (e) {
      _logger.e('Error marcando notificación como leída: $e');
    }
  }

  /// Marcar todas las notificaciones como leídas
  static Future<void> markAllAsRead() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('notificaciones')
          .where('leida', isEqualTo: false)
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'leida': true});
      }

      await batch.commit();
      _logger.i('Todas las notificaciones marcadas como leídas');
    } catch (e) {
      _logger.e('Error marcando todas las notificaciones como leídas: $e');
    }
  }

  /// Eliminar notificación
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('notificaciones')
          .doc(notificationId)
          .delete();

      _logger.d('Notificación eliminada: $notificationId');
    } catch (e) {
      _logger.e('Error eliminando notificación: $e');
    }
  }

  /// Obtener conteo de notificaciones no leídas
  static Stream<int> getUnreadCount() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('notificaciones')
        .where('leida', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Verificar eventos próximos y crear notificaciones
  static Future<void> checkUpcomingEvents() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      // Obtener eventos en los que el usuario está inscrito
      final eventosQuery = await _firestore
          .collection('eventos')
          .where('voluntariosInscritos', arrayContains: userId)
          .get();

      for (final eventoDoc in eventosQuery.docs) {
        final eventoData = eventoDoc.data();
        final fechaInicioStr = eventoData['fechaInicio'] as String?;
        
        if (fechaInicioStr != null) {
          try {
            final fechaEvento = DateTime.parse(fechaInicioStr);
            
            // Si el evento es mañana o en menos de 24 horas
            if (fechaEvento.isAfter(now) && fechaEvento.isBefore(tomorrow)) {
              // Verificar si ya se envió esta notificación
              final existingNotification = await _firestore
                  .collection('usuarios')
                  .doc(userId)
                  .collection('notificaciones')
                  .where('eventoId', isEqualTo: eventoDoc.id)
                  .where('tipo', isEqualTo: NotificationType.eventoProximo.toString())
                  .get();

              if (existingNotification.docs.isEmpty) {
                await createNotification(
                  userId: userId,
                  titulo: '🔔 Evento Próximo',
                  mensaje: 'El evento "${eventoData['titulo']}" es mañana. ¡No lo olvides!',
                  tipo: NotificationType.eventoProximo,
                  eventoId: eventoDoc.id,
                );
                
                // Mostrar notificación flotante local
                await LocalNotificationService.showUpcomingEventNotification(
                  eventTitle: eventoData['titulo'] ?? 'Evento',
                  eventId: eventoDoc.id,
                  eventDate: fechaEvento,
                );
              }
            }
          } catch (e) {
            _logger.w('Error parsing date for event ${eventoDoc.id}: $e');
          }
        }
      }
    } catch (e) {
      _logger.e('Error checking upcoming events: $e');
    }
  }

  /// Notificar nuevo evento a todos los usuarios
  static Future<void> notifyNewEvent(String eventoId, String eventoTitulo) async {
    try {
      // Obtener todos los usuarios activos
      final usuariosQuery = await _firestore
          .collection('usuarios')
          .get();

      for (final usuarioDoc in usuariosQuery.docs) {
        await createNotification(
          userId: usuarioDoc.id,
          titulo: '🎉 Nuevo Evento Disponible',
          mensaje: 'Se ha creado un nuevo evento: "$eventoTitulo". ¡Revisa los detalles e inscríbete!',
          tipo: NotificationType.eventoNuevo,
          eventoId: eventoId,
        );
      }

      _logger.i('Notificaciones de nuevo evento enviadas a todos los usuarios');
    } catch (e) {
      _logger.e('Error notifying new event: $e');
    }
  }

  /// Notificar donación verificada
  static Future<void> notifyDonationVerified(
    String userId,
    String donacionId,
    String monto,
  ) async {
    try {
      await createNotification(
        userId: userId,
        titulo: '✅ Donación Verificada',
        mensaje: 'Tu donación de S/ $monto ha sido verificada y confirmada. ¡Gracias por tu contribución!',
        tipo: NotificationType.donacionVerificada,
        donacionId: donacionId,
      );

      _logger.i('Notificación de donación verificada enviada al usuario $userId');
    } catch (e) {
      _logger.e('Error notifying donation verified: $e');
    }
  }
}
