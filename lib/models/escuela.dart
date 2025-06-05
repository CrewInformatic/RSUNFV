class Escuela {
  final String idEscuela;
  final String idFacultad;
  final String nombreEscuela;

  Escuela({
    required this.idEscuela,
    required this.idFacultad,
    required this.nombreEscuela,
  });

  factory Escuela.fromMap(Map<String, dynamic> map) {
    return Escuela(
      idEscuela: map['idEscuela'] ?? '',
      idFacultad: map['idFacultad'] ?? '',
      nombreEscuela: map['nombreEscuela'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idEscuela': idEscuela,
      'idFacultad': idFacultad,
      'nombreEscuela': nombreEscuela,
    };
  }

  Escuela copyWith({
    String? idEscuela,
    String? idFacultad,
    String? nombreEscuela,
  }) {
    return Escuela(
      idEscuela: idEscuela ?? this.idEscuela,
      idFacultad: idFacultad ?? this.idFacultad,
      nombreEscuela: nombreEscuela ?? this.nombreEscuela,
    );
  }
}