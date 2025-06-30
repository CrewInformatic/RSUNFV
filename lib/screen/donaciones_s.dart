import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:image_picker/image_picker.dart';
import '../models/donaciones.dart';
import '../models/usuario.dart';
import '../services/firebase_auth_services.dart';
import '../functions/funciones_donaciones.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  double? _selectedAmount;
  int _currentStep = 0;
  String _metodoPago = 'yape';
  Usuario? _recolectorSeleccionado;
  String? _comprobantePath;
  List<Usuario> _recolectores = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _cargarRecolectores();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      if (userData != null) {
        final user = Usuario.fromFirestore(
            userData.data() as Map<String, dynamic>, userData.id);

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

  Future<void> _cargarRecolectores() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuario_roles')
          .where('rolID', isEqualTo: 'rol_004')
          .get();

      for (var doc in snapshot.docs) {
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(doc['usuarioID'])
            .get();
        
        if (userDoc.exists) {
          setState(() {
            _recolectores.add(Usuario.fromFirestore(
              userDoc.data()!,
              userDoc.id,
            ));
          });
        }
      }
    } catch (e) {
      _logger.e('Error cargando recolectores: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donaciones'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _buildStatisticsSection(),
          ),
          SliverToBoxAdapter(
            child: _buildDonationOptions(),
          ),
          SliverFillRemaining(
            child: _buildRecentDonations(),
          ),
        ],
      ),
      floatingActionButton: isReceptorDonaciones
          ? FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    _showDonationForm(null);
                    return const SizedBox.shrink();
                  },
                );
              },
              backgroundColor: Colors.green,
              label: const Text('Registrar Donación'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.orange.shade700,
                Colors.orange.shade500,
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Apoya Nuestros Proyectos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Tu donación hace posible que continuemos generando impacto positivo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Impacto Generado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                icon: Icons.people_outline,
                value: '5,000+',
                label: 'Beneficiados',
              ),
              _buildStatCard(
                icon: Icons.volunteer_activism,
                value: '200+',
                label: 'Voluntarios',
              ),
              _buildStatCard(
                icon: Icons.emoji_events_outlined,
                value: '25',
                label: 'Proyectos',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.orange.shade700),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationOptions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Elige tu Aporte',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildDonationCard(
                amount: 'S/ 50',
                description: 'Kit básico de ayuda',
                value: 50, // Añade el valor
                onTap: () => _showDonationForm(50),
              ),
              _buildDonationCard(
                amount: 'S/ 100',
                description: 'Kit completo de apoyo',
                value: 100, // Añade el valor
                onTap: () => _showDonationForm(100),
              ),
              _buildDonationCard(
                amount: 'S/ 200',
                description: 'Proyecto completo',
                value: 200, // Añade el valor
                onTap: () => _showDonationForm(200),
              ),
              _buildDonationCard(
                amount: 'Otro monto',
                description: 'Elige tu aporte',
                isCustom: true,
                value: null, // Este no tiene valor fijo
                onTap: () => _showDonationForm(null),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard({
    required String amount,
    required String description,
    required VoidCallback onTap,
    bool isCustom = false,
    double? value, // Añade este parámetro
  }) {
    final bool isSelected = value != null && value == _selectedAmount;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedAmount = isSelected ? null : value;
        });
        onTap();
      },
      child: Card(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isCustom
                ? LinearGradient(
                    colors: [Colors.purple.shade200, Colors.purple.shade100],
                  )
                : LinearGradient(
                    colors: isSelected
                        ? [Colors.orange.shade400, Colors.orange.shade300]
                        : [Colors.orange.shade200, Colors.orange.shade100],
                  ),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: Colors.orange.shade700, width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.orange.shade900 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.orange.shade900 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDonationForm(double? initialAmount) {
    setState(() {
      _selectedAmount = initialAmount;
      _currentStep = 0;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: const Text('Nueva Donación'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                Stepper(
                  currentStep: _currentStep,
                  onStepContinue: () {
                    if (_currentStep < 3) {
                      setState(() => _currentStep++);
                    } else {
                      _procesarDonacion();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep--);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  steps: [
                    Step(
                      title: const Text('Monto y Método'),
                      content: _buildMontoStep(),
                      isActive: _currentStep >= 0,
                    ),
                    Step(
                      title: const Text('Datos'),
                      content: _buildDatosStep(),
                      isActive: _currentStep >= 1,
                    ),
                    Step(
                      title: const Text('Recolector'),
                      content: _buildRecolectorStep(),
                      isActive: _currentStep >= 2,
                    ),
                    Step(
                      title: const Text('Comprobante'),
                      content: _buildComprobanteStep(),
                      isActive: _currentStep >= 3,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMontoStep() {
    return Column(
      children: [
        Text(
          'S/ ${_selectedAmount?.toString() ?? "0"}',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildMetodoPagoOption(
              'yape',
              'Yape',
              Icons.phone_android,
            ),
            const SizedBox(width: 12),
            _buildMetodoPagoOption(
              'transferencia',
              'Transferencia',
              Icons.account_balance,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetodoPagoOption(String value, String label, IconData icon) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _metodoPago = value),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _metodoPago == value
                ? Colors.orange.shade50
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _metodoPago == value
                  ? Colors.orange.shade700
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: _metodoPago == value
                    ? Colors.orange.shade700
                    : Colors.grey.shade700,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _metodoPago == value
                      ? Colors.orange.shade700
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatosStep() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos del Donante',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(currentUser?.nombreUsuario ?? ''),
              subtitle: const Text('Nombre'),
            ),
            ListTile(
              leading: const Icon(Icons.badge),
              title: Text(currentUser?.codigoUsuario ?? ''),
              subtitle: const Text('Código'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecolectorStep() {
    return Column(
      children: _recolectores.map((recolector) => Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.orange.shade100,
            child: Text(
              recolector.nombreUsuario[0].toUpperCase(),
              style: TextStyle(color: Colors.orange.shade900),
            ),
          ),
          title: Text(recolector.nombreUsuario),
          subtitle: Text(recolector.codigoUsuario),
          trailing: Radio<Usuario>(
            value: recolector,
            groupValue: _recolectorSeleccionado,
            onChanged: (value) {
              setState(() => _recolectorSeleccionado = value);
            },
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildComprobanteStep() {
    return Column(
      children: [
        if (_metodoPago == 'yape')
          Image.asset('assets/qr_yape.png')
        else
          const Text('Cuenta BCP: 123-456789-0'),
        const SizedBox(height: 20),
        _comprobantePath != null
            ? Image.network(_comprobantePath!)
            : const Icon(Icons.image, size: 100),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _seleccionarComprobante,
          icon: const Icon(Icons.upload_file),
          label: const Text('Subir Comprobante'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
          ),
        ),
      ],
    );
  }

  Future<void> _seleccionarComprobante() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() => _comprobantePath = image.path);
      // Aquí deberías subir la imagen a tu storage
    }
  }

  Future<void> _procesarDonacion() async {
    if (_selectedAmount == null ||
        _recolectorSeleccionado == null ||
        _comprobantePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nuevaDonacion = Donaciones(
        idDonaciones: FirebaseFirestore.instance.collection('donaciones').doc().id,
        idUsuarioDonador: currentUser!.idUsuario,
        tipoDonacion: 'Monetaria',
        monto: _selectedAmount!,
        descripcion: 'Donación vía ${_metodoPago.toUpperCase()}',
        fechaDonacion: DateTime.now().toIso8601String(),
        idValidacion: '',
        estadoValidacion: 'pendiente',
        metodoPago: _metodoPago,
        idRecolector: _recolectorSeleccionado!.idUsuario,
      );

      await FirebaseFirestore.instance
          .collection('donaciones')
          .doc(nuevaDonacion.idDonaciones)
          .set(nuevaDonacion.toMap());

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donación registrada con éxito'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _logger.e('Error procesando donación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildRecentDonations() {
    return StreamBuilder<List<Donaciones>>(
      stream: DonacionesFunctions.getDonaciones(),
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
        final donacionesFiltradas =
            DonacionesFunctions.filterDonacionesByMonth(
                allDonaciones, _selectedMonth);

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
                  backgroundColor:
                      donacion.estadoValidacion == 'validado'
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
    );
  }
}
