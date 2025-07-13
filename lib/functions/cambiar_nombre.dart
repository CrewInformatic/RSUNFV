import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

Future<bool> cambiarNombre(String nuevoNombre) async {
  final logger = Logger();
  
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    await user.updateDisplayName(nuevoNombre);

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)     
        .update({'nombre': nuevoNombre});

    return true;
  } catch (e) {
    logger.e('Error al cambiar el nombre: $e');
    return false;
  }
}
