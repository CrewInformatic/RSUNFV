class TipoEvento {
  final String idTipo;
  final String nombre;

  TipoEvento({
    required this.idTipo,
    required this.nombre,
  });

  factory TipoEvento.fromMap(Map<String, dynamic> map) {
    return TipoEvento(
      idTipo: map['idTipo'] ?? '',
      nombre: map['nombre'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idTipo': idTipo,
      'nombre': nombre,
    };
  }
}