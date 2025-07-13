import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const List<Map<String, dynamic>> heroCarouselData = [
    {
      'title': '¡Sé el Cambio que Quieres Ver!',
      'subtitle': 'Únete a nuestra comunidad de voluntarios y crea un impacto real en la sociedad',
      'image': 'https://images.unsplash.com/photo-1559027615-cd4628902d4a?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      'gradientStart': 0xFF667eea,
      'gradientEnd': 0xFF764ba2,
      'cta': 'Ser Voluntario',
      'route': '/eventos',
    },
    {
      'title': 'Tu Donación Transforma Vidas',
      'subtitle': 'Cada contribución cuenta para construir un futuro mejor para todos',
      'image': 'https://images.unsplash.com/photo-1593113598332-cd288d649433?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      'gradientStart': 0xFFf093fb,
      'gradientEnd': 0xFFf5576c,
      'cta': 'Donar Ahora',
      'route': '/donaciones',
    },
    {
      'title': 'Eventos que Conectan',
      'subtitle': 'Participa en iniciativas que unen corazones y construyen comunidad',
      'image': 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      'gradientStart': 0xFF4facfe,
      'gradientEnd': 0xFF00f2fe,
      'cta': 'Ver Eventos',
      'route': '/eventos',
    },
  ];

  static const List<Map<String, dynamic>> fallbackImpactStats = [
    {
      'icon': Icons.people_outline,
      'value': '2,847',
      'label': 'Voluntarios Activos',
      'colorValue': 0xFF667eea
    },
    {
      'icon': Icons.favorite_outline,
      'value': '15,692',
      'label': 'Vidas Impactadas',
      'colorValue': 0xFFf5576c
    },
    {
      'icon': Icons.attach_money,
      'value': 'S/. 89,450',
      'label': 'Fondos Recaudados',
      'colorValue': 0xFF4facfe
    },
    {
      'icon': Icons.eco_outlined,
      'value': '47',
      'label': 'Proyectos Activos',
      'colorValue': 0xFF2dd4bf
    },
  ];

  static const List<Map<String, dynamic>> quickActions = [
    {
      'icon': Icons.volunteer_activism,
      'title': 'Voluntariado',
      'subtitle': 'Únete hoy',
      'colorValue': 0xFF667eea,
      'route': '/eventos',
    },
    {
      'icon': Icons.card_giftcard,
      'title': 'Donaciones',
      'subtitle': 'Ayuda ahora',
      'colorValue': 0xFFf5576c,
      'route': '/donaciones',
    },
    {
      'icon': Icons.games,
      'title': 'Juegos',
      'subtitle': 'Diviértete',
      'colorValue': 0xFF9333ea,
      'route': '/games',
    },
    {
      'icon': Icons.emoji_events,
      'title': 'Perfil',
      'subtitle': 'Tu progreso',
      'colorValue': 0xFF2dd4bf,
      'route': '/perfil',
    },
  ];

  static const Map<String, dynamic> rsuInfo = {
    'title': 'Responsabilidad Social Universitaria UNFV',
    'description': 'Promovemos el desarrollo sostenible y la responsabilidad social a través de la participación activa de la comunidad universitaria en proyectos que generen un impacto positivo en la sociedad.',
    'mission': 'Formar profesionales comprometidos con el desarrollo sostenible y la responsabilidad social.',
    'vision': 'Ser reconocidos como la universidad líder en responsabilidad social universitaria del Perú.',
    'values': [
      'Solidaridad y compromiso social',
      'Sostenibilidad ambiental',
      'Transparencia y ética',
      'Innovación y creatividad',
      'Trabajo en equipo',
    ],
    'socialLinks': {
      'facebook': 'https://www.facebook.com/unfv.oficial',
      'instagram': 'https://www.instagram.com/unfv.oficial',
      'twitter': 'https://twitter.com/unfv_oficial',
      'youtube': 'https://www.youtube.com/@UniversidadNacionalFedericoVillarreal',
    },
  };

  static const List<Map<String, dynamic>> volunteerTraits = [
    {
      'icon': Icons.favorite,
      'title': 'Empatía',
      'description': 'Capacidad de entender y compartir los sentimientos de otros',
    },
    {
      'icon': Icons.handshake,
      'title': 'Compromiso',
      'description': 'Dedicación constante para lograr objetivos comunes',
    },
    {
      'icon': Icons.lightbulb,
      'title': 'Creatividad',
      'description': 'Habilidad para encontrar soluciones innovadoras',
    },
    {
      'icon': Icons.group,
      'title': 'Trabajo en Equipo',
      'description': 'Colaboración efectiva para alcanzar metas compartidas',
    },
  ];

  static const List<Map<String, dynamic>> fallbackTestimonials = [
    {
      'name': 'Victor Santamaria',
      'role': 'Coordinador General RSU',
      'message': 'La Responsabilidad Social Universitaria nos ha permitido formar profesionales comprometidos con el desarrollo sostenible de nuestra sociedad. Cada proyecto ejecutado representa una oportunidad de transformación real.',
      'avatar': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
      'rating': 5,
    },
    {
      'name': 'Harold Ortiz Galvez',
      'role': 'Director de Proyectos Comunitarios',
      'message': 'Trabajar en RSU UNFV me ha enseñado que el verdadero impacto educativo trasciende las aulas. Nuestros estudiantes no solo aprenden, sino que transforman realidades en sus comunidades.',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
      'rating': 5,
    },
    {
      'name': 'Luis Loyola',
      'role': 'Especialista en Desarrollo Social',
      'message': 'La articulación entre universidad y sociedad que logramos a través de RSU es extraordinaria. Cada iniciativa conecta el conocimiento académico con las necesidades reales de nuestra comunidad.',
      'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
      'rating': 5,
    },
    {
      'name': 'María González',
      'role': 'Voluntaria desde 2023',
      'message': 'Participar en RSU ha cambiado mi perspectiva sobre el servicio comunitario. Cada proyecto me ha permitido crecer como persona y profesional.',
      'avatar': 'https://images.unsplash.com/photo-1494790108755-2616b612b786?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
      'rating': 5,
    },
    {
      'name': 'Carlos Mendoza',
      'role': 'Coordinador de Eventos',
      'message': 'La organización y el impacto de nuestros eventos es increíble. Ver sonrisas en las personas nos motiva a seguir adelante con más fuerza.',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
      'rating': 5,
    },
  ];

  static const String defaultProfileImageUrl = 
      'https://res.cloudinary.com/dtkjg8f0n/image/upload/v1733585404/default-avatar_cugq40.png';

  static const Duration standardAnimationDuration = Duration(milliseconds: 300);
  
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  
  static const Duration slowAnimationDuration = Duration(milliseconds: 600);

  static const int defaultPageSize = 10;
  
  static const int homeEventLimit = 6;
  
  static const int testimonialLimit = 3;
}
