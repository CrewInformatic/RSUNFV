import 'package:flutter/material.dart';

class PerfilHeader extends StatelessWidget {
  final String imagePath;
  final bool isNetwork;
  final VoidCallback? onCameraTap;

  const PerfilHeader({
    super.key,
    required this.imagePath,
    this.isNetwork = false,
    this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: isNetwork
                  ? NetworkImage(imagePath)       
                  : AssetImage(imagePath) as ImageProvider,
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: onCameraTap,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 18,
                  child: Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}