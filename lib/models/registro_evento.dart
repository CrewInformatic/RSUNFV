import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroEvento {
  final String idRegistro;
  final String idEvento;
  final String idUsuario;
  final String fechaRegistro;

  RegistroEvento({
    required this.idRegistro,
    required this.idEvento,
    required this.idUsuario,
    required this.fechaRegistro,
  });

  factory RegistroEvento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RegistroEvento(
      idRegistro: doc.id,
      idEvento: data['idEvento']?.toString() ?? '',
      idUsuario: data['idUsuario']?.toString() ?? '',
      fechaRegistro: data['fechaRegistro']?.toString() ?? '',
    );
  }

  factory RegistroEvento.fromMap(Map<String, dynamic> map) {
    return RegistroEvento(
      idRegistro: map['idRegistro']?.toString() ?? '',
      idEvento: map['idEvento']?.toString() ?? '',
      idUsuario: map['idUsuario']?.toString() ?? '',
      fechaRegistro: map['fechaRegistro']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idRegistro': idRegistro,
      'idEvento': idEvento,
      'idUsuario': idUsuario,
      'fechaRegistro': fechaRegistro,
    };
  }
}
