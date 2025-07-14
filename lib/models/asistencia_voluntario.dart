class AsistenciaVoluntario {
  final String idEvento;
  final String idUsuario;
  final bool asistio;
  final DateTime? fechaMarcado;
  final String? marcadoPor; // ID del administrador que marcó
  final String? observaciones;

  AsistenciaVoluntario({
    required this.idEvento,
    required this.idUsuario,
    this.asistio = false,
    this.fechaMarcado,
    this.marcadoPor,
    this.observaciones,
  });

  factory AsistenciaVoluntario.fromFirestore(Map<String, dynamic> data) {
    return AsistenciaVoluntario(
      idEvento: data['idEvento'] ?? '',
      idUsuario: data['idUsuario'] ?? '',
      asistio: data['asistio'] ?? false,
      fechaMarcado: data['fechaMarcado'] != null 
          ? DateTime.parse(data['fechaMarcado'])
          : null,
      marcadoPor: data['marcadoPor'],
      observaciones: data['observaciones'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'idEvento': idEvento,
      'idUsuario': idUsuario,
      'asistio': asistio,
      'fechaMarcado': fechaMarcado?.toIso8601String(),
      'marcadoPor': marcadoPor,
      'observaciones': observaciones,
    };
  }

  AsistenciaVoluntario copyWith({
    String? idEvento,
    String? idUsuario,
    bool? asistio,
    DateTime? fechaMarcado,
    String? marcadoPor,
    String? observaciones,
  }) {
    return AsistenciaVoluntario(
      idEvento: idEvento ?? this.idEvento,
      idUsuario: idUsuario ?? this.idUsuario,
      asistio: asistio ?? this.asistio,
      fechaMarcado: fechaMarcado ?? this.fechaMarcado,
      marcadoPor: marcadoPor ?? this.marcadoPor,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}
