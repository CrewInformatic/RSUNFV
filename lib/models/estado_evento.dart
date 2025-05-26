class EstadoEvento {
  final String idEstado;
  final String nombre;

  EstadoEvento({
    required this.idEstado,
    required this.nombre,
  });

  factory EstadoEvento.fromMap(Map<String, dynamic> map) {
    return EstadoEvento(
      idEstado: map['idEstado'] ?? '',
      nombre: map['nombre'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idEstado': idEstado,
      'nombre': nombre,
    };
  }
}