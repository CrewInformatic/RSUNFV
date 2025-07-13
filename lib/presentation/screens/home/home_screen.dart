import 'package:flutter/material.dart';
import 'package:rsunfv_app/widgets/drawer.dart';
import '../../../services/firebase_auth_services.dart';
import 'dart:async';
import '../../../services/cloudinary_services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/evento.dart';
import 'package:logger/logger.dart';

import '../../../services/enhanced_impact_service.dart';

// Import new widgets
import 'widgets/hero_carousel.dart';
import 'widgets/impact_stats.dart';
import 'widgets/quick_actions.dart';
import 'widgets/events_calendar.dart';
import 'widgets/upcoming_events.dart';
import 'widgets/testimonials_section.dart';
import 'widgets/rsu_info_section.dart';
import 'widgets/home_footer.dart';
import 'widgets/detailed_impact_section.dart';

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
          
          const SizedBox(height: 12),
          
          // Impact Statistics
          ImpactStats(
            realStats: _realImpactStats,
            isLoading: _isLoadingData,
            hasError: _hasFirebaseError,
          ),
          
          const SizedBox(height: 12),
          
          // Detailed Impact Section - Nueva sección con estadísticas mejoradas
          const DetailedImpactSection(),
          
          const SizedBox(height: 12),
          
          // Quick Actions
          QuickActions(
            onActionPressed: _navigateToRoute,
          ),
          
          const SizedBox(height: 12),
          
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
          
          const SizedBox(height: 12),
          
          // Upcoming Events
          UpcomingEvents(
            events: _upcomingEvents,
            isLoading: _isLoadingData,
            hasError: _hasFirebaseError,
            onEventTap: _navigateToEventDetail,
          ),
          
          const SizedBox(height: 12),
          
          // Testimonials Section
          TestimonialsSection(
            testimonials: _testimonials,
            isLoading: _isLoadingData,
            hasError: _hasFirebaseError,
          ),
          
          const SizedBox(height: 12),
          
          // RSU Information Section
          const RsuInfoSection(),
          
          const SizedBox(height: 12),
          
          // Footer
          HomeFooter(
            onNavigate: _navigateToRoute,
          ),
          
          const SizedBox(height: 40),
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
      arguments: {
        'id': event.idEvento,
      },
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

  Future<void> _loadImpactStats() async {
    try {
      // Usar el nuevo servicio de estadísticas mejorado
      final stats = await EnhancedImpactService.getCompleteImpactStats();
      
      if (mounted) {
        setState(() {
          _realImpactStats = {
            'volunteers': stats['volunteers']['total'] ?? 150,
            'livesImpacted': stats['communityImpact']['livesImpacted'] ?? 1200,
            'fundsRaised': stats['donations']['totalAmount'] ?? 25000.0,
            'activeProjects': stats['events']['activeEvents'] ?? 8,
          };
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
      
      // Cargar eventos activos y finalizados
      QuerySnapshot query;
      try {
        query = await FirebaseFirestore.instance
            .collection('eventos')
            .where('estado', whereIn: ['activo', 'finalizado'])
            .limit(10)
            .get();
      } catch (indexError) {
        _logger.w('Index not available, using simpler query: $indexError');
        // Fallback - cargar todos los eventos y filtrar en el cliente
        query = await FirebaseFirestore.instance
            .collection('eventos')
            .limit(15)
            .get();
      }

      List<Evento> eventos = [];
      for (var doc in query.docs) {
        try {
          final evento = Evento.fromFirestore(doc);
          
          // Incluir eventos próximos, en curso, y finalizados recientemente (últimos 30 días)
          final fechaEvento = DateTime.parse(evento.fechaInicio);
          final hace30Dias = currentDate.subtract(Duration(days: 30));
          
          // Determinar el estado del evento
          final eventStatus = _getEventStatus(evento);
          
          // Incluir eventos que están:
          // 1. Próximos (upcoming)
          // 2. En curso (ongoing) 
          // 3. Finalizados en los últimos 30 días
          if (eventStatus == 'upcoming' || 
              eventStatus == 'ongoing' || 
              (eventStatus == 'finished' && fechaEvento.isAfter(hace30Dias))) {
            eventos.add(evento);
          }
        } catch (e) {
          _logger.w('Error parsing event ${doc.id}: $e');
        }
      }

      // Ordenar: primero eventos próximos y en curso, luego finalizados
      eventos.sort((a, b) {
        try {
          final statusA = _getEventStatus(a);
          final statusB = _getEventStatus(b);
          final dateA = DateTime.parse(a.fechaInicio);
          final dateB = DateTime.parse(b.fechaInicio);
          
          // Prioridad de estados: ongoing > upcoming > finished
          int getPriority(String status) {
            switch (status) {
              case 'ongoing': return 1;
              case 'upcoming': return 2;
              case 'finished': return 3;
              default: return 4;
            }
          }
          
          final priorityA = getPriority(statusA);
          final priorityB = getPriority(statusB);
          
          if (priorityA != priorityB) {
            return priorityA.compareTo(priorityB);
          }
          
          // Si tienen la misma prioridad, ordenar por fecha
          if (statusA == 'finished' && statusB == 'finished') {
            // Para eventos finalizados, mostrar los más recientes primero
            return dateB.compareTo(dateA);
          } else {
            // Para eventos próximos y en curso, mostrar los más próximos primero
            return dateA.compareTo(dateB);
          }
        } catch (e) {
          return 0;
        }
      });

      // Limitar a 8 eventos para mostrar variedad
      if (eventos.length > 8) {
        eventos = eventos.take(8).toList();
      }

      if (mounted) {
        setState(() {
          _upcomingEvents = eventos;
        });
      }
    } catch (e) {
      _logger.e('Error loading events: $e');
      if (mounted) {
        setState(() {
          _upcomingEvents = [];
        });
      }
    }
  }

  String _getEventStatus(Evento evento) {
    try {
      final now = DateTime.now();
      
      // Parsear fecha de inicio del evento
      final eventStartDate = DateTime.parse(evento.fechaInicio);
      
      // Crear fecha y hora de inicio del evento
      final startTimeParts = evento.horaInicio.split(':');
      final eventStartDateTime = DateTime(
        eventStartDate.year,
        eventStartDate.month,
        eventStartDate.day,
        startTimeParts.length >= 2 ? int.parse(startTimeParts[0]) : 0,
        startTimeParts.length >= 2 ? int.parse(startTimeParts[1]) : 0,
      );
      
      // Crear fecha y hora de fin del evento
      final eventEndDateTime = _parseEventEndDateTime(evento);
      
      // Verificar el estado de la base de datos primero
      final dbStatus = evento.estado.toLowerCase();
      if (dbStatus == 'cancelado' || dbStatus == 'cancelled') {
        return 'cancelled';
      }
      if (dbStatus == 'finalizado' || dbStatus == 'finished') {
        return 'finished';
      }
      
      // Determinar estado basado en fechas y horas actuales
      if (now.isBefore(eventStartDateTime)) {
        // El evento aún no ha comenzado
        if (dbStatus == 'activo') {
          return 'upcoming'; // Disponible para inscripción
        } else {
          return 'inactive'; // No disponible para inscripción
        }
      } else if (now.isAfter(eventEndDateTime)) {
        // El evento ya terminó
        return 'finished';
      } else {
        // El evento está en progreso
        return 'ongoing';
      }
    } catch (e) {
      // Si hay error parseando fechas, usar el estado de la base de datos
      final dbStatus = evento.estado.toLowerCase();
      return dbStatus == 'activo' ? 'upcoming' : dbStatus;
    }
  }

  DateTime _parseEventEndDateTime(Evento evento) {
    try {
      final eventDate = DateTime.parse(evento.fechaInicio);
      final endTimeParts = evento.horaFin.split(':');
      
      if (endTimeParts.length >= 2) {
        final endHour = int.parse(endTimeParts[0]);
        final endMinute = int.parse(endTimeParts[1]);
        
        return DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
          endHour,
          endMinute,
        );
      }
      
      // Si no se puede parsear la hora de fin, asumir que termina al final del día
      return DateTime(eventDate.year, eventDate.month, eventDate.day, 23, 59);
    } catch (e) {
      // En caso de error, usar la fecha del evento + 1 día
      final eventDate = DateTime.parse(evento.fechaInicio);
      return eventDate.add(Duration(days: 1));
    }
  }

  Future<void> _loadTestimonials() async {
    try {
      _logger.i('Loading testimonials from Firestore...');
      
      // Consulta simple sin índice compuesto requerido
      final testimonialsQuery = await FirebaseFirestore.instance
          .collection('testimonios')
          .limit(6)
          .get();
      
      if (testimonialsQuery.docs.isNotEmpty) {
        // Filtrar solo los aprobados en el cliente
        final approvedTestimonials = testimonialsQuery.docs
            .where((doc) => doc.data()['aprobado'] == true)
            .toList();
        
        if (approvedTestimonials.isNotEmpty) {
          final testimonialsData = approvedTestimonials.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['nombre'] ?? 'Usuario Anónimo',
              'role': data['carrera'] ?? 'Estudiante UNFV',
              'message': data['mensaje'] ?? 'Gran experiencia participando en RSU UNFV',
              'rating': (data['rating'] as num?)?.toInt() ?? 5,
              'avatar': data['avatar'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
              'fecha': data['fechaCreacion'],
            };
          }).toList();
          
          _logger.i('Loaded ${testimonialsData.length} approved testimonials from Firestore');
          
          if (mounted) {
            setState(() {
              _testimonials = testimonialsData;
            });
          }
          return;
        }
      }
      
      // Si no hay testimonios aprobados, crear algunos de ejemplo
      _logger.i('No approved testimonials found, creating example data...');
      await _createExampleTestimonials();
      
    } catch (e) {
      _logger.e('Error loading testimonials from Firestore: $e');
      
      // Para evitar bucle infinito, usar datos estáticos directamente
      _logger.i('Using fallback testimonials to avoid infinite loop');
      if (mounted) {
        setState(() {
          _testimonials = AppConstants.fallbackTestimonials;
        });
      }
    }
  }

  Future<void> _createExampleTestimonials() async {
    try {
      // Verificar si ya existen testimonios para evitar duplicados
      final existingQuery = await FirebaseFirestore.instance
          .collection('testimonios')
          .limit(1)
          .get();
      
      if (existingQuery.docs.isNotEmpty) {
        _logger.i('Testimonials already exist, skipping creation');
        // Recargar testimonios existentes
        final testimonialsQuery = await FirebaseFirestore.instance
            .collection('testimonios')
            .limit(6)
            .get();
        
        final testimonialsData = testimonialsQuery.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['nombre'] ?? 'Usuario Anónimo',
            'role': data['carrera'] ?? 'Estudiante UNFV',
            'message': data['mensaje'] ?? 'Gran experiencia participando en RSU UNFV',
            'rating': (data['rating'] as num?)?.toInt() ?? 5,
            'avatar': data['avatar'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
            'fecha': data['fechaCreacion'],
          };
        }).toList();
        
        if (mounted) {
          setState(() {
            _testimonials = testimonialsData;
          });
        }
        return;
      }
      
      final batch = FirebaseFirestore.instance.batch();
      final testimonialsRef = FirebaseFirestore.instance.collection('testimonios');
      
      final exampleTestimonials = [
        {
          'nombre': 'Ana García',
          'carrera': 'Ing. Sistemas - UNFV',
          'mensaje': 'Participar en RSU UNFV ha sido una experiencia transformadora. He podido contribuir a mi comunidad mientras desarrollo habilidades de liderazgo.',
          'rating': 5,
          'aprobado': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'avatar': 'https://images.unsplash.com/photo-1494790108755-2616b612b495?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
        },
        {
          'nombre': 'Carlos Mendoza',
          'carrera': 'Administración - UNFV',
          'mensaje': 'Gracias a RSU UNFV pude participar en proyectos que realmente impactan en la sociedad. La organización es excelente.',
          'rating': 5,
          'aprobado': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
        },
        {
          'nombre': 'María Rodríguez',
          'carrera': 'Derecho - UNFV',
          'mensaje': 'Como estudiante de derecho, encontré en RSU UNFV la oportunidad perfecta para aplicar mis conocimientos en casos reales.',
          'rating': 5,
          'aprobado': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
        },
        {
          'nombre': 'Diego Herrera',
          'carrera': 'Medicina - UNFV',
          'mensaje': 'Los eventos de salud comunitaria organizados por RSU UNFV me han permitido poner en práctica mis conocimientos médicos.',
          'rating': 5,
          'aprobado': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'avatar': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
        },
      ];
      
      for (final testimonial in exampleTestimonials) {
        final docRef = testimonialsRef.doc();
        batch.set(docRef, testimonial);
      }
      
      await batch.commit();
      _logger.i('Successfully created example testimonials');
      
      // Cargar los testimonios recién creados sin recursión
      if (mounted) {
        setState(() {
          _testimonials = exampleTestimonials.map((t) => {
            'name': t['nombre'],
            'role': t['carrera'],
            'message': t['mensaje'],
            'rating': t['rating'],
            'avatar': t['avatar'],
          }).toList();
        });
      }
      
    } catch (e) {
      _logger.e('Error creating example testimonials: $e');
      // Usar datos de fallback para evitar bucle infinito
      if (mounted) {
        setState(() {
          _testimonials = AppConstants.fallbackTestimonials;
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
