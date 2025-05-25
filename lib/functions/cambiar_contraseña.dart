import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Cambia la contraseña del usuario en Firebase Auth y la actualiza en Firestore como hash.
/// Retorna true si fue exitoso, false si hubo error.
Future<bool> cambiarContrasena(String nuevaClave) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Cambiar contraseña en Auth
      await user.updatePassword(nuevaClave);

      // Generar hash SHA256 de la nueva contraseña
      final hash = sha256.convert(utf8.encode(nuevaClave)).toString();

      // Actualizar campo 'clave' en Firestore como hash
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .update({'clave': hash});

      return true;
    }
    return false;
  } catch (e) {
    print('Error al cambiar contraseña: $e');
    return false;
  }
}