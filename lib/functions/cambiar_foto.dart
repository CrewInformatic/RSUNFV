import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import '../services/cloudinary_services.dart';

Future<String?> cambiarFotoPerfil() async {
  final logger = Logger();
  
  try {

    final picker = ImagePicker();

    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85, 
    );

    if (pickedImage == null) {
      logger.i('No image selected');
      return null;
    }

    final imageBytes = await pickedImage.readAsBytes();


    final imageUrl = await CloudinaryService.uploadImage(imageBytes);

    if (imageUrl != null) {
      logger.i('Image uploaded to Cloudinary: $imageUrl');
      return imageUrl;
    } else {
      logger.w('Failed to upload image to Cloudinary'); //Se cambio el print para evitar los avoid_prints por logger
    }

    return null;
  } catch (e) {
    logger.e('Error in cambiarFotoPerfil: $e');
    return null;
  }
}