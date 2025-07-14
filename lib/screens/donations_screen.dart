import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import '../models/donaciones.dart';
import '../models/usuario.dart';
import '../services/firebase_auth_services.dart';
import '../services/validation_service.dart';
import '../utils/date_translation_util.dart';
import 'donation_type_selection_screen.dart';

class DonacionesScreen extends StatefulWidget {
  const DonacionesScreen({super.key});

  @override
  State<DonacionesScreen> createState() => _DonacionesScreenState();
}

class _DonacionesScreenState extends State<DonacionesScreen> {
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  Usuario? currentUser;
  bool isReceptorDonaciones = false;
  String _selectedMonth = DateTranslationUtil.formatMonthYear(DateTime.now());
  
  Stream<List<Donaciones>> _getDonaciones() {
    return FirebaseFirestore.instance
        .collection('donaciones')
        .orderBy('fechaDonacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Donaciones.fromMap({
                  ...doc.data(),
                  'idDonaciones': doc.id, 
                }))
            .toList());
  }

  List<Donaciones> _filterDonacionesByMonth(List<Donaciones> donaciones, String month) {
    return donaciones.where((donacion) {
      try {
        final donacionDate = DateTime.parse(donacion.fechaDonacion);
        final donacionMonth = DateTranslationUtil.formatMonthYear(donacionDate);
        return donacionMonth == month;
      } catch (e) {
        _logger.e('Error parsing date: ${donacion.fechaDonacion}');
        return false;
      }
    }).toList();
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Icon(Icons.calendar_month, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedMonth,
              isExpanded: true,
              underline: Container(),
              items: _getLastSixMonths()
                  .map((month) => DropdownMenuItem(
                        value: month,
                        child: Text(month),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMonth = value;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getLastSixMonths() {
    final List<String> months = [];
    final DateTime now = DateTime.now();
    for (int i = 0; i < 6; i++) {
      final DateTime month = DateTime(now.year, now.month - i);
      months.add(DateTranslationUtil.formatMonthYear(month));
    }
    return months;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      if (userData != null) {
        final user = Usuario.fromFirestore(userData.data() as Map<String, dynamic>, userData.id);
        
        final usuarioRolesDoc = await FirebaseFirestore.instance
            .collection('usuario_roles')
            .where('usuarioID', isEqualTo: user.idUsuario)
            .get();

        if (usuarioRolesDoc.docs.isNotEmpty) {
          final rolID = usuarioRolesDoc.docs.first.data()['rolID'];
          
          if (!mounted) return;
          setState(() {
            currentUser = user;
            isReceptorDonaciones = rolID == 'rol_004';
          });
        }
      }
    } catch (e) {
      _logger.e('Error loading user data: $e');
    }
  }

  Widget _buildVoucherSection(Donaciones donacion) {
    return FutureBuilder<String?>(
      future: ValidationService.getVoucherImageUrl(donacion.idDonaciones),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Verificando comprobante...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        final voucherUrl = snapshot.data;
        if (voucherUrl == null || voucherUrl.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt,
                        color: Colors.green[700],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Voucher del Depósito',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showVoucherModal(voucherUrl),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Ver completo',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.network(
                    voucherUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: Colors.grey),
                              SizedBox(height: 4),
                              Text(
                                'Error al cargar imagen',
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVoucherModal(String voucherUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      const Row(
                        children: [
                          Icon(Icons.receipt, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Voucher del Depósito',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: InteractiveViewer(
                      panEnabled: true,
                      boundaryMargin: const EdgeInsets.all(20),
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          voucherUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 300,
                              color: Colors.grey.shade200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('Cargando voucher...'),
                                  ],
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 300,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'Error al cargar la imagen',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Usa gestos para hacer zoom y desplazarte por la imagen',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donaciones'),
        backgroundColor: Colors.orange.shade700,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: StreamBuilder<List<Donaciones>>(
              stream: _getDonaciones(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  _logger.e('Error: ${snapshot.error}');
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final allDonaciones = snapshot.data ?? [];
                _logger.d('Donaciones totales: ${allDonaciones.length}');
                
                final donacionesFiltradas = _filterDonacionesByMonth(allDonaciones, _selectedMonth);
                _logger.d('Donaciones filtradas: ${donacionesFiltradas.length}');

                if (donacionesFiltradas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.volunteer_activism,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay donaciones en $_selectedMonth',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: donacionesFiltradas.length,
                  itemBuilder: (context, index) {
                    final donacion = donacionesFiltradas[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Donación ${donacion.tipoDonacion}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Chip(
                                  label: Text(donacion.estadoValidacion),
                                  backgroundColor: donacion.estadoValidacion == 'validado'
                                      ? Colors.green[100]
                                      : donacion.estadoValidacion == 'rechazado'
                                          ? Colors.red[100]
                                          : Colors.orange[100],
                                  labelStyle: TextStyle(
                                    color: donacion.estadoValidacion == 'validado'
                                        ? Colors.green[900]
                                        : donacion.estadoValidacion == 'rechazado'
                                            ? Colors.red[900]
                                            : Colors.orange[900],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            if (donacion.nombreUsuarioDonador != null && donacion.nombreUsuarioDonador!.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Donador:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${donacion.nombreUsuarioDonador} ${donacion.apellidoUsuarioDonador ?? ''}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (donacion.emailUsuarioDonador != null && donacion.emailUsuarioDonador!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        donacion.emailUsuarioDonador!,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            
                            if (donacion.descripcion.isNotEmpty) ...[
                              Text(
                                'Descripción:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                donacion.descripcion,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                            ],
                            
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    color: Colors.green[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Monto: S/ ${donacion.monto.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            if (donacion.metodoPago.isNotEmpty && donacion.metodoPago != 'N/A') ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.payment,
                                          color: Colors.blue[600],
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Método de Pago:',
                                          style: TextStyle(
                                            color: Colors.blue[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      donacion.metodoPago,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (donacion.numeroOperacion != null && donacion.numeroOperacion!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Nº Operación: ${donacion.numeroOperacion}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    if (donacion.fechaDeposito != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Fecha depósito: ${DateFormat('dd/MM/yyyy').format(donacion.fechaDeposito!)}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 12),
                            _buildVoucherSection(donacion),

                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Registrada: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(donacion.fechaDonacion))}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DonationTypeSelectionScreen(),
            ),
          );
        },
        backgroundColor: Colors.orange.shade700,
        label: const Text(
          'Nueva Donación',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        icon: const Icon(Icons.favorite, color: Colors.white),
      ),
    );
  }
}
