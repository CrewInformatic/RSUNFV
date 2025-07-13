class RecolectorDonacion {
  final String idUsuario;
  final String nombre;
  final String apellido;
  final String dni;
  final String email;
  final String telefono;
  final String idRol;
  final bool estadoActivo;

  RecolectorDonacion({
    required this.idUsuario,
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.email,
    required this.telefono,
    required this.idRol,
    required this.estadoActivo,
  });

  factory RecolectorDonacion.fromMap(Map<String, dynamic> map, String id) {
    return RecolectorDonacion(
      idUsuario: id,
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      dni: map['dni'] ?? '',
      email: map['email'] ?? '',
      telefono: map['telefono'] ?? '',
      idRol: map['idRol'] ?? '',
      estadoActivo: map['estadoActivo'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'dni': dni,
      'email': email,
      'telefono': telefono,
      'idRol': idRol,
      'estadoActivo': estadoActivo,
    };
  }

  String get nombreCompleto => '$nombre $apellido';
}