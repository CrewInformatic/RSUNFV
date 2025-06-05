class Talla {
  final String idTalla;
  final String nombreTalla;
  final String medidas;

  Talla({
    required this.idTalla,
    required this.nombreTalla,
    required this.medidas,
  });

  factory Talla.fromMap(Map<String, dynamic> map) {
    return Talla(
      idTalla: map['idTalla'] ?? '',
      nombreTalla: map['nombreTalla'] ?? '',
      medidas: map['medidas'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idTalla': idTalla,
      'nombreTalla': nombreTalla,
      'medidas': medidas,
    };
  }

  Talla copyWith({
    String? idTalla,
    String? nombreTalla,
    String? medidas,
  }) {
    return Talla(
      idTalla: idTalla ?? this.idTalla,
      nombreTalla: nombreTalla ?? this.nombreTalla,
      medidas: medidas ?? this.medidas,
    );
  }
}