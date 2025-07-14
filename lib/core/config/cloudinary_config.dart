class CloudinaryConfig {
  // INSTRUCCIONES PARA CONFIGURAR CLOUDINARY:
  // 1. Crea una cuenta en https://cloudinary.com
  // 2. Ve a tu Dashboard y copia tu Cloud Name
  // 3. Reemplaza 'your-cloud-name' con tu Cloud Name real
  // 4. Sube tus imágenes a Cloudinary organizadas en la carpeta 'rsunfv'
  
  static const String cloudName = 'dupkeaqnz'; // TU CLOUD NAME CONFIGURADO
  static const String baseUrl = 'https://res.cloudinary.com/$cloudName/image/upload/';
  
  // Transformaciones predefinidas para diferentes usos
  static const String carouselTransform = 'c_fill,w_2400,h_1600,q_auto,f_auto/'; // c_fill llena completamente el espacio
  static const String thumbnailTransform = 'w_300,h_300,c_fit,q_auto,f_auto/';
  static const String eventImageTransform = 'w_800,h_600,c_fit,q_auto,f_auto/';
  static const String profileImageTransform = 'w_200,h_200,c_fill,q_auto,f_auto/';
  
  // Función helper para construir URLs de Cloudinary
  static String buildUrl(String publicId, {String transform = ''}) {
    return '$baseUrl$transform$publicId';
  }
  
  // URLs específicas para el carousel - CON NUEVO FORMATO DE TRANSFORMACIÓN
  static const Map<String, String> carouselImages = {
    'voluntarios': 'v1752457968/unfv_2_f7aqs7.jpg', // Imagen 1: Voluntarios en acción
    'donaciones': 'v1752457968/unfv_4_wfmsoj.jpg',  // Imagen 2: Donaciones e impacto
    'eventos': 'v1752457968/unfv_1_gx0oa2.jpg',      // Imagen 3: Eventos comunitarios
  };
  
  // URLs de fallback (usando Unsplash como respaldo)
  static const Map<String, String> fallbackImages = {
    'voluntarios': 'https://images.unsplash.com/photo-1559027615-cd4628902d4a?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
    'donaciones': 'https://images.unsplash.com/photo-1593113598332-cd288d649433?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
    'eventos': 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
  };
  
  // Función para obtener URL completa del carousel por clave
  static String getCarouselImageUrl(String key) {
    final publicId = carouselImages[key];
    if (publicId != null) {
      return buildUrl(publicId, transform: carouselTransform);
    }
    return fallbackImages[key] ?? '';
  }
  
  // Función para obtener URL por índice (0, 1, 2)
  static String getCarouselImageUrlByIndex(int index) {
    final keys = carouselImages.keys.toList();
    if (index >= 0 && index < keys.length) {
      final key = keys[index];
      final publicId = carouselImages[key];
      if (publicId != null) {
        return buildUrl(publicId, transform: carouselTransform);
      }
    }
    // Fallback por índice
    final fallbackKeys = fallbackImages.keys.toList();
    if (index >= 0 && index < fallbackKeys.length) {
      return fallbackImages[fallbackKeys[index]] ?? '';
    }
    return '';
  }
  
  // Función para obtener URL de fallback
  static String getFallbackImageUrl(String key) {
    return fallbackImages[key] ?? '';
  }
}
