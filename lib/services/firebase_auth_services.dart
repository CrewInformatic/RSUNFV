import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/usuario.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream de cambios en autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Verificar si hay un usuario logueado
  bool get isLoggedIn => _auth.currentUser != null;

  // Registro con email y contraseña y creación en Firestore
  Future<UserCredential?> signUpWithEmail(String email, String password, {required String nombre}) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Crear documento en la colección "usuarios"
      await _firestore.collection('usuarios').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'email': email,
        'nombre': nombre,
        'rol': 'usuario',
        'fechaRegistro': FieldValue.serverTimestamp(),
        'verificado': false,
      });

      // Enviar email de verificación
      await result.user!.sendEmailVerification();

      return result;
    } on FirebaseAuthException catch (e) {
      _logger.e('Error al registrar: ${e.message}');
      return null;
    }
  }

  // Iniciar sesión
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return result;
    } on FirebaseAuthException catch (e) {
      _logger.e('Error al iniciar sesión: ${e.message}');
      return null;
    }
  }

  // Enviar email de verificación
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      _logger.e('Error enviando verificación: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _logger.e('Error al cerrar sesión: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      _logger.e('Error al enviar recuperación: $e');
    }
  }

  // Eliminar cuenta y su documento en Firestore
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('usuarios').doc(user.uid).delete();
        await user.delete();
      }
    } catch (e) {
      _logger.e('Error al eliminar cuenta: $e');
    }
  }

  // Obtener datos del usuario desde Firestore
  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('No hay usuario autenticado');
        return null;
      }

      final docSnapshot = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (!docSnapshot.exists) {
        _logger.w('No se encontró el documento del usuario');
        return null;
      }

      return docSnapshot;
    } catch (e, stackTrace) {
      _logger.e('Error al obtener datos del usuario: $e');
      _logger.e('Stack trace: $stackTrace');
      return null;
    }
  }

  // Guardar usuario en Firestore
  Future<void> saveUsuario(Usuario usuario) async {
    await _firestore.collection('usuarios').doc(usuario.idUsuario).set(usuario.toMap());
  }

  Future<bool> cambiarPassword(String nuevaPassword) async {
  try {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Cambia la contraseña en Auth
    await user.updatePassword(nuevaPassword);

    // Guarda la fecha de cambio en Firestore (opcional)
    await _firestore.collection('usuarios').doc(user.uid).update({
      'fechaCambioPassword': FieldValue.serverTimestamp(),
    });

    return true;
  } catch (e) {
    _logger.e('Error al cambiar la contraseña: $e');
    return false;
  }
}

}
