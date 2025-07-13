class Validacion {
  final String validationId;
  final String donationId;
  final String proofUrl;
  final bool isValidated;
  final String createdAt;
  final String updatedAt;
  final String? validatedAt;
  final String? validatedBy;
  final String? adminNotes;
  final String? imagenComprobante; // Campo principal para comprobante de validación
  
  // Campos adicionales para mejor trazabilidad
  final String? tipoValidacion;
  final String? metodoValidacion;
  final String? estadoComprobante;
  final String? fechaSubidaComprobante;

  Validacion({
    this.validationId = "",
    this.donationId = "",
    this.proofUrl = "",
    this.isValidated = false,
    this.createdAt = "",
    this.updatedAt = "",
    this.validatedAt,
    this.validatedBy,
    this.adminNotes,
    this.imagenComprobante,
    this.tipoValidacion,
    this.metodoValidacion,
    this.estadoComprobante,
    this.fechaSubidaComprobante,
  });

  factory Validacion.fromMap(Map<String, dynamic> map) {
    return Validacion(
      validationId: map['validationId'] ?? '',
      donationId: map['donationId'] ?? '',
      proofUrl: map['proofUrl'] ?? '',
      isValidated: map['isValidated'] ?? false,
      createdAt: map['createdAt'] ?? '',
      updatedAt: map['updatedAt'] ?? '',
      validatedAt: map['validatedAt'],
      validatedBy: map['validatedBy'],
      adminNotes: map['adminNotes'],
      imagenComprobante: map['Imagen_Comprobante'],
      tipoValidacion: map['tipoValidacion'],
      metodoValidacion: map['metodoValidacion'],
      estadoComprobante: map['estadoComprobante'],
      fechaSubidaComprobante: map['fechaSubidaComprobante'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'validationId': validationId,
      'donationId': donationId,
      'proofUrl': proofUrl,
      'isValidated': isValidated,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'validatedAt': validatedAt,
      'validatedBy': validatedBy,
      'adminNotes': adminNotes,
      'Imagen_Comprobante': imagenComprobante,
      'tipoValidacion': tipoValidacion,
      'metodoValidacion': metodoValidacion,
      'estadoComprobante': estadoComprobante,
      'fechaSubidaComprobante': fechaSubidaComprobante,
    };
  }

  Validacion copyWith({
    String? validationId,
    String? donationId,
    String? proofUrl,
    bool? isValidated,
    String? createdAt,
    String? updatedAt,
    String? validatedAt,
    String? validatedBy,
    String? adminNotes,
    String? imagenComprobante,
    String? tipoValidacion,
    String? metodoValidacion,
    String? estadoComprobante,
    String? fechaSubidaComprobante,
  }) {
    return Validacion(
      validationId: validationId ?? this.validationId,
      donationId: donationId ?? this.donationId,
      proofUrl: proofUrl ?? this.proofUrl,
      isValidated: isValidated ?? this.isValidated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      validatedAt: validatedAt ?? this.validatedAt,
      validatedBy: validatedBy ?? this.validatedBy,
      adminNotes: adminNotes ?? this.adminNotes,
      imagenComprobante: imagenComprobante ?? this.imagenComprobante,
      tipoValidacion: tipoValidacion ?? this.tipoValidacion,
      metodoValidacion: metodoValidacion ?? this.metodoValidacion,
      estadoComprobante: estadoComprobante ?? this.estadoComprobante,
      fechaSubidaComprobante: fechaSubidaComprobante ?? this.fechaSubidaComprobante,
    );
  }
}