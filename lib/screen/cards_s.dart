import 'package:flutter/material.dart';

class EventoDetailScreen extends StatefulWidget {
  @override
  _EventoDetailScreenState createState() => _EventoDetailScreenState();
}

class _EventoDetailScreenState extends State<EventoDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Datos del evento
  final Map<String, String> eventoInfo = {
    'Hora': '9:00 AM - 5:00 PM',
    'Fecha': '15 de Marzo 2024',
    'Lugar': 'Auditorio Principal UNFV',
    'Tiempo': '8 horas académicas',
    'Encargado': 'Dr. María González',
    'Descripción': 'Asesoramiento y seguimiento operativo de la gestión ambiental',
  };

  // Lista de participantes
  final List<Map<String, String>> participantes = [
    {'Nombre': 'Juan Pérez', 'Código': '2021001'},
    {'Nombre': 'María García', 'Código': '2021002'},
    {'Nombre': 'Carlos López', 'Código': '2021003'},
    {'Nombre': 'Ana Martínez', 'Código': '2021004'},
    {'Nombre': 'Luis Rodriguez', 'Código': '2021005'},
    {'Nombre': 'Sofia Herrera', 'Código': '2021006'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {
              // Agregar a favoritos
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con imagen del evento
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  // Imagen del evento
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal, Colors.blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Contenido de la imagen
                        Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ASESORAMIENTO Y\nSEGUIMIENTO OPERATIVO DE\nLA GESTIÓN AMBIENTAL EN\nLA UNFV',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              Row(
                                children: [
                                  Text(
                                    'Del 15 marzo al 30 marzo 2024',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Spacer(),
                                  // Logo UNFV
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.school,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Imagen de personas (simulada)
                        Positioned(
                          right: 20,
                          top: 20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.groups,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tabs
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.teal,
                      tabs: [
                        Tab(text: 'EVENTO'),
                        Tab(text: 'PARTICIPANTES'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Contenido de los tabs
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab EVENTO
                  _buildEventoTab(),
                  // Tab PARTICIPANTES
                  _buildParticipantesTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventoTab() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Información del evento
          Expanded(
            child: ListView(
              children: eventoInfo.entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          '${entry.key}:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // Botón de acción
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Acción del botón
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Inscripción'),
                    content: Text('¿Desea inscribirse a este evento?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Inscribirse'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'INSCRIBIRSE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantesTab() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Lista de participantes
          Expanded(
            child: ListView.builder(
              itemCount: participantes.length,
              itemBuilder: (context, index) {
                final participante = participantes[index];
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          participante['Nombre']!,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          participante['Código']!,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Información adicional
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, color: Colors.teal, size: 20),
                SizedBox(width: 8),
                Text(
                  'Total de participantes: ${participantes.length}',
                  style: TextStyle(
                    color: Colors.teal[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}