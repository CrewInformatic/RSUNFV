import 'package:cloud_firestore/cloud_firestore.dart';

class Evento {
  final String idEvento;
  final String titulo;
  final String descripcion;
  final String foto;
  final String ubicacion;
  final String requisitos; 
  final int cantidadVoluntariosMax;
  final List<String> voluntariosInscritos;
  final String idUsuarioAdm;
  final String idEstado;
  final String idTipo;
  final String fechaCreacion;
  final String fechaInicio;
  final String horaInicio;
  final String horaFin;
  final String estado; 
  
  // Métricas de impacto
  final int? personasAyudadas;
  final int? plantasPlantadas;
  final double? basuraRecolectadaKg;
  final Map<String, dynamic>? metricasPersonalizadas; 

  Evento({
    required this.idEvento,
    required this.titulo,
    required this.descripcion,
    required this.foto,
    required this.ubicacion,
    required this.requisitos, 
    required this.cantidadVoluntariosMax,
    required this.voluntariosInscritos,
    required this.idUsuarioAdm,
    required this.idEstado,
    required this.idTipo,
    required this.fechaCreacion,
    required this.fechaInicio,
    required this.horaInicio,
    required this.horaFin,
    this.estado = 'pendiente',
    this.personasAyudadas,
    this.plantasPlantadas,
    this.basuraRecolectadaKg,
    this.metricasPersonalizadas,
  });

  double getDuracionHoras() {
    try {
      final inicio = DateTime.parse('2024-01-01 $horaInicio:00');
      final fin = DateTime.parse('2024-01-01 $horaFin:00');
      return fin.difference(inicio).inMinutes / 60;
    } catch (e) {
      return 0;
    }
  }

  factory Evento.fromMap(Map<String, dynamic> map) {
    List<String> voluntarios = [];
    if (map['voluntariosInscritos'] != null) {
      if (map['voluntariosInscritos'] is List) {
        voluntarios = (map['voluntariosInscritos'] as List)
            .map((item) => item.toString())
            .toList();
      } else {
        voluntarios = [map['voluntariosInscritos'].toString()];
      }
    }

    return Evento(
      idEvento: map['idEvento']?.toString() ?? '',
      titulo: map['titulo']?.toString() ?? '',
      descripcion: map['descripcion']?.toString() ?? '',
      foto: map['foto']?.toString() ?? '',
      ubicacion: map['ubicacion']?.toString() ?? '',
      requisitos: map['requisitos']?.toString() ?? '',
      cantidadVoluntariosMax: (map['cantidadVoluntariosMax'] ?? 0) is int 
          ? map['cantidadVoluntariosMax'] 
          : int.tryParse(map['cantidadVoluntariosMax'].toString()) ?? 0,
      voluntariosInscritos: voluntarios,
      idUsuarioAdm: map['createdBy']?.toString() ?? map['idUsuarioAdm']?.toString() ?? '',
      idEstado: map['idEstado']?.toString() ?? '',
      idTipo: map['tipo']?.toString() ?? map['idTipo']?.toString() ?? '',
      fechaCreacion: map['createdAt']?.toString() ?? map['fechaCreacion']?.toString() ?? '',
      fechaInicio: map['fechaInicio']?.toString() ?? '',
      horaInicio: map['horaInicio']?.toString() ?? '',
      horaFin: map['horaFin']?.toString() ?? '',
      estado: map['estado']?.toString() ?? 'activo',
      personasAyudadas: map['personasAyudadas'] is int 
          ? map['personasAyudadas'] 
          : int.tryParse(map['personasAyudadas']?.toString() ?? ''),
      plantasPlantadas: map['plantasPlantadas'] is int 
          ? map['plantasPlantadas'] 
          : int.tryParse(map['plantasPlantadas']?.toString() ?? ''),
      basuraRecolectadaKg: map['basuraRecolectadaKg'] is double 
          ? map['basuraRecolectadaKg'] 
          : double.tryParse(map['basuraRecolectadaKg']?.toString() ?? ''),
      metricasPersonalizadas: map['metricasPersonalizadas'] is Map<String, dynamic>
          ? map['metricasPersonalizadas'] 
          : null,
    );
  }

  factory Evento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    List<String> voluntarios = [];
    if (data['voluntariosInscritos'] != null) {
      if (data['voluntariosInscritos'] is List) {
        voluntarios = (data['voluntariosInscritos'] as List)
            .map((item) => item.toString())
            .toList();
      } else {
        voluntarios = [data['voluntariosInscritos'].toString()];
      }
    }

    return Evento(
      idEvento: data['idEvento'] != null && data['idEvento'].toString().isNotEmpty
          ? data['idEvento']
          : doc.id,
      titulo: data['titulo']?.toString() ?? '',
      descripcion: data['descripcion']?.toString() ?? '',
      foto: data['foto']?.toString() ?? '',
      ubicacion: data['ubicacion']?.toString() ?? '',
      requisitos: data['requisitos']?.toString() ?? '',
      cantidadVoluntariosMax: (data['cantidadVoluntariosMax'] ?? 0) is int 
          ? data['cantidadVoluntariosMax'] 
          : int.tryParse(data['cantidadVoluntariosMax'].toString()) ?? 0,
      voluntariosInscritos: voluntarios,
      idUsuarioAdm: data['createdBy']?.toString() ?? data['idUsuarioAdm']?.toString() ?? '',
      idEstado: data['idEstado']?.toString() ?? '',
      idTipo: data['tipo']?.toString() ?? data['idTipo']?.toString() ?? '',
      fechaCreacion: data['createdAt']?.toString() ?? data['fechaCreacion']?.toString() ?? '',
      fechaInicio: data['fechaInicio']?.toString() ?? '',
      horaInicio: data['horaInicio']?.toString() ?? '',
      horaFin: data['horaFin']?.toString() ?? '',
      estado: data['estado']?.toString() ?? 'activo',
      personasAyudadas: data['personasAyudadas'] is int 
          ? data['personasAyudadas'] 
          : int.tryParse(data['personasAyudadas']?.toString() ?? ''),
      plantasPlantadas: data['plantasPlantadas'] is int 
          ? data['plantasPlantadas'] 
          : int.tryParse(data['plantasPlantadas']?.toString() ?? ''),
      basuraRecolectadaKg: data['basuraRecolectadaKg'] is double 
          ? data['basuraRecolectadaKg'] 
          : double.tryParse(data['basuraRecolectadaKg']?.toString() ?? ''),
      metricasPersonalizadas: data['metricasPersonalizadas'] is Map<String, dynamic>
          ? data['metricasPersonalizadas'] 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idEvento': idEvento,
      'titulo': titulo,
      'descripcion': descripcion,
      'foto': foto,
      'ubicacion': ubicacion,
      'requisitos': requisitos,
      'cantidadVoluntariosMax': cantidadVoluntariosMax,
      'voluntariosInscritos': voluntariosInscritos,
      'idUsuarioAdm': idUsuarioAdm,
      'idEstado': idEstado,
      'idTipo': idTipo,
      'fechaCreacion': fechaCreacion,
      'fechaInicio': fechaInicio,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'estado': estado,
      'personasAyudadas': personasAyudadas,
      'plantasPlantadas': plantasPlantadas,
      'basuraRecolectadaKg': basuraRecolectadaKg,
      'metricasPersonalizadas': metricasPersonalizadas,
    };
  }

  Evento copyWith({
    String? idEvento,
    String? titulo,
    String? descripcion,
    String? foto,
    String? ubicacion,
    String? requisitos, 
    int? cantidadVoluntariosMax,
    List<String>? voluntariosInscritos,
    String? idUsuarioAdm,
    String? idEstado,
    String? idTipo,
    String? fechaCreacion,
    String? fechaInicio,
    String? horaInicio,
    String? horaFin,
    String? estado,
    int? personasAyudadas,
    int? plantasPlantadas,
    double? basuraRecolectadaKg,
    Map<String, dynamic>? metricasPersonalizadas,
  }) {
    return Evento(
      idEvento: idEvento ?? this.idEvento,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      foto: foto ?? this.foto,
      ubicacion: ubicacion ?? this.ubicacion,
      requisitos: requisitos ?? this.requisitos, 
      cantidadVoluntariosMax: cantidadVoluntariosMax ?? this.cantidadVoluntariosMax,
      voluntariosInscritos: voluntariosInscritos ?? this.voluntariosInscritos,
      idUsuarioAdm: idUsuarioAdm ?? this.idUsuarioAdm,
      idEstado: idEstado ?? this.idEstado,
      idTipo: idTipo ?? this.idTipo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      estado: estado ?? this.estado,
      personasAyudadas: personasAyudadas ?? this.personasAyudadas,
      plantasPlantadas: plantasPlantadas ?? this.plantasPlantadas,
      basuraRecolectadaKg: basuraRecolectadaKg ?? this.basuraRecolectadaKg,
      metricasPersonalizadas: metricasPersonalizadas ?? this.metricasPersonalizadas,
    );
  }

  bool get isOpen => estado == 'activo' && !isFull;
  bool get isFull => voluntariosInscritos.length >= cantidadVoluntariosMax;
  bool get isPast => DateTime.parse(fechaInicio).isBefore(DateTime.now());
  bool get isUpcoming => !isPast;

  bool canRegister(String userId) {
    return isOpen && 
           !voluntariosInscritos.contains(userId) && 
           isUpcoming;
  }
}