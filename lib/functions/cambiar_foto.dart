import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cloudinary_services.dart';

Future<String?> cambiarFotoPerfil() async {
  try {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, 
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      
      // Subir imagen a Cloudinary y obtener URL
      final String? imageUrl = await CloudinaryService.uploadProfileImage(
        imageFile,
      );

      if (imageUrl != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Guardar URL directamente
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .update({
            'fotoPerfil': imageUrl,
          });
          
          return imageUrl;
        }
      }
    }
    return null;
  } catch (e) {
    print('Error al cambiar foto: $e');
    return null;
  }
}