import 'package:firebase_auth/firebase_auth.dart';

/// Cierra la sesión del usuario actual en Firebase Auth.
Future<void> cerrarSesion() async {
  await FirebaseAuth.instance.signOut();
}