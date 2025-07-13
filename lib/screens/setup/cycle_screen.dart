import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../controllers/setup_data_controller.dart';

class CicloScreen extends StatefulWidget {
  final SetupDataController controller;

  const CicloScreen({super.key, required this.controller});

  @override
  State<CicloScreen> createState() => _CicloScreenState();
}

class _CicloScreenState extends State<CicloScreen> {
  final _logger = Logger();
  String? selectedCiclo;
  bool isLoading = false;
  
  final List<String> ciclos = [
    'I ciclo',
    'II ciclo',
    'III ciclo',
    'IV ciclo',
    'V ciclo',
    'VI ciclo',
    'VII ciclo',
    'VIII ciclo',
    'IX ciclo',
    'X ciclo',
  ];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    setState(() => isLoading = true);
    try {
      await widget.controller.init();
      
      setState(() {
        selectedCiclo = widget.controller.usuario.ciclo.isEmpty 
          ? null 
          : widget.controller.usuario.ciclo;
        isLoading = false;
      });
    } catch (e) {
      _logger.e('Error en initializeScreen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar: $e')),
        );
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveCiclo() async {
    if (selectedCiclo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un ciclo')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      widget.controller.updateCiclo(selectedCiclo!);
      await widget.controller.saveUserData();
      
      if (mounted) {
        Navigator.pushNamed(context, '/setup/talla');
      }
    } catch (e) {
      _logger.e('Error guardando ciclo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
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
        title: const Text('Ciclo académico'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu Ciclo',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Selecciona tu ciclo actual',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 40),
                  DropdownButtonFormField<String>(
                    value: selectedCiclo,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Selecciona tu ciclo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    items: ciclos.map((String ciclo) {
                      return DropdownMenuItem<String>(
                        value: ciclo,
                        child: Text(ciclo),
                      );
                    }).toList(),
                    onChanged: isLoading 
                      ? null 
                      : (String? newValue) {
                          setState(() => selectedCiclo = newValue);
                        },
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: isLoading ? null : _saveCiclo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Siguiente'),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Paso 3 de 4',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}