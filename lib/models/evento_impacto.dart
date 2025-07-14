class EventoImpacto {
  final String idEvento;
  final int personasAyudadas;
  final int plantasPlantadas;
  final double basuraRecolectadaKg;
  final Map<String, dynamic> metricasPersonalizadas;
  final DateTime fechaRegistro;
  final String registradoPor; // ID del usuario administrador

  EventoImpacto({
    required this.idEvento,
    this.personasAyudadas = 0,
    this.plantasPlantadas = 0,
    this.basuraRecolectadaKg = 0.0,
    this.metricasPersonalizadas = const {},
    required this.fechaRegistro,
    required this.registradoPor,
  });

  factory EventoImpacto.fromFirestore(Map<String, dynamic> data) {
    return EventoImpacto(
      idEvento: data['idEvento'] ?? '',
      personasAyudadas: data['personasAyudadas'] ?? 0,
      plantasPlantadas: data['plantasPlantadas'] ?? 0,
      basuraRecolectadaKg: (data['basuraRecolectadaKg'] ?? 0.0).toDouble(),
      metricasPersonalizadas: Map<String, dynamic>.from(data['metricasPersonalizadas'] ?? {}),
      fechaRegistro: DateTime.parse(data['fechaRegistro'] ?? DateTime.now().toIso8601String()),
      registradoPor: data['registradoPor'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'idEvento': idEvento,
      'personasAyudadas': personasAyudadas,
      'plantasPlantadas': plantasPlantadas,
      'basuraRecolectadaKg': basuraRecolectadaKg,
      'metricasPersonalizadas': metricasPersonalizadas,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'registradoPor': registradoPor,
    };
  }

  EventoImpacto copyWith({
    String? idEvento,
    int? personasAyudadas,
    int? plantasPlantadas,
    double? basuraRecolectadaKg,
    Map<String, dynamic>? metricasPersonalizadas,
    DateTime? fechaRegistro,
    String? registradoPor,
  }) {
    return EventoImpacto(
      idEvento: idEvento ?? this.idEvento,
      personasAyudadas: personasAyudadas ?? this.personasAyudadas,
      plantasPlantadas: plantasPlantadas ?? this.plantasPlantadas,
      basuraRecolectadaKg: basuraRecolectadaKg ?? this.basuraRecolectadaKg,
      metricasPersonalizadas: metricasPersonalizadas ?? this.metricasPersonalizadas,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      registradoPor: registradoPor ?? this.registradoPor,
    );
  }
}
