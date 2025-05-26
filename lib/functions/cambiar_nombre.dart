import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> cambiarNombre(String nuevoNombre) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Cambia el displayName en Firebase Auth
    await user.updateDisplayName(nuevoNombre);

    // Actualiza el nombre en Firestore (ajusta la colección si es necesario)
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .update({'nombre': nuevoNombre});

    return true;
  } catch (e) {
    print('Error al cambiar el nombre: $e');
    return false;
  }
}