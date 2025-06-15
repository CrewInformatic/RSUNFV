import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  static const String cloudName = 'dupkeaqnz';
  static const String uploadPreset = 'u5jbjfxu';
  static const String apiUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  static Future<String?> uploadProfileImage(File imageFile, {String? fileName}) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['upload_preset'] = uploadPreset;
      
      // Si tenemos un fileName (hash), lo usamos como public_id
      if (fileName != null) {
        request.fields['public_id'] = fileName;
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonData = json.decode(responseString);

      if (response.statusCode == 200) {
        return jsonData['secure_url'];
      } else {
        throw Exception('Error en la respuesta: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }

  static String getImageUrl(String hash) {
    return 'https://res.cloudinary.com/$cloudName/image/upload/$hash';
  }
}