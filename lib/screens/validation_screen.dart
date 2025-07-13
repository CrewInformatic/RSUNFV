import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/validacion.dart';
import '../services/validation_service.dart';

class ValidationScreen extends StatefulWidget {
  const ValidationScreen({super.key});

  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'todos';

  final Map<String, String> _filterOptions = {
    'todos': 'Todas las validaciones',
    'validadas': 'Solo validadas',
    'pendientes': 'Solo pendientes',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Validaciones'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Panel de filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                // Barra de búsqueda
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por ID de validación o donación...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 12),
                // Filtros
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: InputDecoration(
                          labelText: 'Estado',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _filterOptions.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lista de validaciones
          Expanded(
            child: StreamBuilder<List<Validacion>>(
              stream: ValidationService.getAllValidations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final validaciones = snapshot.data ?? [];
                final filteredValidaciones = _filterValidaciones(validaciones);

                if (filteredValidaciones.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron validaciones'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredValidaciones.length,
                  itemBuilder: (context, index) {
                    final validacion = filteredValidaciones[index];
                    return _buildValidacionCard(validacion);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Validacion> _filterValidaciones(List<Validacion> validaciones) {
    var filtered = validaciones;

    // Filtrar por estado
    if (_selectedFilter == 'validadas') {
      filtered = filtered.where((v) => v.isValidated).toList();
    } else if (_selectedFilter == 'pendientes') {
      filtered = filtered.where((v) => !v.isValidated).toList();
    }

    // Filtrar por búsqueda
    final searchTerm = _searchController.text.toLowerCase().trim();
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((v) {
        return v.validationId.toLowerCase().contains(searchTerm) ||
               v.donationId.toLowerCase().contains(searchTerm) ||
               (v.adminNotes?.toLowerCase().contains(searchTerm) ?? false);
      }).toList();
    }

    return filtered;
  }

  Widget _buildValidacionCard(Validacion validacion) {
    final createdDate = DateTime.tryParse(validacion.createdAt);
    final validatedDate = validacion.validatedAt != null 
        ? DateTime.tryParse(validacion.validatedAt!)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con IDs
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID Validación: ${validacion.validationId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'ID Donación: ${validacion.donationId}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Estado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: validacion.isValidated ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    validacion.isValidated ? 'Validada' : 'Pendiente',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Información temporal
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Creada: ${createdDate != null ? DateFormat('dd/MM/yy HH:mm').format(createdDate) : 'N/A'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      if (validatedDate != null)
                        Text(
                          'Validada: ${DateFormat('dd/MM/yy HH:mm').format(validatedDate)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Notas del admin
            if (validacion.adminNotes != null && validacion.adminNotes!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notas del administrador:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      validacion.adminNotes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (validacion.proofUrl.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _showProofDialog(validacion.proofUrl),
                    icon: const Icon(Icons.image, size: 16),
                    label: const Text('Ver Comprobante'),
                  ),
                if (validacion.imagenComprobante != null && validacion.imagenComprobante!.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _showProofDialog(validacion.imagenComprobante!),
                    icon: const Icon(Icons.verified, size: 16),
                    label: const Text('Ver Validación'),
                  ),
                TextButton.icon(
                  onPressed: () => _showValidacionDetail(validacion),
                  icon: const Icon(Icons.info, size: 16),
                  label: const Text('Detalles'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProofDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Comprobante'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text('Error al cargar imagen'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showValidacionDetail(Validacion validacion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Validación ${validacion.validationId}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID Validación:', validacion.validationId),
              _buildDetailRow('ID Donación:', validacion.donationId),
              _buildDetailRow('Estado:', validacion.isValidated ? 'Validada' : 'Pendiente'),
              _buildDetailRow('Validado por:', validacion.validatedBy ?? 'N/A'),
              _buildDetailRow('Fecha creación:', validacion.createdAt),
              _buildDetailRow('Fecha validación:', validacion.validatedAt ?? 'N/A'),
              if (validacion.adminNotes != null)
                _buildDetailRow('Notas:', validacion.adminNotes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
