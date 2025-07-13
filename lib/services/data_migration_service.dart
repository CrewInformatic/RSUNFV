import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Servicio para migrar y corregir datos de donaciones y validaciones
class DataMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Corregir inconsistencias en documentos de donaciones existentes
  static Future<void> fixDonationDataInconsistencies() async {
    try {
      debugPrint('Iniciando corrección de inconsistencias en donaciones...');
      
      final donationsSnapshot = await _firestore
          .collection('donaciones')
          .get();

      int correctedCount = 0;
      
      for (final doc in donationsSnapshot.docs) {
        final data = doc.data();
        final docId = doc.id;
        Map<String, dynamic> updates = {};
        
        // 1. Corregir IDUsuarioDonador si contiene un ID de donación en lugar del usuario
        final idUsuario = data['IDUsuarioDonador'] ?? data['idUsuarioDonador'];
        if (idUsuario != null && idUsuario.toString().startsWith('DON-')) {
          // Si IDUsuarioDonador contiene un ID de donación, necesitamos el ID real del usuario
          // Por ahora, mantener el campo pero comentar que necesita corrección manual
          updates['_needsUserIdCorrection'] = true;
          updates['_incorrectUserId'] = idUsuario;
          debugPrint('⚠️  Donación $docId tiene IDUsuarioDonador incorrecto: $idUsuario');
        }
        
        // 2. Asegurar que idDonaciones coincida con el ID del documento
        if (docId.startsWith('DON-')) {
          updates['idDonaciones'] = docId;
        }
        
        // 3. Convertir estadoValidacion booleano a string si es necesario
        final estadoValidacion = data['estadoValidacion'];
        if (estadoValidacion is bool) {
          updates['estadoValidacion'] = estadoValidacion ? 'validado' : 'pendiente';
        }
        
        // 4. Normalizar campos de usuario
        final idUsuarioDonador = data['IDUsuarioDonador'];
        if (idUsuarioDonador != null && !idUsuarioDonador.toString().startsWith('DON-')) {
          updates['idUsuarioDonador'] = idUsuarioDonador;
        }
        
        final idValidacion = data['IDValidacion'];
        if (idValidacion != null) {
          updates['idValidacion'] = idValidacion;
        }
        
        // Aplicar actualizaciones si hay cambios
        if (updates.isNotEmpty) {
          await _firestore
              .collection('donaciones')
              .doc(docId)
              .update(updates);
          correctedCount++;
          debugPrint('✅ Corregida donación: $docId');
        }
      }
      
      debugPrint('✅ Corrección completada. $correctedCount donaciones actualizadas.');
      
    } catch (e) {
      debugPrint('❌ Error en corrección de donaciones: $e');
    }
  }

  /// Verificar y corregir la relación entre donaciones y validaciones
  static Future<void> fixDonationValidationRelationship() async {
    try {
      debugPrint('Iniciando corrección de relaciones donación-validación...');
      
      final validationsSnapshot = await _firestore
          .collection('validacion')
          .get();

      int correctedCount = 0;
      
      for (final doc in validationsSnapshot.docs) {
        final data = doc.data();
        final validationId = doc.id;
        final donationId = data['donationId'];
        
        if (donationId != null && donationId.startsWith('DON-')) {
          // Verificar que la donación exista
          final donationDoc = await _firestore
              .collection('donaciones')
              .doc(donationId)
              .get();
          
          if (donationDoc.exists) {
            // Actualizar la donación con el ID de validación correcto
            await _firestore
                .collection('donaciones')
                .doc(donationId)
                .update({
              'IDValidacion': validationId,
              'idValidacion': validationId,
            });
            
            correctedCount++;
            debugPrint('✅ Relación corregida: $donationId ↔ $validationId');
          } else {
            debugPrint('⚠️  Validación huérfana encontrada: $validationId para donación inexistente: $donationId');
          }
        }
      }
      
      debugPrint('✅ Corrección de relaciones completada. $correctedCount relaciones actualizadas.');
      
    } catch (e) {
      debugPrint('❌ Error en corrección de relaciones: $e');
    }
  }

  /// Generar un ID de validación consistente basado en un ID de donación
  static String generateConsistentValidationId(String donationId) {
    if (!donationId.startsWith('DON-')) {
      throw ArgumentError('donationId debe empezar con "DON-"');
    }
    
    // Extraer timestamp del donationId
    final parts = donationId.replaceFirst('DON-', '').split('-');
    final timestamp = parts[0];
    
    // Generar sufijo único pero reproducible
    final suffix = _generateHashSuffix(donationId);
    
    return 'VAL-$timestamp-$suffix';
  }

  /// Generar sufijo hash basado en el donationId para consistencia
  static String _generateHashSuffix(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    
    // Convertir a string alfanumérico de 8 caracteres
    final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final result = StringBuffer();
    int absHash = hash.abs();
    
    for (int i = 0; i < 8; i++) {
      result.write(chars[absHash % chars.length]);
      absHash ~/= chars.length;
    }
    
    return result.toString();
  }

  /// Ejecutar todas las correcciones
  static Future<void> runAllMigrations() async {
    debugPrint('🚀 Iniciando migración completa de datos...');
    
    await fixDonationDataInconsistencies();
    debugPrint('');
    await fixDonationValidationRelationship();
    
    debugPrint('');
    debugPrint('🎉 Migración completada exitosamente!');
  }

  /// Verificar integridad de datos
  static Future<void> verifyDataIntegrity() async {
    try {
      debugPrint('🔍 Verificando integridad de datos...');
      
      // Verificar donaciones
      final donationsSnapshot = await _firestore.collection('donaciones').get();
      final validationsSnapshot = await _firestore.collection('validacion').get();
      
      debugPrint('📊 Estadísticas:');
      debugPrint('  - Total donaciones: ${donationsSnapshot.docs.length}');
      debugPrint('  - Total validaciones: ${validationsSnapshot.docs.length}');
      
      // Verificar donaciones con validaciones
      int donationsWithValidations = 0;
      int validationsWithDonations = 0;
      
      for (final doc in donationsSnapshot.docs) {
        final data = doc.data();
        final idValidacion = data['IDValidacion'] ?? data['idValidacion'];
        if (idValidacion != null && idValidacion.toString().startsWith('VAL-')) {
          donationsWithValidations++;
        }
      }
      
      for (final doc in validationsSnapshot.docs) {
        final data = doc.data();
        final donationId = data['donationId'];
        if (donationId != null && donationId.toString().startsWith('DON-')) {
          validationsWithDonations++;
        }
      }
      
      debugPrint('  - Donaciones con validación: $donationsWithValidations');
      debugPrint('  - Validaciones con donación: $validationsWithDonations');
      
      if (donationsWithValidations == validationsWithDonations) {
        debugPrint('✅ Integridad de datos verificada correctamente');
      } else {
        debugPrint('⚠️  Posibles inconsistencias detectadas');
      }
      
    } catch (e) {
      debugPrint('❌ Error verificando integridad: $e');
    }
  }

  /// Migrar URLs de comprobantes de donaciones a la colección de validación
  static Future<void> migrateVoucherUrlsToValidation() async {
    try {
      debugPrint('Iniciando migración de URLs de comprobantes a colección de validación...');
      
      // Obtener todas las donaciones que tienen voucherUrl
      final donationsSnapshot = await _firestore
          .collection('donaciones')
          .where('voucherUrl', isNotEqualTo: null)
          .get();

      int migratedCount = 0;
      
      for (final doc in donationsSnapshot.docs) {
        final data = doc.data();
        final donationId = doc.id;
        final voucherUrl = data['voucherUrl'];
        
        if (voucherUrl != null && voucherUrl.toString().isNotEmpty) {
          // Verificar si ya existe una validación para esta donación
          final existingValidation = await _firestore
              .collection('validacion')
              .where('donationId', isEqualTo: donationId)
              .limit(1)
              .get();
          
          if (existingValidation.docs.isEmpty) {
            // Crear nuevo registro de validación con el comprobante
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final validationId = 'VAL-$timestamp';
            final now = DateTime.now().toIso8601String();
            
            final validationData = {
              'validationId': validationId,
              'donationId': donationId,
              'proofUrl': '', // Campo legacy vacío
              'Imagen_Comprobante': voucherUrl, // URL del comprobante migrada aquí
              'isValidated': data['estadoValidacion'] == 'validado' || data['estadoValidacion'] == true,
              'createdAt': now,
              'updatedAt': now,
              'tipoValidacion': 'administrativa',
              'metodoValidacion': 'migración automática',
              'estadoComprobante': 'migrado desde donación',
              'fechaSubidaComprobante': now,
            };
            
            // Crear el documento de validación
            await _firestore
                .collection('validacion')
                .doc(validationId)
                .set(validationData);
            
            // Actualizar la donación para eliminar voucherUrl y agregar referencia a validación
            await _firestore
                .collection('donaciones')
                .doc(donationId)
                .update({
              'voucherUrl': FieldValue.delete(), // Eliminar campo voucherUrl
              'idValidacion': validationId, // Agregar referencia a validación
            });
            
            migratedCount++;
            debugPrint('✅ Migrado comprobante de donación $donationId a validación $validationId');
          } else {
            // Si ya existe validación, solo actualizar la imagen del comprobante si no existe
            final existingData = existingValidation.docs.first.data();
            if (existingData['Imagen_Comprobante'] == null || existingData['Imagen_Comprobante'].toString().isEmpty) {
              await _firestore
                  .collection('validacion')
                  .doc(existingValidation.docs.first.id)
                  .update({
                'Imagen_Comprobante': voucherUrl,
                'estadoComprobante': 'migrado desde donación',
                'updatedAt': DateTime.now().toIso8601String(),
              });
              
              // Eliminar voucherUrl de la donación
              await _firestore
                  .collection('donaciones')
                  .doc(donationId)
                  .update({
                'voucherUrl': FieldValue.delete(),
              });
              
              migratedCount++;
              debugPrint('✅ Actualizado comprobante en validación existente para donación $donationId');
            }
          }
        }
      }
      
      debugPrint('✅ Migración completada. $migratedCount URLs de comprobantes migradas a validación.');
      
    } catch (e) {
      debugPrint('❌ Error durante la migración de URLs de comprobantes: $e');
      rethrow;
    }
  }
}
