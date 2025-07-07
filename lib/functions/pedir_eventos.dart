import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/evento.dart';

class EventosFunctions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final Logger _logger = Logger();

  static Stream<List<Evento>> streamEventos() {
    return _firestore
        .collection('eventos')
        .snapshots()
        .map((snapshot) {
          final eventos = snapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();
          eventos.sort((a, b) {
            final fechaA = DateTime.tryParse(a.fechaInicio) ?? DateTime.now();
            final fechaB = DateTime.tryParse(b.fechaInicio) ?? DateTime.now();
            return fechaB.compareTo(fechaA);
          });
          return eventos;
        });
  }

  static Future<List<Evento>> obtenerEventosProximos() async {
    try {
      final snapshot = await _firestore.collection('eventos').get();
      final eventos = snapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();
      final ahora = DateTime.now();
      
      final eventosProximos = eventos.where((evento) {
        final fechaEvento = DateTime.tryParse(evento.fechaInicio);
        return fechaEvento != null && fechaEvento.isAfter(ahora);
      }).toList();
      
      eventosProximos.sort((a, b) {
        final fechaA = DateTime.tryParse(a.fechaInicio) ?? DateTime.now();
        final fechaB = DateTime.tryParse(b.fechaInicio) ?? DateTime.now();
        return fechaA.compareTo(fechaB);
      });

      return eventosProximos;
    } catch (e) {
      _logger.e('Error obteniendo eventos próximos: $e');
      return [];
    }
  }

  static Future<List<Evento>> buscarEventos(String termino) async {
    try {
      final snapshot = await _firestore.collection('eventos').get();
      final eventos = snapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();
      
      return eventos.where((evento) =>
          evento.titulo.toLowerCase().contains(termino.toLowerCase()) ||
          evento.descripcion.toLowerCase().contains(termino.toLowerCase()) ||
          evento.ubicacion.toLowerCase().contains(termino.toLowerCase())
      ).toList();
    } catch (e) {
      _logger.e('Error buscando eventos: $e');
      return [];
    }
  }

  static Future<Map<String, int>> obtenerEstadisticasEventos() async {
    try {
      final snapshot = await _firestore.collection('eventos').get();
      final eventos = snapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();
      final ahora = DateTime.now();

      int proximos = 0;
      int pasados = 0;
      
      for (final evento in eventos) {
        final fechaEvento = DateTime.tryParse(evento.fechaInicio);
        if (fechaEvento != null) {
          if (fechaEvento.isAfter(ahora)) {
            proximos++;
          } else {
            pasados++;
          }
        }
      }

      return {
        'total': eventos.length,
        'proximos': proximos,
        'pasados': pasados,
        'totalVoluntarios': eventos.fold<int>(0, (total, evento) => total + evento.voluntariosInscritos.length),
      };
    } catch (e) {
      _logger.e('Error obteniendo estadísticas: $e');
      return {
        'total': 0,
        'proximos': 0,
        'pasados': 0,
        'totalVoluntarios': 0,
      };
    }
  }

  static Future<bool> registrarUsuarioEnEvento(String eventoId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _logger.w('Usuario no autenticado');
        return false;
      }
      final isAlreadyRegistered = await verificarRegistroUsuario(eventoId);
      if (isAlreadyRegistered) {
        _logger.i('Usuario ya está registrado en el evento');
        return false;
      }

      final eventoRef = _firestore.collection('eventos').doc(eventoId);
      
      return await _firestore.runTransaction<bool>((transaction) async {
        final eventoDoc = await transaction.get(eventoRef);
        
        if (!eventoDoc.exists) {
          throw Exception('Evento no encontrado');
        }

        final eventoData = eventoDoc.data();
        if (eventoData == null) {
          throw Exception('Datos del evento no válidos');
        }

        final List<dynamic> voluntariosInscritosRaw = eventoData['voluntariosInscritos'] ?? [];
        final List<String> voluntariosInscritos = voluntariosInscritosRaw.cast<String>();
        if (voluntariosInscritos.contains(userId)) {
          _logger.i('Usuario ya registrado (verificación en transacción)');
          return false;
        }

        final int cantidadMax = eventoData['cantidadVoluntariosMax'] ?? 0;
        if (cantidadMax > 0 && voluntariosInscritos.length >= cantidadMax) {
          throw Exception('El evento ha alcanzado el máximo de participantes ($cantidadMax)');
        }
        final updatedVoluntarios = [...voluntariosInscritos, userId];
        transaction.update(eventoRef, {
          'voluntariosInscritos': updatedVoluntarios,
        });
        final registroId = '${eventoId}_${userId}_${DateTime.now().millisecondsSinceEpoch}';
        transaction.set(
          _firestore.collection('registros_eventos').doc(registroId),
          {
            'idEvento': eventoId,
            'idUsuario': userId,
            'fechaRegistro': DateTime.now().toIso8601String(),
            'estado': 'activo',
          }
        );

        _logger.i('Usuario registrado exitosamente en evento $eventoId');
        return true;
      });
    } catch (e) {
      _logger.e('Error registrando usuario en evento: $e');
      if (e.toString().contains('already-exists') || e.toString().contains('permission-denied')) {
        return false;
      }
      rethrow;
    }
  }

  static Future<bool> verificarRegistroUsuario(String eventoId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _logger.w('Usuario no autenticado');
        return false;
      }

      final eventoDoc = await _firestore
          .collection('eventos')
          .doc(eventoId)
          .get();

      if (!eventoDoc.exists) {
        _logger.w('Evento no encontrado: $eventoId');
        return false;
      }

      final eventoData = eventoDoc.data();
      if (eventoData == null) {
        _logger.w('Datos del evento nulos');
        return false;
      }

      final List<dynamic> voluntariosInscritosRaw = eventoData['voluntariosInscritos'] ?? [];
      final List<String> voluntariosInscritos = voluntariosInscritosRaw.cast<String>();

      final isRegistered = voluntariosInscritos.contains(userId);
      _logger.i('Verificación de registro - Usuario: $userId, Evento: $eventoId, Registrado: $isRegistered');
      
      return isRegistered;
    } catch (e) {
      _logger.e('Error verificando registro: $e');
      return false;
    }
  }
}