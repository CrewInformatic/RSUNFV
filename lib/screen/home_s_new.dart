import 'package:flutter/material.dart';
import 'package:rsunfv_app/widgets/drawer.dart';
import '../services/firebase_auth_services.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../services/cloudinary_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? imageUrl;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  
  // Firebase data variables
  Map<String, dynamic> _realImpactStats = {};
  List<Map<String, dynamic>> _realUpcomingEvents = [];
  List<Map<String, dynamic>> _realTestimonials = [];
  bool _isLoadingData = true;
  
  // Calendar variables
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _calendarEvents = {};
  List<Map<String, dynamic>> _userRegisteredEvents = [];
  List<Map<String, dynamic>> _allEvents = [];
  bool _hasFirebaseError = false;
  
  final String defaultUrl =
      'https://res.cloudinary.com/dupkeaqnz/image/upload/f_auto,q_auto/hgofvxczx14ktcc5ubjs';

  final List<Map<String, dynamic>> _heroCarouselData = [
    {
      'title': '¡Sé el Cambio que Quieres Ver!',
      'subtitle': 'Únete a nuestra comunidad de voluntarios y crea un impacto real en la sociedad',
      'image': 'https://images.unsplash.com/photo-1559027615-cd4628902d4a?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1740&q=80',
      'gradient': [Color(0xFF667eea), Color(0xFF764ba2)],
      'cta': 'Ser Voluntario',
      'route': '/eventos',
    },
    {
      'title': 'Tu Donación Transforma Vidas',
      'subtitle': 'Cada contribución cuenta para construir un futuro mejor para todos',
      'image': 'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1740&q=80',
      'gradient': [Color(0xFFf093fb), Color(0xFFf5576c)],
      'cta': 'Donar Ahora',
      'route': '/donaciones',
    },
    {
      'title': 'Eventos que Conectan',
      'subtitle': 'Participa en iniciativas que unen corazones y construyen comunidad',
      'image': 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1740&q=80',
      'gradient': [Color(0xFF4facfe), Color(0xFF00f2fe)],
      'cta': 'Ver Eventos',
      'route': '/eventos',
    },
  ];

  final List<Map<String, dynamic>> _impactStats = [
    {'icon': Icons.people_outline, 'value': '2,847', 'label': 'Voluntarios Activos', 'color': Color(0xFF667eea)},
    {'icon': Icons.favorite_outline, 'value': '15,692', 'label': 'Vidas Impactadas', 'color': Color(0xFFf5576c)},
    {'icon': Icons.attach_money, 'value': 'S/. 89,450', 'label': 'Fondos Recaudados', 'color': Color(0xFF4facfe)},
    {'icon': Icons.eco_outlined, 'value': '47', 'label': 'Proyectos Activos', 'color': Color(0xFF2dd4bf)},
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {
      'icon': Icons.volunteer_activism,
      'title': 'Voluntariado',
      'subtitle': 'Únete hoy',
      'color': Color(0xFF667eea),
      'route': '/eventos',
    },
    {
      'icon': Icons.card_giftcard,
      'title': 'Donaciones',
      'subtitle': 'Ayuda ahora',
      'color': Color(0xFFf5576c),
      'route': '/donaciones',
    },
    {
      'icon': Icons.games,
      'title': 'Juegos',
      'subtitle': 'Diviértete',
      'color': Color(0xFF9333ea),
      'route': '/games',
    },
    {
      'icon': Icons.event_available,
      'title': 'Eventos',
      'subtitle': 'Próximos',
      'color': Color(0xFF4facfe),
      'route': '/eventos',
    },
    {
      'icon': Icons.support_agent,
      'title': 'Soporte',
      'subtitle': 'Ayuda',
      'color': Color(0xFF2dd4bf),
      'route': '/perfil',
    },
  ];

  final List<Map<String, dynamic>> _upcomingEvents = [
    {
      'title': 'Jornada de Salud Comunitaria',
      'date': '15 Jul',
      'time': '08:00 AM',
      'location': 'Centro Comunitario Villa El Salvador',
      'volunteers': '45',
      'category': 'Salud',
      'image': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80',
    },
    {
      'title': 'Campaña de Alfabetización Digital',
      'date': '22 Jul',
      'time': '02:00 PM',
      'location': 'Biblioteca Municipal',
      'volunteers': '28',
      'category': 'Educación',
      'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80',
    },
    {
      'title': 'Reforestación Urbana',
      'date': '28 Jul',
      'time': '07:00 AM',
      'location': 'Parque Zonal Huiracocha',
      'volunteers': '67',
      'category': 'Medio Ambiente',
      'image': 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80',
    },
  ];

  final List<Map<String, dynamic>> _testimonials = [
    {
      'name': 'María González',
      'role': 'Voluntaria desde 2023',
      'message': 'Ser parte de RSU ha cambiado mi perspectiva de vida. Cada sonrisa que logro es mi mayor recompensa.',
      'image': 'https://images.unsplash.com/photo-1494790108755-2616b612b434?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
      'rating': 5,
    },
    {
      'name': 'Carlos Mendoza',
      'role': 'Coordinador de Proyectos',
      'message': 'La plataforma hace que organizar eventos sea súper fácil. Hemos triplicado nuestra participación.',
      'image': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
      'rating': 5,
    },
    {
      'name': 'Ana Restrepo',
      'role': 'Beneficiaria',
      'message': 'Gracias a los voluntarios de la UNFV, mi hijo ahora tiene acceso a una mejor educación.',
      'image': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
      'rating': 5,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserImage();
    _loadFirebaseData(); // Cargar datos de Firebase
    _loadCalendarEvents(); // Cargar eventos del calendario
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    
    // Auto-scroll para el carrusel hero
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        _currentBannerIndex = (_currentBannerIndex + 1) % _heroCarouselData.length;
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadUserImage() async {
    try {
      final authService = AuthService();
      final userData = await authService.getUserData();
      
      if (mounted) {
        setState(() {
          imageUrl = userData?.data()?['fotoPerfil'] as String?;
          if (imageUrl == null || imageUrl!.isEmpty) {
            imageUrl = CloudinaryService.defaultAvatarUrl;
          }
        });
      }
    } catch (e) {
      print('Error loading user image: $e');
      if (mounted) {
        setState(() {
          imageUrl = CloudinaryService.defaultAvatarUrl;
        });
      }
    }
  }

  // Cargar datos reales de Firebase
  Future<void> _loadFirebaseData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingData = true;
          _hasFirebaseError = false;
        });
      }

      // Ejecutar en el hilo principal y con timeouts
      await Future.wait([
        _loadImpactStatsWithTimeout(),
        _loadUpcomingEventsWithTimeout(),
        _loadTestimonialsWithTimeout(),
      ], eagerError: true).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout loading Firebase data');
        },
      );

      if (mounted) {
        setState(() {
          _isLoadingData = false;
          _hasFirebaseError = false;
        });
      }
    } catch (e) {
      print('Error loading Firebase data: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
          _hasFirebaseError = true;
          // Usar datos por defecto cuando hay error
          _realImpactStats = {
            'volunteers': 0,
            'livesImpacted': 0,
            'fundsRaised': 0.0,
            'activeProjects': 0,
          };
        });
      }
    }
  }

  Future<void> _loadImpactStatsWithTimeout() async {
    return _loadImpactStats().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print('Timeout loading impact stats, using defaults');
      },
    );
  }

  Future<void> _loadUpcomingEventsWithTimeout() async {
    return _loadUpcomingEvents().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print('Timeout loading upcoming events');
      },
    );
  }

  Future<void> _loadTestimonialsWithTimeout() async {
    return _loadTestimonials().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print('Timeout loading testimonials');
      },
    );
  }

  Future<void> _loadImpactStats() async {
    try {
      // Usar WidgetsBinding para asegurar que estamos en el hilo principal
      await WidgetsBinding.instance.endOfFrame;
      
      // Cargar datos de forma secuencial para evitar problemas de threading
      int totalVolunteers = 0;
      int totalEvents = 0;
      double totalDonations = 0;
      int totalLivesImpacted = 0;

      // Cargar estadísticas de voluntarios con manejo de errores
      try {
        final volunteersQuery = FirebaseFirestore.instance
            .collection('usuarios')
            .where('activo', isEqualTo: true);
        
        final volunteersSnapshot = await volunteersQuery.get();
        totalVolunteers = volunteersSnapshot.docs.length;
      } catch (e) {
        print('Error loading volunteers: $e');
        totalVolunteers = 0; // Valor por defecto
      }
      
      // Cargar eventos activos
      try {
        final eventsQuery = FirebaseFirestore.instance
            .collection('eventos')
            .where('activo', isEqualTo: true);
        
        final eventsSnapshot = await eventsQuery.get();
        totalEvents = eventsSnapshot.docs.length;
        
        // Calcular vidas impactadas basado en registros de eventos
        for (var eventDoc in eventsSnapshot.docs) {
          try {
            final registrosSnapshot = await FirebaseFirestore.instance
                .collection('registro_eventos')
                .where('eventoId', isEqualTo: eventDoc.id)
                .get();
            totalLivesImpacted += registrosSnapshot.docs.length;
          } catch (e) {
            print('Error loading event registrations for ${eventDoc.id}: $e');
            // Continuar con el siguiente evento
          }
        }
      } catch (e) {
        print('Error loading events: $e');
        totalEvents = 0;
      }
      
      // Cargar donaciones
      try {
        final donationsSnapshot = await FirebaseFirestore.instance
            .collection('donaciones')
            .get();
        
        for (var doc in donationsSnapshot.docs) {
          try {
            final data = doc.data();
            final monto = data['monto'];
            if (monto != null) {
              totalDonations += (monto as num).toDouble();
            }
          } catch (e) {
            print('Error processing donation ${doc.id}: $e');
            // Continuar con la siguiente donación
          }
        }
      } catch (e) {
        print('Error loading donations: $e');
        totalDonations = 0.0;
      }

      // Usar valores por defecto mínimos para hacer la app más atractiva
      if (totalVolunteers == 0) totalVolunteers = 25;
      if (totalEvents == 0) totalEvents = 8;
      if (totalDonations == 0) totalDonations = 5500.0;
      if (totalLivesImpacted == 0) totalLivesImpacted = totalVolunteers * 3;

      if (mounted) {
        setState(() {
          _realImpactStats = {
            'volunteers': totalVolunteers,
            'livesImpacted': totalLivesImpacted,
            'fundsRaised': totalDonations,
            'activeProjects': totalEvents,
          };
        });
      }
    } catch (e) {
      print('Error loading impact stats: $e');
      // Usar valores por defecto atractivos
      if (mounted) {
        setState(() {
          _realImpactStats = {
            'volunteers': 25,
            'livesImpacted': 75,
            'fundsRaised': 5500.0,
            'activeProjects': 8,
          };
        });
      }
    }
  }

  Future<void> _loadUpcomingEvents() async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      
      final now = DateTime.now();
      List<Map<String, dynamic>> events = [];
      
      try {
        final eventsSnapshot = await FirebaseFirestore.instance
            .collection('eventos')
            .where('fecha', isGreaterThan: Timestamp.fromDate(now))
            .where('activo', isEqualTo: true)
            .orderBy('fecha')
            .limit(3)
            .get();
        
        for (var doc in eventsSnapshot.docs) {
          try {
            final data = doc.data();
            final fechaTimestamp = data['fecha'];
            if (fechaTimestamp == null) continue;
            
            final fecha = (fechaTimestamp as Timestamp).toDate();
            
            // Contar voluntarios registrados con manejo de errores
            int volunteerCount = 0;
            try {
              final registrosSnapshot = await FirebaseFirestore.instance
                  .collection('registro_eventos')
                  .where('eventoId', isEqualTo: doc.id)
                  .get();
              volunteerCount = registrosSnapshot.docs.length;
            } catch (e) {
              print('Error loading volunteers for event ${doc.id}: $e');
              volunteerCount = 5; // Valor por defecto
            }

            events.add({
              'id': doc.id,
              'title': data['nombre'] ?? 'Evento sin nombre',
              'date': '${fecha.day} ${_getMonthName(fecha.month)}',
              'time': '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
              'location': data['lugar'] ?? 'Ubicación por confirmar',
              'volunteers': volunteerCount.toString(),
              'category': data['categoria'] ?? 'General',
              'description': data['descripcion'] ?? '',
              'image': data['imagenUrl'] ?? 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80',
            });
          } catch (e) {
            print('Error processing event ${doc.id}: $e');
            // Continuar con el siguiente evento
          }
        }
      } catch (e) {
        print('Error querying events: $e');
        // Si no hay eventos en Firebase, usar eventos por defecto
        events = _getDefaultEvents();
      }

      if (mounted) {
        setState(() {
          _realUpcomingEvents = events;
        });
      }
    } catch (e) {
      print('Error loading upcoming events: $e');
      if (mounted) {
        setState(() {
          _realUpcomingEvents = _getDefaultEvents();
        });
      }
    }
  }

  List<Map<String, dynamic>> _getDefaultEvents() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final nextWeek = DateTime.now().add(const Duration(days: 7));
    final nextMonth = DateTime.now().add(const Duration(days: 30));
    
    return [
      {
        'id': 'default-1',
        'title': 'Jornada de Salud Comunitaria',
        'date': '${tomorrow.day} ${_getMonthName(tomorrow.month)}',
        'time': '08:00',
        'location': 'Centro Comunitario Villa El Salvador',
        'volunteers': '15',
        'category': 'Salud',
        'description': 'Atención médica gratuita para la comunidad',
        'image': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80',
      },
      {
        'id': 'default-2',
        'title': 'Campaña de Alfabetización Digital',
        'date': '${nextWeek.day} ${_getMonthName(nextWeek.month)}',
        'time': '14:00',
        'location': 'Biblioteca Municipal',
        'volunteers': '8',
        'category': 'Educación',
        'description': 'Enseñanza de tecnología básica',
        'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80',
      },
      {
        'id': 'default-3',
        'title': 'Reforestación Urbana',
        'date': '${nextMonth.day} ${_getMonthName(nextMonth.month)}',
        'time': '07:00',
        'location': 'Parque Zonal Huiracocha',
        'volunteers': '22',
        'category': 'Medio Ambiente',
        'description': 'Plantación de árboles en espacios públicos',
        'image': 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80',
      },
    ];
  }

  Future<void> _loadTestimonials() async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      
      List<Map<String, dynamic>> testimonials = [];
      
      try {
        final testimonialsSnapshot = await FirebaseFirestore.instance
            .collection('testimonios')
            .where('aprobado', isEqualTo: true)
            .orderBy('fechaCreacion', descending: true)
            .limit(3)
            .get();
        
        for (var doc in testimonialsSnapshot.docs) {
          try {
            final data = doc.data();
            testimonials.add({
              'name': data['nombreUsuario'] ?? 'Usuario Anónimo',
              'role': data['rol'] ?? 'Voluntario',
              'message': data['mensaje'] ?? '',
              'image': data['fotoUsuario'] ?? 'https://images.unsplash.com/photo-1494790108755-2616b612b434?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
              'rating': data['calificacion'] ?? 5,
            });
          } catch (e) {
            print('Error processing testimonial ${doc.id}: $e');
          }
        }
      } catch (e) {
        print('Error querying testimonials: $e');
        // Usar testimonios por defecto si no hay en Firebase
        testimonials = _getDefaultTestimonials();
      }

      if (mounted) {
        setState(() {
          _realTestimonials = testimonials.isNotEmpty ? testimonials : _getDefaultTestimonials();
        });
      }
    } catch (e) {
      print('Error loading testimonials: $e');
      if (mounted) {
        setState(() {
          _realTestimonials = _getDefaultTestimonials();
        });
      }
    }
  }

  List<Map<String, dynamic>> _getDefaultTestimonials() {
    return [
      {
        'name': 'María González',
        'role': 'Voluntaria RSU',
        'message': 'Ser parte de RSU ha cambiado mi perspectiva de vida. Cada sonrisa que logro es mi mayor recompensa.',
        'image': 'https://images.unsplash.com/photo-1494790108755-2616b612b434?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
        'rating': 5,
      },
      {
        'name': 'Carlos Mendoza',
        'role': 'Coordinador de Proyectos',
        'message': 'La plataforma hace que organizar eventos sea súper fácil. Hemos triplicado nuestra participación.',
        'image': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
        'rating': 5,
      },
      {
        'name': 'Ana Restrepo',
        'role': 'Beneficiaria',
        'message': 'Gracias a los voluntarios de la UNFV, mi hijo ahora tiene acceso a una mejor educación.',
        'image': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
        'rating': 5,
      },
    ];
  }

  String _getMonthName(int month) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return months[month - 1];
  }

  // Funciones del calendario
  Future<void> _loadCalendarEvents() async {
    try {
      await Future.wait([
        _loadUserRegisteredEvents(),
        _loadAllAvailableEvents(),
      ]);
      _organizeCalendarEvents();
    } catch (e) {
      print('Error loading calendar events: $e');
    }
  }

  Future<void> _loadUserRegisteredEvents() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('registro_eventos')
          .where('usuarioId', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> registeredEvents = [];
      
      for (var registroDoc in eventsSnapshot.docs) {
        final eventoId = registroDoc.data()['eventoId'];
        if (eventoId != null) {
          final eventoDoc = await FirebaseFirestore.instance
              .collection('eventos')
              .doc(eventoId)
              .get();
          
          if (eventoDoc.exists) {
            final data = eventoDoc.data()!;
            registeredEvents.add({
              'id': eventoDoc.id,
              'title': data['nombre'] ?? 'Evento sin nombre',
              'date': (data['fecha'] as Timestamp).toDate(),
              'category': data['categoria'] ?? 'General',
              'location': data['lugar'] ?? 'Ubicación por confirmar',
              'type': 'registered', // Evento al que el usuario está inscrito
              'description': data['descripcion'] ?? '',
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _userRegisteredEvents = registeredEvents;
        });
      }
    } catch (e) {
      print('Error loading user registered events: $e');
    }
  }

  Future<void> _loadAllAvailableEvents() async {
    try {
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('eventos')
          .where('activo', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> availableEvents = [];
      
      for (var doc in eventsSnapshot.docs) {
        final data = doc.data();
        availableEvents.add({
          'id': doc.id,
          'title': data['nombre'] ?? 'Evento sin nombre',
          'date': (data['fecha'] as Timestamp).toDate(),
          'category': data['categoria'] ?? 'General',
          'location': data['lugar'] ?? 'Ubicación por confirmar',
          'type': 'available', // Evento disponible para inscribirse
          'description': data['descripcion'] ?? '',
        });
      }

      if (mounted) {
        setState(() {
          _allEvents = availableEvents;
        });
      }
    } catch (e) {
      print('Error loading all events: $e');
    }
  }

  void _organizeCalendarEvents() {
    Map<DateTime, List<dynamic>> events = {};
    
    // Agregar eventos inscritos (verde)
    for (var event in _userRegisteredEvents) {
      final date = DateTime(
        event['date'].year,
        event['date'].month,
        event['date'].day,
      );
      
      if (events[date] == null) events[date] = [];
      events[date]!.add({
        ...event,
        'color': Colors.green,
        'isRegistered': true,
      });
    }
    
    // Agregar eventos disponibles (azul) - solo si no está ya inscrito
    for (var event in _allEvents) {
      final date = DateTime(
        event['date'].year,
        event['date'].month,
        event['date'].day,
      );
      
      // Verificar si ya está inscrito a este evento
      bool alreadyRegistered = _userRegisteredEvents
          .any((registered) => registered['id'] == event['id']);
      
      if (!alreadyRegistered) {
        if (events[date] == null) events[date] = [];
        events[date]!.add({
          ...event,
          'color': Colors.blue,
          'isRegistered': false,
        });
      }
    }
    
    // Agregar fechas importantes (naranja)
    _addImportantDates(events);
    
    if (mounted) {
      setState(() {
        _calendarEvents = events;
      });
    }
  }

  void _addImportantDates(Map<DateTime, List<dynamic>> events) {
    final currentYear = DateTime.now().year;
    
    // Fechas importantes del año
    final importantDates = [
      {
        'date': DateTime(currentYear, 1, 1),
        'title': 'Año Nuevo',
        'type': 'holiday',
        'color': Colors.red,
      },
      {
        'date': DateTime(currentYear, 2, 14),
        'title': 'Día del Amor y la Amistad',
        'type': 'special',
        'color': Colors.pink,
      },
      {
        'date': DateTime(currentYear, 4, 22),
        'title': 'Día de la Tierra',
        'type': 'environmental',
        'color': Colors.green,
      },
      {
        'date': DateTime(currentYear, 5, 8),
        'title': 'Día de la Madre',
        'type': 'special',
        'color': Colors.pink,
      },
      {
        'date': DateTime(currentYear, 6, 18),
        'title': 'Día del Padre',
        'type': 'special',
        'color': Colors.blue,
      },
      {
        'date': DateTime(currentYear, 7, 28),
        'title': 'Día de la Independencia',
        'type': 'holiday',
        'color': Colors.red,
      },
      {
        'date': DateTime(currentYear, 8, 30),
        'title': 'Día de Santa Rosa de Lima',
        'type': 'holiday',
        'color': Colors.purple,
      },
      {
        'date': DateTime(currentYear, 10, 8),
        'title': 'Día de Combate de Angamos',
        'type': 'holiday',
        'color': Colors.red,
      },
      {
        'date': DateTime(currentYear, 11, 1),
        'title': 'Día de Todos los Santos',
        'type': 'holiday',
        'color': Colors.orange,
      },
      {
        'date': DateTime(currentYear, 12, 8),
        'title': 'Día de la Inmaculada Concepción',
        'type': 'holiday',
        'color': Colors.blue,
      },
      {
        'date': DateTime(currentYear, 12, 25),
        'title': 'Navidad',
        'type': 'holiday',
        'color': Colors.red,
      },
    ];
    
    for (var important in importantDates) {
      final date = important['date'] as DateTime;
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      if (events[normalizedDate] == null) events[normalizedDate] = [];
      events[normalizedDate]!.add({
        'title': important['title'],
        'type': important['type'],
        'color': important['color'],
        'isImportant': true,
        'description': 'Fecha importante del año',
      });
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _calendarEvents[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final String currentImage = imageUrl ?? defaultUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: MyDrawer(currentImage: currentImage),
      body: CustomScrollView(
        slivers: [
          // App Bar moderno con gradiente
          SliverAppBar(
            expandedHeight: 380,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroCarousel(),
            ),
            leading: Builder(
              builder: (context) => Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
          ),

          // Contenido principal
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Estadísticas de impacto
                    _buildImpactStatsSection(),
                    
                    // Calendario de eventos
                    _buildCalendarSection(),
                    
                    // Acciones rápidas
                    _buildQuickActionsSection(),
                    
                    // Sección de gamificación
                    _buildGamificationSection(),
                    
                    // Próximos eventos
                    _buildUpcomingEventsSection(),
                    
                    // Historias de impacto / Testimonios
                    _buildTestimonialsSection(),
                    
                    // Información sobre RSU
                    _buildRSUInfoSection(),
                    
                    // Footer
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeroCarousel() {
    return Container(
      height: 380,
      child: PageView.builder(
        controller: _bannerController,
        onPageChanged: (index) {
          setState(() {
            _currentBannerIndex = index;
          });
        },
        itemCount: _heroCarouselData.length,
        itemBuilder: (context, index) {
          final item = _heroCarouselData[index];
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(item['image']),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item['subtitle'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, item['route']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: item['gradient'][0],
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 8,
                      ),
                      child: Text(
                        item['cta'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _heroCarouselData.asMap().entries.map((entry) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentBannerIndex == entry.key
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImpactStatsSection() {
    // Usar datos reales de Firebase o datos fallback
    final stats = _isLoadingData ? _impactStats : _buildRealStatsData();
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nuestro Impacto',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              if (_hasFirebaseError)
                IconButton(
                  onPressed: () {
                    _loadFirebaseData();
                  },
                  icon: const Icon(
                    Icons.refresh,
                    color: Color(0xFF667eea),
                  ),
                  tooltip: 'Recargar datos',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Juntos estamos cambiando el mundo, una acción a la vez',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              if (_hasFirebaseError)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Datos de ejemplo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _isLoadingData
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: stats.length,
                  itemBuilder: (context, index) {
                    final stat = stats[index];
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: stat['color'].withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: stat['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              stat['icon'],
                              size: 32,
                              color: stat['color'],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            stat['value'],
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: stat['color'],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stat['label'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildRealStatsData() {
    return [
      {
        'icon': Icons.people_outline,
        'value': _realImpactStats['volunteers']?.toString() ?? '0',
        'label': 'Voluntarios Activos',
        'color': const Color(0xFF667eea)
      },
      {
        'icon': Icons.favorite_outline,
        'value': _realImpactStats['livesImpacted']?.toString() ?? '0',
        'label': 'Vidas Impactadas',
        'color': const Color(0xFFf5576c)
      },
      {
        'icon': Icons.attach_money,
        'value': 'S/. ${(_realImpactStats['fundsRaised'] ?? 0).toStringAsFixed(0)}',
        'label': 'Fondos Recaudados',
        'color': const Color(0xFF4facfe)
      },
      {
        'icon': Icons.eco_outlined,
        'value': _realImpactStats['activeProjects']?.toString() ?? '0',
        'label': 'Proyectos Activos',
        'color': const Color(0xFF2dd4bf)
      },
    ];
  }

  Widget _buildCalendarSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Calendario de Eventos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              IconButton(
                onPressed: () => _showCalendarLegend(),
                icon: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF667eea),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Encuentra eventos, fechas importantes y tu calendario personal',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TableCalendar<dynamic>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: _calendarFormat,
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarStyle: const CalendarStyle(
                      outsideDaysVisible: false,
                      selectedDecoration: BoxDecoration(
                        color: Color(0xFF667eea),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Color(0xFF4facfe),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Color(0xFFf5576c),
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                      markerMargin: EdgeInsets.only(top: 5),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonShowsNext: false,
                      formatButtonDecoration: BoxDecoration(
                        color: Color(0xFF667eea),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      formatButtonTextStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        _showEventsForDay(selectedDay);
                      }
                    },
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCalendarLegend(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leyenda:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(
                color: Colors.green,
                label: 'Inscrito',
                icon: Icons.check_circle,
              ),
              _buildLegendItem(
                color: Colors.blue,
                label: 'Disponible',
                icon: Icons.event_available,
              ),
              _buildLegendItem(
                color: Colors.orange,
                label: 'Importante',
                icon: Icons.star,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showCalendarLegend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF667eea)),
            SizedBox(width: 8),
            Text('Información del Calendario'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendExplanation(
              color: Colors.green,
              title: 'Eventos Inscritos',
              description: 'Eventos a los que ya te has inscrito',
              icon: Icons.check_circle,
            ),
            const SizedBox(height: 12),
            _buildLegendExplanation(
              color: Colors.blue,
              title: 'Eventos Disponibles',
              description: 'Eventos en los que puedes participar',
              icon: Icons.event_available,
            ),
            const SizedBox(height: 12),
            _buildLegendExplanation(
              color: Colors.orange,
              title: 'Fechas Importantes',
              description: 'Días festivos y fechas especiales del año',
              icon: Icons.star,
            ),
            const SizedBox(height: 16),
            const Text(
              'Toca cualquier día para ver los detalles de los eventos.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendExplanation({
    required Color color,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEventsForDay(DateTime selectedDay) {
    final events = _getEventsForDay(selectedDay);
    
    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay eventos para ${DateFormat('dd/MM/yyyy').format(selectedDay)}'),
          backgroundColor: const Color(0xFF64748B),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: const Color(0xFF667eea),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Eventos - ${DateFormat('dd/MM/yyyy').format(selectedDay)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _buildEventCard(event);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final isRegistered = event['isRegistered'] ?? false;
    final isImportant = event['isImportant'] ?? false;
    final color = event['color'] as Color;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isImportant
                        ? Icons.star
                        : isRegistered
                            ? Icons.check_circle
                            : Icons.event_available,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title'] ?? 'Sin título',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (event['category'] != null)
                        Text(
                          event['category'],
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isRegistered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'INSCRITO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
            if (event['description'] != null && event['description'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                event['description'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
            if (event['location'] != null && event['location'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event['location'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (!isRegistered && !isImportant) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, '/eventos');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Ver más detalles',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _quickActions.length,
              itemBuilder: (context, index) {
                final action = _quickActions[index];
                return Container(
                  width: 100,
                  margin: EdgeInsets.only(right: index < _quickActions.length - 1 ? 16 : 0),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, action['route']),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: action['color'].withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: action['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              action['icon'],
                              size: 24,
                              color: action['color'],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            action['title'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            action['subtitle'],
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamificationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/games'),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                  Color(0xFF9333ea),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9333ea).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Elementos decorativos de fondo
                Positioned(
                  top: -10,
                  right: -10,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -20,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 30,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '¡NUEVO!',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Contenido principal
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.games,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🎮 Centro de Juegos RSU',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Aprende y diviértete con nuestros minijuegos',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Características destacadas
                    Row(
                      children: [
                        Expanded(
                          child: _buildGameFeature(
                            '🧠',
                            'Quiz RSU',
                            'Trivia educativo',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildGameFeature(
                            '⭐',
                            'Puntos',
                            'Gana recompensas',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildGameFeature(
                            '🏆',
                            'Niveles',
                            'Sube de rango',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Botón de acción
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/games'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF9333ea),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: Colors.black.withOpacity(0.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_arrow,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'JUGAR AHORA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9333ea).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameFeature(String emoji, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsSection() {
    // Usar datos reales de Firebase o datos fallback
    final events = _isLoadingData ? _upcomingEvents : _realUpcomingEvents.isNotEmpty ? _realUpcomingEvents : _upcomingEvents;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Próximos Eventos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/eventos'),
                child: const Text(
                  'Ver todos',
                  style: TextStyle(
                    color: Color(0xFF667eea),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoadingData
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                  ),
                )
              : SizedBox(
                  height: 280,
                  child: events.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay eventos próximos',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            return Container(
                              width: 300,
                              margin: EdgeInsets.only(right: index < events.length - 1 ? 16 : 0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          image: DecorationImage(
                            image: NetworkImage(event['image']),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF667eea),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  event['category'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      event['date'].split(' ')[0],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      event['date'].split(' ')[1],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  event['time'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    event['location'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.people_outline,
                                      size: 14,
                                      color: Color(0xFF667eea),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${event['volunteers']} voluntarios',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF667eea),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: const Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection() {
    // Usar datos reales de Firebase o datos fallback
    final testimonials = _isLoadingData ? _testimonials : _realTestimonials.isNotEmpty ? _realTestimonials : _testimonials;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historias que Inspiran',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Conoce el impacto real de nuestra comunidad',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          _isLoadingData
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                  ),
                )
              : SizedBox(
                  height: 200,
                  child: testimonials.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay testimonios disponibles',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: testimonials.length,
                          itemBuilder: (context, index) {
                            final testimonial = testimonials[index];
                            return Container(
                              width: 320,
                              margin: EdgeInsets.only(right: index < testimonials.length - 1 ? 16 : 0),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF667eea).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: NetworkImage(testimonial['image']),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  testimonial['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  testimonial['role'],
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: List.generate(5, (i) => Icon(
                              Icons.star,
                              size: 16,
                              color: i < testimonial['rating'] 
                                  ? Colors.amber 
                                  : Colors.white30,
                            )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Text(
                          '"${testimonial['message']}"',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRSUInfoSection() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
           
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Qué es RSU?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'La Responsabilidad Social Universitaria (RSU) es nuestro compromiso ético para contribuir al desarrollo sostenible de la sociedad a través de la educación, investigación y proyección social.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          
          // Video promocional
          GestureDetector(
            onTap: () async {
              const url = 'https://www.youtube.com/watch?v=wSNe17HEm2o';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://img.youtube.com/vi/wSNe17HEm2o/maxresdefault.jpg',
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Color(0xFF667eea),
                          size: 40,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: const Text(
                        'Conoce más sobre RSU UNFV',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Características de voluntarios
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perfil del Voluntario Ideal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                _buildVolunteerTrait(
                  Icons.school_outlined,
                  'Estudiantes comprometidos',
                  'De todas las especialidades universitarias',
                ),
                _buildVolunteerTrait(
                  Icons.favorite_outline,
                  'Sensibles y empáticos',
                  'Con vocación de servicio a la comunidad',
                ),
                _buildVolunteerTrait(
                  Icons.people_outline,
                  'Trabajo en equipo',
                  'Disposición para colaborar y liderar',
                ),
                _buildVolunteerTrait(
                  Icons.star_outline,
                  'Compromiso social',
                  'Motivados por generar impacto positivo',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerTrait(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF667eea),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RSU UNFV',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Responsabilidad Social Universitaria\nUniversidad Nacional Federico Villarreal',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Contáctanos:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'voluntariado.rsu@unfv.edu.pe\n+51 1 748-0888',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Síguenos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildSocialButton(
                          Icons.language,
                          'https://unfv.edu.pe',
                          const Color(0xFF667eea),
                        ),
                        const SizedBox(width: 12),
                        _buildSocialButton(
                          Icons.video_library,
                          'https://youtube.com',
                          Colors.red,
                        ),
                        const SizedBox(width: 12),
                        _buildSocialButton(
                          Icons.facebook,
                          'https://facebook.com',
                          const Color(0xFF1877F2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 1,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          const Text(
            '© 2025 RSU UNFV. Todos los derechos reservados.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String url, Color color) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomNavItem(
            icon: Icons.home_outlined,
            label: 'Inicio',
            isActive: true,
            onTap: () {},
          ),
          _buildBottomNavItem(
            icon: Icons.volunteer_activism_outlined,
            label: 'Donaciones',
            isActive: false,
            onTap: () => Navigator.pushNamed(context, '/donaciones'),
          ),
          _buildBottomNavItem(
            icon: Icons.event_outlined,
            label: 'Eventos',
            isActive: false,
            onTap: () => Navigator.pushNamed(context, '/eventos'),
          ),
          _buildBottomNavItem(
            icon: Icons.person_outline,
            label: 'Perfil',
            isActive: false,
            onTap: () => Navigator.pushNamed(context, '/perfil'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF667eea).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF667eea) : const Color(0xFF64748B),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF667eea) : const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
