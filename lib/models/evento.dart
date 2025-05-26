import 'package:cloud_firestore/cloud_firestore.dart';

class Evento {
  final String idEventos;
  final String titulo;
  final String descripcion;
  final String foto;
  final String ubicacion;
  final String requisitos;
  final int cantidadVoluntarios;
  final String idAdmin;
  final String idEstado;
  final String idTipo;
  final Timestamp fechaCreacion;
  final Timestamp fechaInicio;

  Evento({
    required this.idEventos,
    required this.titulo,
    required this.descripcion,
    required this.foto,
    required this.ubicacion,
    required this.requisitos,
    required this.cantidadVoluntarios,
    required this.idAdmin,
    required this.idEstado,
    required this.idTipo,
    required this.fechaCreacion,
    required this.fechaInicio,
  });

  factory Evento.fromMap(Map<String, dynamic> map) {
    return Evento(
      idEventos: map['idEventos'] ?? '',
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      foto: map['foto'] ?? '',
      ubicacion: map['ubicacion'] ?? '',
      requisitos: map['requisitos'] ?? '',
      cantidadVoluntarios: map['cantidadVoluntarios'] ?? 0,
      idAdmin: map['idAdmin'] ?? '',
      idEstado: map['idEstado'] ?? '',
      idTipo: map['idTipo'] ?? '',
      fechaCreacion: map['fechaCreacion'] ?? Timestamp.now(),
      fechaInicio: map['fechaInicio'] ?? Timestamp.now(),
    );
  }

  factory Evento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Evento.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'idEventos': idEventos,
      'titulo': titulo,
      'descripcion': descripcion,
      'foto': foto,
      'ubicacion': ubicacion,
      'requisitos': requisitos,
      'cantidadVoluntarios': cantidadVoluntarios,
      'idAdmin': idAdmin,
      'idEstado': idEstado,
      'idTipo': idTipo,
      'fechaCreacion': fechaCreacion,
      'fechaInicio': fechaInicio,
    };
  }
}