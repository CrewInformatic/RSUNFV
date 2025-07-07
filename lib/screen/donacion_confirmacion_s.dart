import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'donacion_certificado_s.dart';

class DonacionConfirmacionScreen extends StatefulWidget {
  final Map<String, dynamic> donacionData;
  final Map<String, dynamic> metodoPago;
  final String donacionId;
  
  const DonacionConfirmacionScreen({
    super.key,
    required this.donacionData,
    required this.metodoPago,
    required this.donacionId,
  });

  @override
  State<DonacionConfirmacionScreen> createState() => _DonacionConfirmacionScreenState();
}

class _DonacionConfirmacionScreenState extends State<DonacionConfirmacionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _clockAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  
  bool _isValidated = false;
  bool _isListening = true;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Animación del reloj que gira continuamente
    _clockAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_clockAnimationController);
    
    _animationController.forward();
    _escucharValidacion();
  }

  void _escucharValidacion() {
    // Escuchar cambios en la donación para detectar validación
    FirebaseFirestore.instance
        .collection('donaciones')
        .doc(widget.donacionId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && _isListening) {
        final data = snapshot.data() as Map<String, dynamic>;
        final estado = data['estadoValidacion'] ?? 'pendiente';
        
        if (estado == 'validado' && !_isValidated) {
          setState(() {
            _isValidated = true;
            _isListening = false;
          });
          
          // Mostrar notificación de validación
          _mostrarNotificacionValidacion();
        }
      }
    });
  }

  void _mostrarNotificacionValidacion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              '¡Pago Verificado!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu donación ha sido confirmada exitosamente',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _irACertificado();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ver Certificado'),
          ),
        ],
      ),
    );
  }

  void _irACertificado() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DonacionCertificadoScreen(
          donacionData: widget.donacionData,
          metodoPago: widget.metodoPago,
          donacionId: widget.donacionId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monto = widget.donacionData['monto'] ?? 0.0;
    final nombreDonador = widget.donacionData['NombreUsuarioDonador'] ?? '';
    final nombreRecolector = widget.donacionData['NombreRecolector'] ?? '';
    final apellidoRecolector = widget.donacionData['ApellidoRecolector'] ?? '';
    final fechaDonacion = DateTime.tryParse(widget.donacionData['fechaDonacion'] ?? '') ?? DateTime.now();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donación Registrada - Verificación Pendiente'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Steps indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildStep('✓', 'Tipo', true, Colors.green),
                  _buildStepConnector(true),
                  _buildStep('✓', 'Datos', true, Colors.green),
                  _buildStepConnector(true),
                  _buildStep('✓', 'Recolector', true, Colors.green),
                  _buildStepConnector(true),
                  _buildStep('✓', 'Pago', true, Colors.green),
                  _buildStepConnector(!_isValidated),
                  _buildStep(_isValidated ? '✓' : '⏳', 'Verificación', true, 
                            _isValidated ? Colors.green : Colors.orange.shade700),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Mensaje de agradecimiento animado
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade600, Colors.yellow.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '🎀',
                            style: TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '¡Gracias por tu Generosidad!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tu donación ha sido registrada exitosamente',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Información de la donación
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInfoRow('Donante:', nombreDonador),
                    _buildInfoRow('Monto:', 'S/ ${monto.toStringAsFixed(2)}'),
                    _buildInfoRow('Recolector:', '$nombreRecolector $apellidoRecolector'),
                    _buildInfoRow('Fecha:', DateFormat('dd/MM/yyyy HH:mm').format(fechaDonacion)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Estado de verificación
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Reloj animado mejorado
                    AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        if (_isValidated) {
                          return Icon(
                            Icons.verified,
                            size: 48,
                            color: Colors.green,
                          );
                        } else {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange.shade50,
                              border: Border.all(color: Colors.orange.shade700, width: 3),
                            ),
                            child: Stack(
                              children: [
                                // Números del reloj
                                ...List.generate(12, (index) {
                                  final angle = (index * math.pi * 2) / 12;
                                  return Transform.rotate(
                                    angle: angle,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          (index == 0 ? 12 : index).toString(),
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                // Centro del reloj
                                Center(
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                                // Manecilla de minutos (rápida)
                                Transform.rotate(
                                  angle: _rotationAnimation.value * 12,
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 15),
                                      width: 1.5,
                                      height: 25,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                                // Manecilla de horas (lenta)
                                Transform.rotate(
                                  angle: _rotationAnimation.value,
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 20),
                                      width: 2,
                                      height: 18,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isValidated ? 'Certificado en Proceso' : 'Verificando Pago...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isValidated ? Colors.green[700] : Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isValidated 
                          ? 'Tu certificado de donación será enviado a ${widget.donacionData['EmailUsuarioDonador'] ?? 'tu email'} una vez que se haya verificado el pago correspondiente.'
                          : 'Estamos verificando tu pago. Tu certificado de donación será enviado a ${widget.donacionData['EmailUsuarioDonador'] ?? 'tu email'} una vez completada la verificación.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Información importante
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.yellow[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        '¿Qué sigue ahora?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoStep('✓', 'Verificación del pago'),
                  _buildInfoStep('📧', 'Envío del certificado'),
                  _buildInfoStep('📞', 'Actualizaciones por email'),
                  _buildInfoStep('📞', 'Contacto del recolector'),
                  const SizedBox(height: 8),
                  Text(
                    'Importante: Tu recolector asignado se comunicará contigo si hubiera algún problema durante el proceso.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Volver al Inicio'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (_isValidated)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _irACertificado,
                      icon: const Icon(Icons.card_membership),
                      label: const Text('Ver Certificado'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String icon, String label, bool isActive, Color color) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              icon,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? color : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Colors.green : Colors.grey[300],
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStep(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _clockAnimationController.dispose();
    super.dispose();
  }
}
