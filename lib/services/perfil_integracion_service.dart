import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/perfil_usuario.dart';
import '../models/estadisticas_usuario.dart';
import '../models/evento.dart';
import '../models/donaciones.dart';
import '../controllers/perfil_controller.dart';

/// Servicio simplificado para integrar el sistema de persistencia 
/// con la pantalla de perfil existente
class PerfilIntegracionService {
  static final Logger _logger = Logger();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sincroniza automáticamente los datos del perfil con Firebase
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

      // Sincronizar datos usando el controlador principal
      final resultado = await PerfilController.sincronizarDatos(
        eventos: eventosInscritos,
        donaciones: donaciones,
      );

      if (resultado.exitoso) {
        _logger.i('Sincronización automática exitosa: ${resultado.mensaje}');
        
        // Registrar eventos individuales si no están registrados
        await _registrarEventosIndividuales(eventosInscritos);
        
        // Registrar donaciones individuales si no están registradas
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

  /// Obtiene el perfil completo del usuario para mostrar en la UI
  static Future<PerfilUsuario?> obtenerPerfilCompleto() async {
    try {
      return await PerfilController.obtenerPerfil();
    } catch (e) {
      _logger.e('Error obteniendo perfil completo: $e');
      return null;
    }
  }

  /// Obtiene solo las medallas nuevas para mostrar notificaciones
  static List<MedallaObtenida> obtenerMedallasNuevas() {
    return PerfilController.obtenerMedallasNuevas();
  }

  /// Marca las medallas como vistas después de mostrar la notificación
  static Future<bool> marcarMedallasComoVistas() async {
    return await PerfilController.marcarMedallasComoVistas();
  }

  /// Obtiene estadísticas resumidas para mostrar en cards
  static Future<Map<String, dynamic>?> obtenerEstadisticasResumidas() async {
    try {
      return await PerfilControllerExtension.obtenerEstadisticasBasicas();
    } catch (e) {
      _logger.e('Error obteniendo estadísticas resumidas: $e');
      return null;
    }
  }

  /// Registra automáticamente la participación cuando un usuario se inscribe a un evento
  static Future<bool> registrarInscripcionEvento(Evento evento) async {
    try {
      return await PerfilController.registrarParticipacionEvento(evento, 'inscrito');
    } catch (e) {
      _logger.e('Error registrando inscripción a evento: $e');
      return false;
    }
  }

  /// Registra automáticamente cuando un usuario completa un evento
  static Future<bool> registrarCompletacionEvento(Evento evento) async {
    try {
      return await PerfilController.registrarParticipacionEvento(evento, 'completado');
    } catch (e) {
      _logger.e('Error registrando completación de evento: $e');
      return false;
    }
  }

  /// Registra automáticamente cuando un usuario realiza una donación
  static Future<bool> registrarDonacionRealizada(Donaciones donacion) async {
    try {
      return await PerfilController.registrarDonacion(donacion);
    } catch (e) {
      _logger.e('Error registrando donación realizada: $e');
      return false;
    }
  }

  /// Crear respaldo del perfil (opcional)
  static Future<bool> crearRespaldoPerfil() async {
    try {
      return await PerfilController.crearRespaldoPerfil();
    } catch (e) {
      _logger.e('Error creando respaldo del perfil: $e');
      return false;
    }
  }

  /// Obtiene estadísticas globales del sistema para rankings
  static Future<Map<String, dynamic>> obtenerEstadisticasGlobales() async {
    try {
      return await PerfilController.obtenerEstadisticasGlobales();
    } catch (e) {
      _logger.e('Error obteniendo estadísticas globales: $e');
      return {};
    }
  }

  /// Limpia cache y datos locales (útil para logout)
  static void limpiarDatosLocales() {
    PerfilController.limpiarDatosLocales();
    _logger.i('Datos locales del perfil limpiados');
  }

  // Métodos privados auxiliares

  /// Registra eventos individuales que no han sido registrados
  static Future<void> _registrarEventosIndividuales(List<Evento> eventos) async {
    for (final evento in eventos) {
      try {
        // Determinar estado basado en el evento
        String estado = 'inscrito';
        if (evento.estado.toLowerCase() == 'finalizado') {
          estado = 'completado';
        } else if (evento.estado.toLowerCase() == 'cancelado') {
          estado = 'cancelado';
        }

        await PerfilController.registrarParticipacionEvento(evento, estado);
      } catch (e) {
        _logger.w('Error registrando evento individual ${evento.titulo}: $e');
        // Continuar con los demás eventos
      }
    }
  }

  /// Registra donaciones individuales que no han sido registradas
  static Future<void> _registrarDonacionesIndividuales(List<Donaciones> donaciones) async {
    for (final donacion in donaciones) {
      try {
        await PerfilController.registrarDonacion(donacion);
      } catch (e) {
        _logger.w('Error registrando donación individual ${donacion.idDonaciones}: $e');
        // Continuar con las demás donaciones
      }
    }
  }
}

/// Clase auxiliar para facilitar la integración con widgets existentes
class PerfilWidget {
  /// Método estático para usar en initState() de ProfileScreen
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

  /// Método para obtener medallas nuevas y mostrar notificación
  static Future<List<MedallaObtenida>> verificarNuevasMedallas() async {
    final medallasNuevas = PerfilIntegracionService.obtenerMedallasNuevas();
    
    if (medallasNuevas.isNotEmpty) {
      // Opcional: Marcar como vistas automáticamente después de obtenerlas
      // await PerfilIntegracionService.marcarMedallasComoVistas();
    }
    
    return medallasNuevas;
  }

  /// Método para crear respaldo periódico del perfil
  static Future<bool> respaldarPerfilPeriodico() async {
    return await PerfilIntegracionService.crearRespaldoPerfil();
  }
}
