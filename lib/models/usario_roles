class UsuarioRoles {
  final String idRoles;
  final String usuarioID;
  final String fechaAsignacion;
  final String rolID;

  UsuarioRoles({
    required this.idRoles,
    required this.usuarioID,
    required this.fechaAsignacion,
    required this.rolID,
  });

  factory UsuarioRoles.fromMap(Map<String, dynamic> map) {
    return UsuarioRoles(
      idRoles: map['idRoles'] ?? '',
      usuarioID: map['usuarioID'] ?? '',
      fechaAsignacion: map['fechaAsignacion'] ?? '',
      rolID: map['rolID'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idRoles': idRoles,
      'usuarioID': usuarioID,
      'fechaAsignacion': fechaAsignacion,
      'rolID': rolID,
    };
  }

  UsuarioRoles copyWith({
    String? idRoles,
    String? usuarioID,
    String? fechaAsignacion,
    String? rolID,
  }) {
    return UsuarioRoles(
      idRoles: idRoles ?? this.idRoles,
      usuarioID: usuarioID ?? this.usuarioID,
      fechaAsignacion: fechaAsignacion ?? this.fechaAsignacion,
      rolID: rolID ?? this.rolID,
    );
  }
}