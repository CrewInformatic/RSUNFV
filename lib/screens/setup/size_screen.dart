import 'package:flutter/material.dart';
import '../../controllers/setup_data_controller.dart';

class TallaScreen extends StatefulWidget {
  final SetupDataController controller;

  const TallaScreen({super.key, required this.controller});

  @override
  State<TallaScreen> createState() => _TallaScreenState();
}

class _TallaScreenState extends State<TallaScreen> {
  bool isLoading = false;
  String? selectedTalla;

  final List<Map<String, String>> tallas = [
    {'id': 'XS', 'nombre': 'Extra Small (XS)'},
    {'id': 'S', 'nombre': 'Small (S)'},
    {'id': 'M', 'nombre': 'Medium (M)'},
    {'id': 'L', 'nombre': 'Large (L)'},
    {'id': 'XL', 'nombre': 'Extra Large (XL)'},
    {'id': 'XXL', 'nombre': 'Double Extra Large (XXL)'},
  ];

  @override
  void initState() {
    super.initState();
    _initController().then((_) {
      if (mounted) {
        setState(() {
          selectedTalla = widget.controller.usuario.poloTallaID;
        });
      }
    });
  }

  Future<void> _initController() async {
    setState(() => isLoading = true);
    try {
      await widget.controller.init();
      setState(() => isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar: $e')),
        );
      }
      setState(() => isLoading = false);
    }
  }

  void _showConfirmationDialog(BuildContext context, String tallaId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar selección'),
          content: const Text('¿Estás seguro de tu selección de talla?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Cierra el diálogo
                await _saveTallaAndNavigate(tallaId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveTallaAndNavigate(String tallaId) async {
    setState(() => isLoading = true);
    try {
      // Actualizar la talla
      widget.controller.updateTalla(tallaId);
      final success = await widget.controller.saveUserData();
      
      if (success && mounted) {
        // Navegar a la pantalla principal y limpiar el stack de navegación
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home', 
          (route) => false, 
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al guardar los datos'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Talla de polo'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Selecciona tu talla de polo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: tallas.length,
                    itemBuilder: (context, index) {
                      final talla = tallas[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(talla['nombre']!),
                          selected: selectedTalla == talla['id'],
                          selectedTileColor: Colors.orange.shade100,
                          onTap: () {
                            setState(() => selectedTalla = talla['id']);
                            _showConfirmationDialog(context, talla['id']!);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black45,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}