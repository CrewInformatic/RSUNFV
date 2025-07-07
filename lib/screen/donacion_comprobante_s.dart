import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DonacionComprobanteScreen extends StatelessWidget {
  final Map<String, dynamic> donacionData;
  final Map<String, dynamic> metodoPago;
  
  const DonacionComprobanteScreen({
    super.key,
    required this.donacionData,
    required this.metodoPago,
  });

  @override
  Widget build(BuildContext context) {
    final monto = donacionData['monto'] ?? 0.0;
    final fechaDonacion = DateTime.tryParse(donacionData['fechaDonacion'] ?? '') ?? DateTime.now();
    final nombreDonador = donacionData['NombreUsuarioDonador'] ?? '';
    final apellidoDonador = donacionData['ApellidoUsuarioDonador'] ?? '';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprobante de Donación'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Encabezado de éxito
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade600, Colors.green.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '¡Donación Exitosa!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gracias por tu generosidad',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Comprobante
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título del comprobante
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.volunteer_activism,
                            size: 48,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'COMPROBANTE DE DONACIÓN',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Universidad Nacional Federico Villarreal',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    
                    // Detalles de la donación
                    _buildComprobanteRow('ID Donación:', donacionData['idDonaciones'] ?? 'N/A'),
                    _buildComprobanteRow('Fecha:', DateFormat('dd/MM/yyyy HH:mm').format(fechaDonacion)),
                    _buildComprobanteRow('Donador:', '$nombreDonador $apellidoDonador'),
                    _buildComprobanteRow('Email:', donacionData['EmailUsuarioDonador'] ?? 'N/A'),
                    _buildComprobanteRow('Tipo de Donación:', donacionData['tipoDonacion'] ?? 'N/A'),
                    
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    
                    // Monto destacado
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'MONTO DONADO',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'S/ ${monto.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    
                    // Método de pago
                    _buildComprobanteRow('Método de Pago:', metodoPago['nombre'] ?? 'N/A'),
                    if (metodoPago['numero'] != null)
                      _buildComprobanteRow('Número:', metodoPago['numero']),
                    if (metodoPago['cuenta'] != null)
                      _buildComprobanteRow('Cuenta:', metodoPago['cuenta']),
                    
                    const SizedBox(height: 16),
                    
                    // Descripción si existe
                    if (donacionData['descripcion'] != null && donacionData['descripcion'].toString().trim().isNotEmpty) ...[
                      _buildComprobanteRow('Mensaje:', donacionData['descripcion']),
                      const SizedBox(height: 16),
                    ],
                    
                    // Estado
                    _buildComprobanteRow('Estado:', donacionData['estadoValidacion'] ?? 'Pendiente'),
                    
                    const SizedBox(height: 24),
                    
                    // Nota informativa
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tu donación está siendo procesada. Recibirás una confirmación por email una vez que sea validada.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copiarComprobante(context),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Volver al Inicio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
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

  Widget _buildComprobanteRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copiarComprobante(BuildContext context) {
    final monto = donacionData['monto'] ?? 0.0;
    final fechaDonacion = DateTime.tryParse(donacionData['fechaDonacion'] ?? '') ?? DateTime.now();
    final nombreDonador = donacionData['NombreUsuarioDonador'] ?? '';
    final apellidoDonador = donacionData['ApellidoUsuarioDonador'] ?? '';
    
    final comprobante = '''
COMPROBANTE DE DONACIÓN
Universidad Nacional Federico Villarreal

ID Donación: ${donacionData['idDonaciones'] ?? 'N/A'}
Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(fechaDonacion)}
Donador: $nombreDonador $apellidoDonador
Email: ${donacionData['EmailUsuarioDonador'] ?? 'N/A'}
Tipo: ${donacionData['tipoDonacion'] ?? 'N/A'}
Monto: S/ ${monto.toStringAsFixed(2)}
Método de Pago: ${metodoPago['nombre'] ?? 'N/A'}
Estado: ${donacionData['estadoValidacion'] ?? 'Pendiente'}

¡Gracias por tu donación!
''';

    Clipboard.setData(ClipboardData(text: comprobante));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comprobante copiado al portapapeles'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
