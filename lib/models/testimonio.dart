import 'package:cloud_firestore/cloud_firestore.dart';

class Testimonio {
  final String id;
  final String usuarioId;
  final String mensaje;
  final int calificacion;
  final bool esAnonimo;
  final String? nombreUsuario;
  final String? carreraUsuario;
  final DateTime fechaCreacion;
  final bool aprobado;
  final String estado; // 'pendiente', 'aprobado', 'rechazado'

  Testimonio({
    required this.id,
    required this.usuarioId,
    required this.mensaje,
    required this.calificacion,
    required this.esAnonimo,
    this.nombreUsuario,
    this.carreraUsuario,
    required this.fechaCreacion,
    this.aprobado = false,
    this.estado = 'pendiente',
  });

  factory Testimonio.fromFirestore(Map<String, dynamic> data, String id) {
    return Testimonio(
      id: id,
      usuarioId: data['usuarioId'] ?? '',
      mensaje: data['mensaje'] ?? '',
      calificacion: data['calificacion'] ?? 5,
      esAnonimo: data['esAnonimo'] ?? false,
      nombreUsuario: data['nombreUsuario'],
      carreraUsuario: data['carreraUsuario'],
      fechaCreacion: data['fechaCreacion'] != null 
          ? (data['fechaCreacion'] as Timestamp).toDate()
          : DateTime.now(),
      aprobado: data['aprobado'] ?? false,
      estado: data['estado'] ?? 'pendiente',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'usuarioId': usuarioId,
      'mensaje': mensaje,
      'calificacion': calificacion,
      'esAnonimo': esAnonimo,
      'nombreUsuario': nombreUsuario,
      'carreraUsuario': carreraUsuario,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'aprobado': aprobado,
      'estado': estado,
    };
  }

  Testimonio copyWith({
    String? id,
    String? usuarioId,
    String? mensaje,
    int? calificacion,
    bool? esAnonimo,
    String? nombreUsuario,
    String? carreraUsuario,
    DateTime? fechaCreacion,
    bool? aprobado,
    String? estado,
  }) {
    return Testimonio(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      mensaje: mensaje ?? this.mensaje,
      calificacion: calificacion ?? this.calificacion,
      esAnonimo: esAnonimo ?? this.esAnonimo,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      carreraUsuario: carreraUsuario ?? this.carreraUsuario,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      aprobado: aprobado ?? this.aprobado,
      estado: estado ?? this.estado,
    );
  }
}
