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
  });

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
    );
  }
}