import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart'; 

FirebaseFirestore db = FirebaseFirestore.instance;

/// Obtener todos los usuarios
Future<List<Usuario>> getAllUsuarios() async {
  List<Usuario> usuarios = [];
  QuerySnapshot snapshot = await db.collection('usuarios').get();

  for (var doc in snapshot.docs) {
    usuarios.add(Usuario.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
  }

  return usuarios;
}

/// Obtener usuario por ID
Future<Usuario?> getUsuarioById(String id) async {
  DocumentSnapshot doc = await db.collection('usuarios').doc(id).get();
  if (doc.exists) {
    return Usuario.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
  }
  return null;
}

/// Obtener usuarios por rol
Future<List<Usuario>> getUsuariosByRol(String rol) async {
  List<Usuario> usuarios = [];
  QuerySnapshot snapshot = await db.collection('usuarios').where('rol', isEqualTo: rol).get();

  for (var doc in snapshot.docs) {
    usuarios.add(Usuario.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
  }

  return usuarios;
}

/// Agregar un nuevo usuario
Future<void> addUsuario(Usuario usuario) async {
  await db.collection('usuarios').add(usuario.toMap());
}

/// Actualizar usuario existente
Future<void> updateUsuario(String id, Usuario usuario) async {
  await db.collection('usuarios').doc(id).update(usuario.toMap());
}

/// Eliminar usuario
Future<void> deleteUsuario(String id) async {
  await db.collection('usuarios').doc(id).delete();
}
