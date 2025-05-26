class AdminEvento {
  final String idAdmin;
  final String nombre;

  AdminEvento({
    required this.idAdmin,
    required this.nombre,
  });

  factory AdminEvento.fromMap(Map<String, dynamic> map) {
    return AdminEvento(
      idAdmin: map['idAdmin'] ?? '',
      nombre: map['nombre'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idAdmin': idAdmin,
      'nombre': nombre,
    };
  }
}