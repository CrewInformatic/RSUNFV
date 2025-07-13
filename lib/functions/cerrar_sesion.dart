import 'package:firebase_auth/firebase_auth.dart';

Future<void> cerrarSesion() async {
  await FirebaseAuth.instance.signOut();
}