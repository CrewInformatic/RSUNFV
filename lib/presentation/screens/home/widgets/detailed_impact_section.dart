import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/enhanced_impact_service.dart';
import 'package:intl/intl.dart';

class DetailedImpactSection extends StatefulWidget {
  const DetailedImpactSection({super.key});

  @override
  State<DetailedImpactSection> createState() => _DetailedImpactSectionState();
}

class _DetailedImpactSectionState extends State<DetailedImpactSection> {
  Map<String, dynamic> _detailedStats = {};
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadDetailedStats();
  }

  Future<void> _loadDetailedStats() async {
    try {
      final stats = await EnhancedImpactService.getCompleteImpactStats();

      if (mounted) {
        setState(() {
          _detailedStats = stats;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

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
          if (_isLoading)
            _buildLoadingState(isTablet)
          else if (_hasError)
            _buildErrorState(isTablet)
          else
            _buildDetailedStats(isTablet),
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
            'Impacto Detallado',
            style: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Análisis completo de nuestro trabajo social',
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
    return Container(
      height: isTablet ? 300 : 250,
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
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isTablet) {
    return Container(
      height: isTablet ? 300 : 250,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: isTablet ? 48 : 40,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar estadísticas',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mostrando datos de ejemplo',
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: AppColors.mediumText,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDetailedStats,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(bool isTablet) {
    final donations = _detailedStats['donations'] as Map<String, dynamic>? ?? {};
    final events = _detailedStats['events'] as Map<String, dynamic>? ?? {};
    final impact = _detailedStats['communityImpact'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        _buildDonationsCard(donations, isTablet),
        const SizedBox(height: 16),
        
        _buildEventsCard(events, isTablet),
        const SizedBox(height: 16),
        
        _buildCommunityImpactCard(impact, isTablet),
        const SizedBox(height: 16),
        
        _buildEnvironmentalImpactCard(impact, isTablet),
      ],
    );
  }

  Widget _buildDonationsCard(Map<String, dynamic> donations, bool isTablet) {
    final totalAmount = donations['totalAmount'] as double? ?? 0.0;
    final approvedCount = donations['approvedCount'] as int? ?? 0;
    final pendingCount = donations['pendingCount'] as int? ?? 0;
    final thisMonthCount = donations['thisMonthCount'] as int? ?? 0;

    return Container(
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
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.attach_money,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Donaciones Recaudadas',
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total acumulado y estadísticas',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: AppColors.mediumText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Recaudado',
                    _formatCurrency(totalAmount),
                    Colors.green,
                    isTablet,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Aprobadas',
                    approvedCount.toString(),
                    Colors.blue,
                    isTablet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Pendientes',
                    pendingCount.toString(),
                    Colors.orange,
                    isTablet,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Este Mes',
                    thisMonthCount.toString(),
                    Colors.purple,
                    isTablet,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsCard(Map<String, dynamic> events, bool isTablet) {
    final totalEvents = events['totalEvents'] as int? ?? 0;
    final activeEvents = events['activeEvents'] as int? ?? 0;
    final finishedEvents = events['finishedEvents'] as int? ?? 0;
    final totalParticipants = events['totalParticipants'] as int? ?? 0;
    final volunteerHours = events['totalVolunteerHours'] as double? ?? 0.0;

    return Container(
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
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eventos y Participación',
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Actividades realizadas y en curso',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: AppColors.mediumText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Eventos',
                    totalEvents.toString(),
                    Colors.blue,
                    isTablet,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Activos',
                    activeEvents.toString(),
                    Colors.green,
                    isTablet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Finalizados',
                    finishedEvents.toString(),
                    Colors.purple,
                    isTablet,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Participantes',
                    totalParticipants.toString(),
                    Colors.orange,
                    isTablet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Horas de Voluntariado',
              '${volunteerHours.toStringAsFixed(0)} hrs',
              Colors.red,
              isTablet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityImpactCard(Map<String, dynamic> impact, bool isTablet) {
    final livesImpacted = impact['livesImpacted'] as int? ?? 0;
    final institutions = impact['beneficiaryInstitutions'] as int? ?? 0;
    final socialProjects = impact['socialProjects'] as int? ?? 0;
    final educationalPrograms = impact['educationalPrograms'] as int? ?? 0;

    return Container(
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
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.pink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.pink,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Impacto Comunitario',
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Personas e instituciones beneficiadas',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: AppColors.mediumText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Vidas Impactadas',
                    _formatNumber(livesImpacted),
                    Colors.pink,
                    isTablet,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Instituciones',
                    institutions.toString(),
                    Colors.indigo,
                    isTablet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Proyectos Sociales',
                    socialProjects.toString(),
                    Colors.teal,
                    isTablet,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Prog. Educativos',
                    educationalPrograms.toString(),
                    Colors.amber,
                    isTablet,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentalImpactCard(Map<String, dynamic> impact, bool isTablet) {
    final environmentalImpact = impact['environmentalImpact'] as Map<String, dynamic>? ?? {};
    final treesPlanted = environmentalImpact['treesPlanted'] as int? ?? 0;
    final wasteCollected = environmentalImpact['wasteCollected'] as int? ?? 0;
    final recycledItems = environmentalImpact['recycledItems'] as int? ?? 0;
    final sustainabilityScore = impact['sustainabilityScore'] as double? ?? 0.0;

    return Container(
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
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Impacto Ambiental',
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Contribución al medio ambiente',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: AppColors.mediumText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Árboles Plantados',
                    treesPlanted.toString(),
                    Colors.green,
                    isTablet,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Residuos (kg)',
                    wasteCollected.toString(),
                    Colors.brown,
                    isTablet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Reciclados',
                    recycledItems.toString(),
                    Colors.blue,
                    isTablet,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Sostenibilidad',
                    '${sustainabilityScore.toStringAsFixed(1)}%',
                    Colors.green,
                    isTablet,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isTablet) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 12 : 11,
              color: AppColors.mediumText,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/. ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatNumber(int number) {
    final formatter = NumberFormat('#,###', 'es_PE');
    return formatter.format(number);
  }
}
