import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/evento.dart';
import '../models/usuario.dart';
import '../services/cloudinary_services.dart';
import '../services/notification_trigger_service.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_routes.dart';
import '../widgets/drawer.dart';
import '../widgets/notification_button.dart';
import 'package:intl/intl.dart';

/// Pantalla mejorada de eventos con filtros avanzados y integración completa con Firestore.
/// 
/// Características:
/// - Filtros por tipo, fecha, estado y ubicación
/// - Búsqueda en tiempo real
/// - Visualización mejorada de eventos
/// - Inscripción/desinscripción en tiempo real
/// - Integración completa con Cloudinary y Firestore
/// - Estados de carga y manejo de errores
class EventosScreenNew extends StatefulWidget {
  const EventosScreenNew({super.key});

  @override
  State<EventosScreenNew> createState() => _EventosScreenNewState();
}

class _EventosScreenNewState extends State<EventosScreenNew> with TickerProviderStateMixin {
  // Services
  static final Logger _logger = Logger();
  
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  
  // Data state
  List<Evento> _allEvents = [];
  List<Evento> _filteredEvents = [];
  List<String> _userRegisteredEvents = [];
  Usuario? _currentUser;
  
  // UI state
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Filter state
  String _selectedCategory = 'todos';
  String _selectedStatus = 'todos';
  String _selectedTimeFilter = 'todos';
  bool _showOnlyAvailable = false;
  bool _showOnlyUserEvents = false;
  
  // Categories
  final List<Map<String, dynamic>> _categories = [
    {'id': 'todos', 'name': 'Todos', 'icon': Icons.apps},
    {'id': 'educacion', 'name': 'Educación', 'icon': Icons.school},
    {'id': 'social', 'name': 'Social', 'icon': Icons.people},
    {'id': 'ambiental', 'name': 'Ambiental', 'icon': Icons.eco},
    {'id': 'salud', 'name': 'Salud', 'icon': Icons.local_hospital},
    {'id': 'deportivo', 'name': 'Deportivo', 'icon': Icons.sports},
    {'id': 'cultural', 'name': 'Cultural', 'icon': Icons.palette},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Implementar scroll infinito si es necesario
    });
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _loadCurrentUser(),
      _loadEvents(),
    ]);
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

  Future<void> _loadEvents() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Cargar eventos desde Firestore
      final query = await FirebaseFirestore.instance
          .collection('eventos')
          .orderBy('createdAt', descending: true)
          .get();

      final events = <Evento>[];
      final userRegisteredEvents = <String>[];
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      for (var doc in query.docs) {
        try {
          _logger.d('Processing event document: ${doc.id}');
          _logger.d('Document data: ${doc.data()}');
          
          final evento = Evento.fromFirestore(doc);
          events.add(evento);
          
          _logger.d('Successfully parsed event: ${evento.titulo}');
          
          // Verificar si el usuario está inscrito
          if (currentUserId != null && 
              evento.voluntariosInscritos.contains(currentUserId)) {
            userRegisteredEvents.add(evento.idEvento);
          }
        } catch (e) {
          _logger.e('Error parsing event ${doc.id}: $e');
          _logger.e('Document data: ${doc.data()}');
        }
      }

      _logger.i('Loaded ${events.length} events successfully');

      if (mounted) {
        setState(() {
          _allEvents = events;
          _userRegisteredEvents = userRegisteredEvents;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      _logger.e('Error loading events: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Error al cargar eventos: ${e.toString()}';
        });
      }
    }
  }

  void _applyFilters() {
    List<Evento> filtered = List.from(_allEvents);
    final searchQuery = _searchController.text.toLowerCase();

    // Filtro de búsqueda
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((event) {
        return event.titulo.toLowerCase().contains(searchQuery) ||
               event.descripcion.toLowerCase().contains(searchQuery) ||
               event.ubicacion.toLowerCase().contains(searchQuery);
      }).toList();
    }

    // Filtro por categoría (basado en el campo 'tipo')
    if (_selectedCategory != 'todos') {
      filtered = filtered.where((event) => 
          event.idTipo.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    // Filtro por estado
    if (_selectedStatus != 'todos') {
      filtered = filtered.where((event) => 
          event.estado.toLowerCase() == _selectedStatus.toLowerCase()).toList();
    }

    // Filtro por tiempo
    final now = DateTime.now();
    if (_selectedTimeFilter != 'todos') {
      switch (_selectedTimeFilter) {
        case 'hoy':
          filtered = filtered.where((event) {
            try {
              final eventDate = DateTime.parse(event.fechaInicio);
              return eventDate.year == now.year &&
                     eventDate.month == now.month &&
                     eventDate.day == now.day;
            } catch (e) {
              return false;
            }
          }).toList();
          break;
        case 'semana':
          final weekFromNow = now.add(const Duration(days: 7));
          filtered = filtered.where((event) {
            try {
              final eventDate = DateTime.parse(event.fechaInicio);
              return eventDate.isAfter(now) && eventDate.isBefore(weekFromNow);
            } catch (e) {
              return false;
            }
          }).toList();
          break;
        case 'mes':
          final monthFromNow = DateTime(now.year, now.month + 1, now.day);
          filtered = filtered.where((event) {
            try {
              final eventDate = DateTime.parse(event.fechaInicio);
              return eventDate.isAfter(now) && eventDate.isBefore(monthFromNow);
            } catch (e) {
              return false;
            }
          }).toList();
          break;
      }
    }

    // Filtro solo disponibles
    if (_showOnlyAvailable) {
      filtered = filtered.where((event) => 
          event.voluntariosInscritos.length < event.cantidadVoluntariosMax).toList();
    }

    // Filtro solo eventos del usuario
    if (_showOnlyUserEvents) {
      filtered = filtered.where((event) => 
          _userRegisteredEvents.contains(event.idEvento)).toList();
    }

    setState(() {
      _filteredEvents = filtered;
    });
  }

  Future<void> _toggleEventRegistration(Evento event) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Debes iniciar sesión para inscribirte', isError: true);
        return;
      }

      // Verificar el estado del evento
      final eventStatus = _getEventStatus(event);
      if (eventStatus.toLowerCase() == 'finalizado') {
        _showSnackBar('No puedes inscribirte a un evento que ya finalizó', isError: true);
        return;
      }
      
      if (eventStatus.toLowerCase() == 'cancelado') {
        _showSnackBar('No puedes inscribirte a un evento cancelado', isError: true);
        return;
      }

      final isRegistered = _userRegisteredEvents.contains(event.idEvento);
      
      // Optimistic update
      setState(() {
        if (isRegistered) {
          _userRegisteredEvents.remove(event.idEvento);
        } else {
          _userRegisteredEvents.add(event.idEvento);
        }
      });

      // Update in Firestore
      final eventRef = FirebaseFirestore.instance
          .collection('eventos')
          .doc(event.idEvento);

      if (isRegistered) {
        // Desinscribirse
        await eventRef.update({
          'voluntariosInscritos': FieldValue.arrayRemove([user.uid])
        });
        _showSnackBar('Te has desinscrito del evento');
      } else {
        // Verificar cupos disponibles
        if (event.voluntariosInscritos.length >= event.cantidadVoluntariosMax) {
          _showSnackBar('No hay cupos disponibles', isError: true);
          // Revertir optimistic update
          setState(() {
            _userRegisteredEvents.remove(event.idEvento);
          });
          return;
        }
        
        // Inscribirse
        await eventRef.update({
          'voluntariosInscritos': FieldValue.arrayUnion([user.uid])
        });
        _showSnackBar('Te has inscrito exitosamente');
        
        // Crear notificación de inscripción
        await NotificationTriggerService.notifyEventRegistration(
          event.idEvento, 
          event.titulo
        );
        
        // Programar recordatorio 24h antes del evento
        try {
          final fechaEvento = DateTime.parse(event.fechaInicio);
          await NotificationTriggerService.scheduleEventReminder(
            event.idEvento,
            event.titulo,
            fechaEvento,
          );
        } catch (e) {
          _logger.w('Error scheduling reminder for event ${event.idEvento}: $e');
        }
      }

      // Reload events to get updated data
      await _loadEvents();
      
    } catch (e) {
      _logger.e('Error toggling event registration: $e');
      _showSnackBar('Error al actualizar inscripción', isError: true);
      
      // Revertir optimistic update
      setState(() {
        if (_userRegisteredEvents.contains(event.idEvento)) {
          _userRegisteredEvents.remove(event.idEvento);
        } else {
          _userRegisteredEvents.add(event.idEvento);
        }
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(),
      drawer: MyDrawer(
        currentImage: _currentUser?.fotoPerfil ?? CloudinaryService.defaultAvatarUrl,
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          _buildTabBar(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Eventos RSU UNFV',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.darkText,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.darkText),
      actions: [
        const NotificationButton(iconColor: AppColors.darkText),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadEvents,
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterModal,
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar eventos...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.greyLight,
            ),
            onChanged: (_) => _applyFilters(),
          ),
          
          const SizedBox(height: 16),
          
          // Category filters
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['id'];
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.mediumText,
                        ),
                        const SizedBox(width: 4),
                        Text(category['name'] as String),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category['id'] as String;
                      });
                      _applyFilters();
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.darkText,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.mediumText,
        indicatorColor: AppColors.primary,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event, size: 20),
                const SizedBox(width: 4),
                Text('Todos (${_filteredEvents.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 20),
                const SizedBox(width: 4),
                Text('Inscritos (${_userRegisteredEvents.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 4),
                const Text('Próximos'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando eventos...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEvents,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildEventsList(_filteredEvents),
        _buildEventsList(_filteredEvents.where((event) =>
            _userRegisteredEvents.contains(event.idEvento)).toList()),
        _buildEventsList(_getUpcomingEvents()),
      ],
    );
  }

  List<Evento> _getUpcomingEvents() {
    final now = DateTime.now();
    return _filteredEvents.where((event) {
      try {
        final eventDate = DateTime.parse(event.fechaInicio);
        return eventDate.isAfter(now);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Widget _buildEventsList(List<Evento> events) {
    if (events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No se encontraron eventos'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return _buildEventCard(events[index]);
        },
      ),
    );
  }

  Widget _buildEventCard(Evento event) {
    final isRegistered = _userRegisteredEvents.contains(event.idEvento);
    final availableSpots = event.cantidadVoluntariosMax - event.voluntariosInscritos.length;
    final isAvailable = availableSpots > 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToEventDetail(event),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image
            _buildEventImage(event),
            
            // Event content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.titulo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      _buildStatusBadge(event),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    event.descripcion,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.mediumText,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Event details
                  _buildEventDetails(event),
                  
                  const SizedBox(height: 16),
                  
                  // Registration info and button
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$availableSpots cupos disponibles',
                              style: TextStyle(
                                fontSize: 12,
                                color: isAvailable ? AppColors.success : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${event.voluntariosInscritos.length}/${event.cantidadVoluntariosMax} inscritos',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.mediumText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildRegistrationButton(event, isRegistered, isAvailable),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage(Evento event) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        image: DecorationImage(
          image: NetworkImage(
            event.foto.isNotEmpty 
                ? event.foto 
                : 'https://images.unsplash.com/photo-1559027615-cd4628902d4a?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
          ),
          fit: BoxFit.cover,
          onError: (_, __) {},
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Duration badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${event.getDuracionHoras().toStringAsFixed(1)}h',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Evento event) {
    Color color;
    String text;
    
    // Calcular el estado real del evento
    String actualStatus = _getEventStatus(event);
    
    switch (actualStatus.toLowerCase()) {
      case 'activo':
        color = AppColors.success;
        text = 'Activo';
        break;
      case 'finalizado':
        color = AppColors.mediumText;
        text = 'Finalizado';
        break;
      case 'lleno':
        color = Colors.orange;
        text = 'Lleno';
        break;
      case 'cancelado':
        color = Colors.red;
        text = 'Cancelado';
        break;
      default:
        color = AppColors.mediumText;
        text = actualStatus;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getEventStatus(Evento event) {
    // Si el evento fue marcado como cancelado, mantener ese estado
    if (event.estado.toLowerCase() == 'cancelado') {
      return 'Cancelado';
    }
    
    // Verificar si el evento ya finalizó (comparar fecha y hora)
    try {
      final eventEndTime = _parseEventEndDateTime(event);
      final now = DateTime.now();
      
      if (eventEndTime.isBefore(now)) {
        return 'Finalizado';
      }
    } catch (e) {
      // Si hay error parsing la fecha, usar la fecha simple
      try {
        String dateStr = event.fechaInicio;
        if (dateStr.contains('T')) {
          dateStr = dateStr.split('T')[0];
        }
        final eventDate = DateTime.parse(dateStr);
        final now = DateTime.now();
        
        // Si la fecha del evento es anterior a hoy, considerarlo finalizado
        if (eventDate.isBefore(DateTime(now.year, now.month, now.day))) {
          return 'Finalizado';
        }
      } catch (e2) {
        // Si no se puede parsear la fecha, mantener el estado original
      }
    }
    
    // Verificar si está lleno (todos los cupos ocupados)
    if (event.voluntariosInscritos.length >= event.cantidadVoluntariosMax) {
      return 'Lleno';
    }
    
    // Si llegamos aquí, el evento está activo
    return 'Activo';
  }

  DateTime _parseEventEndDateTime(Evento event) {
    try {
      final eventDate = DateTime.parse(event.fechaInicio);
      final endTimeParts = event.horaFin.split(':');
      
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
    } catch (e) {
      // Si hay error, usar la fecha del evento + 2 horas como estimación
      try {
        final eventDate = DateTime.parse(event.fechaInicio);
        return eventDate.add(const Duration(hours: 2));
      } catch (e2) {
        // Último recurso: fecha actual
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  Widget _buildEventDetails(Evento event) {
    return Column(
      children: [
        _buildDetailRow(Icons.access_time, _formatDateTime(event)),
        const SizedBox(height: 4),
        _buildDetailRow(Icons.location_on, event.ubicacion),
        const SizedBox(height: 4),
        _buildDetailRow(Icons.assignment, event.requisitos),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.mediumText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mediumText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(Evento event) {
    try {
      final date = DateTime.parse(event.fechaInicio);
      final formatter = DateFormat('dd/MM/yyyy');
      return '${formatter.format(date)} • ${_formatTime12Hour(event.horaInicio)} - ${_formatTime12Hour(event.horaFin)}';
    } catch (e) {
      // Si falla el parsing, intentar extraer solo la fecha del timestamp
      String dateStr = event.fechaInicio;
      if (dateStr.contains('T')) {
        dateStr = dateStr.split('T')[0];
        try {
          final date = DateTime.parse(dateStr);
          final formatter = DateFormat('dd/MM/yyyy');
          return '${formatter.format(date)} • ${_formatTime12Hour(event.horaInicio)} - ${_formatTime12Hour(event.horaFin)}';
        } catch (e2) {
          // Último recurso: formato manual simple
          return '$dateStr • ${_formatTime12Hour(event.horaInicio)} - ${_formatTime12Hour(event.horaFin)}';
        }
      }
      return '$dateStr • ${_formatTime12Hour(event.horaInicio)} - ${_formatTime12Hour(event.horaFin)}';
    }
  }

  String _formatTime12Hour(String timeString) {
    try {
      // Asumiendo que timeString está en formato "HH:mm"
      final parts = timeString.split(':');
      if (parts.length != 2) return timeString;
      
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      
      String period = hour >= 12 ? 'PM' : 'AM';
      
      // Convertir a formato de 12 horas
      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour = hour - 12;
      }
      
      String minuteStr = minute.toString().padLeft(2, '0');
      return '$hour:$minuteStr $period';
    } catch (e) {
      return timeString;
    }
  }

  Widget _buildRegistrationButton(Evento event, bool isRegistered, bool isAvailable) {
    final eventStatus = _getEventStatus(event);
    
    // Si el evento ya finalizó, mostrar botón deshabilitado
    if (eventStatus.toLowerCase() == 'finalizado') {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.schedule, size: 16),
        label: const Text('Finalizado'),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }
    
    // Si el evento está cancelado
    if (eventStatus.toLowerCase() == 'cancelado') {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.cancel, size: 16),
        label: const Text('Cancelado'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          foregroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }
    
    if (isRegistered) {
      return ElevatedButton.icon(
        onPressed: () => _toggleEventRegistration(event),
        icon: const Icon(Icons.check, size: 16),
        label: const Text('Inscrito'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }
    
    if (!isAvailable || eventStatus.toLowerCase() == 'lleno') {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.event_busy, size: 16),
        label: const Text('Sin cupos'),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }
    
    return ElevatedButton.icon(
      onPressed: () => _toggleEventRegistration(event),
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Inscribirse'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showFilterModal,
      icon: const Icon(Icons.tune),
      label: const Text('Filtros'),
      backgroundColor: AppColors.primary,
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    const Text(
                      'Filtros Avanzados',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          _buildFilterSection(
                            'Estado del Evento',
                            [
                              {'id': 'todos', 'name': 'Todos'},
                              {'id': 'activo', 'name': 'Activos'},
                              {'id': 'finalizado', 'name': 'Finalizados'},
                            ],
                            _selectedStatus,
                            (value) => setModalState(() => _selectedStatus = value),
                          ),
                          
                          _buildFilterSection(
                            'Tiempo',
                            [
                              {'id': 'todos', 'name': 'Todos'},
                              {'id': 'hoy', 'name': 'Hoy'},
                              {'id': 'semana', 'name': 'Esta semana'},
                              {'id': 'mes', 'name': 'Este mes'},
                            ],
                            _selectedTimeFilter,
                            (value) => setModalState(() => _selectedTimeFilter = value),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Toggle filters
                          _buildToggleFilter(
                            'Solo eventos disponibles',
                            _showOnlyAvailable,
                            (value) => setModalState(() => _showOnlyAvailable = value),
                          ),
                          
                          _buildToggleFilter(
                            'Solo mis eventos',
                            _showOnlyUserEvents,
                            (value) => setModalState(() => _showOnlyUserEvents = value),
                          ),
                        ],
                      ),
                    ),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedCategory = 'todos';
                                _selectedStatus = 'todos';
                                _selectedTimeFilter = 'todos';
                                _showOnlyAvailable = false;
                                _showOnlyUserEvents = false;
                              });
                            },
                            child: const Text('Limpiar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _applyFilters();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            child: const Text('Aplicar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<Map<String, String>> options,
    String selectedValue,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option['id'];
            return FilterChip(
              label: Text(option['name']!),
              selected: isSelected,
              onSelected: (_) => onChanged(option['id']!),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.darkText,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildToggleFilter(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  void _navigateToEventDetail(Evento event) {
    Navigator.pushNamed(
      context,
      AppRoutes.eventoDetalle,
      arguments: {
        'id': event.idEvento,
      },
    );
  }
}
