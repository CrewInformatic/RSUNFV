import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import '../services/cloudinary_services.dart';

/// Permite seleccionar, subir y actualizar la foto de perfil del usuario en Firestore.
/// Guarda el hash de la imagen y la URL.
Future<void> cambiarFotoPerfil() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    final imageFile = File(pickedFile.path);

    // Leer bytes de la imagen y generar hash SHA256
    final bytes = await imageFile.readAsBytes();
    final hash = sha256.convert(bytes).toString();

    // Subir a Cloudinary
    final imageUrl = await CloudinaryService.uploadProfileImage(mobileImage: imageFile);

    if (imageUrl != null) {
      // Actualizar en Firestore: guarda la URL y el hash
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .update({
              'fotoPerfil': imageUrl,
              'fotoPerfilHash': hash,
            });
      }
    }
  }
}