import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_colors.dart';

class EventsCalendar extends StatelessWidget {
  final CalendarFormat calendarFormat;
  
  final DateTime focusedDay;
  
  final DateTime? selectedDay;
  
  final Map<DateTime, List<dynamic>> calendarEvents;
  
  final List<Map<String, dynamic>> userRegisteredEvents;
  
  final Function(CalendarFormat) onFormatChanged;
  
  final Function(DateTime) onFocusedDayChanged;
  
  final Function(DateTime, DateTime) onDaySelected;

  const EventsCalendar({
    super.key,
    required this.calendarFormat,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarEvents,
    required this.userRegisteredEvents,
    required this.onFormatChanged,
    required this.onFocusedDayChanged,
    required this.onDaySelected,
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
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(isTablet),
          
          _buildCalendar(isTablet),
          
          if (selectedDay != null && _getEventsForDay(selectedDay!).isNotEmpty)
            _buildSelectedDayEvents(isTablet),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calendario de Eventos',
            style: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Próximas actividades y fechas importantes',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: AppColors.mediumText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
      child: TableCalendar<dynamic>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: focusedDay,
        calendarFormat: calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(
            color: AppColors.error,
            fontSize: isTablet ? 16 : 14,
          ),
          defaultTextStyle: TextStyle(
            fontSize: isTablet ? 16 : 14,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          markerSize: 6,
          cellMargin: const EdgeInsets.all(4),
        ),
        
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          formatButtonTextStyle: const TextStyle(
            color: AppColors.white,
            fontSize: 12,
          ),
          titleTextStyle: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
        
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontSize: isTablet ? 14 : 12,
            fontWeight: FontWeight.w600,
            color: AppColors.mediumText,
          ),
          weekendStyle: TextStyle(
            fontSize: isTablet ? 14 : 12,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        
        selectedDayPredicate: (day) {
          return isSameDay(selectedDay, day);
        },
        onDaySelected: onDaySelected,
        onFormatChanged: onFormatChanged,
        onPageChanged: onFocusedDayChanged,
      ),
    );
  }

  Widget _buildSelectedDayEvents(bool isTablet) {
    final events = _getEventsForDay(selectedDay!);
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Eventos del día',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          ...events.map((event) => _buildEventItem(event, isTablet)),
        ],
      ),
    );
  }

  Widget _buildEventItem(dynamic event, bool isTablet) {
    final isRegistered = userRegisteredEvents.any(
      (userEvent) => userEvent['id'] == event['id'],
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: isRegistered 
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.greyLight,
        borderRadius: BorderRadius.circular(8),
        border: isRegistered 
            ? Border.all(color: AppColors.success, width: 1)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isRegistered ? AppColors.success : AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'] ?? 'Evento sin título',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                if (event['time'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    event['time'],
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: AppColors.mediumText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          if (isRegistered)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Inscrito',
                style: TextStyle(
                  fontSize: isTablet ? 12 : 10,
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return calendarEvents[DateTime(day.year, day.month, day.day)] ?? [];
  }
}
