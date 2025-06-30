import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/donaciones.dart';
import 'package:intl/intl.dart';

class DonacionesFunctions {
  static final Logger _logger = Logger();
  
  static Stream<List<Donaciones>> getDonaciones() {
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

  static List<Donaciones> filterDonacionesByMonth(List<Donaciones> donaciones, String selectedMonth) {
    final DateFormat formatter = DateFormat('MMMM yyyy');
    return donaciones.where((donacion) {
      try {
        if (donacion.fechaDonacion.isEmpty) return false;
        final fecha = DateTime.parse(donacion.fechaDonacion);
        final donacionMonth = formatter.format(fecha);
        return donacionMonth == selectedMonth;
      } catch (e) {
        _logger.e('Error parsing date: ${donacion.fechaDonacion}');
        return false;
      }
    }).toList();
  }

  static List<String> getLastSixMonths() {
    final List<String> months = [];
    final DateTime now = DateTime.now();
    for (int i = 0; i < 6; i++) {
      final DateTime month = DateTime(now.year, now.month - i);
      months.add(DateFormat('MMMM yyyy').format(month));
    }
    return months;
  }

  static Future<void> registrarDonacion(Map<String, dynamic> newDonacion, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('donaciones').add(newDonacion);
      
      if (!context.mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donación registrada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar la donación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}