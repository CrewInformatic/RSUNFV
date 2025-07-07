import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/usuario.dart';
import '../models/facultad.dart';
import '../models/escuela.dart';
import '../services/setup_service.dart';

class SetupDataController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SetupService _setupService = SetupService();
  final Logger _logger = Logger();
  bool isInitialized = false;

  Usuario usuario;

  SetupDataController() : usuario = Usuario(
    idUsuario: '',
    nombreUsuario: '',
    apellidoUsuario: '',
    codigoUsuario: '',
    fotoPerfil: '',
    correo: '',
    fechaNacimiento: '',
    poloTallaID: '',
    esAdmin: false,
    facultadID: '',
    estadoActivo: true,
    ciclo: '',
    edad: 0,
    medallasIDs: [],
  );

  Future<void> init() async {
    if (isInitialized) return;
    
    try {
      await initUser();
      isInitialized = true;
    } catch (e) {
      _logger.e('Error en init()', error: e);
      throw Exception('Error al inicializar controlador: $e'); //Se cambio el print para evitar los avoid_prints por logger
    }
  }

  void checkInitialized() {
    if (!isInitialized) {
      throw Exception('Controller no inicializado. Llama a init() primero.');
    }
  }

  Future<void> initUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      final docSnapshot = await _firestore.collection('usuarios').doc(user.uid).get();
      
      if (!docSnapshot.exists) {
        usuario = Usuario(
          idUsuario: user.uid,
          nombreUsuario: user.displayName ?? '',
          correo: user.email ?? '',
          codigoUsuario: '',
          fotoPerfil: '',
          fechaNacimiento: '',
          poloTallaID: '',
          esAdmin: false,
          facultadID: '',
          estadoActivo: true,
          ciclo: '',
          edad: 0,
          medallasIDs: [],
        );
        await _firestore.collection('usuarios').doc(user.uid).set(usuario.toMap());
        _logger.i('Nuevo usuario creado: ${user.uid}'); 
      } else {
        usuario = Usuario.fromMap(docSnapshot.data() as Map<String, dynamic>);
        _logger.d('Usuario existente cargado: ${user.uid}'); 
      }
      
      isInitialized = true;
    } catch (e) {
      _logger.e('Error al inicializar usuario', error: e);
      throw Exception('Error al inicializar usuario: $e');
    }
  }

  Future<bool> saveUserData() async {
    try {
      if (!isInitialized) throw Exception('Controller no inicializado');
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .update(usuario.toMap());
      _logger.i('Datos de usuario actualizados: ${user.uid}'); 
      return true;
    } catch (e) {
      _logger.e('Error al guardar datos del usuario', error: e);
      return false;
    }
  }

  Future<List<Facultad>> getFacultades() async {
    return await _setupService.getFacultades();
  }

  Future<List<Escuela>> getEscuelasByFacultad(String facultadId) async {
    return await _setupService.getEscuelasByFacultad(facultadId);
  }

  Future<void> updateFacultadEscuela(String facultadId, String escuelaId) async {
    if (usuario.idUsuario.isEmpty) {
      throw Exception('Usuario no inicializado');
    }
    
    await _setupService.updateUserSetup(
      userId: usuario.idUsuario,
      facultadId: facultadId,
      escuelaId: escuelaId,
    );
    
    usuario = usuario.copyWith(
      facultadID: facultadId,
      escuelaId: escuelaId,
    );
  }

  void updateCodigo(String codigo) {
    checkInitialized();
    usuario = usuario.copyWith(codigoUsuario: codigo);
  }

  void updateEdad(int edad) {
    checkInitialized();
    usuario = usuario.copyWith(edad: edad);
  }

  void updateFacultad(String facultadId) {
    checkInitialized();
    usuario = usuario.copyWith(facultadID: facultadId);
  }

  void updateCiclo(String ciclo) async {
    try {
      usuario = usuario.copyWith(
        ciclo: ciclo,
        fechaModificacion: DateTime.now().toIso8601String(),
      );
      _logger.i('Ciclo actualizado a: $ciclo'); // Changed from print
    } catch (e) {
      _logger.e('Error al actualizar ciclo', error: e);
      throw Exception('Error al actualizar el ciclo');
    }
  }

  void updateTalla(String tallaId) {
    checkInitialized();
    usuario = usuario.copyWith(poloTallaID: tallaId);
  }
}