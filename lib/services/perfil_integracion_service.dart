import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/perfil_usuario.dart';
import '../models/estadisticas_usuario.dart';
import '../models/evento.dart';
import '../models/donaciones.dart';
import '../controllers/perfil_controller.dart';

class PerfilIntegracionService {
  static final Logger _logger = Logger();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<bool> sincronizarPerfilAutomatico({
    required List<Evento> eventosInscritos,
    required List<Donaciones> donaciones,
    required EstadisticasUsuario estadisticasActuales,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _logger.w('Usuario no autenticado para sincronización');
        return false;
      }

      _logger.i('Iniciando sincronización automática del perfil');

      final resultado = await PerfilController.sincronizarDatos(
        eventos: eventosInscritos,
        donaciones: donaciones,
      );

      if (resultado.exitoso) {
        _logger.i('Sincronización automática exitosa: ${resultado.mensaje}');
        
        await _registrarEventosIndividuales(eventosInscritos);
        
        await _registrarDonacionesIndividuales(donaciones);
        
        return true;
      } else {
        _logger.w('Error en sincronización automática: ${resultado.mensaje}');
        return false;
      }
    } catch (e) {
      _logger.e('Error en sincronización automática: $e');
      return false;
    }
  }

  static Future<PerfilUsuario?> obtenerPerfilCompleto() async {
    try {
      return await PerfilController.obtenerPerfil();
    } catch (e) {
      _logger.e('Error obteniendo perfil completo: $e');
      return null;
    }
  }

  static List<MedallaObtenida> obtenerMedallasNuevas() {
    return PerfilController.obtenerMedallasNuevas();
  }

  static Future<bool> marcarMedallasComoVistas() async {
    return await PerfilController.marcarMedallasComoVistas();
  }

  static Future<Map<String, dynamic>?> obtenerEstadisticasResumidas() async {
    try {
      return await PerfilControllerExtension.obtenerEstadisticasBasicas();
    } catch (e) {
      _logger.e('Error obteniendo estadísticas resumidas: $e');
      return null;
    }
  }

  static Future<bool> registrarInscripcionEvento(Evento evento) async {
    try {
      return await PerfilController.registrarParticipacionEvento(evento, 'inscrito');
    } catch (e) {
      _logger.e('Error registrando inscripción a evento: $e');
      return false;
    }
  }

  static Future<bool> registrarCompletacionEvento(Evento evento) async {
    try {
      return await PerfilController.registrarParticipacionEvento(evento, 'completado');
    } catch (e) {
      _logger.e('Error registrando completación de evento: $e');
      return false;
    }
  }

  static Future<bool> registrarDonacionRealizada(Donaciones donacion) async {
    try {
      return await PerfilController.registrarDonacion(donacion);
    } catch (e) {
      _logger.e('Error registrando donación realizada: $e');
      return false;
    }
  }

  static Future<bool> crearRespaldoPerfil() async {
    try {
      return await PerfilController.crearRespaldoPerfil();
    } catch (e) {
      _logger.e('Error creando respaldo del perfil: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> obtenerEstadisticasGlobales() async {
    try {
      return await PerfilController.obtenerEstadisticasGlobales();
    } catch (e) {
      _logger.e('Error obteniendo estadísticas globales: $e');
      return {};
    }
  }

  static void limpiarDatosLocales() {
    PerfilController.limpiarDatosLocales();
    _logger.i('Datos locales del perfil limpiados');
  }

  static Future<void> _registrarEventosIndividuales(List<Evento> eventos) async {
    for (final evento in eventos) {
      try {
        String estado = 'inscrito';
        if (evento.estado.toLowerCase() == 'finalizado') {
          estado = 'completado';
        } else if (evento.estado.toLowerCase() == 'cancelado') {
          estado = 'cancelado';
        }

        await PerfilController.registrarParticipacionEvento(evento, estado);
      } catch (e) {
        _logger.w('Error registrando evento individual ${evento.titulo}: $e');
      }
    }
  }

  static Future<void> _registrarDonacionesIndividuales(List<Donaciones> donaciones) async {
    for (final donacion in donaciones) {
      try {
        await PerfilController.registrarDonacion(donacion);
      } catch (e) {
        _logger.w('Error registrando donación individual ${donacion.idDonaciones}: $e');
      }
    }
  }
}

class PerfilWidget {
  static Future<bool> inicializarPerfil({
    required List<Evento> eventosInscritos,
    required List<Donaciones> donaciones,
    required EstadisticasUsuario estadisticasActuales,
  }) async {
    return await PerfilIntegracionService.sincronizarPerfilAutomatico(
      eventosInscritos: eventosInscritos,
      donaciones: donaciones,
      estadisticasActuales: estadisticasActuales,
    );
  }

  static Future<List<MedallaObtenida>> verificarNuevasMedallas() async {
    final medallasNuevas = PerfilIntegracionService.obtenerMedallasNuevas();
    
    if (medallasNuevas.isNotEmpty) {
    }
    
    return medallasNuevas;
  }

  static Future<bool> respaldarPerfilPeriodico() async {
    return await PerfilIntegracionService.crearRespaldoPerfil();
  }
}
