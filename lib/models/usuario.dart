import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cloudinary_services.dart';

class Usuario {
  final String idUsuario;
  final String nombreUsuario;
  final String apellidoUsuario;
  final String codigoUsuario;
  final String fotoPerfil;
  final String correo;
  final String fechaNacimiento;
  final String poloTallaID;
  final bool esAdmin;
  final String facultadID;
  final String escuelaId; 
  final bool estadoActivo;
  final String ciclo;
  final int edad;
  final String medallasID;
  final String fechaRegistro;
  final String fechaModificacion;
  final String idRol; 

  String get nombre => '$nombreUsuario $apellidoUsuario';
  String get email => correo;
  String get codigo => codigoUsuario;

  Usuario({
    this.idUsuario = "",
    this.nombreUsuario = "",
    this.apellidoUsuario = "",
    this.codigoUsuario = "",
    this.fotoPerfil = CloudinaryService.defaultAvatarUrl,  
    this.correo = "",
    this.fechaNacimiento = "",
    this.poloTallaID = "",
    this.esAdmin = false,
    this.facultadID = "",
    this.escuelaId = "",
    this.estadoActivo = false,
    this.ciclo = "",
    this.edad = 0,
    this.medallasID = "",
    this.fechaRegistro = "",
    this.fechaModificacion = "",
    this.idRol = "",
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      idUsuario: map['idUsuario'] ?? '',
      nombreUsuario: map['nombreUsuario'] ?? '',
      apellidoUsuario: map['apellidoUsuario'] ?? '',
      codigoUsuario: map['codigoUsuario'] ?? '',
      fotoPerfil: map['fotoPerfil'] ?? '',
      correo: map['correo'] ?? '',
      fechaNacimiento: map['fechaNacimiento'] ?? '',
      poloTallaID: map['poloTallaID'] ?? '',
      esAdmin: map['esAdmin'] ?? false,
      facultadID: map['facultadID'] ?? '',
      escuelaId: map['escuelaId'] ?? '', 
      estadoActivo: map['estadoActivo'] ?? false,
      ciclo: map['ciclo'] ?? '',
      edad: map['edad'] ?? 0,
      medallasID: map['medallasID'] ?? '',
      fechaRegistro: map['fechaRegistro'] ?? '',
      fechaModificacion: map['fechaModificacion'] ?? '',
      idRol: map['idRol'] ?? '',
    );
  }

  factory Usuario.fromFirestore(Map<String, dynamic> map, String id) {

    String convertToISOString(dynamic value) {
      if (value is Timestamp) {
        return value.toDate().toIso8601String();
      } else if (value is String) {
        return value;
      }
      return DateTime.now().toIso8601String();
    }

    return Usuario(
      idUsuario: map['idUsuario'] != null && map['idUsuario'].toString().isNotEmpty
          ? map['idUsuario']
          : id,
      nombreUsuario: map['nombreUsuario'] ?? '',
      apellidoUsuario: map['apellidoUsuario'] ?? '',
      codigoUsuario: map['codigoUsuario'] ?? '',
      fotoPerfil: map['fotoPerfil'] ?? '',
      correo: map['correo'] ?? '',
      fechaNacimiento: map['fechaNacimiento'] ?? '',
      poloTallaID: map['poloTallaID'] ?? '',
      esAdmin: map['esAdmin'] ?? false,
      facultadID: map['facultadID'] ?? '',
      escuelaId: map['escuelaId'] ?? '',
      estadoActivo: map['estadoActivo'] ?? false,
      ciclo: map['ciclo'] ?? '',
      edad: map['edad'] ?? 0,
      medallasID: map['medallasID'] ?? '',
      fechaRegistro: convertToISOString(map['fechaRegistro']),
      fechaModificacion: convertToISOString(map['fechaModificacion']),
      idRol: map['idRol'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idUsuario': idUsuario,
      'nombreUsuario': nombreUsuario,
      'apellidoUsuario': apellidoUsuario,
      'codigoUsuario': codigoUsuario,
      'fotoPerfil': fotoPerfil,
      'correo': correo,
      'fechaNacimiento': fechaNacimiento,
      'poloTallaID': poloTallaID,
      'esAdmin': esAdmin,
      'facultadID': facultadID,
      'escuelaId': escuelaId,
      'estadoActivo': estadoActivo,
      'ciclo': ciclo,
      'edad': edad,
      'medallasID': medallasID,
      'fechaRegistro': fechaRegistro,
      'fechaModificacion': fechaModificacion,
      'idRol': idRol,
    };
  }

  Usuario copyWith({
    String? idUsuario,
    String? nombreUsuario,
    String? apellidoUsuario,
    String? codigoUsuario,
    String? fotoPerfil,
    String? correo,
    String? fechaNacimiento,
    String? poloTallaID,
    bool? esAdmin,
    String? facultadID,
    String? escuelaId, 
    bool? estadoActivo,
    String? ciclo,
    int? edad,
    String? medallasID,
    String? fechaRegistro,
    String? fechaModificacion,
    String? idRol,
  }) {
    return Usuario(
      idUsuario: idUsuario ?? this.idUsuario,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      apellidoUsuario: apellidoUsuario ?? this.apellidoUsuario,
      codigoUsuario: codigoUsuario ?? this.codigoUsuario,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      correo: correo ?? this.correo,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      poloTallaID: poloTallaID ?? this.poloTallaID,
      esAdmin: esAdmin ?? this.esAdmin,
      facultadID: facultadID ?? this.facultadID,
      escuelaId: escuelaId ?? this.escuelaId, 
      estadoActivo: estadoActivo ?? this.estadoActivo,
      ciclo: ciclo ?? this.ciclo,
      edad: edad ?? this.edad,
      medallasID: medallasID ?? this.medallasID,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaModificacion: fechaModificacion ?? this.fechaModificacion,
      idRol: idRol ?? this.idRol,
    );
  }

  bool get isAdmin => esAdmin;
  bool get isReceptorDonaciones => idRol == 'rol_004';


  bool hasRole(String rolId) {
    return idRol == rolId;
  }
}
