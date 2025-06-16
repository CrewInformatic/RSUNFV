import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudinaryService {
  static const String cloudName = 'dupkeaqnz';
  static const String uploadPreset = 'u5jbjfxu';
  static const String apiUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  static const String defaultAvatarUrl = 
    'https://res.cloudinary.com/dupkeaqnz/image/upload/v1750026029/awiafg8ykptmp0tzxost.gif';

  static Future<void> _updateUserProfile(String imageUrl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Crear fecha actual en formato ISO
        final fechaModificacion = DateTime.now().toIso8601String();
        
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .update({
          'fotoPerfil': imageUrl,
          'fechaModificacion': fechaModificacion, // Usar string en vez de FieldValue
        });
      }
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update profile photo');
    }
  }

  static Future<String?> uploadImage(Uint8List imageBytes) async {
    try {
      final uri = Uri.parse(apiUrl);
      
      // Convert image to base64 for web compatibility
      final base64Image = base64Encode(imageBytes);
      
      final response = await http.post(
        uri,
        body: {
          'file': 'data:image/jpeg;base64,$base64Image',
          'upload_preset': uploadPreset,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final imageUrl = jsonData['secure_url'] as String;
        await _updateUserProfile(imageUrl);
        return imageUrl;
      }
      
      print('Upload failed with status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return null;

    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  static String getProfileImageUrl(String? imageHash) {
    if (imageHash == null || imageHash.isEmpty) {
      return defaultAvatarUrl;
    }
    return 'https://res.cloudinary.com/$cloudName/image/upload/$imageHash';
  }
}