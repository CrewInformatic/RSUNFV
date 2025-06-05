class Donaciones {
  final String idDonaciones;
  final String idEvento;
  final String idUsuarioDonador;
  final String tipoDonacion;
  final double monto;
  final String descripcion;
  final String fechaDonacion;
  final String idValidacion;
  final String estadoValidacion;
  final String metodoPago;
  final String idRecolector;

  Donaciones({
    required this.idDonaciones,
    required this.idEvento,
    required this.idUsuarioDonador,
    required this.tipoDonacion,
    required this.monto,
    required this.descripcion,
    required this.fechaDonacion,
    required this.idValidacion,
    required this.estadoValidacion,
    required this.metodoPago,
    required this.idRecolector,
  });

  factory Donaciones.fromMap(Map<String, dynamic> map) {
    return Donaciones(
      idDonaciones: map['idDonaciones'] ?? '',
      idEvento: map['idEvento'] ?? '',
      idUsuarioDonador: map['idUsuarioDonador'] ?? '',
      tipoDonacion: map['tipoDonacion'] ?? '',
      monto: (map['monto'] ?? 0).toDouble(),
      descripcion: map['descripcion'] ?? '',
      fechaDonacion: map['fechaDonacion'] ?? '',
      idValidacion: map['idValidacion'] ?? '',
      estadoValidacion: map['estadoValidacion'] ?? '',
      metodoPago: map['metodoPago'] ?? '',
      idRecolector: map['idRecolector'] ?? '',
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
    };
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
    );
  }
}