class Medallas {
  final String medallasID;
  final String nombreMedallas;
  final String calificacionNec;
  final String descMedalla;

  Medallas({
    required this.medallasID,
    required this.nombreMedallas,
    required this.calificacionNec,
    required this.descMedalla,
  });

  factory Medallas.fromMap(Map<String, dynamic> map) {
    return Medallas(
      medallasID: map['medallasID'] ?? '',
      nombreMedallas: map['nombreMedallas'] ?? '',
      calificacionNec: map['calificacionNec'] ?? '',
      descMedalla: map['descMedalla'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medallasID': medallasID,
      'nombreMedallas': nombreMedallas,
      'calificacionNec': calificacionNec,
      'descMedalla': descMedalla,
    };
  }

  Medallas copyWith({
    String? medallasID,
    String? nombreMedallas,
    String? calificacionNec,
    String? descMedalla,
  }) {
    return Medallas(
      medallasID: medallasID ?? this.medallasID,
      nombreMedallas: nombreMedallas ?? this.nombreMedallas,
      calificacionNec: calificacionNec ?? this.calificacionNec,
      descMedalla: descMedalla ?? this.descMedalla,
    );
  }
}