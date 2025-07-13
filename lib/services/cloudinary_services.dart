import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class CloudinaryService {
  static final Logger _logger = Logger();
  static const String cloudName = 'dupkeaqnz';
  static const String uploadPreset = 'u5jbjfxu';
  static const String apiUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  static const String defaultAvatarUrl = 
    'https://res.cloudinary.com/dupkeaqnz/image/upload/v1750026029/awiafg8ykptmp0tzxost.gif';

  static Future<void> _updateUserProfile(String imageUrl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final fechaModificacion = DateTime.now().toIso8601String();
        
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .update({
          'fotoPerfil': imageUrl,
          'fechaModificacion': fechaModificacion,
        });
      }
    } catch (e) {
      _logger.e('Error updating user profile: $e');
      throw Exception('Failed to update profile photo');
    }
  }

  static Future<String?> uploadImage(Uint8List imageBytes) async {
    try {
      final uri = Uri.parse(apiUrl);
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
      
      _logger.w('Upload failed with status: ${response.statusCode}');
      _logger.w('Response body: ${response.body}');
      return null;

    } catch (e) {
      _logger.e('Error uploading image: $e');
      return null;
    }
  }

  // Método específico para subir vouchers sin actualizar perfil
  static Future<String?> uploadVoucher(Uint8List imageBytes) async {
    try {
      final uri = Uri.parse(apiUrl);
      final base64Image = base64Encode(imageBytes);
      
      // Generar nombre único con prefijo DON-
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicId = 'DON-$timestamp';
      
      final response = await http.post(
        uri,
        body: {
          'file': 'data:image/jpeg;base64,$base64Image',
          'upload_preset': uploadPreset,
          'public_id': publicId,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final imageUrl = jsonData['secure_url'] as String;
        return imageUrl;
      }
      
      _logger.w('Voucher upload failed with status: ${response.statusCode}');
      _logger.w('Response body: ${response.body}');
      return null;

    } catch (e) {
      _logger.e('Error uploading voucher: $e');
      return null;
    }
  }

  // Método específico para subir comprobantes de validación
  static Future<String?> uploadValidationProof(List<int> imageBytes, String validationId) async {
    try {
      final uri = Uri.parse(apiUrl);
      final base64Image = base64Encode(imageBytes);
      
      // Usar el validationId como public_id (ya incluye el prefijo VAL-)
      final publicId = validationId;
      
      final response = await http.post(
        uri,
        body: {
          'file': 'data:image/jpeg;base64,$base64Image',
          'upload_preset': uploadPreset,
          'public_id': publicId,
          'folder': 'donaciones/comprobantes/$validationId',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final imageUrl = jsonData['secure_url'] as String;
        return imageUrl;
      }
      
      _logger.w('Validation proof upload failed with status: ${response.statusCode}');
      _logger.w('Response body: ${response.body}');
      return null;

    } catch (e) {
      _logger.e('Error uploading validation proof: $e');
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