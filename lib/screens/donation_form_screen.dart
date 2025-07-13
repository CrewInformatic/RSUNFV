import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../services/cloudinary_services.dart';
import '../services/validation_service.dart';
import '../models/usuario.dart';
import '../services/firebase_auth_services.dart';

class DonationFormScreen extends StatefulWidget {
  const DonationFormScreen({super.key});

  @override
  State<DonationFormScreen> createState() => _DonationFormScreenState();
}

class _DonationFormScreenState extends State<DonationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _numeroOperacionController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  String _metodoPago = 'transferencia_bancaria';
  DateTime _fechaDeposito = DateTime.now();
  File? _voucherImage;
  String? _voucherUrl;
  bool _isUploading = false;
  bool _isSubmitting = false;
  Usuario? _currentUser;

  final Map<String, Map<String, dynamic>> _metodosPago = {
    'transferencia_bancaria': {
      'nombre': 'Transferencia Bancaria',
      'icono': Icons.account_balance,
      'color': Colors.blue,
      'cuenta': 'BCP - 123-456789-012',
      'titular': 'Fundación RSU UNFV',
      'requiere_voucher': true,
    },
    'yape': {
      'nombre': 'Yape',
      'icono': Icons.phone_android,
      'color': Colors.purple,
      'cuenta': '987-654-321',
      'titular': 'RSU UNFV',
      'requiere_voucher': true,
    },
    'plin': {
      'nombre': 'Plin',
      'icono': Icons.account_balance_wallet,
      'color': Colors.green,
      'cuenta': '987-654-321',
      'titular': 'RSU UNFV',
      'requiere_voucher': true,
    },
    'efectivo': {
      'nombre': 'Efectivo',
      'icono': Icons.attach_money,
      'color': Colors.orange,
      'cuenta': 'Entregar en oficina RSU',
      'titular': 'Coordinación RSU',
      'requiere_voucher': false,
    },
  };

  final List<double> _montosRapidos = [10.0, 20.0, 50.0, 100.0, 200.0, 500.0];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = AuthService();
      final userData = await authService.getUserData();
      if (userData != null && mounted) {
        setState(() {
          _currentUser = Usuario.fromMap(userData.data() as Map<String, dynamic>);
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos del usuario: $e');
    }
  }

  Future<void> _pickVoucherImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _voucherImage = File(image.path);
      });
    }
  }

  Future<void> _takeVoucherPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _voucherImage = File(image.path);
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVoucherImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _takeVoucherPhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadVoucherImage() async {
    if (_voucherImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final imageBytes = await _voucherImage!.readAsBytes();
      final imageUrl = await CloudinaryService.uploadImage(imageBytes);

      if (imageUrl != null) {
        setState(() {
          _voucherUrl = imageUrl;
          _isUploading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voucher subido exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Error al subir la imagen');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir voucher: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;

    final metodoPagoInfo = _metodosPago[_metodoPago]!;
    
    if (metodoPagoInfo['requiere_voucher'] && _voucherUrl == null && _voucherImage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, sube el voucher antes de continuar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final docId = 'DON-$timestamp';

      final donationData = {
        'idUsuarioDonador': userId,
        'tipoDonacion': 'dinero',
        'monto': double.parse(_montoController.text),
        'descripcion': _descripcionController.text.trim().isNotEmpty 
            ? _descripcionController.text.trim() 
            : 'Donación monetaria',
        'fechaDonacion': DateTime.now().toIso8601String(),
        'idValidacion': '',
        'estadoValidacion': 'pendiente',
        'metodoPago': metodoPagoInfo['nombre'],
        'numeroOperacion': _numeroOperacionController.text.trim(),
        'fechaDeposito': _fechaDeposito.toIso8601String(),
        'NombreUsuarioDonador': _currentUser?.nombreUsuario ?? '',
        'ApellidoUsuarioDonador': _currentUser?.apellidoUsuario ?? '',
        'EmailUsuarioDonador': _currentUser?.correo ?? '',
        'DNIUsuarioDonador': _currentUser?.codigoUsuario ?? '',
        'TelefonoUsuarioDonador': _currentUser?.celular ?? '',
        'Tipo_Usuario': 'PERSONA NATURAL',
        'UsuarioEstadoValidacion': '',
        'banco': '',
        'EmailRecolector': '',
        'facultadRecolector': '',
        'idRecolector': '',
        'NombreRecolector': '',
        'observaciones': '',
      };

      await FirebaseFirestore.instance.collection('donaciones').doc(docId).set(donationData);

      if (_voucherImage != null) {
        final voucherImageBytes = await _voucherImage!.readAsBytes();
        await ValidationService.createValidationRecord(
          donationId: docId,
          voucherImageBytes: voucherImageBytes,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Donación registrada exitosamente! Será validada pronto.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar donación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Donación'),
        backgroundColor: Colors.orange.shade700,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade700, Colors.orange.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.volunteer_activism,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '¡Tu donación hace la diferencia!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cada aporte ayuda a crear un impacto positivo en nuestra comunidad',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildMontoSection(),

              const SizedBox(height: 24),

              _buildMetodoPagoSection(),

              const SizedBox(height: 24),

              _buildDetallesPagoSection(),

              const SizedBox(height: 24),

              if (_metodosPago[_metodoPago]!['requiere_voucher'])
                _buildVoucherSection(),

              const SizedBox(height: 24),

              _buildDescripcionSection(),

              const SizedBox(height: 32),

              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMontoSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Monto de la Donación',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monto en Soles (S/)',
                prefixIcon: const Icon(Icons.monetization_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese un monto';
                }
                final monto = double.tryParse(value);
                if (monto == null || monto <= 0) {
                  return 'Por favor ingrese un monto válido';
                }
                if (monto < 5) {
                  return 'El monto mínimo es S/ 5.00';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Montos sugeridos:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _montosRapidos.map((monto) {
                return GestureDetector(
                  onTap: () {
                    _montoController.text = monto.toStringAsFixed(0);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green.shade300),
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.green.shade50,
                    ),
                    child: Text(
                      'S/ ${monto.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetodoPagoSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Método de Pago',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Column(
              children: _metodosPago.entries.map((entry) {
                final metodo = entry.key;
                final info = entry.value;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<String>(
                    value: metodo,
                    groupValue: _metodoPago,
                    onChanged: (value) {
                      setState(() {
                        _metodoPago = value!;
                        _voucherImage = null;
                        _voucherUrl = null;
                      });
                    },
                    title: Row(
                      children: [
                        Icon(
                          info['icono'] as IconData,
                          color: info['color'] as Color,
                        ),
                        const SizedBox(width: 8),
                        Text(info['nombre'] as String),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cuenta: ${info['cuenta']}'),
                        Text('Titular: ${info['titular']}'),
                      ],
                    ),
                    secondary: info['requiere_voucher'] 
                      ? const Icon(Icons.receipt, color: Colors.orange)
                      : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetallesPagoSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Detalles del Pago',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _numeroOperacionController,
              decoration: InputDecoration(
                labelText: 'Número de Operación',
                hintText: 'Ej: 123456789',
                prefixIcon: const Icon(Icons.confirmation_number),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: _metodosPago[_metodoPago]!['requiere_voucher'] ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el número de operación';
                }
                return null;
              } : null,
            ),
            
            const SizedBox(height: 16),
            
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _fechaDeposito,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _fechaDeposito = date;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fecha del Depósito',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_fechaDeposito),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Voucher del Depósito',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Requerido',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sube una foto clara del voucher o comprobante del depósito realizado',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_voucherImage != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb 
                      ? const Icon(Icons.image, size: 50)
                      : Image.file(
                          _voucherImage!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _uploadVoucherImage,
                      icon: _isUploading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload),
                      label: Text(_isUploading ? 'Subiendo...' : 'Subir Voucher'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _voucherImage = null;
                        _voucherUrl = null;
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ],
              ),
              
              if (_voucherUrl != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Voucher subido exitosamente',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: InkWell(
                  onTap: _showImagePickerOptions,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca para subir voucher',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Galería o Cámara',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDescripcionSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_add, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Mensaje (Opcional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descripcionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Agrega un mensaje personal para tu donación...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final metodoPagoInfo = _metodosPago[_metodoPago]!;
    final requiereVoucher = metodoPagoInfo['requiere_voucher'] as bool;
    final voucherListo = !requiereVoucher || _voucherUrl != null;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting || !voucherListo ? null : _submitDonation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
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
                Text('Procesando Donación...'),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.volunteer_activism),
                const SizedBox(width: 8),
                Text(
                  voucherListo ? 'Registrar Donación' : 'Sube el voucher primero',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
      ),
    );
  }

  @override
  void dispose() {
    _montoController.dispose();
    _numeroOperacionController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
}
