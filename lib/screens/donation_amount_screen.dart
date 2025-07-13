import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/firebase_auth_services.dart';
import 'donation_collector_screen.dart';

class DonationAmountScreen extends StatefulWidget {
  final Usuario recolectorSeleccionado;
  
  const DonationAmountScreen({
    super.key,
    required this.recolectorSeleccionado,
  });

  @override
  State<DonationAmountScreen> createState() => _DonationAmountScreenState();
}

class _DonationAmountScreenState extends State<DonationAmountScreen> {
  final _montoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double? _montoSeleccionado;
  Usuario? _currentUser;
  bool _isLoading = true;
  
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
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos del usuario: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _continuar() {
    if (_formKey.currentState!.validate()) {
      final monto = _montoSeleccionado ?? double.tryParse(_montoController.text) ?? 0.0;
      
      // Crear datos de donación con información del usuario actual
      final donacionData = {
        'monto': monto,
        'tipoDonacion': 'dinero',
        'fechaDonacion': DateTime.now().toIso8601String(),
        'estadoValidacion': 'pendiente',
        'NombreUsuarioDonador': _currentUser?.nombreUsuario ?? 'Usuario',
        'ApellidoUsuarioDonador': _currentUser?.apellidoUsuario ?? '',
        'EmailUsuarioDonador': _currentUser?.correo ?? '',
        'idUsuarioDonador': _currentUser?.idUsuario ?? '',
        'idRecolector': widget.recolectorSeleccionado.idUsuario,
        'NombreRecolector': widget.recolectorSeleccionado.nombreUsuario,
        'ApellidoRecolector': widget.recolectorSeleccionado.apellidoUsuario,
        'EmailRecolector': widget.recolectorSeleccionado.correo,
        'CelularRecolector': widget.recolectorSeleccionado.celular ?? '',
        'YapeRecolector': widget.recolectorSeleccionado.yape ?? '',
        'CuentaBancariaRecolector': widget.recolectorSeleccionado.cuentaBancaria ?? '',
        'BancoRecolector': widget.recolectorSeleccionado.banco ?? '',
        'facultadRecolector': '', // Se debe obtener del recolector
        'Tipo_Usuario': 'PERSONA NATURAL',
      };

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DonacionRecolectorScreen(
            donacionData: donacionData,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Monto de Donación'),
          backgroundColor: Colors.orange.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monto de Donación'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header con información del recolector
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
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: widget.recolectorSeleccionado.fotoPerfil.isNotEmpty
                        ? NetworkImage(widget.recolectorSeleccionado.fotoPerfil)
                        : null,
                    child: widget.recolectorSeleccionado.fotoPerfil.isEmpty
                        ? Icon(Icons.person, color: Colors.white, size: 30)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Recolector Seleccionado',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Text(
                    '${widget.recolectorSeleccionado.nombreUsuario} ${widget.recolectorSeleccionado.apellidoUsuario}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Cuánto deseas donar?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Montos rápidos
                    const Text(
                      'Montos sugeridos:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _montosRapidos.map((monto) {
                        final isSelected = _montoSeleccionado == monto;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _montoSeleccionado = monto;
                              _montoController.text = monto.toStringAsFixed(0);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.orange.shade700 
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.orange.shade700 
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              'S/ ${monto.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Monto personalizado
                    const Text(
                      'O ingresa un monto personalizado:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _montoController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Monto en soles (S/)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixText: 'S/ ',
                        hintText: '0.00',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa un monto';
                        }
                        final monto = double.tryParse(value);
                        if (monto == null || monto <= 0) {
                          return 'Por favor ingresa un monto válido';
                        }
                        if (monto < 5) {
                          return 'El monto mínimo es S/ 5.00';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _montoSeleccionado = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Botón continuar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    ),
                    child: const Text('Atrás'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _continuar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Continuar',
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
          ],
        ),
      ),
    );
  }
}
