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
      requisitos: map['requisitos'] is List
          ? (map['requisitos'] as List).join(', ')
          : (map['requisitos']?.toString() ?? ''),
      cantidadVoluntariosMax: (map['cantidadVoluntariosMax'] ?? 0).toInt(),
      voluntariosInscritos: voluntarios,
      idUsuarioAdm: map['idUsuarioAdm']?.toString() ?? '',
      idEstado: map['idEstado']?.toString() ?? '',
      idTipo: map['idTipo']?.toString() ?? '',
      fechaCreacion: map['fechaCreacion']?.toString() ?? '',
      fechaInicio: map['fechaInicio']?.toString() ?? '',
      horaInicio: map['horaInicio']?.toString() ?? '',
      horaFin: map['horaFin']?.toString() ?? '',
      estado: map['estado']?.toString() ?? 'pendiente',
    );
  }

  factory Evento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Manejo específico para voluntariosInscritos
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
      requisitos: data['requisitos'] is List
          ? (data['requisitos'] as List).join(', ')
          : (data['requisitos']?.toString() ?? ''),
      cantidadVoluntariosMax: (data['cantidadVoluntariosMax'] ?? 0).toInt(),
      voluntariosInscritos: voluntarios,
      idUsuarioAdm: data['idUsuarioAdm']?.toString() ?? '',
      idEstado: data['idEstado']?.toString() ?? '',
      idTipo: data['idTipo']?.toString() ?? '',
      fechaCreacion: data['fechaCreacion']?.toString() ?? '',
      fechaInicio: data['fechaInicio']?.toString() ?? '',
      horaInicio: data['horaInicio']?.toString() ?? '',
      horaFin: data['horaFin']?.toString() ?? '',
      estado: data['estado']?.toString() ?? 'pendiente',
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
      'estado': estado, // Agregado aquí
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