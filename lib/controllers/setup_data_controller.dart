import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/usuario.dart';
import '../models/facultad.dart';
import '../models/escuela.dart';
import '../services/setup_service.dart';

class SetupDataController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SetupService _setupService = SetupService();
  bool isInitialized = false;

  // Usuario con valores por defecto
  Usuario usuario;

  // Constructor con inicialización
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
    medallasID: '',
  );

  // Método de inicialización asíncrono
  Future<void> init() async {
    if (isInitialized) return;
    
    try {
      await initUser();
      isInitialized = true;
    } catch (e) {
      print('Error en init(): $e');
      throw Exception('Error al inicializar controlador: $e');
    }
  }

  // Método para verificar inicialización
  void checkInitialized() {
    if (!isInitialized) {
      throw Exception('Controller no inicializado. Llama a init() primero.');
    }
  }

  // Inicializar usuario con valores por defecto
  Future<void> initUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      final docSnapshot = await _firestore.collection('usuarios').doc(user.uid).get();
      
      if (!docSnapshot.exists) {
        // Si no existe el documento, crearlo con datos básicos
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
          medallasID: '',
        );
        await _firestore.collection('usuarios').doc(user.uid).set(usuario.toMap());
      } else {
        // Si existe, cargar datos
        usuario = Usuario.fromMap(docSnapshot.data() as Map<String, dynamic>);
      }
      
      isInitialized = true;
    } catch (e) {
      print('Error initializing user: $e');
      throw Exception('Error al inicializar usuario: $e');
    }
  }

  // Guardar cambios
  Future<bool> saveUserData() async {
    try {
      if (!isInitialized) throw Exception('Controller no inicializado');
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .update(usuario.toMap());
      return true;
    } catch (e) {
      print('Error saving user data: $e');
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
      escuelaId: escuelaId, // Añadir esta línea
    );
  }

  // Métodos de actualización con verificación
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
    } catch (e) {
      print('Error actualizando ciclo: $e');
      throw Exception('Error al actualizar el ciclo');
    }
  }

  void updateTalla(String tallaId) {
    checkInitialized();
    usuario = usuario.copyWith(poloTallaID: tallaId);
  }
}