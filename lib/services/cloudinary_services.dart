import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  static const String _cloudName = 'dupkeaqnz';   // PROTEGER CREDENCIALES EN PRODUCCIÓN
  static const String _uploadPreset = 'u5jbjfxu';

  /// Sube una imagen a Cloudinary y retorna la URL pública.
  static Future<String?> uploadProfileImage({File? mobileImage, Uint8List? webImage}) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', url);

      request.fields['upload_preset'] = _uploadPreset;

      if (kIsWeb && webImage != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          webImage,
          filename: 'profile.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      } else if (mobileImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          mobileImage.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      } else {
        throw Exception('No se seleccionó ninguna imagen');
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final resBody = await http.Response.fromStream(response);
        final Map<String, dynamic> data = json.decode(resBody.body);

        if (!data.containsKey('secure_url')) {
          throw Exception('La respuesta de Cloudinary no contiene secure_url');
        }

        return data['secure_url'];
      } else {
        throw Exception('Error al subir la imagen: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error al conectar con Cloudinary: $e');
    }
  }
}