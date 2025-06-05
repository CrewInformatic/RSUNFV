class Estado {
  final String idEstado;
  final String nombreEstado;

  Estado({
    required this.idEstado,
    required this.nombreEstado,
  });

  factory Estado.fromMap(Map<String, dynamic> map) {
    return Estado(
      idEstado: map['idEstado'] ?? '',
      nombreEstado: map['nombreEstado'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idEstado': idEstado,
      'nombreEstado': nombreEstado,
    };
  }

  Estado copyWith({
    String? idEstado,
    String? nombreEstado,
  }) {
    return Estado(
      idEstado: idEstado ?? this.idEstado,
      nombreEstado: nombreEstado ?? this.nombreEstado,
    );
  }
}