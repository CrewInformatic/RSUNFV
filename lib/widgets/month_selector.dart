import 'package:flutter/material.dart';
import '../functions/funciones_donaciones.dart';

class MonthSelector extends StatelessWidget {
  final String selectedMonth;
  final ValueChanged<String?> onMonthChanged;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Icon(Icons.calendar_month, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: selectedMonth,
              isExpanded: true,
              underline: Container(),
              items: DonacionesFunctions.getLastSixMonths()
                  .map((month) => DropdownMenuItem(
                        value: month,
                        child: Text(month),
                      ))
                  .toList(),
              onChanged: onMonthChanged,
            ),
          ),
        ],
      ),
    );
  }
}