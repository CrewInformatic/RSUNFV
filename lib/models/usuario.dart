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
  final List<String> medallasIDs;
  final String fechaRegistro;
  final String fechaModificacion;
  final String idRol;
  final int puntosJuego;
  
  final String? yape;
  final String? cuentaBancaria;
  final String? celular;
  final String? banco;

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
    this.medallasIDs = const [],
    this.fechaRegistro = "",
    this.fechaModificacion = "",
    this.idRol = "",
    this.puntosJuego = 0,
    this.yape,
    this.cuentaBancaria,
    this.celular,
    this.banco,
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
      edad: _parseIntFromDynamic(map['edad']),
      medallasIDs: List<String>.from(map['medallasIDs'] ?? []),
      fechaRegistro: map['fechaRegistro'] ?? '',
      fechaModificacion: map['fechaModificacion'] ?? '',
      idRol: map['idRol'] ?? '',
      puntosJuego: _parseIntFromDynamic(map['puntosJuego']),
      yape: map['Yape'] ?? map['yape'],
      cuentaBancaria: map['cuentaBancaria'],
      celular: map['celular'],
      banco: map['banco'],
    );
  }

  /// Método helper para convertir dinámicamente a int
  static int _parseIntFromDynamic(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
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
      edad: _parseIntFromDynamic(map['edad']),
      medallasIDs: List<String>.from(map['medallasIDs'] ?? []),
      fechaRegistro: convertToISOString(map['fechaRegistro']),
      fechaModificacion: convertToISOString(map['fechaModificacion']),
      idRol: map['idRol'] ?? '',
      puntosJuego: _parseIntFromDynamic(map['puntosJuego']),
      yape: map['Yape'] ?? map['yape'],
      cuentaBancaria: map['cuentaBancaria'],
      celular: map['celular'],
      banco: map['banco'],
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
      'medallasIDs': medallasIDs,
      'fechaRegistro': fechaRegistro,
      'fechaModificacion': fechaModificacion,
      'idRol': idRol,
      'puntosJuego': puntosJuego,
      'yape': yape,
      'cuentaBancaria': cuentaBancaria,
      'celular': celular,
      'banco': banco,
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
    List<String>? medallasIDs,
    String? fechaRegistro,
    String? fechaModificacion,
    String? idRol,
    int? puntosJuego,
    String? yape,
    String? cuentaBancaria,
    String? celular,
    String? banco,
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
      medallasIDs: medallasIDs ?? this.medallasIDs,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaModificacion: fechaModificacion ?? this.fechaModificacion,
      idRol: idRol ?? this.idRol,
      puntosJuego: puntosJuego ?? this.puntosJuego,
      yape: yape ?? this.yape,
      cuentaBancaria: cuentaBancaria ?? this.cuentaBancaria,
      celular: celular ?? this.celular,
      banco: banco ?? this.banco,
    );
  }

  bool get isAdmin => esAdmin;
  bool get isReceptorDonaciones => idRol == 'rol_004';

  bool hasRole(String rolId) {
    return idRol == rolId;
  }
}
