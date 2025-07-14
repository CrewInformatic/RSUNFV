import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../services/cloudinary_services.dart';
import '../services/validation_service.dart';
import '../services/donation_anti_spam_service.dart';
import '../widgets/universal_image.dart';
import 'donation_confirmation_screen.dart';

class DonationVoucherScreen extends StatefulWidget {
  final Map<String, dynamic> donacionData;
  final Map<String, dynamic> metodoPago;
  final String donacionId;
  
  const DonationVoucherScreen({
    super.key,
    required this.donacionData,
    required this.metodoPago,
    required this.donacionId,
  });

  @override
  State<DonationVoucherScreen> createState() => _DonationVoucherScreenState();
}

class _DonationVoucherScreenState extends State<DonationVoucherScreen> {
  File? _voucherImage;
  Uint8List? _voucherImageBytes;
  String? _voucherUrl;
  bool _isUploading = false;
  bool _isSubmitting = false;
  final _numeroOperacionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _pickVoucherImage() async {
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
          _voucherImageBytes = bytes;
        });
      } else {
        setState(() {
          _voucherImage = File(image.path);
        });
      }
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
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _voucherImageBytes = bytes;
        });
      } else {
        setState(() {
          _voucherImage = File(image.path);
        });
      }
    }
  }

  Future<void> _uploadVoucher() async {
    if (_voucherImage == null && _voucherImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una imagen del voucher'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validación anti-spam antes de subir el voucher
    final validationResult = await DonationAntiSpamService.canUserUploadVoucher();
    if (!validationResult.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationResult.message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Registrar intento de upload exitoso
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await DonationAntiSpamService.logUploadAttempt(
          userId: currentUser.uid,
          success: true,
        );
      }
      
      String? imageUrl;
      
      if (kIsWeb && _voucherImageBytes != null) {
        imageUrl = await CloudinaryService.uploadVoucher(_voucherImageBytes!);
      } else if (_voucherImage != null) {
        final bytes = await _voucherImage!.readAsBytes();
        imageUrl = await CloudinaryService.uploadVoucher(bytes);
      } else {
        throw Exception('No se pudo cargar la imagen');
      }

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
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      // Registrar intento de upload fallido
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await DonationAntiSpamService.logUploadAttempt(
          userId: currentUser.uid,
          success: false,
          errorReason: e.toString(),
        );
      }

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

  Future<void> _submitVoucher() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_voucherImage == null && _voucherImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor sube el voucher primero'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      Uint8List voucherBytes;
      if (_voucherImageBytes != null) {
        voucherBytes = _voucherImageBytes!;
      } else if (_voucherImage != null) {
        voucherBytes = await _voucherImage!.readAsBytes();
      } else {
        throw Exception('No se pudo obtener la imagen del voucher');
      }

      final validationId = await ValidationService.createValidationRecord(
        donationId: widget.donacionId,
        voucherImageBytes: voucherBytes,
      );

      if (validationId == null) {
        throw Exception('Error al crear el registro de validación');
      }

      await FirebaseFirestore.instance
          .collection('donaciones')
          .doc(widget.donacionId)
          .update({
        'numeroOperacion': _numeroOperacionController.text.trim(),
        'fechaVoucher': Timestamp.now(),
        'estado': 'voucher_subido',
        'idValidacion': validationId,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DonacionConfirmacionScreen(
              donacionData: {
                ...widget.donacionData,
                'numeroOperacion': _numeroOperacionController.text.trim(),
                'estado': 'voucher_subido',
                'idValidacion': validationId,
              },
              metodoPago: widget.metodoPago,
              donacionId: widget.donacionId,
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
            content: Text('Error al enviar voucher: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
                  _pickVoucherImage();
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Cámara'),
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

  @override
  Widget build(BuildContext context) {
    final monto = widget.donacionData['monto'] ?? 0.0;
    final metodoPago = widget.metodoPago['nombre'] ?? 'No especificado';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Voucher'),
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
                    const Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Monto: S/ ${monto.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Método: $metodoPago',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Información de Pago',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...widget.metodoPago.entries.map((entry) {
                      if (entry.key != 'nombre' && entry.key != 'id' && 
                          entry.key != 'icono' && entry.key != 'color' &&
                          entry.key != 'descripcion' && entry.value != null && 
                          entry.value.toString().isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${_formatFieldName(entry.key)}: ${entry.value}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _numeroOperacionController,
                decoration: const InputDecoration(
                  labelText: 'Número de Operación (Opcional)',
                  hintText: 'Ingresa el número de operación del pago',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
                keyboardType: TextInputType.text,
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Voucher de Pago',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Sube una foto clara del comprobante de pago',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 16),
              
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[50],
                  ),
                  child: (_voucherImage != null || _voucherImageBytes != null)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: UniversalImage(
                            file: _voucherImage,
                            bytes: _voucherImageBytes,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toca para agregar voucher',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'JPG, PNG - Máx 5MB',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              if ((_voucherImage != null || _voucherImageBytes != null) && _voucherUrl == null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _uploadVoucher,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isUploading
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
                              Text('Subiendo voucher...'),
                            ],
                          )
                        : const Text(
                            'Subir Voucher',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              
              if (_voucherUrl != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Voucher subido correctamente',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Volver'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _voucherUrl != null && !_isSubmitting
                          ? _submitVoucher
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
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
                                Text('Enviando...'),
                              ],
                            )
                          : const Text(
                              'Confirmar Donación',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFieldName(String key) {
    switch (key) {
      case 'numero':
        return 'Número';
      case 'cuenta':
        return 'Cuenta';
      case 'banco':
        return 'Banco';
      case 'titular':
        return 'Titular';
      case 'contacto':
        return 'Contacto';
      case 'instrucciones':
        return 'Instrucciones';
      default:
        return key;
    }
  }

  @override
  void dispose() {
    _numeroOperacionController.dispose();
    super.dispose();
  }
}
