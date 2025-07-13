import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/usuario.dart';
import '../models/evento.dart';
import '../models/donaciones.dart';

class ProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtiene todos los datos del perfil de usuario de forma optimizada
  static Future<ProfileData> getProfileData() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      // Obtener datos del usuario
      final userDoc = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) throw Exception('Usuario no encontrado');
      
      final usuario = Usuario.fromFirestore(userDoc.data()!, userDoc.id);

      // Ejecutar consultas en paralelo para mayor eficiencia
      final futures = await Future.wait([
        _getEventosInscritos(usuario.idUsuario),
        _getDonacionesUsuario(usuario.idUsuario),
        _getFacultadEscuelaData(usuario),
        _getRolUsuario(usuario.idRol),
      ]);

      return ProfileData(
        usuario: usuario,
        eventosInscritos: futures[0] as List<Evento>,
        donaciones: futures[1] as List<Donaciones>,
        facultadEscuela: futures[2] as Map<String, String>,
        nombreRol: futures[3] as String,
      );

    } catch (e) {
      throw Exception('Error al cargar datos del perfil: $e');
    }
  }

  static Future<List<Evento>> getEventosInscritos(String userId) async {
    final snapshot = await _firestore
        .collection('eventos')
        .where('voluntariosInscritos', arrayContains: userId)
        .get();
    
    return snapshot.docs
        .map((doc) => Evento.fromFirestore(doc))
        .toList();
  }

  static Future<List<Donaciones>> getDonacionesUsuario(String userId) async {
    final snapshot = await _firestore
        .collection('donaciones')
        .where('idUsuarioDonador', isEqualTo: userId)
        .orderBy('fechaCreacion', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => Donaciones.fromMap({'idDonaciones': doc.id, ...doc.data()}))
        .toList();
  }

  static Future<List<Evento>> _getEventosInscritos(String userId) async {
    return getEventosInscritos(userId);
  }

  static Future<List<Donaciones>> _getDonacionesUsuario(String userId) async {
    return getDonacionesUsuario(userId);
  }

  static Future<Map<String, String>> _getFacultadEscuelaData(Usuario usuario) async {
    final futures = <Future<QuerySnapshot>>[];
    
    // Solo consultar si los IDs no están vacíos
    if (usuario.facultadID.isNotEmpty) {
      futures.add(_firestore
          .collection('facultad')
          .where('idFacultad', isEqualTo: usuario.facultadID)
          .limit(1)
          .get());
    }
    
    if (usuario.escuelaId.isNotEmpty) {
      futures.add(_firestore
          .collection('escuela')
          .where('idEscuela', isEqualTo: usuario.escuelaId)
          .limit(1)
          .get());
    }

    if (futures.isEmpty) {
      return {'facultad': 'No asignada', 'escuela': 'No asignada'};
    }

    final results = await Future.wait(futures);
    
    String facultad = 'No asignada';
    String escuela = 'No asignada';
    
    if (usuario.facultadID.isNotEmpty && results.isNotEmpty && results[0].docs.isNotEmpty) {
      final data = results[0].docs.first.data() as Map<String, dynamic>;
      facultad = data['nombreFacultad'] ?? 'No asignada';
    }
    
    if (usuario.escuelaId.isNotEmpty) {
      final escuelaIndex = usuario.facultadID.isNotEmpty ? 1 : 0;
      if (results.length > escuelaIndex && results[escuelaIndex].docs.isNotEmpty) {
        final data = results[escuelaIndex].docs.first.data() as Map<String, dynamic>;
        escuela = data['nombreEscuela'] ?? 'No asignada';
      }
    }
    
    return {'facultad': facultad, 'escuela': escuela};
  }

  static Future<String> _getRolUsuario(String rolId) async {
    if (rolId.isEmpty) return 'Usuario';
    
    final rolQuery = await _firestore
        .collection('roles')
        .where('idRol', isEqualTo: rolId)
        .limit(1)
        .get();
    
    return rolQuery.docs.isNotEmpty 
        ? (rolQuery.docs.first.data()['nombre'] ?? 'Usuario')
        : 'Usuario';
  }

  /// Actualiza las estadísticas del usuario (si el modelo lo soporta)
  static Future<void> updateEstadisticas(String userId, Map<String, dynamic> estadisticas) async {
    await _firestore
        .collection('estadisticas_usuarios')
        .doc(userId)
        .set(estadisticas, SetOptions(merge: true));
  }

  /// Obtiene las estadísticas guardadas del usuario (si existen)
  static Future<Map<String, dynamic>?> getEstadisticas(String userId) async {
    final doc = await _firestore
        .collection('estadisticas_usuarios')
        .doc(userId)
        .get();
    
    return doc.exists ? doc.data() : null;
  }
}

/// Clase para encapsular todos los datos del perfil
class ProfileData {
  final Usuario usuario;
  final List<Evento> eventosInscritos;
  final List<Donaciones> donaciones;
  final Map<String, String> facultadEscuela;
  final String nombreRol;

  ProfileData({
    required this.usuario,
    required this.eventosInscritos,
    required this.donaciones,
    required this.facultadEscuela,
    required this.nombreRol,
  });

  String get nombreFacultad => facultadEscuela['facultad'] ?? 'No asignada';
  String get nombreEscuela => facultadEscuela['escuela'] ?? 'No asignada';
}
