import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationsDebugService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Método para debuggear y comparar datos entre perfil y home
  static Future<Map<String, dynamic>> compareDonationData() async {
    try {
      final userId = _auth.currentUser?.uid;
      
      // 1. Obtener todas las donaciones del sistema (como en home)
      final todasDonacionesSnapshot = await _firestore
          .collection('donaciones')
          .get();

      double totalSistemaAprobadas = 0.0;
      double totalSistemaValidadas = 0.0;
      int conteoSistemaAprobadas = 0;
      int conteoSistemaValidadas = 0;
      
      List<Map<String, dynamic>> donacionesDetalladas = [];

      for (var doc in todasDonacionesSnapshot.docs) {
        final data = doc.data();
        final estado = data['estadoValidacion']?.toString().toLowerCase() ?? '';
        final monto = (data['monto'] ?? 0.0) as double;
        final idDonador = data['idUsuarioDonador'] ?? '';
        final tipo = data['tipoDonacion']?.toString().toLowerCase() ?? '';
        
        donacionesDetalladas.add({
          'id': doc.id,
          'idDonador': idDonador,
          'monto': monto,
          'estado': estado,
          'tipo': tipo,
          'esDelUsuario': idDonador == userId,
        });

        // Contar para sistema total (como home)
        if (estado == 'aprobado') {
          totalSistemaAprobadas += monto;
          conteoSistemaAprobadas++;
        }
        
        if (estado == 'aprobado' || estado == 'validado') {
          totalSistemaValidadas += monto;
          conteoSistemaValidadas++;
        }
      }

      // 2. Obtener donaciones del usuario específico (como en perfil)
      double totalUsuarioValidadas = 0.0;
      int conteoUsuarioValidadas = 0;
      
      if (userId != null) {
        final donacionesUsuarioSnapshot = await _firestore
            .collection('donaciones')
            .where('idUsuarioDonador', isEqualTo: userId)
            .where('estadoValidacion', whereIn: ['aprobado', 'validado'])
            .get();

        for (var doc in donacionesUsuarioSnapshot.docs) {
          final data = doc.data();
          final monto = (data['monto'] ?? 0.0) as double;
          final tipo = data['tipoDonacion']?.toString().toLowerCase() ?? '';
          
          if (tipo == 'dinero' || tipo == 'monetaria') {
            totalUsuarioValidadas += monto;
            conteoUsuarioValidadas++;
          }
        }
      }

      return {
        'sistemaTotal': {
          'soloAprobadas': totalSistemaAprobadas,
          'aprobadas_y_validadas': totalSistemaValidadas,
          'conteoAprobadas': conteoSistemaAprobadas,
          'conteoValidadas': conteoSistemaValidadas,
        },
        'usuarioActual': {
          'totalValidadas': totalUsuarioValidadas,
          'conteoValidadas': conteoUsuarioValidadas,
          'userId': userId,
        },
        'donacionesDetalladas': donacionesDetalladas,
        'analisis': {
          'problema': totalUsuarioValidadas > totalSistemaAprobadas ? 'INCONSISTENCIA DETECTADA' : 'Datos consistentes',
          'explicacion': totalUsuarioValidadas > totalSistemaAprobadas 
              ? 'El usuario tiene más donaciones que todo el sistema (imposible)'
              : 'Los datos son lógicamente consistentes',
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Obtener resumen rápido para mostrar en UI
  static Future<String> getQuickSummary() async {
    try {
      final data = await compareDonationData();
      
      final sistemaAprobadas = data['sistemaTotal']['soloAprobadas'] ?? 0.0;
      final sistemaValidadas = data['sistemaTotal']['aprobadas_y_validadas'] ?? 0.0;
      final usuarioValidadas = data['usuarioActual']['totalValidadas'] ?? 0.0;
      
      return '''
🏠 HOME (Sistema total): S/ ${sistemaAprobadas.toStringAsFixed(2)} (solo 'aprobado')
🏠 HOME (mejorado): S/ ${sistemaValidadas.toStringAsFixed(2)} (aprobado + validado)
👤 PERFIL (Usuario): S/ ${usuarioValidadas.toStringAsFixed(2)} (validadas del usuario)

${data['analisis']['problema']}
${data['analisis']['explicacion']}
      ''';
    } catch (e) {
      return 'Error al obtener resumen: $e';
    }
  }
}
