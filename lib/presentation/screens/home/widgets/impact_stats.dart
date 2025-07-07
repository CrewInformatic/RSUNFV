import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';

/// Impact statistics widget for the home screen.
/// 
/// Displays key metrics like volunteers, lives impacted, funds raised, etc.
/// Supports both real Firebase data and fallback data with loading states.
class ImpactStats extends StatelessWidget {
  /// Real statistics data from Firebase
  final Map<String, dynamic> realStats;
  
  /// Whether data is currently loading
  final bool isLoading;
  
  /// Whether there was an error loading data
  final bool hasError;

  const ImpactStats({
    super.key,
    required this.realStats,
    required this.isLoading,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isTablet ? 4 : 2;
    
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
          
          // Stats grid
          _buildStatsGrid(crossAxisCount, isTablet),
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
            'Nuestro Impacto',
            style: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Transformando vidas juntos',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: AppColors.mediumText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int crossAxisCount, bool isTablet) {
    final stats = _getDisplayStats();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isTablet ? 1.2 : 1.0,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return _buildStatCard(stats[index], isTablet);
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, bool isTablet) {
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
        border: Border.all(
          color: AppColors.greyMedium.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with background
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(stat['colorValue'] as int).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                stat['icon'] as IconData,
                size: isTablet ? 32 : 28,
                color: Color(stat['colorValue'] as int),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Value with loading state
            if (isLoading)
              _buildLoadingValue(isTablet)
            else
              _buildValue(stat['value'] as String, isTablet),
            
            const SizedBox(height: 4),
            
            // Label
            Text(
              stat['label'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: AppColors.mediumText,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingValue(bool isTablet) {
    return Container(
      width: isTablet ? 60 : 50,
      height: isTablet ? 24 : 20,
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildValue(String value, bool isTablet) {
    return Text(
      value,
      style: TextStyle(
        fontSize: isTablet ? 24 : 20,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
      ),
      textAlign: TextAlign.center,
    );
  }

  List<Map<String, dynamic>> _getDisplayStats() {
    if (hasError || realStats.isEmpty) {
      return AppConstants.fallbackImpactStats;
    }

    return [
      {
        'icon': Icons.people_outline,
        'value': _formatNumber(realStats['volunteers'] ?? 0),
        'label': 'Voluntarios Activos',
        'colorValue': 0xFF667eea,
      },
      {
        'icon': Icons.favorite_outline,
        'value': _formatNumber(realStats['livesImpacted'] ?? 0),
        'label': 'Vidas Impactadas',
        'colorValue': 0xFFf5576c,
      },
      {
        'icon': Icons.attach_money,
        'value': _formatCurrency(realStats['fundsRaised'] ?? 0.0),
        'label': 'Fondos Recaudados',
        'colorValue': 0xFF4facfe,
      },
      {
        'icon': Icons.eco_outlined,
        'value': _formatNumber(realStats['activeProjects'] ?? 0),
        'label': 'Proyectos Activos',
        'colorValue': 0xFF2dd4bf,
      },
    ];
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      final formatter = NumberFormat('#,###', 'es_PE');
      return formatter.format(number);
    }
    return number.toString();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/. ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}
