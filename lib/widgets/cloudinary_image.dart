import 'package:flutter/material.dart';

class CloudinaryImage extends StatefulWidget {
  final String cloudinaryUrl;
  final String fallbackUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const CloudinaryImage({
    super.key,
    required this.cloudinaryUrl,
    required this.fallbackUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  State<CloudinaryImage> createState() => _CloudinaryImageState();
}

class _CloudinaryImageState extends State<CloudinaryImage> {
  bool _useFallback = false;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_isLoading)
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade200,
                  Colors.grey.shade300,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey,
              ),
            ),
          ),
        Image.network(
          _useFallback ? widget.fallbackUrl : widget.cloudinaryUrl,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              });
              return child;
            }
            return Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.shade300,
                    Colors.grey.shade200,
                    Colors.grey.shade300,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Error loading image: $error');
            if (!_useFallback) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _useFallback = true;
                    _isLoading = false;
                  });
                }
              });
              return Container(
                width: widget.width,
                height: widget.height,
                color: Colors.grey.shade300,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey,
                  ),
                ),
              );
            } else {
              return Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.shade400,
                      Colors.grey.shade300,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 50,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
