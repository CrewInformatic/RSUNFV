import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/facultad.dart';
import '../models/escuela.dart';

class SetupService {
  static final SetupService _instance = SetupService._internal();
  factory SetupService() => _instance;
  SetupService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  

  static const String _facultadesCollection = 'facultad';
  static const String _escuelasCollection = 'escuela';
  static const String _usuariosCollection = 'usuarios';

  // Obtener facultades
  Future<List<Facultad>> getFacultades() async {
    try {
      final snapshot = await _firestore.collection(_facultadesCollection).get();
      _logger.i('Facultades encontradas: ${snapshot.docs.length}');
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Facultad.fromMap({
          'idFacultad': data['idFacultad'] ?? doc.id,
          'nombreFacultad': data['nombreFacultad'] ?? '',
        });
      }).toList();
    } catch (e) {
      _logger.e('Error obteniendo facultades: $e');
      throw Exception('Error al cargar las facultades: $e');
    }
  }

  // Obtener escuelas por facultad
  Future<List<Escuela>> getEscuelasByFacultad(String facultadId) async {
    try {
      _logger.i('Buscando escuelas para facultad: $facultadId');
      
      final snapshot = await _firestore
          .collection(_escuelasCollection)
          .where('facultad', isEqualTo: facultadId) 
          .get();
      
      _logger.i('Documentos encontrados: ${snapshot.docs.length}');
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        _logger.d('Datos de escuela: $data');
        
        return Escuela.fromMap({
          'idEscuela': data['idEscuela'] ?? doc.id,
          'nombreEscuela': data['nombreEscuela'] ?? '',
          'facultadId': data['facultad'] ?? '',
        });
      }).toList();
    } catch (e) {
      _logger.e('Error obteniendo escuelas: $e');
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
      await _firestore.collection(_usuariosCollection).doc(userId).update({
        'facultadID': facultadId,
        'escuelaId': escuelaId,
        'fechaModificacion': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('Error actualizando usuario: $e');
      throw Exception('Error al actualizar los datos del usuario: $e');
    }
  }
}