import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class TestimonialsSection extends StatefulWidget {
  final List<Map<String, dynamic>> testimonials;
  
  final bool isLoading;
  
  final bool hasError;

  const TestimonialsSection({
    super.key,
    required this.testimonials,
    required this.isLoading,
    required this.hasError,
  });

  @override
  State<TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends State<TestimonialsSection> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    final displayTestimonials = widget.hasError || widget.testimonials.isEmpty
        ? AppConstants.fallbackTestimonials
        : widget.testimonials;
    
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
          
          if (widget.isLoading)
            _buildLoadingState(isTablet)
          else
            _buildTestimonialsCarousel(displayTestimonials, isTablet),
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
            'Testimonios',
            style: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lo que dicen nuestros voluntarios',
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
      height: isTablet ? 200 : 180,
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildTestimonialsCarousel(
    List<Map<String, dynamic>> testimonials,
    bool isTablet,
  ) {
    return Column(
      children: [
        Container(
          constraints: BoxConstraints(
            minHeight: isTablet ? 240 : 220,
            maxHeight: isTablet ? 400 : 350,
          ),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: testimonials.length,
            itemBuilder: (context, index) {
              return _buildTestimonialCard(testimonials[index], isTablet);
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        _buildPageIndicators(testimonials.length),
      ],
    );
  }

  Widget _buildTestimonialCard(Map<String, dynamic> testimonial, bool isTablet) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.all(isTablet ? 24 : 20),
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
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isTablet ? 30 : 25,
                backgroundImage: NetworkImage(
                  testimonial['avatar'] ?? AppConstants.defaultProfileImageUrl,
                ),
                onBackgroundImageError: (_, __) {},
                child: testimonial['avatar'] == null
                    ? Icon(
                        Icons.person,
                        size: isTablet ? 30 : 25,
                        color: AppColors.white,
                      )
                    : null,
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testimonial['name'] ?? 'Usuario Anónimo',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      testimonial['role'] ?? 'Voluntario',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: AppColors.mediumText,
                      ),
                    ),
                  ],
                ),
              ),
              
              _buildStarRating(testimonial['rating'] ?? 5, isTablet),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Icon(
            Icons.format_quote,
            size: isTablet ? 32 : 28,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          
          const SizedBox(height: 8),
          
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                testimonial['message'] ?? 'Sin comentarios disponibles.',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: AppColors.darkText,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(int rating, bool isTablet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          size: isTablet ? 20 : 16,
          color: index < rating ? AppColors.warning : AppColors.greyMedium,
        );
      }),
    );
  }

  Widget _buildPageIndicators(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: AppConstants.standardAnimationDuration,
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentIndex == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentIndex == index
                  ? AppColors.primary
                  : AppColors.greyMedium,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
