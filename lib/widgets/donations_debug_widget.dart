import 'package:flutter/material.dart';
import '../services/donations_debug_service.dart';

class DonationsDebugWidget extends StatefulWidget {
  const DonationsDebugWidget({super.key});

  @override
  State<DonationsDebugWidget> createState() => _DonationsDebugWidgetState();
}

class _DonationsDebugWidgetState extends State<DonationsDebugWidget> {
  String _debugInfo = 'Presiona el botón para analizar';
  bool _isLoading = false;

  Future<void> _analyzeDonations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final summary = await DonationsDebugService.getQuickSummary();
      setState(() {
        _debugInfo = summary;
      });
    } catch (e) {
      setState(() {
        _debugInfo = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'DEPURACIÓN - Análisis de Donaciones',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _analyzeDonations,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Analizar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _debugInfo,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '💡 Este widget es temporal para debuggear el problema de los montos diferentes.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget compacto para usar en desarrollo
class QuickDebugButton extends StatelessWidget {
  const QuickDebugButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        try {
          final summary = await DonationsDebugService.getQuickSummary();
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Depuración Donaciones'),
                content: SingleChildScrollView(
                  child: Text(
                    summary,
                    style: const TextStyle(fontFamily: 'monospace'),
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
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
      },
      icon: const Icon(Icons.bug_report),
      label: const Text('Depurar'),
      backgroundColor: Colors.orange,
    );
  }
}
