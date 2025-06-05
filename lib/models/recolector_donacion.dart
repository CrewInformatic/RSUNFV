class RecolectorDonacion {
  final String idRecolector;
  final String idUsuario;
  final String idRol;
  final String idDonaciones;
  final String fechaRecepcion;
  final String confirmacion;

  RecolectorDonacion({
    required this.idRecolector,
    required this.idUsuario,
    required this.idRol,
    required this.idDonaciones,
    required this.fechaRecepcion,
    required this.confirmacion,
  });

  factory RecolectorDonacion.fromMap(Map<String, dynamic> map) {
    return RecolectorDonacion(
      idRecolector: map['idRecolector'] ?? '',
      idUsuario: map['idUsuario'] ?? '',
      idRol: map['idRol'] ?? '',
      idDonaciones: map['idDonaciones'] ?? '',
      fechaRecepcion: map['fechaRecepcion'] ?? '',
      confirmacion: map['confirmacion'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idRecolector': idRecolector,
      'idUsuario': idUsuario,
      'idRol': idRol,
      'idDonaciones': idDonaciones,
      'fechaRecepcion': fechaRecepcion,
      'confirmacion': confirmacion,
    };
  }

  RecolectorDonacion copyWith({
    String? idRecolector,
    String? idUsuario,
    String? idRol,
    String? idDonaciones,
    String? fechaRecepcion,
    String? confirmacion,
  }) {
    return RecolectorDonacion(
      idRecolector: idRecolector ?? this.idRecolector,
      idUsuario: idUsuario ?? this.idUsuario,
      idRol: idRol ?? this.idRol,
      idDonaciones: idDonaciones ?? this.idDonaciones,
      fechaRecepcion: fechaRecepcion ?? this.fechaRecepcion,
      confirmacion: confirmacion ?? this.confirmacion,
    );
  }
}