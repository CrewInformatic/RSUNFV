import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DataMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        
        final idUsuario = data['IDUsuarioDonador'] ?? data['idUsuarioDonador'];
        if (idUsuario != null && idUsuario.toString().startsWith('DON-')) {
          updates['_needsUserIdCorrection'] = true;
          updates['_incorrectUserId'] = idUsuario;
          debugPrint('⚠️  Donación $docId tiene IDUsuarioDonador incorrecto: $idUsuario');
        }
        
        if (docId.startsWith('DON-')) {
          updates['idDonaciones'] = docId;
        }
        
        final estadoValidacion = data['estadoValidacion'];
        if (estadoValidacion is bool) {
          updates['estadoValidacion'] = estadoValidacion ? 'validado' : 'pendiente';
        }
        
        final idUsuarioDonador = data['IDUsuarioDonador'];
        if (idUsuarioDonador != null && !idUsuarioDonador.toString().startsWith('DON-')) {
          updates['idUsuarioDonador'] = idUsuarioDonador;
        }
        
        final idValidacion = data['IDValidacion'];
        if (idValidacion != null) {
          updates['idValidacion'] = idValidacion;
        }
        
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
          final donationDoc = await _firestore
              .collection('donaciones')
              .doc(donationId)
              .get();
          
          if (donationDoc.exists) {
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

  static String generateConsistentValidationId(String donationId) {
    if (!donationId.startsWith('DON-')) {
      throw ArgumentError('donationId debe empezar con "DON-"');
    }
    
    final parts = donationId.replaceFirst('DON-', '').split('-');
    final timestamp = parts[0];
    
    final suffix = _generateHashSuffix(donationId);
    
    return 'VAL-$timestamp-$suffix';
  }

  static String _generateHashSuffix(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    
    final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final result = StringBuffer();
    int absHash = hash.abs();
    
    for (int i = 0; i < 8; i++) {
      result.write(chars[absHash % chars.length]);
      absHash ~/= chars.length;
    }
    
    return result.toString();
  }

  static Future<void> runAllMigrations() async {
    debugPrint('🚀 Iniciando migración completa de datos...');
    
    await fixDonationDataInconsistencies();
    debugPrint('');
    await fixDonationValidationRelationship();
    
    debugPrint('');
    debugPrint('🎉 Migración completada exitosamente!');
  }

  static Future<void> verifyDataIntegrity() async {
    try {
      debugPrint('🔍 Verificando integridad de datos...');
      
      final donationsSnapshot = await _firestore.collection('donaciones').get();
      final validationsSnapshot = await _firestore.collection('validacion').get();
      
      debugPrint('📊 Estadísticas:');
      debugPrint('  - Total donaciones: ${donationsSnapshot.docs.length}');
      debugPrint('  - Total validaciones: ${validationsSnapshot.docs.length}');
      
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

  static Future<void> migrateVoucherUrlsToValidation() async {
    try {
      debugPrint('Iniciando migración de URLs de comprobantes a colección de validación...');
      
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
          final existingValidation = await _firestore
              .collection('validacion')
              .where('donationId', isEqualTo: donationId)
              .limit(1)
              .get();
          
          if (existingValidation.docs.isEmpty) {
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final validationId = 'VAL-$timestamp';
            final now = DateTime.now().toIso8601String();
            
            final validationData = {
              'validationId': validationId,
              'donationId': donationId,
              'proofUrl': '',
              'Imagen_Comprobante': voucherUrl,
              'isValidated': data['estadoValidacion'] == 'validado' || data['estadoValidacion'] == true,
              'createdAt': now,
              'updatedAt': now,
              'tipoValidacion': 'administrativa',
              'metodoValidacion': 'migración automática',
              'estadoComprobante': 'migrado desde donación',
              'fechaSubidaComprobante': now,
            };
            
            await _firestore
                .collection('validacion')
                .doc(validationId)
                .set(validationData);
            
            await _firestore
                .collection('donaciones')
                .doc(donationId)
                .update({
              'voucherUrl': FieldValue.delete(),
              'idValidacion': validationId,
            });
            
            migratedCount++;
            debugPrint('✅ Migrado comprobante de donación $donationId a validación $validationId');
          } else {
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
