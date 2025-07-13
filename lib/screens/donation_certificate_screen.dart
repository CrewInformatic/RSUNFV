import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DonacionCertificadoScreen extends StatelessWidget {
  final Map<String, dynamic> donacionData;
  final Map<String, dynamic> metodoPago;
  final String donacionId;
  
  const DonacionCertificadoScreen({
    super.key,
    required this.donacionData,
    required this.metodoPago,
    required this.donacionId,
  });

  @override
  Widget build(BuildContext context) {
    final monto = donacionData['monto'] ?? 0.0;
    final fechaDonacion = DateTime.tryParse(donacionData['fechaDonacion'] ?? '') ?? DateTime.now();
    final nombreDonador = donacionData['NombreUsuarioDonador'] ?? '';
    final apellidoDonador = donacionData['ApellidoUsuarioDonador'] ?? '';
    final nombreRecolector = donacionData['NombreRecolector'] ?? '';
    final apellidoRecolector = donacionData['ApellidoRecolector'] ?? '';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificado de Donación'),
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
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade50, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade200, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'UNIVERSIDAD NACIONAL\nFEDERICO VILLARREAL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Container(
                      width: 60,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'CERTIFICADO DE DONACIÓN',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                          height: 1.6,
                        ),
                        children: [
                          const TextSpan(text: 'Por medio del presente documento se certifica que '),
                          TextSpan(
                            text: '$nombreDonador $apellidoDonador',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const TextSpan(text: ' ha realizado una donación por un monto de '),
                          TextSpan(
                            text: 'S/ ${monto.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                              fontSize: 18,
                            ),
                          ),
                          const TextSpan(text: ' soles a favor de los programas sociales de la Universidad Nacional Federico Villarreal.'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade100),
                      ),
                      child: Column(
                        children: [
                          _buildCertificateDetail('ID de Donación:', donacionId),
                          _buildCertificateDetail('Fecha de Donación:', DateFormat('dd \'de\' MMMM \'de\' yyyy', 'es').format(fechaDonacion)),
                          _buildCertificateDetail('Tipo de Donación:', donacionData['tipoDonacion'] ?? 'Monetaria'),
                          _buildCertificateDetail('Método de Pago:', metodoPago['nombre'] ?? 'N/A'),
                          _buildCertificateDetail('Recolector Asignado:', '$nombreRecolector $apellidoRecolector'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '¡GRACIAS POR TU GENEROSIDAD!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tu donación contribuye directamente al bienestar de nuestra comunidad universitaria y a la formación de futuros profesionales.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 120,
                              height: 2,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Firma Autorizada',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'UNFV',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green[300]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, color: Colors.green[700], size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verificado',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('dd/MM/yyyy').format(DateTime.now()),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.qr_code,
                        color: Colors.grey[600],
                        size: 40,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Código de Verificación: ${donacionId.substring(0, 8).toUpperCase()}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _compartirCertificado(context),
                    icon: const Icon(Icons.share),
                    label: const Text('Compartir'),
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

  Widget _buildCertificateDetail(String label, String value) {
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
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _compartirCertificado(BuildContext context) {
    final monto = donacionData['monto'] ?? 0.0;
    final nombreDonador = donacionData['NombreUsuarioDonador'] ?? '';
    final apellidoDonador = donacionData['ApellidoUsuarioDonador'] ?? '';
    final fechaDonacion = DateTime.tryParse(donacionData['fechaDonacion'] ?? '') ?? DateTime.now();
    
    final certificadoTexto = '''
🎓 CERTIFICADO DE DONACIÓN - UNFV

Donador: $nombreDonador $apellidoDonador
Monto: S/ ${monto.toStringAsFixed(2)}
Fecha: ${DateFormat('dd/MM/yyyy').format(fechaDonacion)}
ID: ${donacionId.substring(0, 8).toUpperCase()}

¡Gracias por contribuir con la educación! 🙏

#UNFV #Donaciones #Solidaridad
''';

    Clipboard.setData(ClipboardData(text: certificadoTexto));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Certificado copiado para compartir'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
