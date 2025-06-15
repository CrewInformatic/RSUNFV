import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/facultad.dart';
import '../models/escuela.dart';

class SetupService {
  static final SetupService _instance = SetupService._internal();
  factory SetupService() => _instance;
  SetupService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Nombres correctos de las colecciones
  static const String _facultadesCollection = 'facultad';
  static const String _escuelasCollection = 'escuela';
  static const String _usuariosCollection = 'usuarios';

  // Obtener facultades
  Future<List<Facultad>> getFacultades() async {
    try {
      final snapshot = await _firestore.collection(_facultadesCollection).get();
      print('Facultades encontradas: ${snapshot.docs.length}');
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Facultad.fromMap({
          'idFacultad': data['idFacultad'] ?? doc.id,
          'nombreFacultad': data['nombreFacultad'] ?? '',
        });
      }).toList();
    } catch (e) {
      print('Error obteniendo facultades: $e');
      throw Exception('Error al cargar las facultades: $e');
    }
  }

  // Obtener escuelas por facultad
  Future<List<Escuela>> getEscuelasByFacultad(String facultadId) async {
    try {
      print('Buscando escuelas para facultad: $facultadId');
      
      final snapshot = await _firestore
          .collection('escuela')
          .where('facultad', isEqualTo: facultadId) // Cambiado de facultadId a facultad
          .get();
      
      print('Documentos encontrados: ${snapshot.docs.length}');
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        print('Datos de escuela: $data'); // Debug
        
        return Escuela.fromMap({
          'idEscuela': data['idEscuela'] ?? doc.id,
          'nombreEscuela': data['nombreEscuela'] ?? '',
          'facultadId': data['facultad'] ?? '', // Cambiado de facultadId a facultad
        });
      }).toList();
    } catch (e) {
      print('Error obteniendo escuelas: $e');
      throw Exception('Error al cargar las escuelas: $e');
    }
  }

  // Actualizar usuario con facultad y escuela seleccionadas
  Future<void> updateUserSetup({
    required String userId,
    required String facultadId,
    required String escuelaId,
  }) async {
    try {
      await _firestore.collection('usuarios').doc(userId).update({
        'facultadID': facultadId,
        'escuelaId': escuelaId,
        'fechaModificacion': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error actualizando usuario: $e');
      throw Exception('Error al actualizar los datos del usuario: $e');
    }
  }
}