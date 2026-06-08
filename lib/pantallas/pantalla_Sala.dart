import 'dart:io';
import 'package:flutter/material.dart';
import 'package:proyecto_rockify/widgets/variables.dart';
import 'package:google_fonts/google_fonts.dart';

class PantallaSala extends StatefulWidget {
  final String codigoSala;
  final String token;
  const PantallaSala({super.key, required this.token,required this.codigoSala});

  @override
  State<PantallaSala> createState() => _PantallaSalaState();
}

class _PantallaSalaState extends State<PantallaSala> {
  // Variable para contar los dislikes de la canción que está sonando actualmente
  int dislikesCancionActual = 0;

  // Tu lista de reproducción actual. El elemento [0] siempre es el que suena ahora.
  final List<Map<String, dynamic>> listaColaEspera = [
    {'titulo': 'Blinding Lights', 'artista': 'The Weeknd'}, // Index 0 (Sonando)
    {'titulo': 'Starboy', 'artista': 'The Weeknd'}, // Index 1
    {'titulo': 'Shape of You', 'artista': 'Ed Sheeran'}, // Index 2
    {'titulo': 'One Dance', 'artista': 'Drake'}, // Index 3
  ];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Variables.fondoInferior,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        

        title: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.music_note,
                color: Variables.textos_primarios,
                size: 35,
              ),
              const SizedBox(width: 10),
              Text(
                'Rockify',
                style: GoogleFonts.comfortaa(
                  color: Variables.textos_primarios,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          children: [
            // ============================================================
            // BLOQUE 1: REPRODUCTOR ACTUAL (AHORA TOTALMENTE LIMPIO)
            // ============================================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  // Imagen/Portada de la canción
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 150,
                      height: 150,
                      color: Colors.grey[900],
                      child: const Icon(
                        Icons.music_video,
                        size: 70,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Título actual limpio sin botones estorbando
                  Text(
                    listaColaEspera[0]['titulo'], // Muestra el título de la primera canción
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Artista actual limpio
                  Text(
                    listaColaEspera[0]['artista'], // Muestra el artista de la primera canción
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Barra de progreso
                  const LinearProgressIndicator(
                    value: 0.35,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF00FFCC),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Separador visual
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  "Lista de reproducción",
                  style: TextStyle(
                    color: Variables.textos_primarios.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // ============================================================
            // BLOQUE 2: LISTA CON FOCO EN LA PRIMERA CANCIÓN Y SU DISLIKE
            // ============================================================
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListView.builder(
                  itemCount: listaColaEspera.length,
                  itemBuilder: (context, index) {
                    final cancion = listaColaEspera[index];

                    // 🔥 EL TRUCO: ¿Es la primera canción (la que está sonando)?
                    bool esLaQueEstaSonando = (index == 0);

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: esLaQueEstaSonando
                            ? const Color(0xFF0D2A2A)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: esLaQueEstaSonando
                            ? Border.all(
                                color: const Color(0xFF00FFCC).withOpacity(0.5),
                                width: 1,
                              )
                            : null,
                      ),
                      child: ListTile(
                        // 🔥 CAMBIO AQUÍ: Quitamos el número y volvemos a poner el icono/imagen de la canción
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            8,
                          ), // Bordes suavemente redondeados para la miniatura
                          child: Container(
                            width: 45,
                            height: 45,
                            color: esLaQueEstaSonando
                                ? const Color(0xFF00FFCC).withOpacity(
                                    0.1,
                                  ) // Fondo cian sutil si suena
                                : Colors.white.withOpacity(
                                    0.05,
                                  ), // Fondo gris sutil si está en espera
                            child: Icon(
                              Icons.music_note,
                              // Si es la que está sonando, el icono brilla en cian; si no, se queda gris
                              color: esLaQueEstaSonando
                                  ? const Color(0xFF00FFCC)
                                  : Colors.white54,
                              size: 24,
                            ),
                          ),
                        ),

                        title: Text(
                          cancion['titulo'],
                          style: TextStyle(
                            color: esLaQueEstaSonando
                                ? Colors.white
                                : Colors.white70,
                            fontWeight: esLaQueEstaSonando
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          cancion['artista'],
                          style: const TextStyle(color: Colors.grey),
                        ),

                        // El botón de dislike exclusivo se queda exactamente igual abajo
                        trailing: esLaQueEstaSonando
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "$dislikesCancionActual",
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.thumb_down,
                                      color: Colors.redAccent,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        dislikesCancionActual++;
                                      });
                                    },
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ============================================================
            // BLOQUE 3: BOTÓN CERRAR SALA
            // ============================================================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.cancel),
                label: const Text(
                  "Cerrar Sala",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () => exit(0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
