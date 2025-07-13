import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/perfil_usuario.dart';
import '../models/estadisticas_usuario.dart';
import '../models/evento.dart';
import '../models/donaciones.dart';

/// Servicio para gestionar la persistencia de todos los datos del perfil
/// del usuario en Firebase Firestore
class PerfilPersistenciaService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final Logger _logger = Logger();

  // Colecciones en Firestore
  static const String _coleccionPerfiles = 'perfiles_usuarios';
  static const String _coleccionMedallasObtenidas = 'medallas_obtenidas';
  static const String _coleccionEstadisticasHistoricas = 'estadisticas_historicas';
  static const String _coleccionRegistrosEventos = 'registros_eventos_detallados';
  static const String _coleccionRegistrosDonaciones = 'registros_donaciones_detalladas';

  /// Obtiene el perfil completo del usuario actual
  static Future<PerfilUsuario?> obtenerPerfilUsuario([String? userId]) async {
    try {
      final id = userId ?? _auth.currentUser?.uid;
      if (id == null) {
        _logger.w('Usuario no autenticado');
        return null;
      }

      final doc = await _firestore
          .collection(_coleccionPerfiles)
          .doc(id)
          .get();

      if (!doc.exists) {
        _logger.i('Perfil no existe, creando nuevo perfil para usuario: $id');
        return await crearPerfilNuevo(id);
      }

      return PerfilUsuario.fromFirestore(doc);
    } catch (e) {
      _logger.e('Error obteniendo perfil del usuario: $e');
      return null;
    }
  }

  /// Crea un perfil nuevo para el usuario
  static Future<PerfilUsuario> crearPerfilNuevo(String userId) async {
    try {
      final perfilNuevo = PerfilUsuario.nuevo(userId);
      
      await _firestore
          .collection(_coleccionPerfiles)
          .doc(userId)
          .set(perfilNuevo.toFirestore());

      _logger.i('Perfil creado exitosamente para usuario: $userId');
      return perfilNuevo;
    } catch (e) {
      _logger.e('Error creando perfil nuevo: $e');
      rethrow;
    }
  }

  /// Actualiza las estadísticas del usuario
  static Future<bool> actualizarEstadisticas(
    String userId,
    EstadisticasUsuario estadisticas,
  ) async {
    try {
      // Guardar estadísticas históricas
      await _guardarEstadisticasHistoricas(userId, estadisticas);

      // Actualizar perfil principal
      await _firestore
          .collection(_coleccionPerfiles)
          .doc(userId)
          .update({
        'estadisticas': estadisticas.toMap(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      _logger.i('Estadísticas actualizadas para usuario: $userId');
      return true;
    } catch (e) {
      _logger.e('Error actualizando estadísticas: $e');
      return false;
    }
  }

  /// Registra una nueva medalla obtenida
  static Future<bool> registrarMedallaObtenida(
    String userId,
    MedallaObtenida medalla,
  ) async {
    try {
      final batch = _firestore.batch();

      // Agregar a la colección de medallas obtenidas
      final medallaRef = _firestore
          .collection(_coleccionMedallasObtenidas)
          .doc('${userId}_${medalla.idMedalla}_${DateTime.now().millisecondsSinceEpoch}');
      
      batch.set(medallaRef, medalla.toMap());

      // Actualizar array en el perfil principal
      final perfilRef = _firestore.collection(_coleccionPerfiles).doc(userId);
      batch.update(perfilRef, {
        'medallasObtenidas': FieldValue.arrayUnion([medalla.toMap()]),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      _logger.i('Medalla registrada: ${medalla.nombre} para usuario: $userId');
      return true;
    } catch (e) {
      _logger.e('Error registrando medalla: $e');
      return false;
    }
  }

  /// Registra la participación en un evento
  static Future<bool> registrarParticipacionEvento(
    String userId,
    Evento evento,
    String estado, // inscrito, completado, cancelado
  ) async {
    try {
      final registro = RegistroEvento(
        idEvento: evento.idEvento,
        tituloEvento: evento.titulo,
        descripcionEvento: evento.descripcion,
        categoria: evento.idTipo, // Usar idTipo como categoria
        fechaInscripcion: DateTime.now(),
        fechaParticipacion: estado == 'completado' ? DateTime.parse(evento.fechaInicio) : null,
        estado: estado,
        horasServicio: estado == 'completado' ? _calcularHorasEvento(evento) : 0.0,
        puntosObtenidos: estado == 'completado' ? 10 : 0, // 10 puntos por evento completado
        habilidadesDesarrolladas: _extraerHabilidades(evento.idTipo),
      );

      await _firestore
          .collection(_coleccionRegistrosEventos)
          .doc('${userId}_${evento.idEvento}_${DateTime.now().millisecondsSinceEpoch}')
          .set(registro.toMap());

      // Actualizar perfil principal
      await _firestore
          .collection(_coleccionPerfiles)
          .doc(userId)
          .update({
        'historialEventos': FieldValue.arrayUnion([registro.toMap()]),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      _logger.i('Participación en evento registrada: ${evento.titulo}');
      return true;
    } catch (e) {
      _logger.e('Error registrando participación en evento: $e');
      return false;
    }
  }

  /// Registra una donación realizada
  static Future<bool> registrarDonacion(
    String userId,
    Donaciones donacion,
  ) async {
    try {
      final registro = RegistroDonacion(
        idDonacion: donacion.idDonaciones,
        tipoDonacion: donacion.tipoDonacion,
        monto: donacion.monto,
        descripcion: donacion.descripcion,
        fechaDonacion: DateTime.parse(donacion.fechaDonacion),
        estado: donacion.estadoValidacion,
        recolectorAsignado: donacion.idRecolector,
        puntosObtenidos: 5, // 5 puntos por donación
        metodoPago: donacion.metodoPago,
        comprobante: null, // No disponible en modelo actual
        metadatos: {
          'cantidad': donacion.cantidad,
          'objetos': donacion.objetos,
          'unidadMedida': donacion.unidadMedida,
        },
      );

      await _firestore
          .collection(_coleccionRegistrosDonaciones)
          .doc('${userId}_${donacion.idDonaciones}_${DateTime.now().millisecondsSinceEpoch}')
          .set(registro.toMap());

      // Actualizar perfil principal
      await _firestore
          .collection(_coleccionPerfiles)
          .doc(userId)
          .update({
        'historialDonaciones': FieldValue.arrayUnion([registro.toMap()]),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      _logger.i('Donación registrada: ${donacion.tipoDonacion} - ${donacion.monto}');
      return true;
    } catch (e) {
      _logger.e('Error registrando donación: $e');
      return false;
    }
  }

  /// Actualiza el progreso de gamificación
  static Future<bool> actualizarProgresoGamificacion(
    String userId,
    ProgresoGamificacion progreso,
  ) async {
    try {
      await _firestore
          .collection(_coleccionPerfiles)
          .doc(userId)
          .update({
        'progresoGamificacion': progreso.toMap(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      _logger.i('Progreso de gamificación actualizado para: $userId');
      return true;
    } catch (e) {
      _logger.e('Error actualizando progreso de gamificación: $e');
      return false;
    }
  }

  /// Actualiza la configuración del perfil
  static Future<bool> actualizarConfiguracion(
    String userId,
    ConfiguracionPerfil configuracion,
  ) async {
    try {
      await _firestore
          .collection(_coleccionPerfiles)
          .doc(userId)
          .update({
        'configuracion': configuracion.toMap(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      _logger.i('Configuración de perfil actualizada para: $userId');
      return true;
    } catch (e) {
      _logger.e('Error actualizando configuración: $e');
      return false;
    }
  }

  /// Obtiene el historial detallado de eventos del usuario
  static Future<List<RegistroEvento>> obtenerHistorialEventos(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_coleccionRegistrosEventos)
          .where('idUsuario', isEqualTo: userId)
          .orderBy('fechaInscripcion', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RegistroEvento.fromMap(doc.data()))
          .toList();
    } catch (e) {
      _logger.e('Error obteniendo historial de eventos: $e');
      return [];
    }
  }

  /// Obtiene el historial detallado de donaciones del usuario
  static Future<List<RegistroDonacion>> obtenerHistorialDonaciones(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_coleccionRegistrosDonaciones)
          .where('idUsuario', isEqualTo: userId)
          .orderBy('fechaDonacion', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RegistroDonacion.fromMap(doc.data()))
          .toList();
    } catch (e) {
      _logger.e('Error obteniendo historial de donaciones: $e');
      return [];
    }
  }

  /// Obtiene todas las medallas obtenidas por el usuario
  static Future<List<MedallaObtenida>> obtenerMedallasObtenidas(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_coleccionMedallasObtenidas)
          .where('idUsuario', isEqualTo: userId)
          .orderBy('fechaObtencion', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MedallaObtenida.fromMap(doc.data()))
          .toList();
    } catch (e) {
      _logger.e('Error obteniendo medallas obtenidas: $e');
      return [];
    }
  }

  /// Realiza un respaldo completo del perfil del usuario
  static Future<bool> respaldarPerfil(String userId) async {
    try {
      final perfil = await obtenerPerfilUsuario(userId);
      if (perfil == null) return false;

      // Crear documento de respaldo con timestamp
      final timestamp = DateTime.now().toIso8601String();
      await _firestore
          .collection('respaldos_perfiles')
          .doc('${userId}_$timestamp')
          .set({
        'perfilCompleto': perfil.toFirestore(),
        'fechaRespaldo': FieldValue.serverTimestamp(),
        'version': '1.0',
      });

      _logger.i('Respaldo de perfil creado para: $userId');
      return true;
    } catch (e) {
      _logger.e('Error creando respaldo de perfil: $e');
      return false;
    }
  }

  /// Obtiene estadísticas agregadas de todos los usuarios (para rankings)
  static Future<Map<String, dynamic>> obtenerEstadisticasGlobales() async {
    try {
      final snapshot = await _firestore
          .collection(_coleccionPerfiles)
          .get();

      int totalUsuarios = 0;
      int totalEventosCompletados = 0;
      double totalHorasServicio = 0.0;
      double totalDonaciones = 0.0;
      int totalMedallas = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final estadisticas = data['estadisticas'] as Map<String, dynamic>? ?? {};
        
        totalUsuarios++;
        totalEventosCompletados += (estadisticas['eventosCompletados'] ?? 0) as int;
        totalHorasServicio += ((estadisticas['horasTotales'] ?? 0.0) as num).toDouble();
        totalDonaciones += ((estadisticas['montoTotalDonado'] ?? 0.0) as num).toDouble();
        totalMedallas += (data['medallasObtenidas'] as List?)?.length ?? 0;
      }

      return {
        'totalUsuarios': totalUsuarios,
        'totalEventosCompletados': totalEventosCompletados,
        'totalHorasServicio': totalHorasServicio,
        'totalDonaciones': totalDonaciones,
        'totalMedallas': totalMedallas,
        'promedioEventosPorUsuario': totalUsuarios > 0 ? totalEventosCompletados / totalUsuarios : 0,
        'promedioHorasPorUsuario': totalUsuarios > 0 ? totalHorasServicio / totalUsuarios : 0,
        'promedioDonacionesPorUsuario': totalUsuarios > 0 ? totalDonaciones / totalUsuarios : 0,
      };
    } catch (e) {
      _logger.e('Error obteniendo estadísticas globales: $e');
      return {};
    }
  }

  // Métodos privados auxiliares

  static Future<void> _guardarEstadisticasHistoricas(
    String userId,
    EstadisticasUsuario estadisticas,
  ) async {
    await _firestore
        .collection(_coleccionEstadisticasHistoricas)
        .doc('${userId}_${DateTime.now().millisecondsSinceEpoch}')
        .set({
      'userId': userId,
      'estadisticas': estadisticas.toMap(),
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  static double _calcularHorasEvento(Evento evento) {
    try {
      final horaInicio = evento.horaInicio.split(':');
      final horaFin = evento.horaFin.split(':');
      
      final inicio = TimeOfDay(
        hour: int.parse(horaInicio[0]), 
        minute: int.parse(horaInicio[1])
      );
      final fin = TimeOfDay(
        hour: int.parse(horaFin[0]), 
        minute: int.parse(horaFin[1])
      );

      return ((fin.hour - inicio.hour) * 60 + 
              (fin.minute - inicio.minute)) / 60.0;
    } catch (e) {
      return 2.0; // Valor por defecto
    }
  }

  static List<String> _extraerHabilidades(String categoria) {
    // Mapeo de categorías a habilidades desarrolladas
    final habilidadesPorCategoria = {
      'Educación': ['Comunicación', 'Liderazgo', 'Enseñanza'],
      'Medio Ambiente': ['Consciencia Ambiental', 'Trabajo en Equipo', 'Sostenibilidad'],
      'Salud': ['Empatía', 'Cuidado', 'Responsabilidad Social'],
      'Deportes': ['Trabajo en Equipo', 'Disciplina', 'Motivación'],
      'Arte y Cultura': ['Creatividad', 'Expresión', 'Apreciación Cultural'],
      'Tecnología': ['Innovación', 'Resolución de Problemas', 'Adaptabilidad'],
    };

    return habilidadesPorCategoria[categoria] ?? ['Voluntariado', 'Compromiso Social'];
  }
}

/// Modelo para la respuesta de sincronización
class ResultadoSincronizacion {
  final bool exitoso;
  final String mensaje;
  final Map<String, dynamic>? datos;

  ResultadoSincronizacion({
    required this.exitoso,
    required this.mensaje,
    this.datos,
  });
}
