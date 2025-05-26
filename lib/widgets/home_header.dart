import 'package:flutter/material.dart';
import '../utils/colors.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onToggleMenu;

  const HomeHeader({super.key, required this.onToggleMenu});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ícono de menú hamburguesa + Logo
              Row(
                children: [
                  Builder(
                    builder: (context) => // 🔸 Para evitar problemas de contexto
                        IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    color: AppColors.orangeColors,
                    child: const Center(
                      child: Text(
                        'UNFV',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'UNIVERSIDAD\nNACIONAL FEDERICO\nVILLAREAL',
                        style: TextStyle(
                          color: AppColors.orangeLightColors,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Ícono de home
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: onToggleMenu,
              ),
            ],
          ),
        ),

        // Línea divisoria
        const Divider(
          height: 1,
          thickness: 0.7,
          color: Color(0xFFE0E0E0),
        ),
      ],
    );
  }
}
