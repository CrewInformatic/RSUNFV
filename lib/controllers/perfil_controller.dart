import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/perfil_usuario.dart';
import '../models/estadisticas_usuario.dart';
import '../models/evento.dart';
import '../models/donaciones.dart';
import '../services/perfil_persistencia_service.dart';

class PerfilController {
  static final Logger _logger = Logger();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static PerfilUsuario? _perfilCacheado;
  static DateTime? _fechaUltimaSincronizacion;
  
  static const Duration _tiempoExpiracionCache = Duration(minutes: 5);

  static Future<PerfilUsuario?> obtenerPerfil({bool forzarRecarga = false}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _logger.w('Usuario no autenticado');
        return null;
      }

      if (!forzarRecarga && _perfilCacheado != null && _fechaUltimaSincronizacion != null) {
        final tiempoTranscurrido = DateTime.now().difference(_fechaUltimaSincronizacion!);
        if (tiempoTranscurrido < _tiempoExpiracionCache) {
          _logger.d('Usando perfil desde cache');
          return _perfilCacheado;
        }
      }

      _logger.i('Cargando perfil desde Firebase para usuario: $userId');
      final perfil = await PerfilPersistenciaService.obtenerPerfilUsuario(userId);
      
      if (perfil != null) {
        _perfilCacheado = perfil;
        _fechaUltimaSincronizacion = DateTime.now();
        _logger.i('Perfil cargado y cacheado exitosamente');
      }

      return perfil;
    } catch (e) {
      _logger.e('Error obteniendo perfil: $e');
      return _perfilCacheado;
    }
  }

  static Future<ResultadoSincronizacion> sincronizarDatos({
    List<Evento>? eventos,
    List<Donaciones>? donaciones,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return ResultadoSincronizacion(
          exitoso: false,
          mensaje: 'Usuario no autenticado',
        );
      }

      _logger.i('Iniciando sincronización de datos para usuario: $userId');

      PerfilUsuario? perfilActual = await obtenerPerfil();
      if (perfilActual == null) {
        _logger.i('Creando nuevo perfil para usuario: $userId');
        perfilActual = await PerfilPersistenciaService.crearPerfilNuevo(userId);
      }

      final estadisticasActualizadas = EstadisticasUsuario.calcular(
        eventos: eventos ?? [],
        donaciones: donaciones ?? [],
        userId: userId,
      );

      final medallasAnteriores = perfilActual.medallasObtenidas.map((m) => m.idMedalla).toSet();
      final medallasNuevas = estadisticasActualizadas.medallasObtenidas
          .where((medalla) => !medallasAnteriores.contains(medalla.id))
          .map((medalla) => MedallaObtenida.fromMedalla(medalla))
          .toList();

      final progresoActualizado = _actualizarProgresoGamificacion(
        perfilActual.progresoGamificacion,
        estadisticasActualizadas,
        medallasNuevas,
      );

      final perfilActualizado = perfilActual.copyWith(
        estadisticas: estadisticasActualizadas,
        medallasObtenidas: [
          ...perfilActual.medallasObtenidas,
          ...medallasNuevas,
        ],
        progresoGamificacion: progresoActualizado,
      );

      await _persistirCambios(userId, perfilActualizado, medallasNuevas);

      _perfilCacheado = perfilActualizado;
      _fechaUltimaSincronizacion = DateTime.now();

      _logger.i('Sincronización completada exitosamente');
      return ResultadoSincronizacion(
        exitoso: true,
        mensaje: 'Datos sincronizados exitosamente',
        datos: {
          'medallasNuevas': medallasNuevas.length,
          'puntosActuales': estadisticasActualizadas.puntosTotales,
          'nivelActual': estadisticasActualizadas.nivelActual,
        },
      );

    } catch (e) {
      _logger.e('Error en sincronización: $e');
      return ResultadoSincronizacion(
        exitoso: false,
        mensaje: 'Error en sincronización: ${e.toString()}',
      );
    }
  }

  static Future<bool> registrarParticipacionEvento(
    Evento evento,
    String estado,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final exitoso = await PerfilPersistenciaService.registrarParticipacionEvento(
        userId,
        evento,
        estado,
      );

      if (exitoso) {
        _invalidarCache();
        _logger.i('Participación en evento registrada: ${evento.titulo}');
      }

      return exitoso;
    } catch (e) {
      _logger.e('Error registrando participación en evento: $e');
      return false;
    }
  }

  static Future<bool> registrarDonacion(Donaciones donacion) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final exitoso = await PerfilPersistenciaService.registrarDonacion(
        userId,
        donacion,
      );

      if (exitoso) {
        _invalidarCache();
        _logger.i('Donación registrada: ${donacion.tipoDonacion}');
      }

      return exitoso;
    } catch (e) {
      _logger.e('Error registrando donación: $e');
      return false;
    }
  }

  static Future<bool> marcarMedallasComoVistas() async {
    try {
      if (_perfilCacheado == null) return false;

      final medallasActualizadas = _perfilCacheado!.medallasObtenidas
          .map((medalla) => medalla.copyWith(esNueva: false))
          .toList();

      final perfilActualizado = _perfilCacheado!.copyWith(
        medallasObtenidas: medallasActualizadas,
      );

      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await PerfilPersistenciaService.actualizarEstadisticas(
        userId,
        perfilActualizado.estadisticas,
      );

      _perfilCacheado = perfilActualizado;
      return true;
    } catch (e) {
      _logger.e('Error marcando medallas como vistas: $e');
      return false;
    }
  }

  static Future<bool> actualizarConfiguracion(ConfiguracionPerfil configuracion) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final exitoso = await PerfilPersistenciaService.actualizarConfiguracion(
        userId,
        configuracion,
      );

      if (exitoso && _perfilCacheado != null) {
        _perfilCacheado = _perfilCacheado!.copyWith(configuracion: configuracion);
      }

      return exitoso;
    } catch (e) {
      _logger.e('Error actualizando configuración: $e');
      return false;
    }
  }

  static List<MedallaObtenida> obtenerMedallasNuevas() {
    if (_perfilCacheado == null) return [];
    
    return _perfilCacheado!.medallasObtenidas
        .where((medalla) => medalla.esNueva)
        .toList();
  }

  static Future<Map<String, dynamic>> obtenerEstadisticasGlobales() async {
    try {
      return await PerfilPersistenciaService.obtenerEstadisticasGlobales();
    } catch (e) {
      _logger.e('Error obteniendo estadísticas globales: $e');
      return {};
    }
  }

  static Future<bool> crearRespaldoPerfil() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      return await PerfilPersistenciaService.respaldarPerfil(userId);
    } catch (e) {
      _logger.e('Error creando respaldo: $e');
      return false;
    }
  }

  static ProgresoGamificacion _actualizarProgresoGamificacion(
    ProgresoGamificacion progresoActual,
    EstadisticasUsuario estadisticas,
    List<MedallaObtenida> medallasNuevas,
  ) {
    final puntosDeNuevasMedallas = medallasNuevas
        .fold<int>(0, (total, medalla) => total + medalla.puntosObtenidos);

    final puntosTotalesActualizados = estadisticas.puntosTotales + puntosDeNuevasMedallas;

    final nivelInfo = _calcularNivelYProgreso(puntosTotalesActualizados);

    final contadoresActualizados = Map<String, int>.from(progresoActual.contadoresTipoEventos);

    return ProgresoGamificacion(
      puntosTotales: puntosTotalesActualizados,
      nivelActual: nivelInfo['nivel'],
      puntosParaSiguienteNivel: nivelInfo['puntosParaSiguiente'],
      progresoNivelSiguiente: nivelInfo['progreso'],
      rachaActual: estadisticas.rachaActual,
      mejorRacha: estadisticas.mejorRacha,
      fechaUltimaParticipacion: DateTime.now(),
      contadoresTipoEventos: contadoresActualizados,
      metricasPersonalizadas: {
        'eficienciaVoluntariado': _calcularEficiencia(estadisticas),
        'impactoSocial': _calcularImpacto(estadisticas),
      },
      logrosEspeciales: _actualizarLogrosEspeciales(progresoActual.logrosEspeciales, estadisticas),
      experienciaTotalAcumulada: progresoActual.experienciaTotalAcumulada + 
          (estadisticas.eventosCompletados * 10) + 
          (estadisticas.donacionesRealizadas * 5),
    );
  }

  static Future<void> _persistirCambios(
    String userId,
    PerfilUsuario perfil,
    List<MedallaObtenida> medallasNuevas,
  ) async {
    await PerfilPersistenciaService.actualizarEstadisticas(
      userId,
      perfil.estadisticas,
    );

    for (final medalla in medallasNuevas) {
      await PerfilPersistenciaService.registrarMedallaObtenida(userId, medalla);
    }

    await PerfilPersistenciaService.actualizarProgresoGamificacion(
      userId,
      perfil.progresoGamificacion,
    );
  }

  static Map<String, dynamic> _calcularNivelYProgreso(int puntos) {
    final niveles = {
      'Novato': {'min': 0, 'max': 49},
      'Voluntario': {'min': 50, 'max': 149},
      'Activista': {'min': 150, 'max': 299},
      'Héroe': {'min': 300, 'max': 499},
      'Leyenda': {'min': 500, 'max': 799},
      'Maestro': {'min': 800, 'max': 999999},
    };

    String nivelActual = 'Novato';
    int puntosParaSiguiente = 50;
    double progreso = 0.0;

    for (final entry in niveles.entries) {
      final nivel = entry.key;
      final rango = entry.value;
      
      if (puntos >= rango['min']! && puntos <= rango['max']!) {
        nivelActual = nivel;
        
        if (nivel != 'Maestro') {
          final puntosEnNivel = puntos - rango['min']!;
          final puntosRequeridosNivel = rango['max']! - rango['min']! + 1;
          progreso = puntosEnNivel / puntosRequeridosNivel;
          puntosParaSiguiente = rango['max']! + 1 - puntos;
        } else {
          progreso = 1.0;
          puntosParaSiguiente = 0;
        }
        break;
      }
    }

    return {
      'nivel': nivelActual,
      'puntosParaSiguiente': puntosParaSiguiente,
      'progreso': progreso.clamp(0.0, 1.0),
    };
  }

  static double _calcularEficiencia(EstadisticasUsuario estadisticas) {
    if (estadisticas.eventosInscritos == 0) return 0.0;
    return (estadisticas.eventosCompletados / estadisticas.eventosInscritos * 100).clamp(0, 100);
  }

  static double _calcularImpacto(EstadisticasUsuario estadisticas) {
    return (estadisticas.horasTotales * 2) + 
           (estadisticas.montoTotalDonado * 0.1) + 
           (estadisticas.eventosCompletados * 3);
  }

  static List<String> _actualizarLogrosEspeciales(
    List<String> logrosActuales,
    EstadisticasUsuario estadisticas,
  ) {
    final nuevosLogros = List<String>.from(logrosActuales);

    if (estadisticas.rachaActual >= 30 && !nuevosLogros.contains('racha_maestro')) {
      nuevosLogros.add('racha_maestro');
    }
    
    if (estadisticas.montoTotalDonado >= 1000 && !nuevosLogros.contains('gran_donador')) {
      nuevosLogros.add('gran_donador');
    }
    
    if (estadisticas.horasTotales >= 500 && !nuevosLogros.contains('veterano_servicio')) {
      nuevosLogros.add('veterano_servicio');
    }

    return nuevosLogros;
  }

  static void _invalidarCache() {
    _perfilCacheado = null;
    _fechaUltimaSincronizacion = null;
    _logger.d('Cache de perfil invalidado');
  }

  static void limpiarDatosLocales() {
    _invalidarCache();
    _logger.i('Datos locales del perfil limpiados');
  }
}

extension PerfilControllerExtension on PerfilController {
  static Future<Map<String, dynamic>?> obtenerEstadisticasBasicas() async {
    final perfil = await PerfilController.obtenerPerfil();
    if (perfil == null) return null;

    return {
      'nivel': perfil.estadisticas.nivelActual,
      'puntos': perfil.estadisticas.puntosTotales,
      'eventos': perfil.estadisticas.eventosCompletados,
      'medallas': perfil.medallasObtenidas.length,
      'donaciones': perfil.estadisticas.donacionesRealizadas,
      'horas': perfil.estadisticas.horasTotales,
    };
  }
}
