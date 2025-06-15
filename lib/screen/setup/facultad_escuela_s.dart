import 'package:flutter/material.dart';
import '../../controllers/setup_data_controller.dart';
import '../../models/facultad.dart';
import '../../models/escuela.dart';

class FacultadScreen extends StatefulWidget {
  final SetupDataController controller;

  const FacultadScreen({Key? key, required this.controller}) : super(key: key);

  @override
  _FacultadScreenState createState() => _FacultadScreenState();
}

class _FacultadScreenState extends State<FacultadScreen> {
  bool isLoading = false;
  bool isInitialized = false;
  String? selectedFacultadId;
  String? selectedEscuelaId;
  List<Facultad> facultades = [];
  List<Escuela> escuelas = [];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    setState(() => isLoading = true);
    try {
      await widget.controller.init();
      final facs = await widget.controller.getFacultades();
      
      // Depuración
      print('Facultades cargadas: ${facs.length}');
      facs.forEach((f) => print('Facultad: ${f.idFacultad} - ${f.nombreFacultad}'));
      
      if (mounted) {
        setState(() {
          facultades = facs;
          // Inicialmente no seleccionamos ninguna facultad
          selectedFacultadId = null;
          isInitialized = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error en _initializeScreen: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inicializar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facultad y Escuela'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView( // Add this
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu Facultad',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Selecciona tu facultad y escuela profesional',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 40),
                    // Dropdown Facultad
                    if (facultades.isEmpty)
                      Center(
                        child: Text('No hay facultades disponibles'),
                      )
                    else
                      DropdownButtonFormField<String>(
                        isExpanded: true, // Add this
                        value: selectedFacultadId,
                        hint: const Text('Selecciona una facultad'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        items: facultades.map((Facultad facultad) {
                          return DropdownMenuItem<String>(
                            value: facultad.idFacultad,
                            child: Text(
                              facultad.nombreFacultad,
                              overflow: TextOverflow.ellipsis, // Add this
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) async {
                          if (newValue != null) {
                            setState(() {
                              selectedFacultadId = newValue;
                              selectedEscuelaId = null;
                              escuelas.clear();
                            });
                            await _loadEscuelas(newValue);
                          }
                        },
                      ),
                    if (escuelas.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      // Dropdown Escuela - Only show if facultad is selected
                      DropdownButtonFormField<String>(
                        isExpanded: true, // Add this
                        value: selectedEscuelaId,
                        hint: const Text('Selecciona una escuela'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        items: escuelas.map((Escuela escuela) {
                          return DropdownMenuItem<String>(
                            value: escuela.idEscuela,
                            child: Text(
                              escuela.nombreEscuela,
                              overflow: TextOverflow.ellipsis, // Add this
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedEscuelaId = newValue;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: isLoading ? null : _saveFacultadEscuela,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text('Siguiente'),
                    ),
                  ],
                ),
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

  Future<void> _saveFacultadEscuela() async {
    if (selectedFacultadId == null || selectedEscuelaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor selecciona una facultad y escuela'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await widget.controller.updateFacultadEscuela(
        selectedFacultadId!,
        selectedEscuelaId!,
      );

      if (mounted) {
        // Navigate to next setup screen
        Navigator.pushNamed(context, '/setup/ciclo');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
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

  Future<void> _loadEscuelas(String facultadId) async {
    setState(() => isLoading = true);
    try {
      print('Cargando escuelas para facultad: $facultadId');
      final loadedEscuelas = await widget.controller.getEscuelasByFacultad(facultadId);
      print('Escuelas cargadas: ${loadedEscuelas.length}');
      loadedEscuelas.forEach((e) => print('Escuela: ${e.idEscuela} - ${e.nombreEscuela}'));
      
      if (mounted) {
        setState(() {
          escuelas = loadedEscuelas;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando escuelas: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando escuelas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}