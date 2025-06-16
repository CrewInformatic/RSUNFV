import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_services.dart';

Future<String?> cambiarFotoPerfil() async {
  try {
    // Initialize image picker
    final picker = ImagePicker();
    
    // Pick image from gallery
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // Optimize image size
      maxHeight: 800,
      imageQuality: 85, // Slightly compress
    );

    if (pickedImage == null) {
      print('No image selected');
      return null;
    }

    // Read image as bytes
    final imageBytes = await pickedImage.readAsBytes();

    // Upload to Cloudinary
    final imageUrl = await CloudinaryService.uploadImage(imageBytes);

    if (imageUrl != null) {
      print('Image uploaded to Cloudinary: $imageUrl');
      return imageUrl;
    } else {
      print('Failed to upload image to Cloudinary');
    }

    return null;
  } catch (e) {
    print('Error in cambiarFotoPerfil: $e');
    return null;
  }
}