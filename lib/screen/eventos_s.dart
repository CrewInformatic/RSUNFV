import 'package:flutter/material.dart';
import '../models/evento.dart';

class EventosScreen extends StatelessWidget {
  final int horasAcumuladas;
  final List<Evento> eventos;

  const EventosScreen({
    Key? key,
    this.horasAcumuladas = 0,
    this.eventos = const [],
  }) : super(key: key);

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
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: gradient,
        ),
        child: ListView(
          padding: const EdgeInsets.all(24),
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
                    '$horasAcumuladas',
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
            const SizedBox(height: 32),
            // Logo arriba de "Eventos realizados"
            // (Imagen eliminada según tu solicitud)
            const SizedBox(height: 90),
            // Eventos realizados
            Text(
              'Eventos realizados',
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
            const SizedBox(height: 12),
            if (eventos.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Text(
                    'No hay eventos registrados aún.',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ),
              )
            else
              ...eventos.map((evento) => _EventoCard(evento: evento)).toList(),
          ],
        ),
      ),
    );
  }
}

class _EventoCard extends StatelessWidget {
  final Evento evento;

  const _EventoCard({required this.evento});

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
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evento.titulo,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.place, color: Colors.deepPurple.shade400, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        evento.ubicacion,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.deepPurple.shade400,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.people, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${evento.cantidadVoluntarios} voluntarios',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    evento.descripcion,
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.deepPurple.shade400, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Fecha: ${evento.fechaInicio.toDate().toString().substring(0, 16)}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.deepPurple.shade400,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.calendar_today, color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Horas: ${evento.requisitos}', // Puedes ajustar esto según tu modelo
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}