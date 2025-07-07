import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/usuario.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isLoggedIn => _auth.currentUser != null;
  Future<UserCredential?> signUpWithEmail(String email, String password, {required String nombre}) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _firestore.collection('usuarios').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'email': email,
        'nombre': nombre,
        'rol': 'usuario',
        'fechaRegistro': FieldValue.serverTimestamp(),
        'verificado': false,
      });
      await result.user!.sendEmailVerification();

      return result;
    } on FirebaseAuthException catch (e) {
      _logger.e('Error al registrar: ${e.message}');
      return null;
    }
  }
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
  Future<void> saveUsuario(Usuario usuario) async {
    await _firestore.collection('usuarios').doc(usuario.idUsuario).set(usuario.toMap());
  }

  Future<bool> cambiarPassword(String nuevaPassword) async {
  try {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.updatePassword(nuevaPassword);
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
