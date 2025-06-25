import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import '../models/donaciones.dart';
import '../models/usuario.dart';
import '../services/firebase_auth_services.dart';

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
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  
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
        final donacionMonth = DateFormat('MMMM yyyy').format(donacionDate);
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
      months.add(DateFormat('MMMM yyyy').format(month));
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

  Future<void> _registrarDonacion(Map<String, dynamic> newDonacion) async {
    try {
      await FirebaseFirestore.instance.collection('donaciones').add(newDonacion);
      if (!mounted) return;
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donación registrada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar la donación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDonationForm() {
    final formKey = GlobalKey<FormState>();
    final descripcionController = TextEditingController();
    final cantidadController = TextEditingController();
    String tipoDonacion = 'Ropa';
    String estadoConservacion = 'Nuevo';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Registrar Donación Física',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: tipoDonacion,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Donación',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Ropa', 'Alimentos', 'Útiles', 'Otros']
                      .map((tipo) => DropdownMenuItem(
                            value: tipo,
                            child: Text(tipo),
                          ))
                      .toList(),
                  onChanged: (value) {
                    tipoDonacion = value!;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: cantidadController,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese la cantidad';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción detallada',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese una descripción';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: estadoConservacion,
                  decoration: const InputDecoration(
                    labelText: 'Estado de Conservación',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Nuevo', 'Usado - Como nuevo', 'Usado - Buen estado', 'Usado - Regular']
                      .map((estado) => DropdownMenuItem(
                            value: estado,
                            child: Text(estado),
                          ))
                      .toList(),
                  onChanged: (value) {
                    estadoConservacion = value!;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final newDonacion = {
                        'idDonaciones': FirebaseFirestore.instance.collection('donaciones').doc().id,
                        'idUsuarioDonador': currentUser?.idUsuario ?? '',
                        'tipoDonacion': tipoDonacion,
                        'monto': 0.0,
                        'descripcion': '${descripcionController.text}\nCantidad: ${cantidadController.text}\nEstado: $estadoConservacion',
                        'fechaDonacion': DateTime.now().toIso8601String(),
                        'idValidacion': '',
                        'estadoValidacion': 'pendiente',
                        'metodoPago': 'N/A',
                        'idRecolector': currentUser?.idUsuario,
                      };
                      _registrarDonacion(newDonacion);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Registrar Donación'),
                ),
                const SizedBox(height: 16),
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
                      child: ListTile(
                        title: Text(
                          'Donación ${donacion.tipoDonacion}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(donacion.descripcion),
                            const SizedBox(height: 4),
                            Text(
                              'Monto: S/ ${donacion.monto.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(donacion.estadoValidacion),
                          backgroundColor: donacion.estadoValidacion == 'validado'
                              ? Colors.green[100]
                              : Colors.orange[100],
                          labelStyle: TextStyle(
                            color: donacion.estadoValidacion == 'validado'
                                ? Colors.green[900]
                                : Colors.orange[900],
                          ),
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
      floatingActionButton: isReceptorDonaciones
          ? FloatingActionButton.extended(
              onPressed: _showDonationForm,
              backgroundColor: Colors.green,
              label: const Text('Registrar Donación'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}