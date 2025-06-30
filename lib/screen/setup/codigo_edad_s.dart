import 'package:flutter/material.dart';
import '../../controllers/setup_data_controller.dart';

class CodigoEdadScreen extends StatefulWidget {
  final SetupDataController controller;

  const CodigoEdadScreen({super.key, required this.controller});

  @override
  State<CodigoEdadScreen> createState() => _CodigoEdadScreenState();
}

class _CodigoEdadScreenState extends State<CodigoEdadScreen> {
  final _codigoController = TextEditingController();
  final _edadController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    if (_isInitialized) return;

    setState(() => _isLoading = true);
    try {
      // Inicializar el controlador primero
      await widget.controller.init();
      _isInitialized = true;

      // Cargar datos iniciales solo si el widget sigue montado
      if (mounted) {
        setState(() {
          _codigoController.text = widget.controller.usuario.codigoUsuario;
          _edadController.text = widget.controller.usuario.edad > 0
              ? widget.controller.usuario.edad.toString()
              : '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
    // Mostrar loading mientras se inicializa
    if (_isLoading || !_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
              ),
              SizedBox(height: 16),
              Text('Cargando...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Datos básicos'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Bienvenido!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Para comenzar, necesitamos algunos datos básicos',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 40),
                  TextFormField(
                    controller: _codigoController,
                    decoration: InputDecoration(
                      labelText: 'Código de estudiante',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu código';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    controller: _edadController,
                    decoration: InputDecoration(
                      labelText: 'Edad',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu edad';
                      }
                      final edad = int.tryParse(value);
                      if (edad == null || edad < 16 || edad > 100) {
                        return 'Ingresa una edad válida';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isLoading = true);
                              try {
                                widget.controller.updateCodigo(_codigoController.text);
                                widget.controller.updateEdad(int.parse(_edadController.text));
                                await widget.controller.saveUserData();
                                
                                if (!mounted) return;
                                Navigator.pushNamed(context, '/setup/facultad');
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      minimumSize: Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Continuar',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Paso 1 de 4',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _edadController.dispose();
    super.dispose();
  }
}