import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Upcoming events widget for the home screen.
/// 
/// Displays a horizontal list of upcoming events with registration capabilities.
class UpcomingEvents extends StatelessWidget {
  /// List of upcoming events from Firebase
  final List<Map<String, dynamic>> events;
  
  /// Whether data is currently loading
  final bool isLoading;
  
  /// Whether there was an error loading data
  final bool hasError;
  
  /// Callback when an event is tapped
  final Function(Map<String, dynamic> event) onEventTap;

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
          // Section title
          _buildSectionTitle(isTablet),
          
          const SizedBox(height: 16),
          
          // Events list
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
            'Próximos Eventos',
            style: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Únete a nuestras próximas actividades',
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

  Widget _buildEventCard(Map<String, dynamic> event, bool isTablet) {
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
            // Event image
            _buildEventImage(event, isTablet),
            
            // Event content
            _buildEventContent(event, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage(Map<String, dynamic> event, bool isTablet) {
    return Container(
      height: isTablet ? 120 : 100,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        image: DecorationImage(
          image: NetworkImage(
            event['image'] ?? 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80',
          ),
          fit: BoxFit.cover,
          onError: (_, __) {},
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay
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
          
          // Category badge
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
                event['category'] ?? 'General',
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

  Widget _buildEventContent(Map<String, dynamic> event, bool isTablet) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event title
            Text(
              event['title'] ?? 'Evento sin título',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            // Event details
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
                    '${event['date']} • ${event['time']}',
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
                    event['location'] ?? 'Ubicación por confirmar',
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
            
            // Volunteers count
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: isTablet ? 16 : 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  '${event['volunteers']} voluntarios',
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
}
