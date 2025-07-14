import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/donaciones.dart';

class DonationsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtiene todas las donaciones del usuario actual
  /// Si soloValidadas=true, retorna únicamente donaciones aprobadas/validadas
  static Future<List<Donaciones>> getDonacionesUsuario({
    String? userId, 
    bool soloValidadas = false
  }) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) return [];

      final snapshot = await _firestore
          .collection('donaciones')
          .where('idUsuarioDonador', isEqualTo: uid)
          .orderBy('fechaDonacion', descending: true)
          .get();

      List<Donaciones> donaciones = snapshot.docs.map((doc) {
        final data = doc.data();
        return Donaciones.fromMap({
          ...data,
          'idDonaciones': doc.id,
        });
      }).toList();

      // Filtrar solo validadas si se solicita
      if (soloValidadas) {
        donaciones = donaciones.where((donacion) {
          final estado = donacion.estadoValidacion.toLowerCase();
          return estado == 'aprobado' || estado == 'validado';
        }).toList();
      }

      return donaciones;
    } catch (e) {
      print('Error obteniendo donaciones del usuario: $e');
      return [];
    }
  }

  /// Obtiene solo las donaciones validadas del usuario
  static Future<List<Donaciones>> getDonacionesValidadas({String? userId}) async {
    return await getDonacionesUsuario(userId: userId, soloValidadas: true);
  }

  /// Calcula el monto total donado por el usuario (solo validadas)
  static Future<double> getMontoTotalDonado({String? userId}) async {
    try {
      final donacionesValidadas = await getDonacionesValidadas(userId: userId);
      double total = 0.0;
      
      for (var donacion in donacionesValidadas) {
        if (donacion.tipoDonacion.toLowerCase() == 'dinero' || 
            donacion.tipoDonacion.toLowerCase() == 'monetaria') {
          total += donacion.monto;
        }
      }
      
      return total;
    } catch (e) {
      print('Error calculando monto total donado: $e');
      return 0.0;
    }
  }

  /// Obtiene el historial de donaciones por evento (solo validadas)
  static Future<Map<String, List<Donaciones>>> getDonacionesPorEvento({String? userId}) async {
    try {
      final donacionesValidadas = await getDonacionesValidadas(userId: userId);
      Map<String, List<Donaciones>> donacionesPorEvento = {};
      
      for (var donacion in donacionesValidadas) {
        final eventoId = donacion.idEvento ?? 'general';
        if (!donacionesPorEvento.containsKey(eventoId)) {
          donacionesPorEvento[eventoId] = [];
        }
        donacionesPorEvento[eventoId]!.add(donacion);
      }
      
      return donacionesPorEvento;
    } catch (e) {
      print('Error obteniendo donaciones por evento: $e');
      return {};
    }
  }

  /// Obtiene estadísticas completas de donaciones del usuario
  /// Incluye todas las donaciones pero separa claramente validadas vs pendientes/rechazadas
  static Future<Map<String, dynamic>> getEstadisticasDonaciones({String? userId}) async {
    try {
      // Obtener todas las donaciones para estadísticas completas
      final todasLasDonaciones = await getDonacionesUsuario(userId: userId, soloValidadas: false);
      // Obtener solo validadas para cálculos de monto real
      final donacionesValidadas = await getDonacionesValidadas(userId: userId);
      
      int totalDonaciones = todasLasDonaciones.length;
      int donacionesAprobadas = 0;
      int donacionesPendientes = 0;
      int donacionesRechazadas = 0;
      
      // El monto total y aprobado solo cuenta las validadas
      double montoTotalValidado = 0.0;
      double montoAprobado = 0.0;
      
      Map<String, int> donacionesPorTipo = {};
      Map<String, int> donacionesPorMetodo = {};
      Map<String, int> donacionesValidadasPorTipo = {};
      
      // Procesar todas las donaciones para estadísticas generales
      for (var donacion in todasLasDonaciones) {
        // Contar por estado
        switch (donacion.estadoValidacion.toLowerCase()) {
          case 'aprobado':
          case 'validado':
            donacionesAprobadas++;
            break;
          case 'pendiente':
          case 'en revision':
          case 'en_revision':
            donacionesPendientes++;
            break;
          case 'rechazado':
          case 'denegado':
          case 'rechazada':
            donacionesRechazadas++;
            break;
        }
        
        // Contar por tipo (todas las donaciones)
        final tipo = donacion.tipoDonacion;
        donacionesPorTipo[tipo] = (donacionesPorTipo[tipo] ?? 0) + 1;
        
        // Contar por método de pago (todas las donaciones)
        final metodo = donacion.metodoPago.isNotEmpty ? donacion.metodoPago : 'Otro';
        donacionesPorMetodo[metodo] = (donacionesPorMetodo[metodo] ?? 0) + 1;
      }
      
      // Procesar solo donaciones validadas para montos reales
      for (var donacion in donacionesValidadas) {
        final tipo = donacion.tipoDonacion;
        donacionesValidadasPorTipo[tipo] = (donacionesValidadasPorTipo[tipo] ?? 0) + 1;
        
        // Solo contar monto de donaciones monetarias validadas
        if (donacion.tipoDonacion.toLowerCase() == 'dinero' || 
            donacion.tipoDonacion.toLowerCase() == 'monetaria') {
          montoTotalValidado += donacion.monto;
          montoAprobado += donacion.monto; // Son lo mismo ya que solo son validadas
        }
      }
      
      // Calcular primera y última donación basándose en donaciones validadas
      DateTime? primeraDonacion;
      DateTime? ultimaDonacion;
      
      if (donacionesValidadas.isNotEmpty) {
        try {
          final fechasOrdenadas = donacionesValidadas
              .map((d) => DateTime.parse(d.fechaDonacion))
              .toList()
            ..sort();
          primeraDonacion = fechasOrdenadas.first;
          ultimaDonacion = fechasOrdenadas.last;
        } catch (e) {
          print('Error parseando fechas de donaciones: $e');
        }
      }
      
      return {
        'totalDonaciones': totalDonaciones,
        'donacionesAprobadas': donacionesAprobadas,
        'donacionesPendientes': donacionesPendientes,
        'donacionesRechazadas': donacionesRechazadas,
        'montoTotalValidado': montoTotalValidado, // Solo donaciones validadas
        'montoAprobado': montoAprobado, // Igual que el anterior
        'donacionesPorTipo': donacionesPorTipo, // Todas las donaciones
        'donacionesValidadasPorTipo': donacionesValidadasPorTipo, // Solo validadas
        'donacionesPorMetodo': donacionesPorMetodo,
        'primeraDonacion': primeraDonacion,
        'ultimaDonacion': ultimaDonacion,
        'promedioMensual': _calcularPromedioMensual(donacionesValidadas),
        'tendencia': _calcularTendencia(donacionesValidadas),
      };
    } catch (e) {
      print('Error obteniendo estadísticas de donaciones: $e');
      return {};
    }
  }

  /// Obtiene el ranking de donadores
  static Future<List<Map<String, dynamic>>> getRankingDonadores() async {
    try {
      // Obtener todas las donaciones aprobadas
      final snapshot = await _firestore
          .collection('donaciones')
          .where('estadoValidacion', whereIn: ['aprobado', 'validado'])
          .get();

      Map<String, double> donacionesPorUsuario = {};
      Map<String, int> cantidadDonacionesPorUsuario = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['idUsuarioDonador'] ?? '';
        final monto = (data['monto'] ?? 0.0) as double;
        final tipo = (data['tipoDonacion'] ?? '').toLowerCase();
        
        if (userId.isNotEmpty && (tipo == 'dinero' || tipo == 'monetaria')) {
          donacionesPorUsuario[userId] = (donacionesPorUsuario[userId] ?? 0.0) + monto;
          cantidadDonacionesPorUsuario[userId] = (cantidadDonacionesPorUsuario[userId] ?? 0) + 1;
        }
      }
      
      // Obtener información de usuarios
      List<Map<String, dynamic>> ranking = [];
      
      for (var entry in donacionesPorUsuario.entries) {
        try {
          final userDoc = await _firestore.collection('usuarios').doc(entry.key).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            ranking.add({
              'userId': entry.key,
              'nombreCompleto': '${userData['nombreUsuario'] ?? ''} ${userData['apellidoUsuario'] ?? ''}',
              'fotoPerfil': userData['fotoPerfil'],
              'montoTotal': entry.value,
              'cantidadDonaciones': cantidadDonacionesPorUsuario[entry.key] ?? 0,
              'promedioDonacion': (entry.value / (cantidadDonacionesPorUsuario[entry.key] ?? 1)),
            });
          }
        } catch (e) {
          print('Error obteniendo datos del usuario ${entry.key}: $e');
        }
      }
      
      // Ordenar por monto total donado
      ranking.sort((a, b) => b['montoTotal'].compareTo(a['montoTotal']));
      
      return ranking;
    } catch (e) {
      print('Error obteniendo ranking de donadores: $e');
      return [];
    }
  }

  /// Obtiene las donaciones más recientes del sistema
  static Future<List<Map<String, dynamic>>> getDonacionesRecientes({int limite = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('donaciones')
          .where('estadoValidacion', whereIn: ['aprobado', 'validado'])
          .orderBy('fechaDonacion', descending: true)
          .limit(limite)
          .get();

      List<Map<String, dynamic>> donacionesRecientes = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['idUsuarioDonador'] ?? '';
        
        try {
          final userDoc = await _firestore.collection('usuarios').doc(userId).get();
          String nombreDonador = 'Usuario Anónimo';
          
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            nombreDonador = '${userData['nombreUsuario'] ?? ''} ${userData['apellidoUsuario'] ?? ''}'.trim();
            if (nombreDonador.isEmpty) {
              nombreDonador = 'Usuario Anónimo';
            }
          }
          
          donacionesRecientes.add({
            'nombreDonador': nombreDonador,
            'monto': data['monto'] ?? 0.0,
            'tipoDonacion': data['tipoDonacion'] ?? '',
            'fechaDonacion': data['fechaDonacion'] ?? '',
            'descripcion': data['descripcion'] ?? '',
          });
        } catch (e) {
          print('Error procesando donación reciente: $e');
        }
      }
      
      return donacionesRecientes;
    } catch (e) {
      print('Error obteniendo donaciones recientes: $e');
      return [];
    }
  }

  // Métodos auxiliares privados
  static double _calcularPromedioMensual(List<Donaciones> donaciones) {
    if (donaciones.isEmpty) return 0.0;
    
    try {
      final fechas = donaciones
          .map((d) => DateTime.parse(d.fechaDonacion))
          .toList()
        ..sort();
      
      if (fechas.isEmpty) return 0.0;
      
      final diferenciaMeses = _diferenciaEnMeses(fechas.first, fechas.last);
      final meses = diferenciaMeses > 0 ? diferenciaMeses : 1;
      
      final montoTotal = donaciones
          .where((d) => d.tipoDonacion.toLowerCase() == 'dinero' || 
                       d.tipoDonacion.toLowerCase() == 'monetaria')
          .fold(0.0, (sum, d) => sum + d.monto);
      
      return montoTotal / meses;
    } catch (e) {
      print('Error calculando promedio mensual: $e');
      return 0.0;
    }
  }

  static String _calcularTendencia(List<Donaciones> donaciones) {
    if (donaciones.length < 2) return 'estable';
    
    try {
      final ahora = DateTime.now();
      final hace30Dias = ahora.subtract(const Duration(days: 30));
      final hace60Dias = ahora.subtract(const Duration(days: 60));
      
      final donacionesRecientes = donaciones
          .where((d) => DateTime.parse(d.fechaDonacion).isAfter(hace30Dias))
          .length;
      
      final donacionesAnteriores = donaciones
          .where((d) {
            final fecha = DateTime.parse(d.fechaDonacion);
            return fecha.isAfter(hace60Dias) && fecha.isBefore(hace30Dias);
          })
          .length;
      
      if (donacionesRecientes > donacionesAnteriores) {
        return 'creciente';
      } else if (donacionesRecientes < donacionesAnteriores) {
        return 'decreciente';
      } else {
        return 'estable';
      }
    } catch (e) {
      print('Error calculando tendencia: $e');
      return 'estable';
    }
  }

  static int _diferenciaEnMeses(DateTime inicio, DateTime fin) {
    return (fin.year - inicio.year) * 12 + fin.month - inicio.month;
  }
}
