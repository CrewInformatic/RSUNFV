import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/usuario.dart';
import 'donacion_confirmacion_s.dart';

/// Pantalla para coordinación de donaciones no monetarias
/// Muestra información del recolector para coordinar la entrega
class DonacionCoordinacionScreen extends StatefulWidget {
  final Map<String, dynamic> donacionData;
  final Usuario recolector;
  
  const DonacionCoordinacionScreen({
    super.key,
    required this.donacionData,
    required this.recolector,
  });

  @override
  State<DonacionCoordinacionScreen> createState() => _DonacionCoordinacionScreenState();
}

class _DonacionCoordinacionScreenState extends State<DonacionCoordinacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observacionesController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  void _copiarNumero(String numero) {
    Clipboard.setData(ClipboardData(text: numero));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Número $numero copiado al portapapeles'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmarCoordinacion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Actualizar los datos de la donación con información de coordinación
      final donacionCompleta = {
        ...widget.donacionData,
        'metodoPago': 'coordinacion_recolector',
        'observacionesCoordinacion': _observacionesController.text.trim(),
        'fechaDonacion': DateTime.now().toIso8601String(),
        'estadoValidacion': 'coordinando',
      };

      // Navegar a la pantalla de confirmación
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DonacionConfirmacionScreen(
            donacionData: donacionCompleta,
            metodoPago: {
              'id': 'coordinacion_recolector',
              'nombre': 'Coordinación con Recolector',
              'descripcion': 'Entrega coordinada de objetos',
            },
            donacionId: donacionCompleta['idDonaciones'] ?? '',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar la coordinación: $e'),
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
    final tipoDonacion = widget.donacionData['tipoDonacion'] ?? '';
    final objetos = widget.donacionData['objetos'] ?? '';
    final descripcion = widget.donacionData['descripcion'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Coordinación de Entrega'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumen de la donación
              _buildDonacionSummary(tipoDonacion, objetos, descripcion),
              
              const SizedBox(height: 24),
              
              // Información del recolector
              _buildRecolectorInfo(),
              
              const SizedBox(height: 24),
              
              // Instrucciones
              _buildInstrucciones(),
              
              const SizedBox(height: 24),
              
              // Campo de observaciones
              _buildObservacionesField(),
              
              const SizedBox(height: 32),
              
              // Botón de confirmación
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonacionSummary(String tipoDonacion, String objetos, String descripcion) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTipoIcon(tipoDonacion),
                    color: Colors.orange.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen de tu Donación',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getTipoDisplayName(tipoDonacion),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (objetos.isNotEmpty) ...[
              Text(
                'Objetos a donar:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                objetos,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
            ],
            
            if (descripcion.isNotEmpty) ...[
              Text(
                'Descripción adicional:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                descripcion,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecolectorInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datos del Recolector Asignado',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Nombre del recolector
            _buildInfoRow(
              icon: Icons.person,
              label: 'Recolector',
              value: '${widget.recolector.nombreUsuario} ${widget.recolector.apellidoUsuario}',
            ),
            
            const SizedBox(height: 12),
            
            // Número de teléfono
            if (widget.recolector.celular != null && widget.recolector.celular!.isNotEmpty)
              _buildInfoRowWithCopy(
                icon: Icons.phone,
                label: 'Teléfono',
                value: widget.recolector.celular!,
                onCopy: () => _copiarNumero(widget.recolector.celular!),
              ),
            
            const SizedBox(height: 12),
            
            // Email
            _buildInfoRow(
              icon: Icons.email,
              label: 'Email',
              value: widget.recolector.correo,
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Contacta al recolector para coordinar la entrega de tu donación.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowWithCopy({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onCopy,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
        IconButton(
          onPressed: onCopy,
          icon: const Icon(Icons.copy, size: 16),
          tooltip: 'Copiar número',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildInstrucciones() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instrucciones para la Entrega',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            _buildInstruccionItem(
              numero: '1',
              texto: 'Contacta al recolector usando los datos proporcionados.',
            ),
            
            _buildInstruccionItem(
              numero: '2',
              texto: 'Coordina un lugar y horario conveniente para ambos.',
            ),
            
            _buildInstruccionItem(
              numero: '3',
              texto: 'Prepara los objetos según lo descrito en tu donación.',
            ),
            
            _buildInstruccionItem(
              numero: '4',
              texto: 'El recolector confirmará la recepción de los objetos.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruccionItem({required String numero, required String texto}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.orange.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                numero,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObservacionesField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Observaciones Adicionales (Opcional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _observacionesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Agrega cualquier información adicional para el recolector...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _confirmarCoordinacion,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Confirmar Coordinación',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'alimentos':
        return Icons.restaurant;
      case 'ropa':
        return Icons.checkroom;
      case 'utiles':
        return Icons.school;
      case 'medicamentos':
        return Icons.medical_services;
      case 'juguetes':
        return Icons.toys;
      default:
        return Icons.card_giftcard;
    }
  }

  String _getTipoDisplayName(String tipo) {
    switch (tipo) {
      case 'alimentos':
        return 'Donación de Alimentos';
      case 'ropa':
        return 'Donación de Ropa y Calzado';
      case 'utiles':
        return 'Donación de Útiles Escolares';
      case 'medicamentos':
        return 'Donación de Medicamentos';
      case 'juguetes':
        return 'Donación de Juguetes';
      default:
        return 'Donación en Especie';
    }
  }
}
