class Rol {
  final String idRol;
  final String nombre;
  final String descripcion;
  final List<String> permisos;
  
  Rol({
    required this.idRol,
    required this.nombre,
    required this.descripcion,
    required this.permisos,
  });

  factory Rol.fromMap(Map<String, dynamic> map) {
    return Rol(
      idRol: map['idRol'] ?? '',
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      permisos: List<String>.from(map['permisos'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idRol': idRol,
      'nombre': nombre,
      'descripcion': descripcion,
      'permisos': permisos,
    };
  }
}