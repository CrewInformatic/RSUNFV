﻿import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/evento.dart';

class UpcomingEvents extends StatelessWidget {
  final List<Evento> events;
  
  final bool isLoading;
  
  final bool hasError;
  
  final Function(Evento event) onEventTap;

  const UpcomingEvents({
    super.key,
    required this.events,
    required this.isLoading,
    required this.hasError,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(isTablet),
          
          const SizedBox(height: 16),
          
          if (isLoading)
            _buildLoadingState(isTablet)
          else if (hasError || events.isEmpty)
            _buildEmptyState(isTablet)
          else
            _buildEventsList(isTablet),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(bool isTablet) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Eventos RSU',
            style: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Próximos, en curso y finalizados recientemente',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: AppColors.mediumText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isTablet) {
    return SizedBox(
      height: isTablet ? 240 : 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: isTablet ? 300 : 280,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet) {
    return Container(
      height: isTablet ? 240 : 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.greyMedium.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: isTablet ? 64 : 48,
            color: AppColors.mediumText,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay eventos próximos',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mantente atento para nuevas actividades',
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: AppColors.mediumText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(bool isTablet) {
    return SizedBox(
      height: isTablet ? 240 : 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        itemBuilder: (context, index) {
          return _buildEventCard(events[index], isTablet);
        },
      ),
    );
  }

  Widget _buildEventCard(Evento event, bool isTablet) {
    return GestureDetector(
      onTap: () => onEventTap(event),
      child: Container(
        width: isTablet ? 300 : 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventImage(event, isTablet),
            
            _buildEventContent(event, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage(Evento event, bool isTablet) {
    return Container(
      height: isTablet ? 120 : 100,
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
      child: Stack(
        children: [
          Container(
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
          ),
          
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Voluntariado',
                style: TextStyle(
                  fontSize: isTablet ? 12 : 10,
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventContent(Evento event, bool isTablet) {
    final eventStatus = _getEventStatus(event);
    final statusColor = _getStatusColor(eventStatus);
    
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.titulo,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(eventStatus),
                        color: Colors.white,
                        size: 10,
                      ),
                      SizedBox(width: 2),
                      Text(
                        _getStatusText(eventStatus),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: isTablet ? 16 : 14,
                  color: AppColors.mediumText,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${_formatDate(event.fechaInicio)} • ${_formatTime12Hour(event.horaInicio)}',
                    style: TextStyle(
                      fontSize: isTablet ? 12 : 11,
                      color: AppColors.mediumText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: isTablet ? 16 : 14,
                  color: AppColors.mediumText,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.ubicacion,
                    style: TextStyle(
                      fontSize: isTablet ? 12 : 11,
                      color: AppColors.mediumText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: isTablet ? 16 : 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  '${event.voluntariosInscritos.length}/${event.cantidadVoluntariosMax} voluntarios',
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime12Hour(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return timeString;
      
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      
      String period = hour >= 12 ? 'PM' : 'AM';
      
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

  String _getEventStatus(Evento event) {
    try {
      final now = DateTime.now();
      
      final eventStartDate = DateTime.parse(event.fechaInicio);
      
      final startTimeParts = event.horaInicio.split(':');
      final eventStartDateTime = DateTime(
        eventStartDate.year,
        eventStartDate.month,
        eventStartDate.day,
        startTimeParts.length >= 2 ? int.parse(startTimeParts[0]) : 0,
        startTimeParts.length >= 2 ? int.parse(startTimeParts[1]) : 0,
      );
      
      final eventEndDateTime = _parseEventEndDateTime(event);
      
      final dbStatus = event.estado.toLowerCase();
      if (dbStatus == 'cancelado' || dbStatus == 'cancelled') {
        return 'cancelled';
      }
      if (dbStatus == 'finalizado' || dbStatus == 'finished') {
        return 'finished';
      }
      
      if (now.isBefore(eventStartDateTime)) {
        if (dbStatus == 'activo') {
          return 'upcoming';
        } else {
          return 'inactive';
        }
      } else if (now.isAfter(eventEndDateTime)) {
        return 'finished';
      } else {
        return 'ongoing';
      }
    } catch (e) {
      final dbStatus = event.estado.toLowerCase();
      return dbStatus == 'activo' ? 'upcoming' : dbStatus;
    }
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
      
      return DateTime(eventDate.year, eventDate.month, eventDate.day, 23, 59);
    } catch (e) {
      final eventDate = DateTime.parse(event.fechaInicio);
      return eventDate.add(Duration(days: 1));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'upcoming':
        return Colors.blue;
      case 'ongoing':
        return Colors.orange;
      case 'finished':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'upcoming':
        return 'DISPONIBLE';
      case 'ongoing':
        return 'EN CURSO';
      case 'finished':
        return 'FINALIZADO';
      case 'inactive':
        return 'NO DISPONIBLE';
      case 'cancelled':
        return 'CANCELADO';
      default:
        return 'DESCONOCIDO';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'upcoming':
        return Icons.event_available;
      case 'ongoing':
        return Icons.play_circle;
      case 'finished':
        return Icons.check_circle;
      case 'inactive':
        return Icons.event_busy;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
