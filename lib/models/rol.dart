class Rol {
  final String idRol;
  final String nombre;  // Changed from nombreRol to nombre
  final String descripcion;  // Added descripcion field
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
      nombre: map['nombre'] ?? '',  // Changed from nombreRol
      descripcion: map['descripcion'] ?? '',  // Added descripcion
      permisos: List<String>.from(map['permisos'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idRol': idRol,
      'nombre': nombre,  // Changed from nombreRol
      'descripcion': descripcion,  // Added descripcion
      'permisos': permisos,
    };
  }
}