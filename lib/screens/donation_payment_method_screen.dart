import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';
import 'donation_confirmation_screen.dart';
import 'donation_coordination_screen.dart';

class DonacionMetodoPagoScreen extends StatefulWidget {
  final Map<String, dynamic> donacionData;
  final bool isEditing;
  
  const DonacionMetodoPagoScreen({
    super.key,
    required this.donacionData,
    this.isEditing = false,
  });

  @override
  State<DonacionMetodoPagoScreen> createState() => _DonacionMetodoPagoScreenState();
}

class _DonacionMetodoPagoScreenState extends State<DonacionMetodoPagoScreen> {
  String _metodoSeleccionado = '';
  bool _isProcessing = false;
  List<Map<String, dynamic>> _metodosPago = [];
  
  @override
  void initState() {
    super.initState();
    _configurarMetodosPago();
  }
  
  void _configurarMetodosPago() {
    final tipoDonacion = widget.donacionData['tipoDonacion'] ?? 'dinero';
    
    if (tipoDonacion == 'dinero') {
      // Para donaciones monetarias, usar datos del recolector
      _configurarMetodosMonetarios();
    } else {
      // Para donaciones no monetarias, navegar directamente a coordinación
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navegarACoordinacion();
      });
    }
  }
  
  void _configurarMetodosMonetarios() {
    // Extraer datos del recolector desde donacionData
    final yapePagoRecolector = widget.donacionData['YapeRecolector'] ?? '';
    final cuentaRecolector = widget.donacionData['CuentaBancariaRecolector'] ?? '';
    final bancoRecolector = widget.donacionData['BancoRecolector'] ?? '';
    
    _metodosPago = [
      if (yapePagoRecolector.isNotEmpty) {
        'id': 'yape',
        'nombre': 'Yape',
        'icono': Icons.phone_android,
        'color': Colors.purple,
        'descripcion': 'Pago rápido y seguro con Yape',
        'numero': yapePagoRecolector,
      },
      if (yapePagoRecolector.isNotEmpty) {
        'id': 'plin',
        'nombre': 'Plin',
        'icono': Icons.account_balance_wallet,
        'color': Colors.blue,
        'descripcion': 'Transferencia inmediata con Plin',
        'numero': yapePagoRecolector,
      },
      if (cuentaRecolector.isNotEmpty) {
        'id': 'transferencia',
        'nombre': 'Transferencia Bancaria',
        'icono': Icons.account_balance,
        'color': Colors.green,
        'descripcion': 'Transferencia directa a cuenta bancaria',
        'cuenta': '$bancoRecolector - $cuentaRecolector',
      },
      {
        'id': 'efectivo',
        'nombre': 'Efectivo',
        'icono': Icons.payments,
        'color': Colors.orange,
        'descripcion': 'Entrega en efectivo al recolector',
        'direccion': 'Coordinar con el recolector seleccionado',
      },
    ];
  }
  
  void _navegarACoordinacion() {
    // Crear objeto Usuario desde los datos del recolector
    final recolector = Usuario(
      idUsuario: widget.donacionData['idRecolector'] ?? '',
      nombreUsuario: widget.donacionData['NombreRecolector'] ?? '',
      apellidoUsuario: widget.donacionData['ApellidoRecolector'] ?? '',
      correo: widget.donacionData['EmailRecolector'] ?? '',
      celular: widget.donacionData['CelularRecolector'] ?? '',
      yape: widget.donacionData['YapeRecolector'] ?? '',
      cuentaBancaria: widget.donacionData['CuentaBancariaRecolector'] ?? '',
      banco: widget.donacionData['BancoRecolector'] ?? '',
    );
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DonacionCoordinacionScreen(
          donacionData: widget.donacionData,
          recolector: recolector,
        ),
      ),
    );
  }

  Future<void> _procesarPago() async {
    if (_metodoSeleccionado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un método de pago'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Actualizar los datos de la donación con el método de pago
      final donacionCompleta = {
        ...widget.donacionData,
        'metodoPago': _metodoSeleccionado,
        'fechaDonacion': DateTime.now().toIso8601String(),
      };

      // Guardar en Firestore y obtener el ID del documento
      String donacionDocId;
      if (widget.isEditing) {
        donacionDocId = donacionCompleta['idDonaciones'];
        await FirebaseFirestore.instance
            .collection('donaciones')
            .doc(donacionDocId)
            .update(donacionCompleta);
      } else {
        final docRef = await FirebaseFirestore.instance
            .collection('donaciones')
            .add(donacionCompleta);
        donacionDocId = docRef.id;
      }

      if (!mounted) return;

      // Navegar a la pantalla de confirmación
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DonacionConfirmacionScreen(
            donacionData: donacionCompleta,
            metodoPago: _metodosPago.firstWhere(
              (metodo) => metodo['id'] == _metodoSeleccionado,
            ),
            donacionId: donacionDocId,
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar el pago: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final monto = widget.donacionData['monto'] ?? 0.0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Método de Pago'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Resumen de la donación
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade700, Colors.orange.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                  'Resumen de tu Donación',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'S/ ${monto.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.donacionData['tipoDonacion'] ?? 'Donación',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          
          // Steps indicator
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                _buildStep('✓', 'Tipo', true, Colors.green),
                _buildStepConnector(),
                _buildStep('✓', 'Datos', true, Colors.green),
                _buildStepConnector(),
                _buildStep('✓', 'Recolector', true, Colors.green),
                _buildStepConnector(),
                _buildStep('💳', 'Pago', true, Colors.orange.shade700),
                _buildStepConnector(),
                _buildStep('📄', 'Certificado', false, Colors.grey),
              ],
            ),
          ),
          
          // Lista de métodos de pago
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Selecciona tu método de pago',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                
                ..._metodosPago.map((metodo) => _buildMetodoPagoCard(metodo)),
                
                const SizedBox(height: 24),
                
                // Botón continuar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _procesarPago,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isProcessing
                        ? Row(
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
                              const SizedBox(width: 12),
                              Text('Procesando...'),
                            ],
                          )
                        : Text(
                            'Confirmar Pago',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodoPagoCard(Map<String, dynamic> metodo) {
    final isSelected = _metodoSeleccionado == metodo['id'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? metodo['color'] : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _metodoSeleccionado = metodo['id'];
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: metodo['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  metodo['icono'],
                  color: metodo['color'],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metodo['nombre'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? metodo['color'] : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metodo['descripcion'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (metodo['numero'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Número: ${metodo['numero']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: metodo['color'],
                        ),
                      ),
                    ],
                    if (metodo['cuenta'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        metodo['cuenta'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: metodo['color'],
                        ),
                      ),
                    ],
                    if (metodo['direccion'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        metodo['direccion'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: metodo['color'],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: metodo['color'],
                  size: 24,
                ),
            ],
          ),
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

  Widget _buildStepConnector() {
    return Expanded(
      child: Container(
        height: 2,
        color: Colors.grey[300],
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      ),
    );
  }
}
