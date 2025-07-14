import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio para prevenir spam en donaciones
class DonationAntiSpamService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Tiempo mínimo entre uploads de vouchers (en minutos)
  static const int _minMinutesBetweenUploads = 30;
  
  /// Máximo número de donaciones pendientes permitidas por usuario
  static const int _maxPendingDonations = 3;

  /// Máximo número de donaciones por día por usuario
  static const int _maxDonationsPerDay = 5;

  /// Valida si el usuario puede subir un nuevo voucher
  static Future<ValidationResult> canUserUploadVoucher({String? userId}) async {
    try {
      // 1. Verificar que el usuario esté autenticado
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        return ValidationResult.error(
          'Debes iniciar sesión para realizar donaciones'
        );
      }

      // 2. Verificar tiempo mínimo entre uploads
      final timeValidation = await _validateTimeInterval(uid);
      if (!timeValidation.isValid) {
        return timeValidation;
      }

      // 3. Verificar límite de donaciones pendientes
      final pendingValidation = await _validatePendingDonations(uid);
      if (!pendingValidation.isValid) {
        return pendingValidation;
      }

      // 4. Verificar límite diario de donaciones
      final dailyValidation = await _validateDailyLimit(uid);
      if (!dailyValidation.isValid) {
        return dailyValidation;
      }

      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.error(
        'Error al validar permisos de donación: ${e.toString()}'
      );
    }
  }

  /// Valida el tiempo mínimo entre uploads
  static Future<ValidationResult> _validateTimeInterval(String userId) async {
    try {
      final now = DateTime.now();
      final minTimeAgo = now.subtract(Duration(minutes: _minMinutesBetweenUploads));

      // Obtener todas las donaciones del usuario
      final userDonations = await _firestore
          .collection('donaciones')
          .where('idUsuarioDonador', isEqualTo: userId)
          .get();

      // Filtrar donaciones recientes en memoria
      DateTime? lastDonationTime;
      for (final doc in userDonations.docs) {
        final data = doc.data();
        final fechaDonacion = data['fechaDonacion'] as String?;
        if (fechaDonacion != null) {
          try {
            final donationDate = DateTime.parse(fechaDonacion);
            if (donationDate.isAfter(minTimeAgo)) {
              if (lastDonationTime == null || donationDate.isAfter(lastDonationTime)) {
                lastDonationTime = donationDate;
              }
            }
          } catch (e) {
            // Ignorar fechas mal formateadas
          }
        }
      }

      if (lastDonationTime != null) {
        final remainingMinutes = _minMinutesBetweenUploads - 
            now.difference(lastDonationTime).inMinutes;

        return ValidationResult.error(
          'Debes esperar ${remainingMinutes} minutos antes de realizar otra donación'
        );
      }

      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.error('Error validando tiempo entre donaciones');
    }
  }

  /// Valida el límite de donaciones pendientes
  static Future<ValidationResult> _validatePendingDonations(String userId) async {
    try {
      final pendingDonations = await _firestore
          .collection('donaciones')
          .where('idUsuarioDonador', isEqualTo: userId)
          .where('estadoValidacion', isEqualTo: 'pendiente')
          .get();

      if (pendingDonations.docs.length >= _maxPendingDonations) {
        return ValidationResult.error(
          'Tienes $_maxPendingDonations donaciones pendientes de validación. '
          'Espera a que sean procesadas antes de enviar una nueva donación.'
        );
      }

      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.error('Error validando donaciones pendientes');
    }
  }

  /// Valida el límite diario de donaciones
  static Future<ValidationResult> _validateDailyLimit(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Obtener todas las donaciones del usuario
      final userDonations = await _firestore
          .collection('donaciones')
          .where('idUsuarioDonador', isEqualTo: userId)
          .get();

      // Filtrar donaciones del día actual en memoria
      final todayDonationsCount = userDonations.docs.where((doc) {
        final data = doc.data();
        final fechaDonacion = data['fechaDonacion'] as String?;
        if (fechaDonacion == null) return false;
        
        try {
          final donationDate = DateTime.parse(fechaDonacion);
          return donationDate.isAfter(startOfDay) || 
                 donationDate.isAtSameMomentAs(startOfDay);
        } catch (e) {
          return false;
        }
      }).length;

      if (todayDonationsCount >= _maxDonationsPerDay) {
        return ValidationResult.error(
          'Has alcanzado el límite diario de $_maxDonationsPerDay donaciones. '
          'Podrás realizar más donaciones mañana.'
        );
      }

      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.error('Error validando límite diario');
    }
  }

  /// Registra un intento de upload (exitoso o fallido) para análisis
  static Future<void> logUploadAttempt({
    required String userId,
    required bool success,
    String? errorReason,
  }) async {
    try {
      await _firestore.collection('donation_upload_logs').add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'success': success,
        'errorReason': errorReason,
        'userAgent': 'RSUNFV_App',
      });
    } catch (e) {
      print('Error logging upload attempt: $e');
    }
  }


  /// Obtiene estadísticas detalladas de donaciones del usuario actual
  static Future<Map<String, dynamic>> getUserDonationStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'canDonateNow': false,
          'donationsToday': 0,
          'maxDonationsPerDay': _maxDonationsPerDay,
          'pendingDonations': 0,
          'maxPendingDonations': _maxPendingDonations,
          'minMinutesBetweenUploads': _minMinutesBetweenUploads,
        };
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Obtener TODAS las donaciones del usuario (para evitar consulta compuesta)
      final userDonations = await FirebaseFirestore.instance
          .collection('donaciones')
          .where('idUsuarioDonador', isEqualTo: user.uid)
          .get();

      // Filtrar donaciones del día actual en memoria
      final todayDonations = userDonations.docs.where((doc) {
        final data = doc.data();
        final fechaDonacion = data['fechaDonacion'] as String?;
        if (fechaDonacion == null) return false;
        
        try {
          final donationDate = DateTime.parse(fechaDonacion);
          return donationDate.isAfter(startOfDay) || 
                 donationDate.isAtSameMomentAs(startOfDay);
        } catch (e) {
          return false;
        }
      }).toList();

      // Filtrar donaciones pendientes en memoria
      final pendingDonations = userDonations.docs.where((doc) {
        final data = doc.data();
        final estado = data['estadoValidacion'] as String?;
        return estado == 'pendiente';
      }).toList();

      // Verificar si puede donar por tiempo
      bool canDonateByTime = true;
      if (todayDonations.isNotEmpty) {
        DateTime? lastDonation;
        for (final doc in todayDonations) {
          final data = doc.data();
          final fechaDonacion = data['fechaDonacion'] as String?;
          if (fechaDonacion != null) {
            try {
              final donationDate = DateTime.parse(fechaDonacion);
              if (lastDonation == null || donationDate.isAfter(lastDonation)) {
                lastDonation = donationDate;
              }
            } catch (e) {
              // Ignorar fechas mal formateadas
            }
          }
        }
        
        if (lastDonation != null) {
          canDonateByTime = now.difference(lastDonation).inMinutes >= _minMinutesBetweenUploads;
        }
      }

      return {
        'canDonateNow': canDonateByTime,
        'donationsToday': todayDonations.length,
        'maxDonationsPerDay': _maxDonationsPerDay,
        'pendingDonations': pendingDonations.length,
        'maxPendingDonations': _maxPendingDonations,
        'minMinutesBetweenUploads': _minMinutesBetweenUploads,
      };
    } catch (e) {
      print('Error getting user donation stats: $e');
      return {
        'canDonateNow': false,
        'donationsToday': 0,
        'maxDonationsPerDay': _maxDonationsPerDay,
        'pendingDonations': 0,
        'maxPendingDonations': _maxPendingDonations,
        'minMinutesBetweenUploads': _minMinutesBetweenUploads,
      };
    }
  }
}

/// Resultado de validación
class ValidationResult {
  final bool isValid;
  final String message;

  const ValidationResult._(this.isValid, this.message);

  static ValidationResult success() => 
      const ValidationResult._(true, 'Validación exitosa');

  static ValidationResult error(String message) => 
      ValidationResult._(false, message);
}
