import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';
import 'donacion_metodo_pago_s.dart';

class DonacionRecolectorScreen extends StatefulWidget {
  final Map<String, dynamic> donacionData;
  
  const DonacionRecolectorScreen({
    super.key,
    required this.donacionData,
  });

  @override
  State<DonacionRecolectorScreen> createState() => _DonacionRecolectorScreenState();
}

class _DonacionRecolectorScreenState extends State<DonacionRecolectorScreen> {
  Usuario? _recolectorSeleccionado;
  bool _isLoading = true;
  List<Usuario> _recolectores = [];

  @override
  void initState() {
    super.initState();
    _cargarRecolectores();
  }

  Future<void> _cargarRecolectores() async {
    try {
      // Obtener usuarios directamente con rol_004 (recolector_donacion)
      final usuariosQuery = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('idRol', isEqualTo: 'rol_004')
          .where('estadoActivo', isEqualTo: true)
          .get();

      List<Usuario> recolectores = [];
      
      for (var doc in usuariosQuery.docs) {
        final usuario = Usuario.fromFirestore(
          doc.data(),
          doc.id,
        );
        recolectores.add(usuario);
      }

      setState(() {
        _recolectores = recolectores;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando recolectores: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _continuar() {
    if (_recolectorSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un recolector de confianza'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Agregar el recolector a los datos de la donación
    final donacionConRecolector = {
      ...widget.donacionData,
      'idRecolector': _recolectorSeleccionado!.idUsuario,
      'NombreRecolector': _recolectorSeleccionado!.nombreUsuario,
      'ApellidoRecolector': _recolectorSeleccionado!.apellidoUsuario,
      'EmailRecolector': _recolectorSeleccionado!.email,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DonacionMetodoPagoScreen(
          donacionData: donacionConRecolector,
          isEditing: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monto = widget.donacionData['monto'] ?? 0.0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona tu Recolector de Confianza'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header informativo
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
                  Icons.people,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'Hola ${widget.donacionData['NombreUsuarioDonador']}, Monto: S/ ${monto.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona uno de nuestros recolectores certificados',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
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
                _buildStep('👤', 'Recolector', true, Colors.orange.shade700),
                _buildStepConnector(),
                _buildStep('💳', 'Pago', false, Colors.grey),
                _buildStepConnector(),
                _buildStep('📄', 'Certificado', false, Colors.grey),
              ],
            ),
          ),
          
          // Lista de recolectores
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _recolectores.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay recolectores disponibles',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _recolectores.length,
                        itemBuilder: (context, index) {
                          final recolector = _recolectores[index];
                          final isSelected = _recolectorSeleccionado?.idUsuario == recolector.idUsuario;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: isSelected ? 8 : 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? Colors.orange.shade700 : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  _recolectorSeleccionado = recolector;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: isSelected ? Colors.orange.shade700 : Colors.grey[300]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(28),
                                        child: recolector.fotoPerfil.isNotEmpty
                                            ? Image.network(
                                                recolector.fotoPerfil,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.orange.shade100,
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 30,
                                                      color: Colors.orange.shade700,
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                color: Colors.orange.shade100,
                                                child: Icon(
                                                  Icons.person,
                                                  size: 30,
                                                  color: Colors.orange.shade700,
                                                ),
                                              ),
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 16),
                                    
                                    // Información del recolector
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            recolector.nombre,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.orange.shade700 : Colors.grey[800],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          
                                          // Indicadores de calidad
                                          Row(
                                            children: [
                                              Icon(Icons.star, color: Colors.yellow[700], size: 16),
                                              Text(' 4.8', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                              const SizedBox(width: 12),
                                              Icon(Icons.favorite, color: Colors.red[400], size: 16),
                                              Text(' 147', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                            ],
                                          ),
                                          
                                          const SizedBox(height: 4),
                                          
                                          // Estado y facultad
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[100],
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'Nuevo',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.green[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                                              Text(
                                                ' Facultad de Ingeniería',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Icono de verificación
                                    Column(
                                      children: [
                                        Icon(
                                          Icons.verified,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                        const SizedBox(height: 8),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.orange.shade700,
                                            size: 24,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          // Botón continuar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                  child: const Text('Volver'),
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
