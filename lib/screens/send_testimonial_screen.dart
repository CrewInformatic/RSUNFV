import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/app_colors.dart';

/// Pantalla para que los voluntarios envíen testimonios
class SendTestimonialScreen extends StatefulWidget {
  const SendTestimonialScreen({super.key});

  @override
  State<SendTestimonialScreen> createState() => _SendTestimonialScreenState();
}

class _SendTestimonialScreenState extends State<SendTestimonialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  final _careerController = TextEditingController();
  
  int _rating = 5;
  bool _isLoading = false;
  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    _careerController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          setState(() {
            _nameController.text = userData['nombre'] ?? '';
            _careerController.text = userData['carrera'] ?? '';
          });
        }
      }
    } catch (e) {
      // Error silencioso, usuario puede llenar manualmente
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Enviar Testimonio',
          style: TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildAnonymousToggle(),
              const SizedBox(height: 20),
              if (!_isAnonymous) ...[
                _buildNameField(),
                const SizedBox(height: 16),
                _buildCareerField(),
                const SizedBox(height: 20),
              ],
              _buildRatingSection(),
              const SizedBox(height: 20),
              _buildMessageField(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 20),
              _buildInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.record_voice_over,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Comparte tu experiencia',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Tu testimonio ayudará a otros estudiantes a conocer el impacto de RSU UNFV y motivará a más personas a participar.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mediumText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnonymousToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.greyMedium.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isAnonymous ? Icons.visibility_off : Icons.visibility,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Testimonio anónimo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  'Tu nombre no aparecerá en el testimonio',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mediumText,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isAnonymous,
            onChanged: (value) {
              setState(() {
                _isAnonymous = value;
              });
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Tu nombre completo',
        hintText: 'Ej: María García Rodríguez',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.white,
      ),
      validator: (value) {
        if (!_isAnonymous && (value == null || value.trim().isEmpty)) {
          return 'Por favor ingresa tu nombre';
        }
        return null;
      },
    );
  }

  Widget _buildCareerField() {
    return TextFormField(
      controller: _careerController,
      decoration: InputDecoration(
        labelText: 'Carrera o especialidad',
        hintText: 'Ej: Ingeniería de Sistemas - UNFV',
        prefixIcon: const Icon(Icons.school),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.white,
      ),
      validator: (value) {
        if (!_isAnonymous && (value == null || value.trim().isEmpty)) {
          return 'Por favor ingresa tu carrera';
        }
        return null;
      },
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calificación de tu experiencia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 36,
                    color: index < _rating ? AppColors.warning : AppColors.greyMedium,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _getRatingText(_rating),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.mediumText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Muy insatisfecho';
      case 2:
        return 'Insatisfecho';
      case 3:
        return 'Neutral';
      case 4:
        return 'Satisfecho';
      case 5:
        return 'Muy satisfecho';
      default:
        return '';
    }
  }

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comparte tu experiencia',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageController,
          maxLines: 6,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Cuéntanos cómo ha sido tu experiencia como voluntario en RSU UNFV, qué has aprendido, cómo has crecido, y qué le dirías a otros estudiantes...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: AppColors.white,
            counterStyle: const TextStyle(color: AppColors.mediumText),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor comparte tu experiencia';
            }
            if (value.trim().length < 20) {
              return 'Tu testimonio debe tener al menos 20 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitTestimonial,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Enviando...'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send),
                  SizedBox(width: 8),
                  Text(
                    'Enviar Testimonio',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Información importante',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Tu testimonio será revisado por un administrador antes de ser publicado\n'
            '• Solo se publican testimonios constructivos y respetuosos\n'
            '• Puedes enviar un testimonio cada 30 días\n'
            '• Los testimonios aprobados aparecerán en la página principal',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTestimonial() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Debes estar autenticado para enviar un testimonio');
      }

      // Verificar si el usuario ya envió un testimonio reciente
      final recentTestimonial = await FirebaseFirestore.instance
          .collection('testimonios')
          .where('usuarioId', isEqualTo: user.uid)
          .where('fechaCreacion', 
              isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(const Duration(days: 30))
              ))
          .limit(1)
          .get();

      if (recentTestimonial.docs.isNotEmpty) {
        throw Exception('Solo puedes enviar un testimonio cada 30 días');
      }

      // Crear el testimonio
      final testimonialData = {
        'usuarioId': user.uid,
        'nombre': _isAnonymous ? 'Usuario Anónimo' : _nameController.text.trim(),
        'carrera': _isAnonymous ? 'Estudiante UNFV' : _careerController.text.trim(),
        'mensaje': _messageController.text.trim(),
        'rating': _rating,
        'aprobado': false, // Pendiente de aprobación
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaAprobacion': null,
        'adminAprobador': null,
        'esAnonimo': _isAnonymous,
        'avatar': _isAnonymous ? '' : '', // Se podría cargar la foto del usuario
      };

      await FirebaseFirestore.instance
          .collection('testimonios')
          .add(testimonialData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Testimonio enviado exitosamente! Será revisado por un administrador.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
