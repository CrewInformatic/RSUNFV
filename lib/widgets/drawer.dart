import 'package:flutter/material.dart';
import 'perfil_header.dart'; // Asegúrate de importar tu PerfilHeader
import '../screen/home_s.dart';
import '../screen/perfil_s.dart';

class MyDrawer extends StatelessWidget {
  final String currentImage;

  const MyDrawer({
    super.key,
    required this.currentImage,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: Colors.orange.shade700,
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: PerfilHeader(
              imagePath: currentImage,
              isNetwork: true,
              onCameraTap: () {},
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  HomeScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Perfil'),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  PerfilScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
