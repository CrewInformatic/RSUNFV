import 'package:cloud_firestore/cloud_firestore.dart';
import 'escuela.dart';

class Facultad {
  final String idFacultad;
  final String nombreFacultad;

  Facultad({
    required this.idFacultad,
    required this.nombreFacultad,
  });

  factory Facultad.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Facultad(
      idFacultad: doc.id,
      nombreFacultad: data['nombreFacultad'] ?? '',
    );
  }

  factory Facultad.fromMap(Map<String, dynamic> map) {
    return Facultad(
      idFacultad: map['idFacultad'] ?? '',
      nombreFacultad: map['nombreFacultad'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idFacultad': idFacultad,
      'nombreFacultad': nombreFacultad,
    };
  }
}
