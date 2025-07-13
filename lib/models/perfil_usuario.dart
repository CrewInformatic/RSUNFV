import 'package:cloud_firestore/cloud_firestore.dart';
import 'estadisticas_usuario.dart';
import 'medalla.dart';

/// Modelo principal para gestionar toda la información del perfil del usuario
/// incluyendo estadísticas, medallas, progreso y datos de gamificación
class PerfilUsuario {
  final String idUsuario;
  final String idPerfilUsuario;
  final EstadisticasUsuario estadisticas;
  final List<MedallaObtenida> medallasObtenidas;
  final List<RegistroEvento> historialEventos;
  final List<RegistroDonacion> historialDonaciones;
  final ProgresoGamificacion progresoGamificacion;
  final ConfiguracionPerfil configuracion;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  PerfilUsuario({
    required this.idUsuario,
    required this.idPerfilUsuario,
    required this.estadisticas,
    required this.medallasObtenidas,
    required this.historialEventos,
    required this.historialDonaciones,
    required this.progresoGamificacion,
    required this.configuracion,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  /// Crea un perfil vacío para usuarios nuevos
  factory PerfilUsuario.nuevo(String idUsuario) {
    final ahora = DateTime.now();
    return PerfilUsuario(
      idUsuario: idUsuario,
      idPerfilUsuario: '${idUsuario}_perfil_${ahora.millisecondsSinceEpoch}',
      estadisticas: _crearEstadisticasVacias(),
      medallasObtenidas: [],
      historialEventos: [],
      historialDonaciones: [],
      progresoGamificacion: ProgresoGamificacion.inicial(),
      configuracion: ConfiguracionPerfil.porDefecto(),
      fechaCreacion: ahora,
      fechaActualizacion: ahora,
    );
  }

  /// Convierte desde documento de Firestore
  factory PerfilUsuario.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PerfilUsuario(
      idUsuario: data['idUsuario'] ?? '',
      idPerfilUsuario: doc.id,
      estadisticas: _estadisticasDesdeMap(data['estadisticas'] ?? {}),
      medallasObtenidas: (data['medallasObtenidas'] as List<dynamic>? ?? [])
          .map((m) => MedallaObtenida.fromMap(m))
          .toList(),
      historialEventos: (data['historialEventos'] as List<dynamic>? ?? [])
          .map((e) => RegistroEvento.fromMap(e))
          .toList(),
      historialDonaciones: (data['historialDonaciones'] as List<dynamic>? ?? [])
          .map((d) => RegistroDonacion.fromMap(d))
          .toList(),
      progresoGamificacion: ProgresoGamificacion.fromMap(data['progresoGamificacion'] ?? {}),
      configuracion: ConfiguracionPerfil.fromMap(data['configuracion'] ?? {}),
      fechaCreacion: (data['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaActualizacion: (data['fechaActualizacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convierte a mapa para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'idUsuario': idUsuario,
      'estadisticas': estadisticas.toMap(),
      'medallasObtenidas': medallasObtenidas.map((m) => m.toMap()).toList(),
      'historialEventos': historialEventos.map((e) => e.toMap()).toList(),
      'historialDonaciones': historialDonaciones.map((d) => d.toMap()).toList(),
      'progresoGamificacion': progresoGamificacion.toMap(),
      'configuracion': configuracion.toMap(),
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion': Timestamp.fromDate(DateTime.now()),
    };
  }

  /// Crea una copia con campos actualizados
  PerfilUsuario copyWith({
    EstadisticasUsuario? estadisticas,
    List<MedallaObtenida>? medallasObtenidas,
    List<RegistroEvento>? historialEventos,
    List<RegistroDonacion>? historialDonaciones,
    ProgresoGamificacion? progresoGamificacion,
    ConfiguracionPerfil? configuracion,
  }) {
    return PerfilUsuario(
      idUsuario: idUsuario,
      idPerfilUsuario: idPerfilUsuario,
      estadisticas: estadisticas ?? this.estadisticas,
      medallasObtenidas: medallasObtenidas ?? this.medallasObtenidas,
      historialEventos: historialEventos ?? this.historialEventos,
      historialDonaciones: historialDonaciones ?? this.historialDonaciones,
      progresoGamificacion: progresoGamificacion ?? this.progresoGamificacion,
      configuracion: configuracion ?? this.configuracion,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: DateTime.now(),
    );
  }

  /// Métodos auxiliares estáticos
  static EstadisticasUsuario _crearEstadisticasVacias() {
    return EstadisticasUsuario(
      eventosInscritos: 0,
      eventosCompletados: 0,
      eventosPendientes: 0,
      eventosEnProceso: 0,
      horasTotales: 0.0,
      rachaActual: 0,
      mejorRacha: 0,
      donacionesRealizadas: 0,
      montoTotalDonado: 0.0,
      medallasObtenidas: [],
      medallasDisponibles: Medalla.getMedallasBase(),
      puntosTotales: 0,
      nivelActual: 'Novato',
      progresoNivelSiguiente: 0.0,
    );
  }

  static EstadisticasUsuario _estadisticasDesdeMap(Map<String, dynamic> map) {
    return EstadisticasUsuario(
      eventosInscritos: map['eventosInscritos'] ?? 0,
      eventosCompletados: map['eventosCompletados'] ?? 0,
      eventosPendientes: map['eventosPendientes'] ?? 0,
      eventosEnProceso: map['eventosEnProceso'] ?? 0,
      horasTotales: (map['horasTotales'] ?? 0.0).toDouble(),
      rachaActual: map['rachaActual'] ?? 0,
      mejorRacha: map['mejorRacha'] ?? 0,
      donacionesRealizadas: map['donacionesRealizadas'] ?? 0,
      montoTotalDonado: (map['montoTotalDonado'] ?? 0.0).toDouble(),
      medallasObtenidas: (map['medallasObtenidas'] as List<dynamic>? ?? [])
          .map((m) => Medalla.fromMap(m))
          .toList(),
      medallasDisponibles: (map['medallasDisponibles'] as List<dynamic>? ?? [])
          .map((m) => Medalla.fromMap(m))
          .toList(),
      puntosTotales: map['puntosTotales'] ?? 0,
      nivelActual: map['nivelActual'] ?? 'Novato',
      progresoNivelSiguiente: (map['progresoNivelSiguiente'] ?? 0.0).toDouble(),
    );
  }
}

/// Modelo para medallas obtenidas por el usuario
class MedallaObtenida {
  final String idMedalla;
  final String nombre;
  final String descripcion;
  final String icono;
  final String color;
  final String categoria;
  final String tipo;
  final int requisito;
  final DateTime fechaObtencion;
  final int puntosObtenidos;
  final bool esNueva; // Para notificaciones

  MedallaObtenida({
    required this.idMedalla,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.categoria,
    required this.tipo,
    required this.requisito,
    required this.fechaObtencion,
    required this.puntosObtenidos,
    this.esNueva = false,
  });

  factory MedallaObtenida.fromMedalla(Medalla medalla) {
    return MedallaObtenida(
      idMedalla: medalla.id,
      nombre: medalla.nombre,
      descripcion: medalla.descripcion,
      icono: medalla.icono,
      color: medalla.color,
      categoria: medalla.categoria,
      tipo: medalla.tipo,
      requisito: medalla.requisito,
      fechaObtencion: DateTime.now(),
      puntosObtenidos: _calcularPuntosPorMedalla(medalla.categoria),
      esNueva: true,
    );
  }

  factory MedallaObtenida.fromMap(Map<String, dynamic> map) {
    return MedallaObtenida(
      idMedalla: map['idMedalla'] ?? '',
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      icono: map['icono'] ?? '',
      color: map['color'] ?? '',
      categoria: map['categoria'] ?? '',
      tipo: map['tipo'] ?? '',
      requisito: map['requisito'] ?? 0,
      fechaObtencion: (map['fechaObtencion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      puntosObtenidos: map['puntosObtenidos'] ?? 0,
      esNueva: map['esNueva'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idMedalla': idMedalla,
      'nombre': nombre,
      'descripcion': descripcion,
      'icono': icono,
      'color': color,
      'categoria': categoria,
      'tipo': tipo,
      'requisito': requisito,
      'fechaObtencion': Timestamp.fromDate(fechaObtencion),
      'puntosObtenidos': puntosObtenidos,
      'esNueva': esNueva,
    };
  }

  static int _calcularPuntosPorMedalla(String categoria) {
    switch (categoria) {
      case 'bronce': return 25;
      case 'plata': return 50;
      case 'oro': return 100;
      case 'diamante': return 200;
      case 'especial': return 75;
      default: return 10;
    }
  }

  MedallaObtenida copyWith({bool? esNueva}) {
    return MedallaObtenida(
      idMedalla: idMedalla,
      nombre: nombre,
      descripcion: descripcion,
      icono: icono,
      color: color,
      categoria: categoria,
      tipo: tipo,
      requisito: requisito,
      fechaObtencion: fechaObtencion,
      puntosObtenidos: puntosObtenidos,
      esNueva: esNueva ?? this.esNueva,
    );
  }
}

/// Modelo para el historial de eventos del usuario
class RegistroEvento {
  final String idEvento;
  final String tituloEvento;
  final String descripcionEvento;
  final String categoria;
  final DateTime fechaInscripcion;
  final DateTime? fechaParticipacion;
  final String estado; // inscrito, completado, cancelado
  final double horasServicio;
  final int puntosObtenidos;
  final List<String> habilidadesDesarrolladas;
  final double calificacionEvento; // 1-5 estrellas
  final String? comentarioUsuario;

  RegistroEvento({
    required this.idEvento,
    required this.tituloEvento,
    required this.descripcionEvento,
    required this.categoria,
    required this.fechaInscripcion,
    this.fechaParticipacion,
    required this.estado,
    required this.horasServicio,
    required this.puntosObtenidos,
    required this.habilidadesDesarrolladas,
    this.calificacionEvento = 0.0,
    this.comentarioUsuario,
  });

  factory RegistroEvento.fromMap(Map<String, dynamic> map) {
    return RegistroEvento(
      idEvento: map['idEvento'] ?? '',
      tituloEvento: map['tituloEvento'] ?? '',
      descripcionEvento: map['descripcionEvento'] ?? '',
      categoria: map['categoria'] ?? '',
      fechaInscripcion: (map['fechaInscripcion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaParticipacion: (map['fechaParticipacion'] as Timestamp?)?.toDate(),
      estado: map['estado'] ?? 'inscrito',
      horasServicio: (map['horasServicio'] ?? 0.0).toDouble(),
      puntosObtenidos: map['puntosObtenidos'] ?? 0,
      habilidadesDesarrolladas: List<String>.from(map['habilidadesDesarrolladas'] ?? []),
      calificacionEvento: (map['calificacionEvento'] ?? 0.0).toDouble(),
      comentarioUsuario: map['comentarioUsuario'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idEvento': idEvento,
      'tituloEvento': tituloEvento,
      'descripcionEvento': descripcionEvento,
      'categoria': categoria,
      'fechaInscripcion': Timestamp.fromDate(fechaInscripcion),
      'fechaParticipacion': fechaParticipacion != null ? Timestamp.fromDate(fechaParticipacion!) : null,
      'estado': estado,
      'horasServicio': horasServicio,
      'puntosObtenidos': puntosObtenidos,
      'habilidadesDesarrolladas': habilidadesDesarrolladas,
      'calificacionEvento': calificacionEvento,
      'comentarioUsuario': comentarioUsuario,
    };
  }
}

/// Modelo para el historial de donaciones del usuario
class RegistroDonacion {
  final String idDonacion;
  final String tipoDonacion; // monetaria, alimentos, ropa, etc.
  final double monto;
  final String? descripcion;
  final DateTime fechaDonacion;
  final String estado; // pendiente, aprobado, rechazado
  final String? recolectorAsignado;
  final int puntosObtenidos;
  final String? metodoPago;
  final String? comprobante; // URL del comprobante
  final Map<String, dynamic>? metadatos; // información adicional

  RegistroDonacion({
    required this.idDonacion,
    required this.tipoDonacion,
    required this.monto,
    this.descripcion,
    required this.fechaDonacion,
    required this.estado,
    this.recolectorAsignado,
    required this.puntosObtenidos,
    this.metodoPago,
    this.comprobante,
    this.metadatos,
  });

  factory RegistroDonacion.fromMap(Map<String, dynamic> map) {
    return RegistroDonacion(
      idDonacion: map['idDonacion'] ?? '',
      tipoDonacion: map['tipoDonacion'] ?? '',
      monto: (map['monto'] ?? 0.0).toDouble(),
      descripcion: map['descripcion'],
      fechaDonacion: (map['fechaDonacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estado: map['estado'] ?? 'pendiente',
      recolectorAsignado: map['recolectorAsignado'],
      puntosObtenidos: map['puntosObtenidos'] ?? 0,
      metodoPago: map['metodoPago'],
      comprobante: map['comprobante'],
      metadatos: map['metadatos'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idDonacion': idDonacion,
      'tipoDonacion': tipoDonacion,
      'monto': monto,
      'descripcion': descripcion,
      'fechaDonacion': Timestamp.fromDate(fechaDonacion),
      'estado': estado,
      'recolectorAsignado': recolectorAsignado,
      'puntosObtenidos': puntosObtenidos,
      'metodoPago': metodoPago,
      'comprobante': comprobante,
      'metadatos': metadatos,
    };
  }
}

/// Modelo para el progreso de gamificación del usuario
class ProgresoGamificacion {
  final int puntosTotales;
  final String nivelActual;
  final int puntosParaSiguienteNivel;
  final double progresoNivelSiguiente;
  final int rachaActual;
  final int mejorRacha;
  final DateTime? fechaUltimaParticipacion;
  final Map<String, int> contadoresTipoEventos; // categoria -> cantidad
  final Map<String, double> metricasPersonalizadas; // métricas adicionales
  final List<String> logrosEspeciales; // logros únicos
  final int experienciaTotalAcumulada;

  ProgresoGamificacion({
    required this.puntosTotales,
    required this.nivelActual,
    required this.puntosParaSiguienteNivel,
    required this.progresoNivelSiguiente,
    required this.rachaActual,
    required this.mejorRacha,
    this.fechaUltimaParticipacion,
    required this.contadoresTipoEventos,
    required this.metricasPersonalizadas,
    required this.logrosEspeciales,
    required this.experienciaTotalAcumulada,
  });

  factory ProgresoGamificacion.inicial() {
    return ProgresoGamificacion(
      puntosTotales: 0,
      nivelActual: 'Novato',
      puntosParaSiguienteNivel: 50,
      progresoNivelSiguiente: 0.0,
      rachaActual: 0,
      mejorRacha: 0,
      fechaUltimaParticipacion: null,
      contadoresTipoEventos: {},
      metricasPersonalizadas: {},
      logrosEspeciales: [],
      experienciaTotalAcumulada: 0,
    );
  }

  factory ProgresoGamificacion.fromMap(Map<String, dynamic> map) {
    return ProgresoGamificacion(
      puntosTotales: map['puntosTotales'] ?? 0,
      nivelActual: map['nivelActual'] ?? 'Novato',
      puntosParaSiguienteNivel: map['puntosParaSiguienteNivel'] ?? 50,
      progresoNivelSiguiente: (map['progresoNivelSiguiente'] ?? 0.0).toDouble(),
      rachaActual: map['rachaActual'] ?? 0,
      mejorRacha: map['mejorRacha'] ?? 0,
      fechaUltimaParticipacion: (map['fechaUltimaParticipacion'] as Timestamp?)?.toDate(),
      contadoresTipoEventos: Map<String, int>.from(map['contadoresTipoEventos'] ?? {}),
      metricasPersonalizadas: Map<String, double>.from(map['metricasPersonalizadas'] ?? {}),
      logrosEspeciales: List<String>.from(map['logrosEspeciales'] ?? []),
      experienciaTotalAcumulada: map['experienciaTotalAcumulada'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'puntosTotales': puntosTotales,
      'nivelActual': nivelActual,
      'puntosParaSiguienteNivel': puntosParaSiguienteNivel,
      'progresoNivelSiguiente': progresoNivelSiguiente,
      'rachaActual': rachaActual,
      'mejorRacha': mejorRacha,
      'fechaUltimaParticipacion': fechaUltimaParticipacion != null 
          ? Timestamp.fromDate(fechaUltimaParticipacion!) 
          : null,
      'contadoresTipoEventos': contadoresTipoEventos,
      'metricasPersonalizadas': metricasPersonalizadas,
      'logrosEspeciales': logrosEspeciales,
      'experienciaTotalAcumulada': experienciaTotalAcumulada,
    };
  }
}

/// Configuración del perfil del usuario
class ConfiguracionPerfil {
  final bool notificacionesActivas;
  final bool notificacionesMedallas;
  final bool notificacionesEventos;
  final bool notificacionesDonaciones;
  final bool perfilPublico;
  final bool mostrarEstadisticas;
  final bool mostrarMedallas;
  final String temaPreferido; // claro, oscuro, auto
  final String idiomaPreferido;
  final Map<String, bool> privacidadDatos;

  ConfiguracionPerfil({
    required this.notificacionesActivas,
    required this.notificacionesMedallas,
    required this.notificacionesEventos,
    required this.notificacionesDonaciones,
    required this.perfilPublico,
    required this.mostrarEstadisticas,
    required this.mostrarMedallas,
    required this.temaPreferido,
    required this.idiomaPreferido,
    required this.privacidadDatos,
  });

  factory ConfiguracionPerfil.porDefecto() {
    return ConfiguracionPerfil(
      notificacionesActivas: true,
      notificacionesMedallas: true,
      notificacionesEventos: true,
      notificacionesDonaciones: true,
      perfilPublico: true,
      mostrarEstadisticas: true,
      mostrarMedallas: true,
      temaPreferido: 'auto',
      idiomaPreferido: 'es',
      privacidadDatos: {
        'mostrarNombre': true,
        'mostrarEmail': false,
        'mostrarTelefono': false,
        'mostrarUbicacion': false,
      },
    );
  }

  factory ConfiguracionPerfil.fromMap(Map<String, dynamic> map) {
    return ConfiguracionPerfil(
      notificacionesActivas: map['notificacionesActivas'] ?? true,
      notificacionesMedallas: map['notificacionesMedallas'] ?? true,
      notificacionesEventos: map['notificacionesEventos'] ?? true,
      notificacionesDonaciones: map['notificacionesDonaciones'] ?? true,
      perfilPublico: map['perfilPublico'] ?? true,
      mostrarEstadisticas: map['mostrarEstadisticas'] ?? true,
      mostrarMedallas: map['mostrarMedallas'] ?? true,
      temaPreferido: map['temaPreferido'] ?? 'auto',
      idiomaPreferido: map['idiomaPreferido'] ?? 'es',
      privacidadDatos: Map<String, bool>.from(map['privacidadDatos'] ?? {
        'mostrarNombre': true,
        'mostrarEmail': false,
        'mostrarTelefono': false,
        'mostrarUbicacion': false,
      }),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificacionesActivas': notificacionesActivas,
      'notificacionesMedallas': notificacionesMedallas,
      'notificacionesEventos': notificacionesEventos,
      'notificacionesDonaciones': notificacionesDonaciones,
      'perfilPublico': perfilPublico,
      'mostrarEstadisticas': mostrarEstadisticas,
      'mostrarMedallas': mostrarMedallas,
      'temaPreferido': temaPreferido,
      'idiomaPreferido': idiomaPreferido,
      'privacidadDatos': privacidadDatos,
    };
  }
}

/// Extensión para EstadisticasUsuario para persistencia
extension EstadisticasUsuarioExtension on EstadisticasUsuario {
  static EstadisticasUsuario vacio() {
    return EstadisticasUsuario(
      eventosInscritos: 0,
      eventosCompletados: 0,
      eventosPendientes: 0,
      eventosEnProceso: 0,
      horasTotales: 0.0,
      rachaActual: 0,
      mejorRacha: 0,
      donacionesRealizadas: 0,
      montoTotalDonado: 0.0,
      medallasObtenidas: [],
      medallasDisponibles: Medalla.getMedallasBase(),
      puntosTotales: 0,
      nivelActual: 'Novato',
      progresoNivelSiguiente: 0.0,
    );
  }

  static EstadisticasUsuario fromMap(Map<String, dynamic> map) {
    return EstadisticasUsuario(
      eventosInscritos: map['eventosInscritos'] ?? 0,
      eventosCompletados: map['eventosCompletados'] ?? 0,
      eventosPendientes: map['eventosPendientes'] ?? 0,
      eventosEnProceso: map['eventosEnProceso'] ?? 0,
      horasTotales: (map['horasTotales'] ?? 0.0).toDouble(),
      rachaActual: map['rachaActual'] ?? 0,
      mejorRacha: map['mejorRacha'] ?? 0,
      donacionesRealizadas: map['donacionesRealizadas'] ?? 0,
      montoTotalDonado: (map['montoTotalDonado'] ?? 0.0).toDouble(),
      medallasObtenidas: (map['medallasObtenidas'] as List<dynamic>? ?? [])
          .map((m) => Medalla.fromMap(m))
          .toList(),
      medallasDisponibles: (map['medallasDisponibles'] as List<dynamic>? ?? [])
          .map((m) => Medalla.fromMap(m))
          .toList(),
      puntosTotales: map['puntosTotales'] ?? 0,
      nivelActual: map['nivelActual'] ?? 'Novato',
      progresoNivelSiguiente: (map['progresoNivelSiguiente'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventosInscritos': eventosInscritos,
      'eventosCompletados': eventosCompletados,
      'eventosPendientes': eventosPendientes,
      'eventosEnProceso': eventosEnProceso,
      'horasTotales': horasTotales,
      'rachaActual': rachaActual,
      'mejorRacha': mejorRacha,
      'donacionesRealizadas': donacionesRealizadas,
      'montoTotalDonado': montoTotalDonado,
      'medallasObtenidas': medallasObtenidas.map((m) => m.toMap()).toList(),
      'medallasDisponibles': medallasDisponibles.map((m) => m.toMap()).toList(),
      'puntosTotales': puntosTotales,
      'nivelActual': nivelActual,
      'progresoNivelSiguiente': progresoNivelSiguiente,
    };
  }
}
