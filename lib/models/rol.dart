class Rol {
  final String idRol;
  final String nombreRol;
  final List<String> permisos;
  final String tiempo;

  Rol({
    required this.idRol,
    required this.nombreRol,
    required this.permisos,
    required this.tiempo,
  });

  factory Rol.fromMap(Map<String, dynamic> map) {
    return Rol(
      idRol: map['idRol'] ?? '',
      nombreRol: map['nombreRol'] ?? '',
      permisos: List<String>.from(map['permisos'] ?? []),
      tiempo: map['tiempo'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idRol': idRol,
      'nombreRol': nombreRol,
      'permisos': permisos,
      'tiempo': tiempo,
    };
  }

  Rol copyWith({
    String? idRol,
    String? nombreRol,
    List<String>? permisos,
    String? tiempo,
  }) {
    return Rol(
      idRol: idRol ?? this.idRol,
      nombreRol: nombreRol ?? this.nombreRol,
      permisos: permisos ?? this.permisos,
      tiempo: tiempo ?? this.tiempo,
    );
  }
}