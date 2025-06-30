import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../functions/funciones_donaciones.dart';

class DonacionForm extends StatefulWidget {
  final Usuario? currentUser;
  final double? monto; // Añadimos el parámetro monto

  const DonacionForm({
    super.key,
    this.currentUser,
    this.monto, // Definimos el parámetro nombrado
  });

  @override
  State<DonacionForm> createState() => _DonacionFormState();
}

class _DonacionFormState extends State<DonacionForm> {
  late final TextEditingController _montoController;
  String _metodoPago = 'yape';

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(
      text: widget.monto?.toString() ?? ''
    );
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Haz tu Donación',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [50, 100, 200, 500].map((monto) => 
              ChoiceChip(
                label: Text('S/ $monto'),
                selected: _montoController.text == monto.toString(),
                onSelected: (selected) {
                  setState(() {
                    _montoController.text = selected ? monto.toString() : '';
                  });
                },
              ),
            ).toList(),
          ),
          const SizedBox(height: 20),
          // Campo de monto personalizado
          TextField(
            controller: _montoController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.attach_money),
              labelText: 'Monto personalizado',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Método de pago',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _metodoPago = 'yape';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _metodoPago == 'yape'
                          ? Colors.orange.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _metodoPago == 'yape'
                            ? Colors.orange.shade700
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.phone_android,
                          size: 32,
                          color: _metodoPago == 'yape'
                              ? Colors.orange.shade700
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yape',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _metodoPago == 'yape'
                                ? Colors.orange.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _metodoPago = 'transferencia';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _metodoPago == 'transferencia'
                          ? Colors.orange.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _metodoPago == 'transferencia'
                            ? Colors.orange.shade700
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance,
                          size: 32,
                          color: _metodoPago == 'transferencia'
                              ? Colors.orange.shade700
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Transferencia',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _metodoPago == 'transferencia'
                                ? Colors.orange.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Implementar lógica de donación
              if (_montoController.text.isNotEmpty) {
                // Procesar donación
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text(
              'Donar Ahora',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}