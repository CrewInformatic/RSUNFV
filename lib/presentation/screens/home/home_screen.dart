import 'package:flutter/material.dart';
import 'package:rsunfv_app/widgets/drawer.dart';
import '../../../services/firebase_auth_services.dart';
import 'dart:async';
import '../../../services/cloudinary_services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/evento.dart';
import '../../../models/donaciones.dart';
import '../../../models/usuario.dart';
import 'package:logger/logger.dart';

// Import new widgets
import 'widgets/hero_carousel.dart';
import 'widgets/impact_stats.dart';
import 'widgets/quick_actions.dart';
import 'widgets/events_calendar.dart';
import 'widgets/upcoming_events.dart';
import 'widgets/testimonials_section.dart';
import 'widgets/rsu_info_section.dart';
import 'widgets/home_footer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// Home screen for the RSU application.
/// 
/// Main entry point showing hero carousel, impact statistics, 
/// quick actions, events calendar, and other key information.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Services
  static final Logger _logger = Logger();
  
  // User and UI state
  String? imageUrl;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Carousel state
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  
  // Real Firebase data state
  Map<String, dynamic> _realImpactStats = {};
  bool _isLoadingData = true;
  List<Evento> _upcomingEvents = [];
  List<Map<String, dynamic>> _testimonials = [];
  List<Donaciones> _recentDonations = [];
  
  // User data
  Usuario? _currentUser;
  
  // Calendar state
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _calendarEvents = {};
  List<Map<String, dynamic>> _userRegisteredEvents = [];
  bool _hasFirebaseError = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
    _startCarouselTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
  }

  void _initializeData() {
    _loadUserImage();
    _loadFirebaseData();
    _loadCalendarEvents();
  }

  void _startCarouselTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerController.hasClients) {
        _currentBannerIndex = (_currentBannerIndex + 1) % 
            AppConstants.heroCarouselData.length;
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = imageUrl ?? AppConstants.defaultProfileImageUrl;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(currentImage),
      drawer: MyDrawer(currentImage: currentImage),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildBody(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String currentImage) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: AppColors.darkText),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Image.asset(
            'assets/logo_rsu.png',
            height: 32,
            width: 32,
          ),
          const SizedBox(width: 12),
          const Text(
            'RSU UNFV',
            style: TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/perfil'),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(currentImage),
              onBackgroundImageError: (_, __) {},
              child: currentImage.isEmpty
                  ? const Icon(Icons.person, color: AppColors.white)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          // Hero Carousel
          HeroCarousel(
            onCtaPressed: _navigateToRoute,
            pageController: _bannerController,
            currentIndex: _currentBannerIndex,
            onPageChanged: _onCarouselPageChanged,
          ),
          
          // Impact Statistics
          ImpactStats(
            realStats: _realImpactStats,
            isLoading: _isLoadingData,
            hasError: _hasFirebaseError,
          ),
          
          // Quick Actions
          QuickActions(
            onActionPressed: _navigateToRoute,
          ),
          
          // Events Calendar
          EventsCalendar(
            calendarFormat: _calendarFormat,
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            calendarEvents: _calendarEvents,
            userRegisteredEvents: _userRegisteredEvents,
            onFormatChanged: _onCalendarFormatChanged,
            onFocusedDayChanged: _onFocusedDayChanged,
            onDaySelected: _onDaySelected,
          ),
          
          // Upcoming Events
          UpcomingEvents(
            events: _upcomingEvents,
            isLoading: _isLoadingData,
            hasError: _hasFirebaseError,
            onEventTap: _navigateToEventDetail,
          ),
          
          // Testimonials Section
          TestimonialsSection(
            testimonials: _testimonials,
            isLoading: _isLoadingData,
            hasError: _hasFirebaseError,
          ),
          
          // RSU Information Section
          const RsuInfoSection(),
          
          // Footer
          HomeFooter(
            onNavigate: _navigateToRoute,
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Navigation handlers
  void _navigateToRoute(String route) {
    if (!mounted) return;
    Navigator.pushNamed(context, route);
  }

  void _navigateToEventDetail(Evento event) {
    if (!mounted) return;
    Navigator.pushNamed(
      context, 
      '/evento_detalle',
      arguments: event,
    );
  }

  void _onCarouselPageChanged(int index) {
    setState(() {
      _currentBannerIndex = index;
    });
  }

  // Calendar handlers
  void _onCalendarFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  void _onFocusedDayChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  // Data loading methods
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
      debugPrint('Error loading user image: $e');
      if (mounted) {
        setState(() {
          imageUrl = CloudinaryService.defaultAvatarUrl;
        });
      }
    }
  }

  Future<void> _loadFirebaseData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingData = true;
          _hasFirebaseError = false;
        });
      }
      
      await Future.wait([
        _loadCurrentUser(),
        _loadImpactStats(),
        _loadUpcomingEvents(),
        _loadTestimonials(),
      ], eagerError: true).timeout(
        const Duration(seconds: 15),
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
      _logger.e('Error loading Firebase data: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
          _hasFirebaseError = true;
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

  Future<void> _loadCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists && mounted) {
          setState(() {
            _currentUser = Usuario.fromMap({
              ...userDoc.data()!,
              'idUsuario': userDoc.id,
            });
          });
        }
      }
    } catch (e) {
      _logger.e('Error loading current user: $e');
    }
  }

  Future<void> _loadImpactStats() async {
    try {
      // Obtener estadísticas de usuarios activos
      final usuariosQuery = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('estadoActivo', isEqualTo: true)
          .get();
      
      // Obtener estadísticas de eventos
      final eventosQuery = await FirebaseFirestore.instance
          .collection('eventos')
          .where('estado', isEqualTo: 'activo')
          .get();
      
      // Obtener estadísticas de donaciones
      final donacionesQuery = await FirebaseFirestore.instance
          .collection('donaciones')
          .where('estadoValidacion', isEqualTo: 'aprobado')
          .get();

      // Calcular estadísticas
      int totalVolunteers = usuariosQuery.docs.length;
      int activeProjects = eventosQuery.docs.length;
      
      // Calcular vidas impactadas (aproximadamente 3 por cada evento completado)
      final eventosCompletados = await FirebaseFirestore.instance
          .collection('eventos')
          .where('estado', isEqualTo: 'finalizado')
          .get();
      
      int livesImpacted = eventosCompletados.docs.length * 3;
      
      // Calcular fondos recaudados
      double fundsRaised = 0.0;
      for (var doc in donacionesQuery.docs) {
        final data = doc.data();
        fundsRaised += (data['monto'] as num?)?.toDouble() ?? 0.0;
      }

      // Cargar donaciones recientes
      final donacionesRecientes = await FirebaseFirestore.instance
          .collection('donaciones')
          .orderBy('fechaDonacion', descending: true)
          .limit(5)
          .get();

      List<Donaciones> recentDonations = donacionesRecientes.docs
          .map((doc) => Donaciones.fromMap({
                ...doc.data(),
                'idDonaciones': doc.id,
              }))
          .toList();
      
      if (mounted) {
        setState(() {
          _realImpactStats = {
            'volunteers': totalVolunteers,
            'livesImpacted': livesImpacted,
            'fundsRaised': fundsRaised,
            'activeProjects': activeProjects,
          };
          _recentDonations = recentDonations;
        });
      }
    } catch (e) {
      _logger.e('Error loading impact stats: $e');
      if (mounted) {
        setState(() {
          _realImpactStats = {
            'volunteers': 150,
            'livesImpacted': 1200,
            'fundsRaised': 25000.0,
            'activeProjects': 8,
          };
        });
      }
    }
  }

  Future<void> _loadUpcomingEvents() async {
    try {
      final currentDate = DateTime.now();
      
      // Intentar con orderBy primero, si falla usar query más simple
      QuerySnapshot query;
      try {
        query = await FirebaseFirestore.instance
            .collection('eventos')
            .where('estado', isEqualTo: 'activo')
            .orderBy('fechaInicio')
            .limit(6)
            .get();
      } catch (indexError) {
        _logger.w('Index not available, using simpler query: $indexError');
        // Fallback sin orderBy si no hay índice
        query = await FirebaseFirestore.instance
            .collection('eventos')
            .where('estado', isEqualTo: 'activo')
            .limit(10)
            .get();
      }

      List<Evento> eventos = [];
      for (var doc in query.docs) {
        try {
          final evento = Evento.fromFirestore(doc);
          // Solo incluir eventos futuros
          final fechaEvento = DateTime.parse(evento.fechaInicio);
          if (fechaEvento.isAfter(currentDate)) {
            eventos.add(evento);
          }
        } catch (e) {
          _logger.w('Error parsing event ${doc.id}: $e');
        }
      }

      // Ordenar en el cliente si no se pudo hacer en Firestore
      eventos.sort((a, b) {
        try {
          final dateA = DateTime.parse(a.fechaInicio);
          final dateB = DateTime.parse(b.fechaInicio);
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });

      // Limitar a 6 eventos
      if (eventos.length > 6) {
        eventos = eventos.take(6).toList();
      }

      if (mounted) {
        setState(() {
          _upcomingEvents = eventos;
        });
      }
    } catch (e) {
      _logger.e('Error loading upcoming events: $e');
      if (mounted) {
        setState(() {
          _upcomingEvents = [];
        });
      }
    }
  }

  Future<void> _loadTestimonials() async {
    try {
      // En este caso, cargaremos testimonios desde una colección dedicada
      // Si no existe, usaremos datos de ejemplo
      QuerySnapshot query;
      try {
        query = await FirebaseFirestore.instance
            .collection('testimonios')
            .orderBy('fecha', descending: true)
            .limit(5)
            .get();
      } catch (indexError) {
        _logger.w('Testimonios collection or index not available: $indexError');
        // Si no existe la colección o el índice, usar query simple
        query = await FirebaseFirestore.instance
            .collection('testimonios')
            .limit(5)
            .get();
      }

      List<Map<String, dynamic>> testimonials = [];
      
      if (query.docs.isNotEmpty) {
        testimonials = query.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'nombre': data['nombre'] ?? 'Usuario Anónimo',
            'testimonio': data['testimonio'] ?? '',
            'evento': data['evento'] ?? 'Evento RSU',
            'foto': data['foto'] ?? CloudinaryService.defaultAvatarUrl,
            'fecha': data['fecha'] ?? DateTime.now().toIso8601String(),
          };
        }).toList();
      } else {
        // Testimonios de ejemplo si no hay datos
        testimonials = [
          {
            'id': '1',
            'nombre': 'María García',
            'testimonio': 'Participar en RSU ha sido una experiencia transformadora. He conocido personas increíbles y hemos logrado un impacto real en nuestra comunidad.',
            'evento': 'Campaña de Alimentos',
            'foto': CloudinaryService.defaultAvatarUrl,
            'fecha': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          },
          {
            'id': '2',
            'nombre': 'Carlos Mendoza',
            'testimonio': 'A través de los proyectos de RSU, he desarrollado habilidades de liderazgo y he contribuido a causas que realmente importan.',
            'evento': 'Limpieza de Playas',
            'foto': CloudinaryService.defaultAvatarUrl,
            'fecha': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
          },
        ];
      }

      if (mounted) {
        setState(() {
          _testimonials = testimonials;
        });
      }
    } catch (e) {
      _logger.e('Error loading testimonials: $e');
      if (mounted) {
        setState(() {
          _testimonials = [];
        });
      }
    }
  }

  Future<void> _loadCalendarEvents() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // Cargar todos los eventos para el calendario
      final eventosQuery = await FirebaseFirestore.instance
          .collection('eventos')
          .where('estado', whereIn: ['activo', 'finalizado'])
          .get();

      Map<DateTime, List<dynamic>> calendarEvents = {};
      List<Map<String, dynamic>> userRegisteredEvents = [];

      for (var doc in eventosQuery.docs) {
        try {
          final evento = Evento.fromFirestore(doc);
          final eventDate = DateTime.parse(evento.fechaInicio);
          final dateKey = DateTime(eventDate.year, eventDate.month, eventDate.day);

          // Convertir Evento a Map para compatibilidad con EventsCalendar
          final eventoMap = {
            'id': evento.idEvento,
            'title': evento.titulo,
            'time': evento.horaInicio,
            'description': evento.descripcion,
            'location': evento.ubicacion,
            'date': evento.fechaInicio,
            'maxVolunteers': evento.cantidadVoluntariosMax,
            'registeredVolunteers': evento.voluntariosInscritos.length,
          };

          // Agregar evento al calendario
          if (calendarEvents[dateKey] != null) {
            calendarEvents[dateKey]!.add(eventoMap);
          } else {
            calendarEvents[dateKey] = [eventoMap];
          }

          // Verificar si el usuario está inscrito
          if (user != null && evento.voluntariosInscritos.contains(user.uid)) {
            userRegisteredEvents.add({
              'id': evento.idEvento,
              'title': evento.titulo,
              'date': evento.fechaInicio,
              'time': evento.horaInicio,
            });
          }
        } catch (e) {
          _logger.w('Error parsing calendar event ${doc.id}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _calendarEvents = calendarEvents;
          _userRegisteredEvents = userRegisteredEvents;
        });
      }
    } catch (e) {
      _logger.e('Error loading calendar events: $e');
      if (mounted) {
        setState(() {
          _calendarEvents = {};
          _userRegisteredEvents = [];
        });
      }
    }
  }
}
