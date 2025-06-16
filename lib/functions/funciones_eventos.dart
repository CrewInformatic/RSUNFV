import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventFunctions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<bool> isUserRegistered(String eventId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final DocumentSnapshot<Map<String, dynamic>> eventoDoc = 
          await _firestore.collection('eventos').doc(eventId).get();

      if (!eventoDoc.exists) return false;

      // Asegurar que voluntariosInscritos sea tratado como List<String>
      final List<String> voluntariosInscritos = 
          List<String>.from(eventoDoc.data()?['voluntariosInscritos'] ?? []);

      return voluntariosInscritos.contains(userId);
    } catch (e) {
      print('Error verificando registro: $e');
      return false;
    }
  }



  static Future<bool> registerUserForEvent(String eventId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      final DocumentReference<Map<String, dynamic>> eventoRef = 
          _firestore.collection('eventos').doc(eventId);

      return await _firestore.runTransaction<bool>((transaction) async {
        final eventoDoc = await transaction.get(eventoRef);

        if (!eventoDoc.exists) {
          throw Exception('Evento no encontrado');
        }

        // Convertir explícitamente a List<String>
        final List<String> voluntariosInscritos = 
            List<String>.from(eventoDoc.data()?['voluntariosInscritos'] ?? []);

        // Verificar registro existente
        if (voluntariosInscritos.contains(userId)) {
          return false;
        }

        final int cantidadMax = eventoDoc.data()?['cantidadVoluntariosMax'] ?? 0;

        // Verificar límite de participantes
        if (voluntariosInscritos.length >= cantidadMax) {
          throw Exception('El evento ha alcanzado el máximo de participantes');
        }

        // Agregar nuevo usuario
        voluntariosInscritos.add(userId);

        // Actualizar documento con la nueva lista
        transaction.update(eventoRef, {
          'voluntariosInscritos': voluntariosInscritos,
        });

        return true;
      });

    } catch (e) {
      print('Error en registro: $e');
      rethrow;
    }
  }

  static Future<List<String>> getEventParticipantsList(String eventId) async {
    try {
      final eventoDoc = await _firestore
          .collection('eventos')
          .doc(eventId)
          .get();

      if (!eventoDoc.exists) return [];

      return List<String>.from(eventoDoc.data()?['voluntariosInscritos'] ?? []);
    } catch (e) {
      print('Error obteniendo lista de participantes: $e');
      return [];
    }
  }

  static Stream<QuerySnapshot> getEventParticipantsStream(String eventId) {
    return _firestore
        .collection('eventos')
        .doc(eventId)
        .collection('participantes')
        .snapshots();
  }
}