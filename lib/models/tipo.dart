class Tipo {
  final String idTipo;
  final String nombreActividad;
  final String clasificacion;
  final List<String> actividades;

  Tipo({
    required this.idTipo,
    required this.nombreActividad,
    required this.clasificacion,
    required this.actividades,
  });

  factory Tipo.fromMap(Map<String, dynamic> map) {
    return Tipo(
      idTipo: map['idTipo'] ?? '',
      nombreActividad: map['nombreActividad'] ?? '',
      clasificacion: map['clasificacion'] ?? '',
      actividades: List<String>.from(map['actividades'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idTipo': idTipo,
      'nombreActividad': nombreActividad,
      'clasificacion': clasificacion,
      'actividades': actividades,
    };
  }

  Tipo copyWith({
    String? idTipo,
    String? nombreActividad,
    String? clasificacion,
    List<String>? actividades,
  }) {
    return Tipo(
      idTipo: idTipo ?? this.idTipo,
      nombreActividad: nombreActividad ?? this.nombreActividad,
      clasificacion: clasificacion ?? this.clasificacion,
      actividades: actividades ?? this.actividades,
    );
  }
}