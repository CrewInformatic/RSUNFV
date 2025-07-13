import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/donaciones.dart';
import '../services/validation_service.dart';

class DonationManagementScreen extends StatefulWidget {
  const DonationManagementScreen({super.key});

  @override
  State<DonationManagementScreen> createState() => _DonationManagementScreenState();
}

class _DonationManagementScreenState extends State<DonationManagementScreen> {
  String _selectedStatus = 'todos';
  String _selectedType = 'todos';
  String _selectedPaymentMethod = 'todos';
  bool _onlyWithVoucher = false;
  final _searchController = TextEditingController();

  final Map<String, String> _statusOptions = {
    'todos': 'Todos los estados',
    'pendiente': 'Pendientes',
    'validado': 'Validadas',
    'rechazado': 'Rechazadas',
  };

  final Map<String, String> _typeOptions = {
    'todos': 'Todos los tipos',
    'Dinero': 'Donaciones monetarias',
    'Ropa': 'Ropa',
    'Alimentos': 'Alimentos',
    'Útiles': 'Útiles',
    'Otros': 'Otros',
  };

  final Map<String, String> _paymentOptions = {
    'todos': 'Todos los métodos',
    'Transferencia Bancaria': 'Transferencia Bancaria',
    'Yape': 'Yape',
    'Plin': 'Plin',
    'Efectivo': 'Efectivo',
    'N/A': 'Sin método',
  };

  Stream<List<Donaciones>> _getDonacionesFiltered() {
    Query query = FirebaseFirestore.instance
        .collection('donaciones')
        .orderBy('fechaDonacion', descending: true);

    return query.snapshots().map((snapshot) {
      List<Donaciones> donaciones = snapshot.docs
          .map((doc) => Donaciones.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'idDonaciones': doc.id,
              }))
          .toList();

      // Aplicar filtros
      if (_selectedStatus != 'todos') {
        donaciones = donaciones.where((d) => d.estadoValidacion == _selectedStatus).toList();
      }

      if (_selectedType != 'todos') {
        donaciones = donaciones.where((d) => d.tipoDonacion == _selectedType).toList();
      }

      if (_selectedPaymentMethod != 'todos') {
        donaciones = donaciones.where((d) => d.metodoPago == _selectedPaymentMethod).toList();
      }

      if (_onlyWithVoucher) {
        // Simplemente mostrar todas las donaciones - el filtro de voucher se puede hacer de otra manera
        // O eliminar este filtro ya que es complejo de implementar con la nueva arquitectura
      }

      // Filtro de búsqueda
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        donaciones = donaciones.where((d) {
          return d.nombreUsuarioDonador?.toLowerCase().contains(searchTerm) == true ||
                 d.emailUsuarioDonador?.toLowerCase().contains(searchTerm) == true ||
                 d.descripcion.toLowerCase().contains(searchTerm) ||
                 d.numeroOperacion?.toLowerCase().contains(searchTerm) == true;
        }).toList();
      }

      return donaciones;
    });
  }

  Future<void> _updateDonationStatus(String donationId, String newStatus) async {
    try {
      // Actualizar el estado de la donación
      await FirebaseFirestore.instance
          .collection('donaciones')
          .doc(donationId)
          .update({'estadoValidacion': newStatus});

      // Si se está validando, crear registro en la colección validacion
      if (newStatus == 'validado') {
        await _createValidationRecord(donationId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a: $newStatus'),
            backgroundColor: newStatus == 'validado' ? Colors.green : 
                           newStatus == 'rechazado' ? Colors.red : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createValidationRecord(String donationId) async {
    try {
      // Obtener información de la donación
      final donacionDoc = await FirebaseFirestore.instance
          .collection('donaciones')
          .doc(donationId)
          .get();
      
      if (donacionDoc.exists) {
        // Usar el servicio de validación para crear el registro
        final validationId = await ValidationService.createValidationRecord(
          donationId: donationId,
          adminNotes: 'Donación validada por administrador',
        );
        
        if (validationId != null) {
          debugPrint('Validation record created with ID: $validationId');
        }
      }
    } catch (e) {
      // Error silencioso para no interrumpir el flujo principal
      debugPrint('Error creating validation record: $e');
    }
  }

  void _showVoucherDialog(String voucherUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.95,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Voucher de Depósito',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Imagen
              Expanded(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.1,
                  maxScale: 5.0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Image.network(
                      voucherUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('Error al cargar la imagen'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusUpdateDialog(Donaciones donacion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Donación de: ${donacion.nombreUsuarioDonador ?? 'Usuario anónimo'}'),
            Text('Monto: S/ ${donacion.monto.toStringAsFixed(2)}'),
            Text('Estado actual: ${donacion.estadoValidacion}'),
            const SizedBox(height: 16),
            const Text('Seleccionar nuevo estado:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          if (donacion.estadoValidacion != 'validado')
            ElevatedButton(
              onPressed: () {
                _updateDonationStatus(donacion.idDonaciones, 'validado');
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Validar', style: TextStyle(color: Colors.white)),
            ),
          if (donacion.estadoValidacion != 'rechazado')
            ElevatedButton(
              onPressed: () {
                _updateDonationStatus(donacion.idDonaciones, 'rechazado');
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
            ),
          if (donacion.estadoValidacion != 'pendiente')
            ElevatedButton(
              onPressed: () {
                _updateDonationStatus(donacion.idDonaciones, 'pendiente');
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Pendiente', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Donaciones'),
        backgroundColor: Colors.orange.shade700,
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
                    hintText: 'Buscar por nombre, email, descripción o nº operación...',
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
                
                // Filtros en fila
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Filtro de estado
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          underline: Container(),
                          items: _statusOptions.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            }
                          },
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Filtro de tipo
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedType,
                          underline: Container(),
                          items: _typeOptions.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedType = value;
                              });
                            }
                          },
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Filtro de método de pago
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedPaymentMethod,
                          underline: Container(),
                          items: _paymentOptions.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedPaymentMethod = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Checkbox para voucher
                Row(
                  children: [
                    Checkbox(
                      value: _onlyWithVoucher,
                      onChanged: (value) {
                        setState(() {
                          _onlyWithVoucher = value ?? false;
                        });
                      },
                    ),
                    const Text('Solo donaciones con voucher'),
                  ],
                ),
              ],
            ),
          ),
          
          // Lista de donaciones
          Expanded(
            child: StreamBuilder<List<Donaciones>>(
              stream: _getDonacionesFiltered(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final donaciones = snapshot.data ?? [];

                if (donaciones.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No se encontraron donaciones'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: donaciones.length,
                  itemBuilder: (context, index) {
                    final donacion = donaciones[index];
                    
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: donacion.estadoValidacion == 'validado'
                              ? Colors.green
                              : donacion.estadoValidacion == 'rechazado'
                                  ? Colors.red
                                  : Colors.orange,
                          child: Icon(
                            donacion.estadoValidacion == 'validado'
                                ? Icons.check
                                : donacion.estadoValidacion == 'rechazado'
                                    ? Icons.close
                                    : Icons.schedule,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          '${donacion.nombreUsuarioDonador ?? 'Usuario anónimo'} - S/ ${donacion.monto.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${donacion.tipoDonacion} - ${donacion.metodoPago}'),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(donacion.fechaDonacion)),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FutureBuilder<bool>(
                              future: ValidationService.hasVoucherImage(donacion.idDonaciones),
                              builder: (context, snapshot) {
                                if (snapshot.data == true) {
                                  return IconButton(
                                    icon: const Icon(Icons.receipt, color: Colors.green),
                                    onPressed: () async {
                                      final voucherUrl = await ValidationService.getVoucherImageUrl(donacion.idDonaciones);
                                      if (voucherUrl != null) {
                                        _showVoucherDialog(voucherUrl);
                                      }
                                    },
                                    tooltip: 'Ver voucher',
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.orange.shade700),
                              onPressed: () => _showStatusUpdateDialog(donacion),
                              tooltip: 'Cambiar estado',
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (donacion.descripcion.isNotEmpty) ...[
                                  const Text(
                                    'Descripción:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(donacion.descripcion),
                                  const SizedBox(height: 8),
                                ],
                                
                                if (donacion.emailUsuarioDonador != null) ...[
                                  const Text(
                                    'Email:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(donacion.emailUsuarioDonador!),
                                  const SizedBox(height: 8),
                                ],
                                
                                if (donacion.numeroOperacion != null && donacion.numeroOperacion!.isNotEmpty) ...[
                                  const Text(
                                    'Número de operación:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(donacion.numeroOperacion!),
                                  const SizedBox(height: 8),
                                ],
                                
                                if (donacion.fechaDeposito != null) ...[
                                  const Text(
                                    'Fecha de depósito:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(DateFormat('dd/MM/yyyy').format(donacion.fechaDeposito!)),
                                  const SizedBox(height: 8),
                                ],
                                
                                // Botones de acción rápida
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    if (donacion.estadoValidacion != 'validado')
                                      ElevatedButton.icon(
                                        onPressed: () => _updateDonationStatus(donacion.idDonaciones, 'validado'),
                                        icon: const Icon(Icons.check, size: 16),
                                        label: const Text('Validar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    if (donacion.estadoValidacion != 'rechazado')
                                      ElevatedButton.icon(
                                        onPressed: () => _updateDonationStatus(donacion.idDonaciones, 'rechazado'),
                                        icon: const Icon(Icons.close, size: 16),
                                        label: const Text('Rechazar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    if (donacion.estadoValidacion != 'pendiente')
                                      ElevatedButton.icon(
                                        onPressed: () => _updateDonationStatus(donacion.idDonaciones, 'pendiente'),
                                        icon: const Icon(Icons.schedule, size: 16),
                                        label: const Text('Pendiente'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
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
