class Validacion {
  final String idValidacion;
  final String numeroOperacion;
  final String imagenComprobante;
  final String comentario;

  Validacion({
    this.idValidacion = "",
    this.numeroOperacion = "",
    this.imagenComprobante = "",
    this.comentario = "",
  });

  factory Validacion.fromMap(Map<String, dynamic> map) {
    return Validacion(
      idValidacion: map['idValidacion'] ?? '',
      numeroOperacion: map['numeroOperacion'] ?? '',
      imagenComprobante: map['imagenComprobante'] ?? '',
      comentario: map['comentario'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idValidacion': idValidacion,
      'numeroOperacion': numeroOperacion,
      'imagenComprobante': imagenComprobante,
      'comentario': comentario,
    };
  }

  Validacion copyWith({
    String? idValidacion,
    String? numeroOperacion,
    String? imagenComprobante,
    String? comentario,
  }) {
    return Validacion(
      idValidacion: idValidacion ?? this.idValidacion,
      numeroOperacion: numeroOperacion ?? this.numeroOperacion,
      imagenComprobante: imagenComprobante ?? this.imagenComprobante,
      comentario: comentario ?? this.comentario,
    );
  }
}