import 'package:cloud_firestore/cloud_firestore.dart';

class Donaciones {
  final String idDonaciones;
  final String? idEvento;
  final String idUsuarioDonador;
  final String tipoDonacion;
  final double monto;
  final String descripcion;
  final String fechaDonacion;
  final String idValidacion;
  final String estadoValidacion;
  final String metodoPago;
  final String? idRecolector;
  
  final String? apellidoUsuarioDonador;
  final String? dniUsuarioDonador;
  final String? emailUsuarioDonador;
  final String? nombreUsuarioDonador;
  final String? telefonoUsuarioDonador;
  final String? tipoUsuario;
  final String? usuarioEstadoValidacion;
  final bool? estadoValidacionBool;
  
  final String? banco;
  final String? emailRecolector;
  final String? facultadRecolector;
  final String? nombreRecolector;
  final String? observaciones;
  
  final String? apellidoRecolector;
  final String? bancoRecolector;
  final String? celularRecolector;
  final String? cuentaBancariaRecolector;
  final String? yapeRecolector;
  
  final String? estado;
  final DateTime? fechaVoucher;
  
  final int? cantidad;
  final String? objetos;
  final String? unidadMedida;
  
  final String? numeroOperacion;
  final DateTime? fechaDeposito;

  Donaciones({
    required this.idDonaciones,
    this.idEvento,
    required this.idUsuarioDonador,
    required this.tipoDonacion,
    required this.monto,
    required this.descripcion,
    required this.fechaDonacion,
    required this.idValidacion,
    required this.estadoValidacion,
    required this.metodoPago,
    this.idRecolector,
    this.apellidoUsuarioDonador,
    this.dniUsuarioDonador,
    this.emailUsuarioDonador,
    this.nombreUsuarioDonador,
    this.telefonoUsuarioDonador,
    this.tipoUsuario,
    this.usuarioEstadoValidacion,
    this.estadoValidacionBool,
    this.banco,
    this.emailRecolector,
    this.facultadRecolector,
    this.nombreRecolector,
    this.observaciones,
    this.apellidoRecolector,
    this.bancoRecolector,
    this.celularRecolector,
    this.cuentaBancariaRecolector,
    this.yapeRecolector,
    this.estado,
    this.fechaVoucher,
    this.cantidad,
    this.objetos,
    this.unidadMedida,
    this.numeroOperacion,
    this.fechaDeposito,
  });

  factory Donaciones.fromMap(Map<String, dynamic> map) {
    return Donaciones(
      idDonaciones: map['idDonaciones'] ?? '',
      idEvento: map['idEvento'],
      idUsuarioDonador: map['idUsuarioDonador'] ?? map['IDUsuarioDonador'] ?? '',
      tipoDonacion: map['tipoDonacion'] ?? '',
      monto: _parseDouble(map['monto']),
      descripcion: map['descripcion'] ?? '',
      fechaDonacion: map['fechaDonacion'] ?? '',
      idValidacion: map['idValidacion'] ?? map['IDValidacion'] ?? '',
      estadoValidacion: _parseEstadoValidacion(map['estadoValidacion']),
      metodoPago: map['metodoPago'] ?? '',
      idRecolector: map['idRecolector'],
      apellidoUsuarioDonador: map['ApellidoUsuarioDonador'],
      dniUsuarioDonador: map['DNIUsuarioDonador'],
      emailUsuarioDonador: map['EmailUsuarioDonador'],
      nombreUsuarioDonador: map['NombreUsuarioDonador'],
      telefonoUsuarioDonador: map['TelefonoUsuarioDonador'],
      tipoUsuario: map['Tipo_Usuario'],
      usuarioEstadoValidacion: map['UsuarioEstadoValidacion'],
      estadoValidacionBool: map['estadoValidacionBool'] is bool ? map['estadoValidacionBool'] : 
                           (map['estadoValidacion'] is bool ? map['estadoValidacion'] : null),
      banco: map['banco'],
      emailRecolector: map['emailRecolector'] ?? map['EmailRecolector'],
      facultadRecolector: map['facultadRecolector'],
      nombreRecolector: map['nombreRecolector'] ?? map['NombreRecolector'],
      observaciones: map['observaciones'],
      apellidoRecolector: map['ApellidoRecolector'],
      bancoRecolector: map['BancoRecolector'],
      celularRecolector: map['CelularRecolector'],
      cuentaBancariaRecolector: map['CuentaBancariaRecolector'],
      yapeRecolector: map['YapeRecolector'],
      estado: map['estado'],
      fechaVoucher: map['fechaVoucher'] != null ? 
        (map['fechaVoucher'] is Timestamp ? 
         (map['fechaVoucher'] as Timestamp).toDate() : 
         DateTime.tryParse(map['fechaVoucher'].toString())) : null,
      cantidad: map['cantidad'] is int ? map['cantidad'] : 
               (map['cantidad'] is String ? int.tryParse(map['cantidad']) : null),
      objetos: map['objetos'],
      unidadMedida: map['unidadMedida'],
      numeroOperacion: map['numeroOperacion'],
      fechaDeposito: map['fechaDeposito'] != null ? DateTime.tryParse(map['fechaDeposito']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idDonaciones': idDonaciones,
      'idEvento': idEvento,
      'idUsuarioDonador': idUsuarioDonador,
      'tipoDonacion': tipoDonacion,
      'monto': monto,
      'descripcion': descripcion,
      'fechaDonacion': fechaDonacion,
      'idValidacion': idValidacion,
      'estadoValidacion': estadoValidacion,
      'metodoPago': metodoPago,
      'idRecolector': idRecolector,
      'apellidoUsuarioDonador': apellidoUsuarioDonador,
      'dniUsuarioDonador': dniUsuarioDonador,
      'emailUsuarioDonador': emailUsuarioDonador,
      'NombreUsuarioDonador': nombreUsuarioDonador,
      'TelefonoUsuarioDonador': telefonoUsuarioDonador,
      'Tipo_Usuario': tipoUsuario,
      'UsuarioEstadoValidacion': usuarioEstadoValidacion,
      'banco': banco,
      'emailRecolector': emailRecolector,
      'facultadRecolector': facultadRecolector,
      'nombreRecolector': nombreRecolector,
      'observaciones': observaciones,
      'ApellidoRecolector': apellidoRecolector,
      'BancoRecolector': bancoRecolector,
      'CelularRecolector': celularRecolector,
      'CuentaBancariaRecolector': cuentaBancariaRecolector,
      'YapeRecolector': yapeRecolector,
      'estado': estado,
      'fechaVoucher': fechaVoucher != null ? Timestamp.fromDate(fechaVoucher!) : null,
      'cantidad': cantidad,
      'objetos': objetos,
      'unidadMedida': unidadMedida,
      'numeroOperacion': numeroOperacion,
      'fechaDeposito': fechaDeposito?.toIso8601String(),
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  static String _parseEstadoValidacion(dynamic value) {
    if (value == null) return 'pendiente';
    if (value is String) return value;
    if (value is bool) return value ? 'validado' : 'pendiente';
    return 'pendiente';
  }

  Donaciones copyWith({
    String? idDonaciones,
    String? idEvento,
    String? idUsuarioDonador,
    String? tipoDonacion,
    double? monto,
    String? descripcion,
    String? fechaDonacion,
    String? idValidacion,
    String? estadoValidacion,
    String? metodoPago,
    String? idRecolector,
    String? apellidoUsuarioDonador,
    String? dniUsuarioDonador,
    String? emailUsuarioDonador,
    String? nombreUsuarioDonador,
    String? telefonoUsuarioDonador,
    String? tipoUsuario,
    String? usuarioEstadoValidacion,
    bool? estadoValidacionBool,
    String? banco,
    String? emailRecolector,
    String? facultadRecolector,
    String? nombreRecolector,
    String? observaciones,
    String? apellidoRecolector,
    String? bancoRecolector,
    String? celularRecolector,
    String? cuentaBancariaRecolector,
    String? yapeRecolector,
    String? estado,
    DateTime? fechaVoucher,
    int? cantidad,
    String? objetos,
    String? unidadMedida,
    String? numeroOperacion,
    DateTime? fechaDeposito,
  }) {
    return Donaciones(
      idDonaciones: idDonaciones ?? this.idDonaciones,
      idEvento: idEvento ?? this.idEvento,
      idUsuarioDonador: idUsuarioDonador ?? this.idUsuarioDonador,
      tipoDonacion: tipoDonacion ?? this.tipoDonacion,
      monto: monto ?? this.monto,
      descripcion: descripcion ?? this.descripcion,
      fechaDonacion: fechaDonacion ?? this.fechaDonacion,
      idValidacion: idValidacion ?? this.idValidacion,
      estadoValidacion: estadoValidacion ?? this.estadoValidacion,
      metodoPago: metodoPago ?? this.metodoPago,
      idRecolector: idRecolector ?? this.idRecolector,
      apellidoUsuarioDonador: apellidoUsuarioDonador ?? this.apellidoUsuarioDonador,
      dniUsuarioDonador: dniUsuarioDonador ?? this.dniUsuarioDonador,
      emailUsuarioDonador: emailUsuarioDonador ?? this.emailUsuarioDonador,
      nombreUsuarioDonador: nombreUsuarioDonador ?? this.nombreUsuarioDonador,
      telefonoUsuarioDonador: telefonoUsuarioDonador ?? this.telefonoUsuarioDonador,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      usuarioEstadoValidacion: usuarioEstadoValidacion ?? this.usuarioEstadoValidacion,
      estadoValidacionBool: estadoValidacionBool ?? this.estadoValidacionBool,
      banco: banco ?? this.banco,
      emailRecolector: emailRecolector ?? this.emailRecolector,
      facultadRecolector: facultadRecolector ?? this.facultadRecolector,
      nombreRecolector: nombreRecolector ?? this.nombreRecolector,
      observaciones: observaciones ?? this.observaciones,
      apellidoRecolector: apellidoRecolector ?? this.apellidoRecolector,
      bancoRecolector: bancoRecolector ?? this.bancoRecolector,
      celularRecolector: celularRecolector ?? this.celularRecolector,
      cuentaBancariaRecolector: cuentaBancariaRecolector ?? this.cuentaBancariaRecolector,
      yapeRecolector: yapeRecolector ?? this.yapeRecolector,
      estado: estado ?? this.estado,
      fechaVoucher: fechaVoucher ?? this.fechaVoucher,
      cantidad: cantidad ?? this.cantidad,
      objetos: objetos ?? this.objetos,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      numeroOperacion: numeroOperacion ?? this.numeroOperacion,
      fechaDeposito: fechaDeposito ?? this.fechaDeposito,
    );
  }
}