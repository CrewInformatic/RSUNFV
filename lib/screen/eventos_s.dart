import 'package:flutter/material.dart';
import '../models/evento.dart';
import 'cards_s.dart' as cards;
import '../functions/pedir_eventos.dart';

class EventosScreen extends StatefulWidget {
  final int horasAcumuladas;

  const EventosScreen({
    super.key,
    this.horasAcumuladas = 0,
  });

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  String filtroActual = 'todos';
  String terminoBusqueda = '';
  Map<String, int> estadisticas = {};
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    final stats = await EventosFunctions.obtenerEstadisticasEventos();
    setState(() {
      estadisticas = stats;
    });
  }

  void _buscarEventos(String termino) async {
    final resultados = await EventosFunctions.buscarEventos(termino);
    // ...existing code...
  }

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [Colors.orange.shade700, Colors.deepPurple.shade400],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos de Voluntariado'),
        backgroundColor: Colors.orange.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
              _cargarEstadisticas();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Meta y motivación
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: Colors.white.withOpacity(0.95),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Por qué hacemos estos eventos?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Los eventos de voluntariado permiten a los estudiantes contribuir a la sociedad, '
                      'desarrollar habilidades personales y profesionales, y acumular horas reconocidas por la universidad.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Horas acumuladas
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.deepPurple.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, color: Colors.white, size: 36),
                  const SizedBox(width: 16),
                  Text(
                    'Horas acumuladas:',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.horasAcumuladas}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.deepPurple.shade200,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Barra de búsqueda
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar eventos...',
                prefixIcon: Icon(Icons.search, color: Colors.orange.shade700),
                suffixIcon: terminoBusqueda.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.orange.shade700),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            terminoBusqueda = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  terminoBusqueda = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Filtros
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FiltroChip(
                    label: 'Todos',
                    isSelected: filtroActual == 'todos',
                    onTap: () => setState(() => filtroActual = 'todos'),
                  ),
                  const SizedBox(width: 8),
                  _FiltroChip(
                    label: 'Próximos',
                    isSelected: filtroActual == 'proximos',
                    onTap: () => setState(() => filtroActual = 'proximos'),
                  ),
                  const SizedBox(width: 8),
                  _FiltroChip(
                    label: 'Pasados',
                    isSelected: filtroActual == 'pasados',
                    onTap: () => setState(() => filtroActual = 'pasados'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Estadísticas
            if (estadisticas.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _EstadisticaItem(
                      label: 'Total',
                      valor: estadisticas['total']!,
                      icono: Icons.event,
                    ),
                    _EstadisticaItem(
                      label: 'Próximos',
                      valor: estadisticas['proximos']!,
                      icono: Icons.upcoming,
                    ),
                    _EstadisticaItem(
                      label: 'Voluntarios',
                      valor: estadisticas['totalVoluntarios']!,
                      icono: Icons.people,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Título de eventos
            Text(
              'Eventos ${filtroActual == 'todos' ? 'disponibles' : filtroActual}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.deepPurple.shade200,
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lista de eventos
            StreamBuilder<List<Evento>>(
              stream: EventosFunctions.streamEventos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          'Cargando eventos...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.error, color: Colors.white, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar eventos',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final eventos = snapshot.data ?? [];

                if (eventos.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.event_busy, color: Colors.white, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          terminoBusqueda.isNotEmpty
                              ? 'No se encontraron eventos'
                              : 'No hay eventos disponibles',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        if (terminoBusqueda.isNotEmpty)
                          Text(
                            'para "$terminoBusqueda"',
                            style: TextStyle(color: Colors.white70),
                          ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: eventos
                      .map(
                        (evento) => GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => cards.EventoDetailScreen(
                                  eventoId: evento.idEvento,
                                ),
                              ),
                            );
                          },
                          child: _EventoCard(evento: evento),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.orange.shade700 : Colors.white,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.orange.shade700 : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _EstadisticaItem extends StatelessWidget {
  final String label;
  final int valor;
  final IconData icono;

  const _EstadisticaItem({
    required this.label,
    required this.valor,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icono, color: Colors.orange.shade700, size: 24),
        const SizedBox(height: 4),
        Text(
          valor.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _EventoCard extends StatelessWidget {
  final Evento evento;

  const _EventoCard({required this.evento});

  bool get esEventoProximo {
    final fechaEvento = DateTime.tryParse(evento.fechaInicio);
    if (fechaEvento == null) return false;
    return fechaEvento.isAfter(DateTime.now());
  }

  String get estadoEvento {
    return esEventoProximo ? 'Próximo' : 'Finalizado';
  }

  Color get colorEstado {
    return esEventoProximo ? Colors.green : Colors.grey;
  }

  // Getter para obtener la cantidad de voluntarios inscritos
  int get cantidadVoluntarios {
    return evento.voluntariosInscritos.length;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      margin: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.orange.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del evento
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(
                    evento.foto.isNotEmpty
                        ? evento.foto
                        : 'https://res.cloudinary.com/dupkeaqnz/image/upload/v1747969459/cld-sample-3.jpg',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
                    ),
                  ),
                ),
                // Badge de estado
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorEstado,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      estadoEvento,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Contenido de la tarjeta
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    evento.titulo,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Ubicación y voluntarios
                  Row(
                    children: [
                      Icon(Icons.place, color: Colors.deepPurple.shade400, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          evento.ubicacion,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.deepPurple.shade400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.people, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '$cantidadVoluntarios voluntarios',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Descripción
                  Text(
                    evento.descripcion,
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Fecha y requisitos
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.deepPurple.shade400, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Fecha: ${_formatearFecha(evento.fechaInicio)}',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.deepPurple.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (evento.requisitos.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.assignment, color: Colors.orange.shade700, size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Requisitos: ${evento.requisitos}',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(String fechaString) {
    try {
      final fecha = DateTime.tryParse(fechaString);
      if (fecha == null) {
        return fechaString; 
      }
      
      final meses = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      
      return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year} - ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fechaString; 
    }
  }
}