
class Usuario {
  final String idUsuario;
  final String codigoUsuario;
  final String nombre;
  final String apellido;
  final String correo;
  final String clave;
  final String escuelaID;
  final String fechaNacimientoID;
  final String fotoPerfil;
  final String poloTallaID;
  final List<String> medallasID;
  final bool estadoActivo;


  Usuario({
    required this.idUsuario,
    required this.codigoUsuario,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.clave,
    required this.escuelaID,
    required this.fechaNacimientoID,
    required this.fotoPerfil,
    required this.poloTallaID,
    required this.medallasID,
    required this.estadoActivo,
  });

  // Crear objeto desde Firestore
  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      idUsuario: map['idUsuario'] ?? '',
      codigoUsuario: map['codigoUsuario'] ?? '',
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      correo: map['correo'] ?? '',
      clave: map['clave'] ?? '',
      escuelaID: map['escuelaID'] ?? '',
      fechaNacimientoID: map['fechaNacimientoID'] ?? '',
      fotoPerfil: map['fotoPerfil'] ?? '',
      poloTallaID: map['poloTallaID'] ?? '',
      medallasID: List<String>.from(map['medallasID'] ?? []),
      estadoActivo: map['estadoActivo'] ?? false,
    );
  }

  factory Usuario.fromFirestore(Map<String, dynamic> map, String id) {
    return Usuario(
      idUsuario: id,
      codigoUsuario: map['codigoUsuario'] ?? '',
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      correo: map['correo'] ?? '',
      clave: map['clave'] ?? '',
      escuelaID: map['escuelaID'] ?? '',
      fechaNacimientoID: map['fechaNacimientoID'] ?? '',
      fotoPerfil: map['fotoPerfil'] ?? '',
      poloTallaID: map['poloTallaID'] ?? '',
      medallasID: List<String>.from(map['medallasID'] ?? []),
      estadoActivo: map['estadoActivo'] ?? false,
    );
  }


  // Convertir a JSON para Firestore
  Map<String, dynamic> toMap() {
    return {
      'idUsuario': idUsuario,
      'codigoUsuario': codigoUsuario,
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'clave': clave,
      'escuelaID': escuelaID,
      'fechaNacimientoID': fechaNacimientoID,
      'fotoPerfil': fotoPerfil,
      'poloTallaID': poloTallaID,
      'medallasID': medallasID,
      'estadoActivo': estadoActivo,
    };
  }
}

