import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Footer section widget for the home screen.
/// 
/// Displays important links, contact information, and app version.
class HomeFooter extends StatelessWidget {
  /// Callback for navigation
  final Function(String route) onNavigate;

  const HomeFooter({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: 16,
      ),
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, Color(0xFF2D3748)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(isTablet),
          
          const SizedBox(height: 24),
          
          // Content
          if (isTablet)
            _buildTabletLayout()
          else
            _buildMobileLayout(),
          
          const SizedBox(height: 20),
          
          // Bottom section
          _buildBottomSection(isTablet),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Row(
      children: [
        Container(
          width: isTablet ? 56 : 48,
          height: isTablet ? 56 : 48,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/logo_rsu.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RSU UNFV',
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                'Responsabilidad Social Universitaria',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: AppColors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildQuickLinks()),
        const SizedBox(width: 32),
        Expanded(child: _buildContactInfo()),
        const SizedBox(width: 32),
        Expanded(child: _buildSocialLinks()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildQuickLinks(),
        const SizedBox(height: 24),
        _buildContactInfo(),
        const SizedBox(height: 24),
        _buildSocialLinks(),
      ],
    );
  }

  Widget _buildQuickLinks() {
    final links = [
      {'title': 'Eventos', 'route': '/eventos'},
      {'title': 'Donaciones', 'route': '/donaciones'},
      {'title': 'Mi Perfil', 'route': '/perfil'},
      {'title': 'Juegos', 'route': '/games'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enlaces Rápidos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        
        const SizedBox(height: 12),
        
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => onNavigate(link['route'] as String),
            child: Text(
              link['title'] as String,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.white.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contacto',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        
        const SizedBox(height: 12),
        
        _buildContactItem(
          icon: Icons.location_on,
          text: 'Jr. Carlos Gonzales 285, Lima',
        ),
        
        const SizedBox(height: 8),
        
        _buildContactItem(
          icon: Icons.phone,
          text: '+51 1 748-0888',
        ),
        
        const SizedBox(height: 8),
        
        _buildContactItem(
          icon: Icons.email,
          text: 'rsu@unfv.edu.pe',
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.white.withOpacity(0.8),
        ),
        
        const SizedBox(width: 8),
        
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Síguenos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            _buildSocialButton(
              icon: Icons.facebook,
              onTap: () {
                // Navigate to Facebook
              },
            ),
            
            const SizedBox(width: 12),
            
            _buildSocialButton(
              icon: Icons.camera_alt, // Instagram
              onTap: () {
                // Navigate to Instagram
              },
            ),
            
            const SizedBox(width: 12),
            
            _buildSocialButton(
              icon: Icons.video_camera_back, // YouTube
              onTap: () {
                // Navigate to YouTube
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppColors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildBottomSection(bool isTablet) {
    return Column(
      children: [
        Divider(
          color: AppColors.white.withOpacity(0.2),
          thickness: 1,
        ),
        
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '© 2024 Universidad Nacional Federico Villarreal',
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: AppColors.white.withOpacity(0.6),
              ),
            ),
            
            Text(
              'v1.0.0',
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: AppColors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
