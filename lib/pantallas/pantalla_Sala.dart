import 'dart:io';
import 'package:flutter/material.dart';
import 'package:proyecto_rockify/widgets/variables.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async'; // Para usar Timer
import 'package:proyecto_rockify/pantallas/peticionesApi.dart';

class PantallaSala extends StatefulWidget {
  final String codigoSala;
  final String token;
  const PantallaSala({
    super.key,
    required this.token,
    required this.codigoSala,
  });

  @override
  State<PantallaSala> createState() => _PantallaSalaState();
}

class _PantallaSalaState extends State<PantallaSala> {
  // Variable para contar los dislikes de la canción que está sonando actualmente

  bool dislikePresionado = false;
  int dislikesCancionActual = 0;
  double progresoCancion = 0.3;
  //########## VARIABLES PARAEL CENTRO DE LA CANCION ###############

  String imagen = "https://picsum.photos/250";
  String titulo = "Ninguna cancion sonando";
  String artista = "Abre spotify en tu navegador";
  String mensajeCola = "La cola esta vacia, Añade canciones!";

  // Tu lista de reproducción actual. El elemento [0] siempre es el que suena ahora.
  final List<Map<String, dynamic>> listaColaEspera = [];

  //Se pone dentro de la clase
  @override
  void initState() {
    super.initState();

    // Iniciamos todo el flujo automático secuencial
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel(); // Si el usuario sale de la sala, apaga el temporizador
      } else {
        print("La lista $listaColaEspera");
        setState(() {
          //listaColaEspera.removeAt(0);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Variables.fondoInferior,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        //Centra el titulo al centro sin importar que hayga iconos a lado
        centerTitle: true,
        title: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, //Alinea en vertical
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
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                children: [
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: Variables.estiloBotones,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text("ID: 6521", style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: Variables.estiloBotones,
                      icon: Icon(Icons.person),
                      label: Text("2", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
            // ============================================================
            // BLOQUE 1: REPRODUCTOR ACTUAL (AHORA TOTALMENTE LIMPIO)
            // ============================================================
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  // Imagen/Portada de la canción
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 180,
                      height: 180,
                      color: Colors.grey[900],
                      child: Image.network(imagen),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Título actual limpio sin botones estorbando
                  Text(
                    titulo, // Muestra el título de la primera canción
                    style: GoogleFonts.comfortaa(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    //En caso de desborde del widget
                    maxLines: 1,
                    //La propiedad overflow indica si hay un desborde muestre ... puntos para no aparecer las lineas negras y amarillas
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Artista actual limpio
                  Text(
                    artista, // Muestra el artista de la primera canción
                    style: GoogleFonts.comfortaa(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  // Barra de progreso
                  Slider(
                    value: progresoCancion,
                    onChanged: (value) {},
                    activeColor: Variables.textos_primarios,
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
                  style: GoogleFonts.comfortaa(
                    color: Variables.textos_primarios,
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
                child: listaColaEspera.isEmpty
                    ? Center(
                        child: Text(
                          "La cola esta vacia, añade canciones!",
                          style: GoogleFonts.comfortaa(
                            color: Variables.textos_primarios.withOpacity(0.4),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : ListView.builder(
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
                                      color: const Color(
                                        0xFF00FFCC,
                                      ).withOpacity(0.5),
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
                                style: GoogleFonts.comfortaa(
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
                                style: GoogleFonts.comfortaa(
                                  color: Colors.grey,
                                ),
                              ),

                              //El trailing sirve para poner un elemento a la parte derecha final del list tile
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
                                          icon: Icon(
                                            Icons.thumb_down,
                                            color: Colors.red,

                                            size: 22,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              dislikesCancionActual++;
                                              dislikePresionado = true;
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
              width: 150,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(34),
                  ),
                ),

                label: Text(
                  "Cerrar Sala",
                  style: GoogleFonts.comfortaa(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
