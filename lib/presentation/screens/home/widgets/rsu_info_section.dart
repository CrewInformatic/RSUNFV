import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class RsuInfoSection extends StatelessWidget {
  const RsuInfoSection({super.key});

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
          
          _buildInfoCards(isTablet),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(bool isTablet) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Sobre RSU UNFV',
          style: TextStyle(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards(bool isTablet) {
    final infoItems = [
      {
        'icon': Icons.school,
        'title': 'Nuestra Misión',
        'description': 'Formar profesionales comprometidos con el desarrollo sostenible y la transformación social de nuestro país.',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.group,
        'title': 'Comunidad Activa',
        'description': 'Miles de estudiantes, docentes y egresados unidos en proyectos de impacto social y ambiental.',
        'color': AppColors.info,
      },
      {
        'icon': Icons.eco,
        'title': 'Compromiso Ambiental',
        'description': 'Iniciativas sostenibles que contribuyen al cuidado del medio ambiente y la preservación del planeta.',
        'color': AppColors.success,
      },
    ];

    return Column(
      children: infoItems.map((item) => _buildInfoCard(
        icon: item['icon'] as IconData,
        title: item['title'] as String,
        description: item['description'] as String,
        color: item['color'] as Color,
        isTablet: isTablet,
      )).toList(),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isTablet,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyMedium.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isTablet ? 56 : 48,
            height: isTablet ? 56 : 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: isTablet ? 28 : 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 14,
                    color: AppColors.mediumText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
