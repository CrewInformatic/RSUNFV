import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../models/medalla.dart';
import '../models/donaciones.dart';

class EstadisticasUsuario {
  final int eventosInscritos;
  final int eventosCompletados;
  final int eventosPendientes;
  final int eventosEnProceso;
  final double horasTotales;
  final int rachaActual;
  final int mejorRacha;
  final int donacionesRealizadas;
  final double montoTotalDonado;
  final List<Medalla> medallasObtenidas;
  final List<Medalla> medallasDisponibles;
  final int puntosTotales;
  final String nivelActual;
  final double progresoNivelSiguiente;

  EstadisticasUsuario({
    required this.eventosInscritos,
    required this.eventosCompletados,
    required this.eventosPendientes,
    required this.eventosEnProceso,
    required this.horasTotales,
    required this.rachaActual,
    required this.mejorRacha,
    required this.donacionesRealizadas,
    required this.montoTotalDonado,
    required this.medallasObtenidas,
    required this.medallasDisponibles,
    required this.puntosTotales,
    required this.nivelActual,
    required this.progresoNivelSiguiente,
  });

  static EstadisticasUsuario calcular({
    required List<Evento> eventos,
    required List<Donaciones> donaciones,
    required String userId,
  }) {
    // Calcular estadísticas básicas
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

    // Calcular donaciones
    int donacionesRealizadas = donaciones.length;
    double montoTotalDonado = 0;
    for (var donacion in donaciones) {
      if (donacion.tipoDonacion.toLowerCase() == 'dinero' || 
          donacion.tipoDonacion.toLowerCase() == 'monetaria') {
        montoTotalDonado += donacion.monto;
      }
    }

    // Calcular rachas (simplificado - en producción usar fechas reales)
    int rachaActual = _calcularRachaActual(eventos);
    int mejorRacha = _calcularMejorRacha(eventos);

    // Calcular medallas
    List<Medalla> medallasBase = Medalla.getMedallasBase();
    List<Medalla> medallasObtenidas = [];
    List<Medalla> medallasDisponibles = [];

    for (var medalla in medallasBase) {
      bool desbloqueada = false;
      
      switch (medalla.tipo) {
        case 'eventos':
          desbloqueada = eventosCompletados >= medalla.requisito;
          break;
        case 'horas':
          desbloqueada = horasTotales >= medalla.requisito;
          break;
        case 'racha':
          desbloqueada = mejorRacha >= medalla.requisito;
          break;
        case 'donaciones':
          desbloqueada = donacionesRealizadas >= medalla.requisito;
          break;
        case 'monto_donaciones':
          desbloqueada = montoTotalDonado >= medalla.requisito;
          break;
        case 'diversidad':
          desbloqueada = _calcularTiposEventos(eventos) >= medalla.requisito;
          break;
        case 'especial':
          // Lógica especial para cada medalla
          if (medalla.id == 'madrugador') {
            desbloqueada = _tieneEventoTemprano(eventos);
          } else if (medalla.id == 'nocturno') {
            desbloqueada = _tieneEventoNocturno(eventos);
          } else if (medalla.id == 'fin_semana') {
            desbloqueada = _tieneEventosFinSemana(eventos);
          }
          break;
        case 'liderazgo':
          // Por ahora simplificado - en producción verificar si organizó eventos
          desbloqueada = false;
          break;
      }

      if (desbloqueada) {
        medallasObtenidas.add(medalla.copyWith(
          desbloqueada: true,
          fechaObtencion: DateTime.now(),
        ));
      } else {
        medallasDisponibles.add(medalla);
      }
    }

    // Calcular puntos y nivel
    int puntosTotales = _calcularPuntos(
      eventosCompletados, 
      horasTotales, 
      medallasObtenidas, 
      donacionesRealizadas
    );
    
    String nivelActual = _calcularNivel(puntosTotales);
    double progresoNivel = _calcularProgresoNivel(puntosTotales);

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
      medallasObtenidas: medallasObtenidas,
      medallasDisponibles: medallasDisponibles,
      puntosTotales: puntosTotales,
      nivelActual: nivelActual,
      progresoNivelSiguiente: progresoNivel,
    );
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

  static int _calcularRachaActual(List<Evento> eventos) {
    // Simplificado - en producción usar fechas reales
    int racha = 0;
    for (var evento in eventos.reversed) {
      if (evento.estado.toLowerCase() == 'finalizado') {
        racha++;
      } else {
        break;
      }
    }
    return racha;
  }

  static int _calcularMejorRacha(List<Evento> eventos) {
    // Simplificado
    return _calcularRachaActual(eventos);
  }

  static bool _tieneEventoTemprano(List<Evento> eventos) {
    for (var evento in eventos) {
      try {
        final hora = int.parse(evento.horaInicio.split(':')[0]);
        if (hora < 7 && evento.estado.toLowerCase() == 'finalizado') return true;
      } catch (e) {
        // Ignorar errores de parsing
      }
    }
    return false;
  }

  static bool _tieneEventoNocturno(List<Evento> eventos) {
    for (var evento in eventos) {
      try {
        final hora = int.parse(evento.horaInicio.split(':')[0]);
        if (hora >= 22 && evento.estado.toLowerCase() == 'finalizado') return true;
      } catch (e) {
        // Ignorar errores de parsing
      }
    }
    return false;
  }

  static bool _tieneEventosFinSemana(List<Evento> eventos) {
    bool tienesSabado = false;
    bool tienesDomingo = false;
    
    for (var evento in eventos) {
      if (evento.estado.toLowerCase() == 'finalizado') {
        try {
          final fecha = DateTime.parse(evento.fechaInicio);
          if (fecha.weekday == 6) tienesSabado = true;  // Sábado
          if (fecha.weekday == 7) tienesDomingo = true; // Domingo
        } catch (e) {
          // Ignorar errores de parsing
        }
      }
    }
    
    return tienesSabado && tienesDomingo;
  }

  static int _calcularTiposEventos(List<Evento> eventos) {
    Set<String> tipos = {};
    for (var evento in eventos) {
      if (evento.estado.toLowerCase() == 'finalizado') {
        tipos.add(evento.idTipo);
      }
    }
    return tipos.length;
  }

  static int _calcularPuntos(
    int eventosCompletados, 
    double horas, 
    List<Medalla> medallas, 
    int donaciones
  ) {
    int puntos = 0;
    
    // Puntos por eventos (10 puntos cada uno)
    puntos += eventosCompletados * 10;
    
    // Puntos por horas (2 puntos por hora)
    puntos += (horas * 2).round();
    
    // Puntos por medallas
    for (var medalla in medallas) {
      switch (medalla.categoria) {
        case 'bronce':
          puntos += 25;
          break;
        case 'plata':
          puntos += 50;
          break;
        case 'oro':
          puntos += 100;
          break;
        case 'diamante':
          puntos += 200;
          break;
        case 'especial':
          puntos += 75;
          break;
      }
    }
    
    // Puntos por donaciones (5 puntos cada una)
    puntos += donaciones * 5;
    
    return puntos;
  }

  static String _calcularNivel(int puntos) {
    if (puntos < 50) return 'Novato';
    if (puntos < 150) return 'Voluntario';
    if (puntos < 300) return 'Activista';
    if (puntos < 500) return 'Héroe';
    if (puntos < 800) return 'Leyenda';
    return 'Maestro';
  }

  static double _calcularProgresoNivel(int puntos) {
    List<int> niveles = [0, 50, 150, 300, 500, 800, 1200];
    
    for (int i = 0; i < niveles.length - 1; i++) {
      if (puntos >= niveles[i] && puntos < niveles[i + 1]) {
        double progreso = (puntos - niveles[i]) / (niveles[i + 1] - niveles[i]);
        return progreso;
      }
    }
    
    return 1.0; // Nivel máximo
  }

  double get porcentajeCompletado {
    return eventosInscritos > 0 
        ? (eventosCompletados / eventosInscritos) 
        : 0.0;
  }

  String get siguienteNivel {
    switch (nivelActual) {
      case 'Novato': return 'Voluntario';
      case 'Voluntario': return 'Activista';
      case 'Activista': return 'Héroe';
      case 'Héroe': return 'Leyenda';
      case 'Leyenda': return 'Maestro';
      default: return 'Máximo';
    }
  }

  int get puntosParaSiguienteNivel {
    switch (nivelActual) {
      case 'Novato': return 50 - puntosTotales;
      case 'Voluntario': return 150 - puntosTotales;
      case 'Activista': return 300 - puntosTotales;
      case 'Héroe': return 500 - puntosTotales;
      case 'Leyenda': return 800 - puntosTotales;
      default: return 0;
    }
  }
}

// Extension para medallas
extension MedallaExtension on Medalla {
  Medalla copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? icono,
    String? color,
    int? requisito,
    String? tipo,
    String? categoria,
    bool? desbloqueada,
    DateTime? fechaObtencion,
  }) {
    return Medalla(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      icono: icono ?? this.icono,
      color: color ?? this.color,
      requisito: requisito ?? this.requisito,
      tipo: tipo ?? this.tipo,
      categoria: categoria ?? this.categoria,
      desbloqueada: desbloqueada ?? this.desbloqueada,
      fechaObtencion: fechaObtencion ?? this.fechaObtencion,
    );
  }
}
