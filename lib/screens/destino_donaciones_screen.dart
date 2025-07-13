import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DestinoDonacionesScreen extends StatefulWidget {
  const DestinoDonacionesScreen({super.key});

  @override
  State<DestinoDonacionesScreen> createState() => _DestinoDonacionesScreenState();
}

class _DestinoDonacionesScreenState extends State<DestinoDonacionesScreen> {
  bool isLoading = true;
  Map<String, double> destinoTotales = {};
  List<Color> gradientColors = [
    const Color(0xFFFF8C00),
    const Color(0xFFFFD700),
  ];

  @override
  void initState() {
    super.initState();
    _cargarDestinoDonaciones();
  }

  Future<void> _cargarDestinoDonaciones() async {
    try {
      final donacionesSnapshot = await FirebaseFirestore.instance
          .collection('donaciones')
          .get();

      Map<String, double> totales = {};

      for (var doc in donacionesSnapshot.docs) {
        final destino = doc.data()['tipoDonacion'] as String;
        final monto = (doc.data()['monto'] as num).toDouble();

        totales[destino] = (totales[destino] ?? 0) + monto;
      }

      if (mounted) {
        setState(() {
          destinoTotales = totales;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando destinos: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Destino de Donaciones'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Distribución de Donaciones',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _buildPieChart(),
                  const SizedBox(height: 30),
                  _buildDestinationCards(),
                ],
              ),
            ),
    );
  }

  Widget _buildPieChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sections: _buildPieSections(),
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    List<PieChartSectionData> sections = [];
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
    ];

    int i = 0;
    final total = destinoTotales.values.reduce((a, b) => a + b);

    destinoTotales.forEach((destino, monto) {
      final percentage = (monto / total) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: monto,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      i++;
    });

    return sections;
  }

  Widget _buildDestinationCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: destinoTotales.entries.map((entry) {
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade100,
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(
                  _getIconForDestino(entry.key),
                  size: 40,
                  color: Colors.orange.shade700,
                ),
                title: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Total: S/ ${entry.value.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${((entry.value / destinoTotales.values.reduce((a, b) => a + b)) * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconForDestino(String destino) {
    switch (destino.toLowerCase()) {
      case 'alimentos':
        return Icons.restaurant;
      case 'materiales':
        return Icons.school;
      case 'transporte':
        return Icons.directions_bus;
      case 'monetaria':
        return Icons.attach_money;
      default:
        return Icons.category;
    }
  }
}