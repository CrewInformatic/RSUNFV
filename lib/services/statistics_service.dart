import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/estadisticas_usuario.dart';
import '../models/evento.dart';
import '../models/donaciones.dart';

class StatisticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtiene las estadísticas del usuario desde la base de datos
  static Future<EstadisticasUsuario> getEstadisticasUsuario({String? userId}) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        return _getEmptyStatistics();
      }

      // Obtener eventos del usuario
      final eventosSnapshot = await _firestore
          .collection('eventos')
          .where('participantes', arrayContains: uid)
          .get();

      final eventos = eventosSnapshot.docs.map((doc) {
        final data = doc.data();
        return Evento.fromMap({
          ...data,
          'idEvento': doc.id,
        });
      }).toList();

      // Obtener donaciones del usuario (solo validadas para estadísticas)
      final donacionesSnapshot = await _firestore
          .collection('donaciones')
          .where('idUsuarioDonador', isEqualTo: uid)
          .where('estadoValidacion', whereIn: ['aprobado', 'validado'])
          .get();

      final donaciones = donacionesSnapshot.docs.map((doc) {
        final data = doc.data();
        return Donaciones.fromMap({
          ...data,
          'idDonaciones': doc.id,
        });
      }).toList();

      // Calcular estadísticas
      return calcularEstadisticasCompletas(
        eventos: eventos,
        donaciones: donaciones,
        userId: uid,
      );

    } catch (e) {
      print('Error obteniendo estadísticas del usuario: $e');
      return _getEmptyStatistics();
    }
  }

  /// Calcula estadísticas completas con datos dinámicos
  static EstadisticasUsuario calcularEstadisticasCompletas({
    required List<Evento> eventos,
    required List<Donaciones> donaciones,
    required String userId,
  }) {
    // Cálculos de eventos
    int eventosInscritos = eventos.length;
    int eventosCompletados = 0;
    int eventosPendientes = 0;
    int eventosEnProceso = 0;
    double horasTotales = 0;

    for (var evento in eventos) {
      switch (evento.estado.toLowerCase()) {
        case 'finalizado':
          eventosCompletados++;
          horasTotales += _calcularHorasEvento(evento);
          break;
        case 'en proceso':
          eventosEnProceso++;
          break;
        case 'pendiente':
          eventosPendientes++;
          break;
      }
    }

    // Cálculos de donaciones (solo validadas)
    int donacionesRealizadas = donaciones.length;
    double montoTotalDonado = 0;
    
    for (var donacion in donaciones) {
      // Solo contar montos de donaciones monetarias ya que están pre-filtradas como validadas
      if (donacion.tipoDonacion.toLowerCase() == 'dinero' || 
          donacion.tipoDonacion.toLowerCase() == 'monetaria') {
        montoTotalDonado += donacion.monto;
      }
    }

    // Cálculos de rachas
    int rachaActual = _calcularRachaActual(eventos);
    int mejorRacha = _calcularMejorRacha(eventos);

    // Calcular puntos y nivel
    int puntosTotales = _calcularPuntosTotales(
      eventosCompletados: eventosCompletados,
      horasTotales: horasTotales,
      donacionesRealizadas: donacionesRealizadas,
      montoTotalDonado: montoTotalDonado,
    );

    Map<String, dynamic> nivelInfo = _calcularNivel(puntosTotales);

    return EstadisticasUsuario(
      eventosInscritos: eventosInscritos,
      eventosCompletados: eventosCompletados,
      eventosPendientes: eventosPendientes,
      eventosEnProceso: eventosEnProceso,
      horasTotales: horasTotales,
      rachaActual: rachaActual,
      mejorRacha: mejorRacha,
      donacionesRealizadas: donacionesRealizadas,
      montoTotalDonado: montoTotalDonado,
      medallasObtenidas: [], // Se obtienen por separado
      medallasDisponibles: [], // Se obtienen por separado
      puntosTotales: puntosTotales,
      nivelActual: nivelInfo['nivel'],
      progresoNivelSiguiente: nivelInfo['progreso'],
    );
  }

  /// Obtiene rangos y niveles desde la base de datos
  static Future<List<Map<String, dynamic>>> getRangosEstadisticas() async {
    try {
      final snapshot = await _firestore
          .collection('rangos_estadisticas')
          .orderBy('puntosRequeridos')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nombre': data['nombre'] ?? '',
          'descripcion': data['descripcion'] ?? '',
          'puntosRequeridos': data['puntosRequeridos'] ?? 0,
          'icono': data['icono'] ?? '🏆',
          'color': data['color'] ?? '#FFD700',
          'beneficios': data['beneficios'] ?? [],
        };
      }).toList();
    } catch (e) {
      print('Error obteniendo rangos: $e');
      return _getRangosDefault();
    }
  }

  /// Guarda estadísticas del usuario en la base de datos
  static Future<void> guardarEstadisticasUsuario(EstadisticasUsuario estadisticas, {String? userId}) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) return;

      await _firestore.collection('usuarios_estadisticas').doc(uid).set({
        'eventosInscritos': estadisticas.eventosInscritos,
        'eventosCompletados': estadisticas.eventosCompletados,
        'eventosPendientes': estadisticas.eventosPendientes,
        'eventosEnProceso': estadisticas.eventosEnProceso,
        'horasTotales': estadisticas.horasTotales,
        'rachaActual': estadisticas.rachaActual,
        'mejorRacha': estadisticas.mejorRacha,
        'donacionesRealizadas': estadisticas.donacionesRealizadas,
        'montoTotalDonado': estadisticas.montoTotalDonado,
        'puntosTotales': estadisticas.puntosTotales,
        'nivelActual': estadisticas.nivelActual,
        'progresoNivelSiguiente': estadisticas.progresoNivelSiguiente,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error guardando estadísticas: $e');
    }
  }

  /// Obtiene ranking de usuarios basado en diferentes métricas
  static Future<Map<String, List<Map<String, dynamic>>>> getRankingUsuarios() async {
    try {
      final snapshot = await _firestore
          .collection('usuarios_estadisticas')
          .get();

      List<Map<String, dynamic>> usuarios = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userDoc = await _firestore.collection('usuarios').doc(doc.id).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          usuarios.add({
            'userId': doc.id,
            'nombreCompleto': '${userData['nombreUsuario'] ?? ''} ${userData['apellidoUsuario'] ?? ''}',
            'fotoPerfil': userData['fotoPerfil'],
            'eventosCompletados': data['eventosCompletados'] ?? 0,
            'horasTotales': data['horasTotales'] ?? 0.0,
            'donacionesRealizadas': data['donacionesRealizadas'] ?? 0,
            'montoTotalDonado': data['montoTotalDonado'] ?? 0.0,
            'puntosTotales': data['puntosTotales'] ?? 0,
          });
        }
      }

      return {
        'eventos': usuarios..sort((a, b) => b['eventosCompletados'].compareTo(a['eventosCompletados'])),
        'horas': usuarios..sort((a, b) => b['horasTotales'].compareTo(a['horasTotales'])),
        'donaciones': usuarios..sort((a, b) => b['montoTotalDonado'].compareTo(a['montoTotalDonado'])),
        'puntos': usuarios..sort((a, b) => b['puntosTotales'].compareTo(a['puntosTotales'])),
      };
    } catch (e) {
      print('Error obteniendo ranking: $e');
      return {};
    }
  }

  // Métodos auxiliares privados
  static EstadisticasUsuario _getEmptyStatistics() {
    return EstadisticasUsuario(
      eventosInscritos: 0,
      eventosCompletados: 0,
      eventosPendientes: 0,
      eventosEnProceso: 0,
      horasTotales: 0,
      rachaActual: 0,
      mejorRacha: 0,
      donacionesRealizadas: 0,
      montoTotalDonado: 0,
      medallasObtenidas: [],
      medallasDisponibles: [],
      puntosTotales: 0,
      nivelActual: 'Principiante',
      progresoNivelSiguiente: 0,
    );
  }

  static double _calcularHorasEvento(Evento evento) {
    try {
      if (evento.horaInicio.isNotEmpty && evento.horaFin.isNotEmpty) {
        final inicio = DateTime.parse('2000-01-01 ${evento.horaInicio}');
        final fin = DateTime.parse('2000-01-01 ${evento.horaFin}');
        return fin.difference(inicio).inMinutes / 60.0;
      }
    } catch (e) {
      print('Error calculando horas del evento: $e');
    }
    return 4.0; // Valor por defecto
  }

  static int _calcularRachaActual(List<Evento> eventos) {
    // Implementar lógica de racha basada en eventos completados consecutivos
    // Por ahora retorna un valor simplificado
    return eventos.where((e) => e.estado.toLowerCase() == 'finalizado').isNotEmpty ? 1 : 0;
  }

  static int _calcularMejorRacha(List<Evento> eventos) {
    // Implementar lógica de mejor racha histórica
    // Por ahora retorna un valor simplificado
    return eventos.where((e) => e.estado.toLowerCase() == 'finalizado').length;
  }

  static int _calcularPuntosTotales({
    required int eventosCompletados,
    required double horasTotales,
    required int donacionesRealizadas,
    required double montoTotalDonado,
  }) {
    int puntos = 0;
    puntos += eventosCompletados * 10; // 10 puntos por evento
    puntos += (horasTotales * 2).round(); // 2 puntos por hora
    puntos += donacionesRealizadas * 5; // 5 puntos por donación
    puntos += (montoTotalDonado * 0.1).round(); // 0.1 puntos por sol donado
    return puntos;
  }

  static Map<String, dynamic> _calcularNivel(int puntosTotales) {
    final rangos = [
      {'nombre': 'Principiante', 'puntos': 0},
      {'nombre': 'Voluntario', 'puntos': 50},
      {'nombre': 'Colaborador', 'puntos': 150},
      {'nombre': 'Activista', 'puntos': 300},
      {'nombre': 'Héroe', 'puntos': 500},
      {'nombre': 'Leyenda', 'puntos': 1000},
    ];

    for (int i = rangos.length - 1; i >= 0; i--) {
      final puntosRango = rangos[i]['puntos'] as int;
      if (puntosTotales >= puntosRango) {
        double progreso = 0.0;
        if (i < rangos.length - 1) {
          final puntosActuales = puntosTotales - puntosRango;
          final puntosRangoSiguiente = rangos[i + 1]['puntos'] as int;
          final puntosNecesarios = puntosRangoSiguiente - puntosRango;
          progreso = puntosActuales / puntosNecesarios;
        } else {
          progreso = 1.0;
        }
        
        return {
          'nivel': rangos[i]['nombre'],
          'progreso': progreso.clamp(0.0, 1.0),
        };
      }
    }

    return {'nivel': 'Principiante', 'progreso': 0.0};
  }

  static List<Map<String, dynamic>> _getRangosDefault() {
    return [
      {
        'id': 'principiante',
        'nombre': 'Principiante',
        'descripcion': 'Está empezando su camino en el voluntariado',
        'puntosRequeridos': 0,
        'icono': '🌱',
        'color': '#8BC34A',
        'beneficios': ['Acceso básico a eventos'],
      },
      {
        'id': 'voluntario',
        'nombre': 'Voluntario',
        'descripcion': 'Ya tiene experiencia en voluntariado',
        'puntosRequeridos': 50,
        'icono': '🙋‍♂️',
        'color': '#2196F3',
        'beneficios': ['Acceso a eventos especiales', 'Certificados de participación'],
      },
      {
        'id': 'heroe',
        'nombre': 'Héroe',
        'descripcion': 'Un verdadero héroe de la comunidad',
        'puntosRequeridos': 500,
        'icono': '🦸‍♂️',
        'color': '#FF5722',
        'beneficios': ['Acceso prioritario', 'Reconocimientos especiales', 'Eventos exclusivos'],
      },
    ];
  }
}
