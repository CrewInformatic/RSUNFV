import 'package:flutter/material.dart';
import 'package:rsunfv_app/widgets/drawer.dart';
import '../services/firebase_auth_services.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../services/cloudinary_services.dart';

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
      debugPrint('Error loading user image: $e');
      if (mounted) {
        setState(() {
          imageUrl = CloudinaryService.defaultAvatarUrl;
        });
      }
    }
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
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
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
                    
                    // Acciones rápidas
                    _buildQuickActionsSection(),
                    
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
    // return Container( // sized_box_for_whitespace
    return SizedBox(
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
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
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
                                : Colors.white.withValues(alpha: 0.4),
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
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nuestro Impacto',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Juntos estamos cambiando el mundo, una acción a la vez',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: _impactStats.length,
            itemBuilder: (context, index) {
              final stat = _impactStats[index];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: stat['color'].withValues(alpha: 0.1),
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
                        color: stat['color'].withValues(alpha: 0.1),
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
                            color: action['color'].withValues(alpha: 0.1),
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
                              color: action['color'].withValues(alpha: 0.1),
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

  Widget _buildUpcomingEventsSection() {
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
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _upcomingEvents.length,
              itemBuilder: (context, index) {
                final event = _upcomingEvents[index];
                return Container(
                  width: 300,
                  margin: EdgeInsets.only(right: index < _upcomingEvents.length - 1 ? 16 : 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
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
                                  color: Colors.white.withValues(alpha: 0.9),
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
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _testimonials.length,
              itemBuilder: (context, index) {
                final testimonial = _testimonials[index];
                return Container(
                  width: 320,
                  margin: EdgeInsets.only(right: index < _testimonials.length - 1 ? 16 : 0),
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
                        color: const Color(0xFF667eea).withValues(alpha: 0.3),
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
            color: Colors.black.withValues(alpha: 0.1),
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
                    color: Colors.black.withValues(alpha: 0.2),
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
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
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
              color: const Color(0xFF667eea).withValues(alpha: 0.1),
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
          color: isActive ? const Color(0xFF667eea).withValues(alpha: 0.1) : Colors.transparent,
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
