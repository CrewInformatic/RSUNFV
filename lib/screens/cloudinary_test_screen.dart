import 'package:flutter/material.dart';
import '../core/config/cloudinary_config.dart';
import '../widgets/cloudinary_image.dart';

class CloudinaryTestScreen extends StatelessWidget {
  const CloudinaryTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de Cloudinary'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración actual de Cloudinary:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cloud Name: ${CloudinaryConfig.cloudName}'),
                  Text('Base URL: ${CloudinaryConfig.baseUrl}'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text(
              'Test de imágenes del carousel:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _buildImageTest('Voluntarios', 'voluntarios'),
            const SizedBox(height: 16),
            _buildImageTest('Donaciones', 'donaciones'),
            const SizedBox(height: 16),
            _buildImageTest('Eventos', 'eventos'),
            
            const SizedBox(height: 24),
            const Text(
              'URLs generadas:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Voluntarios:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    CloudinaryConfig.getCarouselImageUrl('voluntarios'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  const Text('Donaciones:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    CloudinaryConfig.getCarouselImageUrl('donaciones'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  const Text('Eventos:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    CloudinaryConfig.getCarouselImageUrl('eventos'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📝 Instrucciones:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('1. Si ves "your-cloud-name" arriba, necesitas configurar CloudinaryConfig.cloudName'),
                  Text('2. Si las imágenes no cargan, verifica que hayas subido las imágenes con los nombres correctos'),
                  Text('3. Las imágenes de fallback (Unsplash) deberían cargar siempre'),
                  Text('4. Revisa CLOUDINARY_SETUP.md para instrucciones detalladas'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTest(String title, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CloudinaryImage(
              cloudinaryUrl: CloudinaryConfig.getCarouselImageUrl(key),
              fallbackUrl: CloudinaryConfig.getFallbackImageUrl(key),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}
