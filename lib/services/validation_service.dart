import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/validacion.dart';
import 'cloudinary_services.dart';

/// Servicio para manejar validaciones de donaciones
class ValidationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Crear un nuevo registro de validación con prefijo VAL-
  static Future<String?> createValidationRecord({
    required String donationId,
    String? adminNotes,
    List<int>? voucherImageBytes, // Imagen del comprobante/voucher
  }) async {
    try {
      // Generar ID de validación con prefijo VAL- basado en el donationId
      // Extraer el timestamp del donationId para mantener consistencia
      final donationTimestamp = donationId.replaceFirst('DON-', '').split('-')[0];
      final validationSuffix = _generateRandomSuffix();
      final validationId = 'VAL-$donationTimestamp-$validationSuffix';
      
      // Obtener información del admin actual
      final currentUser = _auth.currentUser;
      final adminId = currentUser?.uid ?? 'sistema';
      
      // Subir imagen del comprobante a Cloudinary si se proporciona
      String? imagenComprobanteUrl;
      if (voucherImageBytes != null) {
        imagenComprobanteUrl = await CloudinaryService.uploadValidationProof(
          voucherImageBytes, 
          validationId
        );
      }
      
      // Crear documento de validación
      final validationData = {
        'validationId': validationId,
        'donationId': donationId,
        'proofUrl': '', // Ya no guardamos el voucher aquí inicialmente
        'isValidated': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'validatedAt': DateTime.now().toIso8601String(),
        'validatedBy': adminId,
        'adminNotes': adminNotes ?? 'Donación validada por administrador',
        'Imagen_Comprobante': imagenComprobanteUrl, // Aquí guardamos la imagen del comprobante
        // Campos adicionales para mejor trazabilidad
        'tipoValidacion': 'administrativa',
        'metodoValidacion': 'manual',
        'estadoComprobante': imagenComprobanteUrl != null ? 'subido' : 'pendiente',
        'fechaSubidaComprobante': imagenComprobanteUrl != null ? DateTime.now().toIso8601String() : null,
      };
      
      await _firestore
          .collection('validacion')
          .doc(validationId)
          .set(validationData);
      
      // Actualizar la donación con el ID de validación
      await _firestore
          .collection('donaciones')
          .doc(donationId)
          .update({
        'idValidacion': validationId, // Corregido para coincidir con el modelo
        'IDValidacion': validationId, // Mantener compatibilidad con datos existentes
        'fechaValidacion': FieldValue.serverTimestamp(),
        'UsuarioEstadoValidacion': adminId,
        // NO guardar voucherUrl aquí - solo en validación
      });
      
      return validationId;
    } catch (e) {
      debugPrint('Error creating validation record: $e');
      return null;
    }
  }

  /// Generar sufijo aleatorio para ID de validación
  static String _generateRandomSuffix() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final suffix = List.generate(8, (index) {
      return chars[(random + index) % chars.length];
    }).join();
    return suffix;
  }

  /// Obtener todas las validaciones
  static Stream<List<Validacion>> getAllValidations() {
    return _firestore
        .collection('validacion')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['validationId'] = doc.id; // Asegurar que el ID esté incluido
        return Validacion.fromMap(data);
      }).toList();
    });
  }

  /// Obtener validaciones por donationId
  static Stream<List<Validacion>> getValidationsByDonation(String donationId) {
    return _firestore
        .collection('validacion')
        .where('donationId', isEqualTo: donationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['validationId'] = doc.id;
        return Validacion.fromMap(data);
      }).toList();
    });
  }

  /// Subir comprobante de validación y actualizarlo en el registro
  static Future<bool> uploadValidationProof({
    required String validationId,
    required List<int> imageBytes,
    String? adminNotes,
  }) async {
    try {
      // Subir imagen a Cloudinary con prefijo VAL-
      final cloudinaryUrl = await CloudinaryService.uploadValidationProof(imageBytes, validationId);
      
      if (cloudinaryUrl != null) {
        // Actualizar el documento de validación
        await _firestore
            .collection('validacion')
            .doc(validationId)
            .update({
          'Imagen_Comprobante': cloudinaryUrl,
          'updatedAt': DateTime.now().toIso8601String(),
          'adminNotes': adminNotes,
        });
        
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error uploading validation proof: $e');
      return false;
    }
  }

  /// Actualizar notas del admin en una validación
  static Future<bool> updateAdminNotes({
    required String validationId,
    required String adminNotes,
  }) async {
    try {
      await _firestore
          .collection('validacion')
          .doc(validationId)
          .update({
        'adminNotes': adminNotes,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error updating admin notes: $e');
      return false;
    }
  }

  /// Obtener una validación específica por ID
  static Future<Validacion?> getValidationById(String validationId) async {
    try {
      final doc = await _firestore
          .collection('validacion')
          .doc(validationId)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['validationId'] = doc.id;
        return Validacion.fromMap(data);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting validation by ID: $e');
      return null;
    }
  }

  /// Obtener la URL de la imagen de comprobante para una donación específica
  static Future<String?> getVoucherImageUrl(String donationId) async {
    try {
      final querySnapshot = await _firestore
          .collection('validacion')
          .where('donationId', isEqualTo: donationId)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final validationData = querySnapshot.docs.first.data();
        return validationData['Imagen_Comprobante'] as String?;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error obteniendo imagen de comprobante: $e');
      return null;
    }
  }

  /// Verificar si una donación tiene imagen de comprobante
  static Future<bool> hasVoucherImage(String donationId) async {
    final imageUrl = await getVoucherImageUrl(donationId);
    return imageUrl != null && imageUrl.isNotEmpty;
  }
}
