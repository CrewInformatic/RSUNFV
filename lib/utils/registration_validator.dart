import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class RegistrationValidator {
  static final Logger _logger = Logger();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<RegistrationResult> validateRegistration(String eventoId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return RegistrationResult.error('Usuario no autenticado');
      }

      final eventoDoc = await _firestore.collection('eventos').doc(eventoId).get();
      
      if (!eventoDoc.exists) {
        return RegistrationResult.error('Evento no encontrado');
      }

      final eventoData = eventoDoc.data();
      if (eventoData == null) {
        return RegistrationResult.error('Datos del evento no válidos');
      }

      final List<dynamic> voluntariosInscritosRaw = eventoData['voluntariosInscritos'] ?? [];
      final List<String> voluntariosInscritos = voluntariosInscritosRaw.cast<String>();

      if (voluntariosInscritos.contains(userId)) {
        return RegistrationResult.alreadyRegistered();
      }

      final int cantidadMax = eventoData['cantidadVoluntariosMax'] ?? 0;
      if (cantidadMax > 0 && voluntariosInscritos.length >= cantidadMax) {
        return RegistrationResult.error('El evento ha alcanzado el máximo de participantes ($cantidadMax)');
      }

      final String fechaInicio = eventoData['fechaInicio'] ?? '';
      if (fechaInicio.isNotEmpty) {
        final DateTime? fechaEventoStart = DateTime.tryParse(fechaInicio);
        if (fechaEventoStart != null && fechaEventoStart.isBefore(DateTime.now())) {
          return RegistrationResult.error('El evento ya ha comenzado');
        }
      }

      return RegistrationResult.canRegister();
    } catch (e) {
      _logger.e('Error validating registration: $e');
      return RegistrationResult.error('Error de validación: ${e.toString()}');
    }
  }

  static Future<RegistrationResult> attemptRegistration(String eventoId) async {
    try {
      final validation = await validateRegistration(eventoId);
      if (!validation.canProceed) {
        return validation;
      }

      final userId = _auth.currentUser!.uid;
      final eventoRef = _firestore.collection('eventos').doc(eventoId);

      final result = await _firestore.runTransaction<bool>((transaction) async {
        final eventoDoc = await transaction.get(eventoRef);
        
        if (!eventoDoc.exists) {
          throw Exception('Evento no encontrado');
        }

        final eventoData = eventoDoc.data()!;
        final List<dynamic> voluntariosInscritosRaw = eventoData['voluntariosInscritos'] ?? [];
        final List<String> voluntariosInscritos = voluntariosInscritosRaw.cast<String>();

        if (voluntariosInscritos.contains(userId)) {
          return false;
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

        return true;
      });

      if (result) {
        _logger.i('Registration successful for user $userId in event $eventoId');
        return RegistrationResult.success();
      } else {
        return RegistrationResult.alreadyRegistered();
      }
    } catch (e) {
      _logger.e('Registration failed: $e');
      return RegistrationResult.error('Error en el registro: ${e.toString()}');
    }
  }
}

class RegistrationResult {
  final RegistrationStatus status;
  final String message;

  const RegistrationResult._(this.status, this.message);

  static RegistrationResult canRegister() => 
      const RegistrationResult._(RegistrationStatus.canRegister, 'Puede registrarse');
  
  static RegistrationResult alreadyRegistered() => 
      const RegistrationResult._(RegistrationStatus.alreadyRegistered, 'Ya está registrado');
  
  static RegistrationResult success() => 
      const RegistrationResult._(RegistrationStatus.success, 'Registro exitoso');
  
  static RegistrationResult error(String message) => 
      RegistrationResult._(RegistrationStatus.error, message);

  bool get canProceed => status == RegistrationStatus.canRegister;
  bool get isSuccess => status == RegistrationStatus.success;
  bool get isAlreadyRegistered => status == RegistrationStatus.alreadyRegistered;
  bool get isError => status == RegistrationStatus.error;
}

enum RegistrationStatus {
  canRegister,
  alreadyRegistered,
  success,
  error,
}
