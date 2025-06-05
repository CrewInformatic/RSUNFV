class Facultad {
  final String idFacultad;
  final String nombreFacultad;
  final String escuelaID;

  Facultad({
    required this.idFacultad,
    required this.nombreFacultad,
    required this.escuelaID,
  });

  factory Facultad.fromMap(Map<String, dynamic> map) {
    return Facultad(
      idFacultad: map['idFacultad'] ?? '',
      nombreFacultad: map['nombreFacultad'] ?? '',
      escuelaID: map['escuelaID'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idFacultad': idFacultad,
      'nombreFacultad': nombreFacultad,
      'escuelaID': escuelaID,
    };
  }

  Facultad copyWith({
    String? idFacultad,
    String? nombreFacultad,
    String? escuelaID,
  }) {
    return Facultad(
      idFacultad: idFacultad ?? this.idFacultad,
      nombreFacultad: nombreFacultad ?? this.nombreFacultad,
      escuelaID: escuelaID ?? this.escuelaID,
    );
  }
}