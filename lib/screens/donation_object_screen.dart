import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../services/firebase_auth_services.dart';
import '../services/cloudinary_services.dart';
import '../widgets/universal_image.dart';
import '../models/usuario.dart';
import 'donation_collector_screen.dart';

class DonationObjectScreen extends StatefulWidget {
  const DonationObjectScreen({super.key});

  @override
  State<DonationObjectScreen> createState() => _DonationObjectScreenState();
}

class _DonationObjectScreenState extends State<DonationObjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _observacionesController = TextEditingController();
  
  String _categoriaSeleccionada = '';
  int _cantidadEstimada = 1;
  String _estadoObjetos = 'nuevo';
  File? _imagenObjetos;
  Uint8List? _imagenObjetosBytes;
  bool _isSubmitting = false;
  Usuario? _usuarioActual;

  final List<Map<String, dynamic>> _categorias = [
    {
      'id': 'ropa_calzado',
      'nombre': 'Ropa y Calzado',
      'icon': Icons.checkroom,
      'ejemplos': ['Ropa infantil', 'Ropa adulta', 'Zapatos', 'Accesorios'],
    },
    {
      'id': 'libros_educativo',
      'nombre': 'Libros y Material Educativo',
      'icon': Icons.menu_book,
      'ejemplos': ['Libros escolares', 'Libros universitarios', 'Cuadernos', 'Útiles escolares'],
    },
    {
      'id': 'higiene_cuidado',
      'nombre': 'Productos de Higiene',
      'icon': Icons.soap,
      'ejemplos': ['Jabones', 'Champú', 'Pasta dental', 'Productos de cuidado personal'],
    },
    {
      'id': 'alimentos',
      'nombre': 'Alimentos No Perecibles',
      'icon': Icons.restaurant,
      'ejemplos': ['Enlatados', 'Granos', 'Cereales', 'Productos secos'],
    },
    {
      'id': 'juguetes',
      'nombre': 'Juguetes y Entretenimiento',
      'icon': Icons.toys,
      'ejemplos': ['Juguetes educativos', 'Peluches', 'Juegos de mesa', 'Material deportivo'],
    },
    {
      'id': 'electrodomesticos',
      'nombre': 'Electrodomésticos y Electrónicos',
      'icon': Icons.electrical_services,
      'ejemplos': ['Electrodomésticos pequeños', 'Dispositivos electrónicos', 'Cables', 'Accesorios'],
    },
    {
      'id': 'otros',
      'nombre': 'Otros',
      'icon': Icons.inventory,
      'ejemplos': ['Muebles pequeños', 'Decoración', 'Herramientas', 'Otros artículos útiles'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _cargarUsuarioActual();
  }

  Future<void> _cargarUsuarioActual() async {
    try {
      final authService = AuthService();
      final docSnapshot = await authService.getUserData();
      
      if (docSnapshot != null && docSnapshot.exists) {
        final userData = docSnapshot.data()!;
        final usuario = Usuario.fromFirestore(userData, docSnapshot.id);
        setState(() {
          _usuarioActual = usuario;
        });
      }
    } catch (e) {
      debugPrint('Error cargando usuario: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imagenObjetosBytes = bytes;
        });
      } else {
        setState(() {
          _imagenObjetos = File(image.path);
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imagenObjetosBytes = bytes;
        });
      } else {
        setState(() {
          _imagenObjetos = File(image.path);
        });
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Cámara'),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoriaSeleccionada.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una categoría'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_usuarioActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Usuario no identificado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? imagenUrl;
      
      // Subir imagen si existe
      if (_imagenObjetos != null || _imagenObjetosBytes != null) {
        if (kIsWeb && _imagenObjetosBytes != null) {
          imagenUrl = await CloudinaryService.uploadVoucher(_imagenObjetosBytes!);
        } else if (_imagenObjetos != null) {
          final bytes = await _imagenObjetos!.readAsBytes();
          imagenUrl = await CloudinaryService.uploadVoucher(bytes);
        }
      }

      // Crear datos de donación de objeto
      final donacionData = {
        'tipoDonacion': 'objeto',
        'categoria': _categoriaSeleccionada,
        'descripcion': _descripcionController.text.trim(),
        'cantidadEstimada': _cantidadEstimada,
        'estadoObjetos': _estadoObjetos,
        'observaciones': _observacionesController.text.trim(),
        'imagenUrl': imagenUrl,
        'fechaCreacion': Timestamp.now(),
        'estado': 'pendiente_recolector',
        
        // Datos del donador
        'idUsuarioDonador': _usuarioActual!.idUsuario,
        'NombreUsuarioDonador': _usuarioActual!.nombreUsuario,
        'ApellidoUsuarioDonador': _usuarioActual!.apellidoUsuario,
        'EmailUsuarioDonador': _usuarioActual!.correo,
        'CodigoUsuarioDonador': _usuarioActual!.codigoUsuario,
        'Tipo_Usuario': 'PERSONA NATURAL',
        'estadoValidacion': 'pendiente',
      };

      // Navegar a selección de recolector
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DonacionRecolectorScreen(
              donacionData: donacionData,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar donación: $e'),
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
        title: const Text('Donación de Objetos'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header informativo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Dona Objetos Útiles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ayuda a nuestra comunidad donando artículos que ya no uses',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Selección de categoría
              const Text(
                'Categoría de Objetos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _categorias.length,
                itemBuilder: (context, index) {
                  final categoria = _categorias[index];
                  final isSelected = _categoriaSeleccionada == categoria['id'];
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _categoriaSeleccionada = categoria['id'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade50 : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue.shade300 : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            categoria['icon'],
                            size: 32,
                            color: isSelected ? Colors.blue.shade700 : Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            categoria['nombre'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.blue.shade700 : Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // Ejemplos de la categoría seleccionada
              if (_categoriaSeleccionada.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ejemplos:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _categorias.firstWhere((c) => c['id'] == _categoriaSeleccionada)['ejemplos'].join(', '),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción de los objetos',
                  hintText: 'Describe detalladamente los objetos que vas a donar',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  if (value.trim().length < 10) {
                    return 'La descripción debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Cantidad estimada
              const Text(
                'Cantidad Estimada',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  IconButton(
                    onPressed: _cantidadEstimada > 1
                        ? () => setState(() => _cantidadEstimada--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_cantidadEstimada unidades/piezas',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _cantidadEstimada++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Estado de los objetos
              const Text(
                'Estado de los Objetos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Nuevo'),
                    selected: _estadoObjetos == 'nuevo',
                    onSelected: (selected) {
                      if (selected) setState(() => _estadoObjetos = 'nuevo');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Muy Bueno'),
                    selected: _estadoObjetos == 'muy_bueno',
                    onSelected: (selected) {
                      if (selected) setState(() => _estadoObjetos = 'muy_bueno');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Bueno'),
                    selected: _estadoObjetos == 'bueno',
                    onSelected: (selected) {
                      if (selected) setState(() => _estadoObjetos = 'bueno');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Regular'),
                    selected: _estadoObjetos == 'regular',
                    onSelected: (selected) {
                      if (selected) setState(() => _estadoObjetos = 'regular');
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Foto de los objetos
              const Text(
                'Foto de los Objetos (Opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  child: (_imagenObjetos != null || _imagenObjetosBytes != null)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: UniversalImage(
                            file: _imagenObjetos,
                            bytes: _imagenObjetosBytes,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toca para agregar foto',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Observaciones adicionales
              TextFormField(
                controller: _observacionesController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones adicionales (Opcional)',
                  hintText: 'Información adicional que consideres importante',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 32),
              
              // Botón continuar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Procesando...'),
                          ],
                        )
                      : const Text(
                          'Continuar con Recolector',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }
}
