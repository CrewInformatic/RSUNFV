import 'package:flutter/foundation.dart';
import '../services/donations_debug_service.dart';

/// Clase para ejecutar debug rápido desde cualquier parte
class QuickDebug {
  /// Ejecuta debug y muestra resultados en console
  static Future<void> runDonationsDebug() async {
    if (kDebugMode) {
      print('\n========== DEBUG DONACIONES ==========');
      try {
        final data = await DonationsDebugService.compareDonationData();
        
        print('\n🏠 SISTEMA TOTAL (Home Screen):');
        print('Solo aprobadas: S/ ${data['sistemaTotal']['soloAprobadas']}');
        print('Aprobadas + Validadas: S/ ${data['sistemaTotal']['aprobadas_y_validadas']}');
        print('Conteo aprobadas: ${data['sistemaTotal']['conteoAprobadas']}');
        print('Conteo validadas: ${data['sistemaTotal']['conteoValidadas']}');
        
        print('\n👤 USUARIO ACTUAL (Profile Screen):');
        print('Total validadas: S/ ${data['usuarioActual']['totalValidadas']}');
        print('Conteo validadas: ${data['usuarioActual']['conteoValidadas']}');
        print('User ID: ${data['usuarioActual']['userId']}');
        
        print('\n🔍 ANÁLISIS:');
        print('${data['analisis']['problema']}');
        print('${data['analisis']['explicacion']}');
        
        print('\n📋 DONACIONES DETALLADAS:');
        final donaciones = data['donacionesDetalladas'] as List<Map<String, dynamic>>;
        for (var i = 0; i < donaciones.length && i < 10; i++) {
          final donacion = donaciones[i];
          final esDelUsuario = donacion['esDelUsuario'] ? '👤' : '👥';
          print('$esDelUsuario ${donacion['estado']}: S/ ${donacion['monto']} (${donacion['tipo']})');
        }
        if (donaciones.length > 10) {
          print('... y ${donaciones.length - 10} donaciones más');
        }
        
        print('\n======================================\n');
      } catch (e) {
        print('ERROR en debug: $e');
      }
    }
  }
  
  /// Debug simplificado que retorna solo string
  static Future<String> getSimpleDebug() async {
    try {
      final data = await DonationsDebugService.compareDonationData();
      return '''
HOME: S/ ${data['sistemaTotal']['soloAprobadas']} → S/ ${data['sistemaTotal']['aprobadas_y_validadas']}
PERFIL: S/ ${data['usuarioActual']['totalValidadas']}
${data['analisis']['problema']}
      ''';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
