import 'package:flutter/material.dart';
import 'package:rsunfv_app/widgets/drawer.dart';
import '../../../services/firebase_auth_services.dart';
import 'dart:async';
import '../../../services/cloudinary_services.dart';
import 'package:table_calendar/table_calendar.dart';

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
  // User and UI state
  String? imageUrl;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Carousel state
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  
  // Data state
  Map<String, dynamic> _realImpactStats = {};
  bool _isLoadingData = true;
  List<Map<String, dynamic>> _upcomingEvents = [];
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

  void _navigateToEventDetail(Map<String, dynamic> event) {
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
        _loadImpactStats(),
        _loadUpcomingEvents(),
        _loadTestimonials(),
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
      debugPrint('Error loading Firebase data: $e');
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
      // Implementation for loading impact statistics
      // This would contain the Firebase queries for stats
      
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
    } catch (e) {
      debugPrint('Error loading impact stats: $e');
      // Handle error
    }
  }

  Future<void> _loadUpcomingEvents() async {
    try {
      // Implementation for loading upcoming events
      // This would contain the Firebase queries for events
      
      if (mounted) {
        setState(() {
          _upcomingEvents = [
            {
              'id': '1',
              'titulo': 'Campaña de Recolección de Alimentos',
              'descripcion': 'Ayuda a familias en necesidad donando alimentos no perecederos',
              'fechaInicio': DateTime.now().add(const Duration(days: 3)),
              'fechaFin': DateTime.now().add(const Duration(days: 5)),
              'ubicacion': 'Universidad Nacional Federico Villarreal',
              'cuposDisponibles': 25,
              'cuposMaximos': 50,
              'imageUrl': 'https://example.com/food-campaign.jpg',
              'categoria': 'Ayuda Social',
            },
            {
              'id': '2',
              'titulo': 'Limpieza de Playas - Chorrillos',
              'descripcion': 'Jornada de limpieza ambiental en las playas de Chorrillos',
              'fechaInicio': DateTime.now().add(const Duration(days: 7)),
              'fechaFin': DateTime.now().add(const Duration(days: 7)),
              'ubicacion': 'Playa Agua Dulce, Chorrillos',
              'cuposDisponibles': 15,
              'cuposMaximos': 30,
              'imageUrl': 'https://example.com/beach-cleanup.jpg',
              'categoria': 'Medio Ambiente',
            },
            {
              'id': '3',
              'titulo': 'Taller de Reciclaje Creativo',
              'descripcion': 'Aprende a crear objetos útiles con materiales reciclados',
              'fechaInicio': DateTime.now().add(const Duration(days: 10)),
              'fechaFin': DateTime.now().add(const Duration(days: 10)),
              'ubicacion': 'Aula Magna - UNFV',
              'cuposDisponibles': 8,
              'cuposMaximos': 20,
              'imageUrl': 'https://example.com/recycling-workshop.jpg',
              'categoria': 'Educación',
            },
          ];
        });
      }
    } catch (e) {
      debugPrint('Error loading upcoming events: $e');
      // Handle error
    }
  }

  Future<void> _loadTestimonials() async {
    try {
      // Implementation for loading testimonials
      // This would contain the Firebase queries for testimonials
      
      if (mounted) {
        setState(() {
          _testimonials = [
            {
              'id': '1',
              'name': 'María González',
              'role': 'Estudiante de Ingeniería',
              'content': 'Participar en RSU UNFV me ha permitido crecer como persona y contribuir de manera significativa a mi comunidad. Es una experiencia transformadora.',
              'rating': 5,
              'imageUrl': 'https://example.com/maria.jpg',
              'date': DateTime.now().subtract(const Duration(days: 15)),
            },
            {
              'id': '2',
              'name': 'Carlos Mendoza',
              'role': 'Egresado de Administración',
              'content': 'Las actividades de responsabilidad social me enseñaron valores de liderazgo y trabajo en equipo que ahora aplico en mi vida profesional.',
              'rating': 5,
              'imageUrl': 'https://example.com/carlos.jpg',
              'date': DateTime.now().subtract(const Duration(days: 30)),
            },
            {
              'id': '3',
              'name': 'Ana Flores',
              'role': 'Docente de Psicología',
              'content': 'Ver el compromiso de nuestros estudiantes con la comunidad es inspirador. RSU UNFV forma ciudadanos conscientes y responsables.',
              'rating': 5,
              'imageUrl': 'https://example.com/ana.jpg',
              'date': DateTime.now().subtract(const Duration(days: 45)),
            },
          ];
        });
      }
    } catch (e) {
      debugPrint('Error loading testimonials: $e');
      // Handle error
    }
  }

  Future<void> _loadCalendarEvents() async {
    try {
      // Implementation for loading calendar events
      // This would contain the Firebase queries for calendar data
      
      if (mounted) {
        setState(() {
          _calendarEvents = {};
          _userRegisteredEvents = [];
        });
      }
    } catch (e) {
      debugPrint('Error loading calendar events: $e');
      // Handle error
    }
  }
}
