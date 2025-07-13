class Escuela {
  final String idEscuela;
  final String nombreEscuela;
  final String facultadId;

  Escuela({
    required this.idEscuela,
    required this.nombreEscuela,
    required this.facultadId,
  });

  factory Escuela.fromMap(Map<String, dynamic> map) {
    return Escuela(
      idEscuela: map['idEscuela'] ?? '',
      nombreEscuela: map['nombreEscuela'] ?? '',
      facultadId: map['facultadId'] ?? map['facultad'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idEscuela': idEscuela,
      'nombreEscuela': nombreEscuela,
      'facultad': facultadId,
    };
  }
}
