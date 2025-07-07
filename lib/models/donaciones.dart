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
  
  // Campos adicionales del usuario donador
  final String? apellidoUsuarioDonador;
  final String? dniUsuarioDonador;
  final String? emailUsuarioDonador;
  final String? nombreUsuarioDonador;
  final String? telefonoUsuarioDonador;
  final String? tipoUsuario;
  final String? usuarioEstadoValidacion;
  final bool? estadoValidacionBool;
  
  // Campos adicionales para donaciones en especie
  final int? cantidad;
  final String? objetos;
  final String? unidadMedida;

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
    this.cantidad,
    this.objetos,
    this.unidadMedida,
  });

  factory Donaciones.fromMap(Map<String, dynamic> map) {
    return Donaciones(
      idDonaciones: map['idDonaciones'] ?? '',
      idEvento: map['idEvento'],
      idUsuarioDonador: map['idUsuarioDonador'] ?? '',
      tipoDonacion: map['tipoDonacion'] ?? '',
      monto: _parseDouble(map['monto']),
      descripcion: map['descripcion'] ?? '',
      fechaDonacion: map['fechaDonacion'] ?? '',
      idValidacion: map['idValidacion'] ?? '',
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
      cantidad: map['cantidad'] is int ? map['cantidad'] : 
               (map['cantidad'] is String ? int.tryParse(map['cantidad']) : null),
      objetos: map['objetos'],
      unidadMedida: map['unidadMedida'],
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
      'ApellidoUsuarioDonador': apellidoUsuarioDonador,
      'DNIUsuarioDonador': dniUsuarioDonador,
      'EmailUsuarioDonador': emailUsuarioDonador,
      'NombreUsuarioDonador': nombreUsuarioDonador,
      'TelefonoUsuarioDonador': telefonoUsuarioDonador,
      'Tipo_Usuario': tipoUsuario,
      'UsuarioEstadoValidacion': usuarioEstadoValidacion,
      'cantidad': cantidad,
      'objetos': objetos,
      'unidadMedida': unidadMedida,
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
    int? cantidad,
    String? objetos,
    String? unidadMedida,
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
      cantidad: cantidad ?? this.cantidad,
      objetos: objetos ?? this.objetos,
      unidadMedida: unidadMedida ?? this.unidadMedida,
    );
  }
}