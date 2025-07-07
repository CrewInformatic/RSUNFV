import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/donaciones.dart';
import '../models/usuario.dart';
import '../services/firebase_auth_services.dart';
import 'donacion_recolector_s.dart';

class DonacionPagoScreen extends StatefulWidget {
  final Donaciones? donacion;
  
  const DonacionPagoScreen({
    super.key,
    this.donacion,
  });

  @override
  State<DonacionPagoScreen> createState() => _DonacionPagoScreenState();
}

class _DonacionPagoScreenState extends State<DonacionPagoScreen> {
  final AuthService _authService = AuthService();
  Usuario? currentUser;
  
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _objetosController = TextEditingController();
  
  String _tipoDonacion = 'dinero';
  
  // Información específica por tipo de donación
  final Map<String, Map<String, dynamic>> _tiposDonacionInfo = {
    'dinero': {
      'campo': 'monto',
      'label': 'Monto de la Donación',
      'prefijo': 'S/ ',
      'placeholder': '0.00',
      'icono': Icons.attach_money,
      'color': Colors.green,
      'teclado': TextInputType.numberWithOptions(decimal: true),
      'botones': [10, 20, 50, 100, 200, 500],
    },
    'alimentos': {
      'campo': 'cantidad',
      'label': 'Cantidad de Alimentos',
      'prefijo': '',
      'placeholder': 'Ej: 10 kg de arroz',
      'icono': Icons.restaurant,
      'color': Colors.orange,
      'teclado': TextInputType.text,
      'botones': ['1 kg', '5 kg', '10 kg', '20 kg', '50 kg'],
    },
    'ropa': {
      'campo': 'objetos',
      'label': 'Descripción de Ropa',
      'prefijo': '',
      'placeholder': 'Ej: 5 camisas, 3 pantalones',
      'icono': Icons.checkroom,
      'color': Colors.blue,
      'teclado': TextInputType.text,
      'botones': ['Camisas', 'Pantalones', 'Zapatos', 'Abrigos', 'Ropa Interior'],
    },
    'utiles': {
      'campo': 'objetos',
      'label': 'Útiles Escolares/Oficina',
      'prefijo': '',
      'placeholder': 'Ej: 10 cuadernos, 5 lapiceros',
      'icono': Icons.school,
      'color': Colors.purple,
      'teclado': TextInputType.text,
      'botones': ['Cuadernos', 'Lapiceros', 'Libros', 'Mochilas', 'Calculadoras'],
    },
    'medicamentos': {
      'campo': 'objetos',
      'label': 'Medicamentos y Suministros',
      'prefijo': '',
      'placeholder': 'Ej: Paracetamol, vendas, alcohol',
      'icono': Icons.medical_services,
      'color': Colors.red,
      'teclado': TextInputType.text,
      'botones': ['Analgésicos', 'Vendas', 'Alcohol', 'Vitaminas', 'Termómetros'],
    },
    'juguetes': {
      'campo': 'objetos',
      'label': 'Juguetes',
      'prefijo': '',
      'placeholder': 'Ej: Muñecas, carritos, juegos',
      'icono': Icons.toys,
      'color': Colors.pink,
      'teclado': TextInputType.text,
      'botones': ['Muñecas', 'Carritos', 'Juegos de Mesa', 'Peluches', 'Deportivos'],
    },
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // Si estamos editando una donación existente
    if (widget.donacion != null) {
      _montoController.text = widget.donacion!.monto.toString();
      _descripcionController.text = widget.donacion!.descripcion;
      _tipoDonacion = widget.donacion!.tipoDonacion;
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      if (userData != null) {
        final user = Usuario.fromFirestore(
          userData.data() as Map<String, dynamic>, 
          userData.id
        );
        setState(() {
          currentUser = user;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _continuarPago() {
    if (_formKey.currentState!.validate() && currentUser != null) {
      final tipoInfo = _tiposDonacionInfo[_tipoDonacion]!;
      double monto = 0.0;
      int? cantidad;
      String? objetos;
      
      // Manejar campos según el tipo de donación
      if (_tipoDonacion == 'dinero') {
        monto = double.tryParse(_montoController.text) ?? 0.0;
      } else {
        // Para donaciones en especie, usar cantidad en lugar de monto
        if (tipoInfo['campo'] == 'cantidad') {
          final cantidadTexto = _cantidadController.text;
          // Extraer número de la cantidad (ej: "10 kg" -> 10)
          final numeroMatch = RegExp(r'\d+').firstMatch(cantidadTexto);
          cantidad = numeroMatch != null ? int.tryParse(numeroMatch.group(0)!) : 1;
          monto = cantidad?.toDouble() ?? 1.0;
        } else {
          cantidad = 1; // Default para objetos
          monto = 1.0;
        }
        objetos = _objetosController.text.trim();
      }
      
      // Crear objeto de donación con datos del usuario
      final donacionData = {
        'idDonaciones': widget.donacion?.idDonaciones ?? 
                       FirebaseFirestore.instance.collection('donaciones').doc().id,
        'idUsuarioDonador': currentUser!.idUsuario,
        'tipoDonacion': _tipoDonacion,
        'monto': monto,
        'cantidad': cantidad,
        'objetos': objetos,
        'unidadMedida': _tipoDonacion == 'dinero' ? 'soles' : 'unidades',
        'descripcion': _descripcionController.text.trim(),
        'fechaDonacion': DateTime.now().toIso8601String(),
        'idValidacion': '',
        'estadoValidacion': 'pendiente',
        'metodoPago': '',
        'idRecolector': null,
        
        // Datos del usuario donador
        'NombreUsuarioDonador': currentUser!.nombreUsuario,
        'ApellidoUsuarioDonador': currentUser!.apellidoUsuario,
        'EmailUsuarioDonador': currentUser!.email,
        'DNIUsuarioDonador': currentUser!.codigoUsuario,
        'TelefonoUsuarioDonador': '', // No disponible en modelo actual
        'Tipo_Usuario': 'PERSONA NATURAL',
        'UsuarioEstadoValidacion': currentUser!.estadoActivo ? 'activo' : 'inactivo',
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DonacionRecolectorScreen(
            donacionData: donacionData,
          ),
        ),
      );
    }
  }

  String _getTipoDisplayName(String tipo) {
    switch (tipo) {
      case 'dinero':
        return 'Donación Monetaria';
      case 'alimentos':
        return 'Alimentos';
      case 'ropa':
        return 'Ropa y Calzado';
      case 'utiles':
        return 'Útiles Escolares';
      case 'medicamentos':
        return 'Medicamentos';
      case 'juguetes':
        return 'Juguetes';
      default:
        return tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.donacion != null ? 'Editar Donación' : 'Nueva Donación'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icono
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade700, Colors.orange.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.volunteer_activism,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Realizar Donación',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Tu generosidad hace la diferencia',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Información del donador
              if (currentUser != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información del Donador',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Nombre:', currentUser!.nombre),
                        _buildInfoRow('Email:', currentUser!.email),
                        _buildInfoRow('Código:', currentUser!.codigoUsuario),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Tipo de donación
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tipo de Donación',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _tipoDonacion,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.category, color: Colors.orange.shade700),
                        ),
                        items: [
                          'dinero',
                          'alimentos',
                          'ropa',
                          'utiles',
                          'medicamentos',
                          'juguetes'
                        ].map((tipo) => DropdownMenuItem(
                          value: tipo,
                          child: Row(
                            children: [
                              Icon(
                                _tiposDonacionInfo[tipo]!['icono'],
                                color: _tiposDonacionInfo[tipo]!['color'],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(_getTipoDisplayName(tipo)),
                            ],
                          ),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _tipoDonacion = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Monto
              // Campos dinámicos según tipo de donación
              _buildCamposDinamicos(),
              
              const SizedBox(height: 16),
              
              // Descripción/Mensaje
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mensaje (Opcional)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descripcionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.message, color: Colors.orange.shade700),
                          hintText: 'Escribe un mensaje de apoyo...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Botón continuar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _continuarPago,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'Continuar con el Pago',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCamposDinamicos() {
    final tipoInfo = _tiposDonacionInfo[_tipoDonacion]!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tipoInfo['label'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: tipoInfo['color'],
              ),
            ),
            const SizedBox(height: 12),
            
            // Campo principal (monto, cantidad u objetos)
            if (_tipoDonacion == 'dinero') 
              _buildCampoMonto(tipoInfo)
            else if (tipoInfo['campo'] == 'cantidad')
              _buildCampoCantidad(tipoInfo)
            else
              _buildCampoObjetos(tipoInfo),
            
            // Botones rápidos
            if (tipoInfo['botones'].isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Opciones rápidas:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (tipoInfo['botones'] as List).map<Widget>((opcion) {
                  return ActionChip(
                    label: Text(opcion.toString()),
                    onPressed: () {
                      if (_tipoDonacion == 'dinero') {
                        _montoController.text = opcion.toString();
                      } else if (tipoInfo['campo'] == 'cantidad') {
                        _cantidadController.text = opcion.toString();
                      } else {
                        // Para objetos, añadir al texto existente
                        final currentText = _objetosController.text;
                        if (currentText.isEmpty) {
                          _objetosController.text = opcion.toString();
                        } else {
                          _objetosController.text = '$currentText, $opcion';
                        }
                      }
                    },
                    backgroundColor: tipoInfo['color'].withOpacity(0.1),
                    labelStyle: TextStyle(color: tipoInfo['color']),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCampoMonto(Map<String, dynamic> tipoInfo) {
    return TextFormField(
      controller: _montoController,
      keyboardType: tipoInfo['teclado'],
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: Icon(tipoInfo['icono'], color: tipoInfo['color']),
        prefixText: tipoInfo['prefijo'],
        hintText: tipoInfo['placeholder'],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese el monto';
        }
        if (double.tryParse(value) == null) {
          return 'Ingrese un monto válido';
        }
        if (double.parse(value) <= 0) {
          return 'El monto debe ser mayor a 0';
        }
        return null;
      },
    );
  }

  Widget _buildCampoCantidad(Map<String, dynamic> tipoInfo) {
    return TextFormField(
      controller: _cantidadController,
      keyboardType: tipoInfo['teclado'],
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: Icon(tipoInfo['icono'], color: tipoInfo['color']),
        hintText: tipoInfo['placeholder'],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese la cantidad';
        }
        return null;
      },
    );
  }

  Widget _buildCampoObjetos(Map<String, dynamic> tipoInfo) {
    return TextFormField(
      controller: _objetosController,
      keyboardType: tipoInfo['teclado'],
      maxLines: 2,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: Icon(tipoInfo['icono'], color: tipoInfo['color']),
        hintText: tipoInfo['placeholder'],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor describa los objetos a donar';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
}
