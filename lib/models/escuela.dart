import 'package:cloud_firestore/cloud_firestore.dart';

class Escuela {
  final String idEscuela;
  final String nombre;
  final String descripcion;
  final String facultadID;
  final bool estadoActivo;

  Escuela({
    required this.idEscuela,
    required this.nombre,
    required this.descripcion,
    required this.facultadID,
    required this.estadoActivo,
  });

  // Crear un objeto desde un mapa (por ejemplo, de Firestore)
  factory Escuela.fromMap(Map<String, dynamic> map) {
    return Escuela(
      idEscuela: map['idEscuela'] ?? '',
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      facultadID: map['facultadID'] ?? '',
      estadoActivo: map['estadoActivo'] ?? true,
    );
  }

  // Crear un objeto desde un DocumentSnapshot de Firestore
  factory Escuela.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Escuela(
      idEscuela: doc.id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      facultadID: data['facultadID'] ?? '',
      estadoActivo: data['estadoActivo'] ?? true,
    );
  }

  // Convertir el objeto a un mapa (para guardar en Firestore)
  Map<String, dynamic> toMap() {
    return {
      'idEscuela': idEscuela,
      'nombre': nombre,
      'descripcion': descripcion,
      'facultadID': facultadID,
      'estadoActivo': estadoActivo,
    };
  }
}