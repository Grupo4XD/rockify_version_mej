import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_rockify/pantallas/pantalla_Inicio.dart';
import 'package:proyecto_rockify/pantallas/peticionesApi.dart';
import 'package:proyecto_rockify/widgets/variables.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async'; // Para usar Timer
import 'package:firebase_core/firebase_core.dart';
import 'package:proyecto_rockify/firebase_options.dart';
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
  bool dislikePresionado = false;
  int dislikesCancionActual = 0;
  double progresoCancion = 0.0;

  // ── VARIABLES DEL REPRODUCTOR CENTRAL ──────────────────────────────
  String imagen = "https://picsum.photos/250";
  String titulo = "Ninguna canción sonando";
  String artista = "Abre Spotify en tu navegador";

  // ── USUARIOS EN LÍNEA (tiempo real desde Firestore) ─────────────────
  int usuariosEnLinea = 1;
  StreamSubscription<DocumentSnapshot>? _streamUsuarios;

  // ── LISTA DE COLA ───────────────────────────────────────────────────
  // Cada elemento tiene: { 'titulo': ..., 'artista': ..., 'imagen': ... }
  List<Map<String, dynamic>> listaColaEspera = [];

  Timer? _timer;

  // ── VARIABLES DEL BUSCADOR ──────────────────────────────────────────
  final TextEditingController _buscadorController = TextEditingController();
  Timer? _debounce; // Nuestro temporizador para no saturar la API
  bool _estaBuscando = false; // Para mostrar el CircularProgressIndicator
  List<dynamic> _resultadosBusqueda =
      []; // Aquí guardaremos las canciones encontradas

  void _alEscribirBusqueda(String texto) {
    // 1. Si el temporizador estaba contando, lo cancelamos.
    // Esto asegura que si el usuario teclea rápido, el contador se reinicia.
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // 2. Si el texto está vacío, limpiamos la pantalla inmediatamente
    if (texto.isEmpty) {
      setState(() {
        _resultadosBusqueda.clear();
        _estaBuscando = false;
      });
      return;
    }

    // 3. Mostramos la barrita de carga
    setState(() {
      _estaBuscando = true;
    });

    // 4. Iniciamos un nuevo temporizador de 500 milisegundos
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      // Este código SOLO se ejecutará si el usuario dejó de teclear por medio segundo
      final resultados = await Peticionesapi.buscarCanciones(
        widget.token,
        texto,
      );

      // Siempre verificamos si el widget sigue montado antes de usar setState después de un await
      if (mounted) {
        setState(() {
          _resultadosBusqueda = resultados ?? [];
          _estaBuscando = false; // Ocultamos la barrita de carga
        });
      }
    });
  }

  // ────────────────────────────────────────────────────────────────────
  // FUNCIÓN QUE HACE AMBAS PETICIONES Y ACTUALIZA EL ESTADO
  // ────────────────────────────────────────────────────────────────────
  Future<void> _actualizarReproductor() async {
    // 1. Canción actual
    final Map<String, dynamic>? datosCancion =
        await Peticionesapi.ObtenerCancionActual(widget.token);

    // 2. Cola de reproducción
    final Map<String, dynamic>? datosCola =
        await Peticionesapi.obtenerColaReproduccion(widget.token);

    // Solo actualiza la UI si el widget sigue montado (el usuario no salió)
    if (!mounted) return;

    setState(() {
      // ── Actualizar reproductor central ──────────────────────────────
      if (datosCancion != null) {
        titulo = datosCancion['item']['name'] ?? 'Sin título';

        // Los artistas vienen como lista; los unimos con coma
        final artistas = datosCancion['item']['artists'] as List<dynamic>?;
        artista = artistas != null
            ? artistas.map((a) => a['name']).join(', ')
            : 'Desconocido';

        // La imagen viene dentro de album -> images -> [0] -> url
        final imagenes =
            datosCancion['item']['album']?['images'] as List<dynamic>?;
        imagen = (imagenes != null && imagenes.isNotEmpty)
            ? imagenes[0]['url']
            : 'https://picsum.photos/250';

        // Progreso: progress_ms / duration_ms  (estos vienen en el objeto
        // raíz del currently-playing, pero ObtenerCancionActual devuelve
        // solo el 'item'. Por ahora dejamos progreso en 0; lo ampliaremos
        // cuando ajustes la API para devolver también progress_ms)
        int progresoMs = datosCancion['progress_ms'] ?? 0;
        int duracionMs = datosCancion['item']['duration_ms'] ?? 1;

        progresoCancion = progresoMs / duracionMs;
      } else {
        print("Ha ocurrido un error");
        titulo = "Ninguna canción sonando";
        artista = "Abre Spotify en tu navegador";
        imagen = "https://picsum.photos/250";
        progresoCancion = 0.0;
      }

      // ── Actualizar cola ─────────────────────────────────────────────
      if (datosCola != null) {
        final queue = datosCola['queue'] as List<dynamic>?;
        if (queue != null && queue.isNotEmpty) {
          listaColaEspera = queue.map((item) {
            final artistas = item['artists'] as List<dynamic>?;
            final imagenes = item['album']?['images'] as List<dynamic>?;
            return {
              'titulo': item['name'] ?? 'Sin título',
              'artista': artistas != null
                  ? artistas.map((a) => a['name']).join(', ')
                  : 'Desconocido',
              'imagen': (imagenes != null && imagenes.isNotEmpty)
                  ? imagenes[0]['url']
                  : '',
            };
          }).toList();
        } else {
          listaColaEspera = [];
        }
      } else {
        listaColaEspera = [];
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // Primera carga inmediata para no esperar los 3 segundos
    _actualizarReproductor();

    // Luego se repite cada 3 segundos
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _actualizarReproductor();
    });

    // Stream en tiempo real de usuarios_en_linea desde Firestore
    _streamUsuarios = FirebaseFirestore.instance
        .collection('salas')
        .doc(widget.codigoSala)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && mounted) {
            setState(() {
              usuariosEnLinea = snapshot.data()?['usuarios_en_linea'] ?? 1;
            });
          }
        });
  }

  // ── CERRAR SALA: borra el doc de Firestore y vuelve a PantallaInicio ─
  Future<void> _cerrarSala() async {
    _timer?.cancel();
    _streamUsuarios?.cancel();

    // Borra el documento de la sala en Firestore
    await FirebaseFirestore.instance
        .collection('salas')
        .doc(widget.codigoSala)
        .delete();

    if (!mounted) return;

    // Navega a PantallaInicio limpiando todo el stack de navegación
    //Elimina todas las pantallas del stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => PantallaInicio()),
      (route) => false, // Elimina todas las pantallas anteriores
    );
  }

  @override
  void dispose() {
    // Cancelar el timer cuando el widget se destruye (usuario sale de la sala)
    _timer?.cancel();
    _streamUsuarios?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Variables.fondoInferior,

      //###################### BUSCADOR ##################
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: 23,
                ),

                SizedBox(
                  height: 45,
                  child: TextField(
                    controller:
                        _buscadorController, // <-- Conectamos el controlador
                    onChanged:
                        _alEscribirBusqueda, // <-- Conectamos la función del temporizador
                    style: GoogleFonts.comfortaa(
                      color: Variables.textos_primarios,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: "Busca una canción",
                      hintStyle: TextStyle(
                        color: Variables.textos_primarios.withOpacity(0.5),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Variables.textos_primarios,
                      ),
                      // Si hay texto, mostramos una 'X' para limpiar la búsqueda
                      suffixIcon: _buscadorController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Variables.textos_primarios,
                              ),
                              onPressed: () {
                                _buscadorController.clear();
                                _alEscribirBusqueda(''); // Forzamos la limpieza
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: Variables.textos_primarios.withOpacity(0.4),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                          color: Variables.textos_primarios,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 15),
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
                            child: Text(
                              "ID: ${widget.codigoSala}",
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: Variables.estiloBotones,
                          icon: const Icon(Icons.person),
                          label: Text(
                            "$usuariosEnLinea",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ============================================================
                // BLOQUE 1: REPRODUCTOR ACTUAL
                // ============================================================
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      // Portada de la canción
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 180,
                          height: 180,
                          color: Colors.grey[900],
                          child: Image.network(
                            imagen,
                            fit: BoxFit.cover,
                            // Si la imagen falla, muestra un icono
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.album,
                              color: Colors.white54,
                              size: 80,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Título
                      Text(
                        titulo,
                        style: GoogleFonts.comfortaa(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Artista
                      Text(
                        artista,
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
                // BLOQUE 2: COLA DE CANCIONES
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
                              "La cola está vacía, ¡añade canciones!",
                              style: GoogleFonts.comfortaa(
                                color: Variables.textos_primarios.withOpacity(
                                  0.4,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: listaColaEspera.length,
                            itemBuilder: (context, index) {
                              final cancionCola = listaColaEspera[index];
                              final bool esLaQueEstaSonando = (index == 0);

                              return Container(
                                margin: const EdgeInsets.symmetric(
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
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: cancionCola['imagen'] != ''
                                        ? Image.network(
                                            cancionCola['imagen'],
                                            width: 45,
                                            height: 45,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                _iconoMusica(
                                                  esLaQueEstaSonando,
                                                ),
                                          )
                                        : _iconoMusica(esLaQueEstaSonando),
                                  ),
                                  title: Text(
                                    cancionCola['titulo'],
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
                                    cancionCola['artista'],
                                    style: GoogleFonts.comfortaa(
                                      color: Colors.grey,
                                    ),
                                  ),
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
                /** SizedBox(
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
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('salas')
                        .doc(widget.codigoSala)
                        .delete(); // Borra la sala de Firebase al salir
                    // Regresa a la pantalla anterior (login)
                    _cerrarSala();
                  },
                ),
              ), **/
              ],
            ),
            // ==========================================
            // CAPA 2: RESULTADOS DE BÚSQUEDA (Flotante encima)
            // ==========================================
            // Solo mostramos esta caja si hay texto en el buscador
            if (_buscadorController.text.isNotEmpty)
              Positioned(
                top:
                    75, // Se ubica justo debajo de tu TextField (que mide 45) + margen
                left: 0,
                right: 0,
                // Le damos una altura máxima para que se pueda scrollear si hay muchos resultados
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 350),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF003333,
                    ), // Color oscuro para resaltar
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _estaBuscando
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              color: Variables.textos_primarios,
                            ),
                          ),
                        )
                      : _resultadosBusqueda.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            "No se encontraron canciones.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.comfortaa(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap:
                              true, // Hace que la lista ocupe solo el espacio de sus elementos
                          itemCount: _resultadosBusqueda.length,
                          itemBuilder: (context, index) {
                            final cancion = _resultadosBusqueda[index];

                            final titulo = cancion['name'] ?? 'Desconocido';
                            final artistas =
                                cancion['artists'] as List<dynamic>?;
                            final nombreArtista =
                                artistas != null && artistas.isNotEmpty
                                ? artistas[0]['name']
                                : 'Sin artista';

                            final imagenes =
                                cancion['album']?['images'] as List<dynamic>?;
                            final urlImagen =
                                imagenes != null && imagenes.isNotEmpty
                                ? imagenes[0]['url']
                                : '';

                            // 1. EXTRAEMOS EL URI DE LA CANCIÓN
                            // Spotify necesita este código único (ej: spotify:track:4iV5W9...) para identificar la canción
                            final uriCancion = cancion['uri'] ?? '';

                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: urlImagen.isNotEmpty
                                    ? Image.network(
                                        urlImagen,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 40,
                                        height: 40,
                                        color: Colors.grey,
                                      ),
                              ),
                              title: Text(
                                titulo,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                nombreArtista,
                                style: const TextStyle(color: Colors.white70),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              // 2. AGREGAMOS EL BOTÓN EN EL LADO DERECHO (trailing)
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Variables
                                      .fondoBotones, // Tus colores personalizados de variables.dart
                                  foregroundColor: Variables.textos_primarios,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                onPressed: () async {
                                  // Al ser una petición de red, la función debe usar async/await

                                  // A. Enviamos la canción a la cola de Spotify
                                  bool exito =
                                      await Peticionesapi.anadirCancionACola(
                                        widget.token,
                                        uriCancion,
                                      );

                                  if (exito) {
                                    print("✅ Canción añadida correctamente");

                                    // B. REFRESCAR EL REPRODUCTOR Y LA COLA DE LA INTERFAZ
                                    // Volvemos a llamar a tu función existente para que traiga los datos nuevos de inmediato
                                    await _actualizarReproductor();
                                  } else {
                                    print(
                                      "❌ Error al intentar añadir la canción",
                                    );
                                  }

                                  // C. Opcional: Limpiamos el buscador y cerramos la lista flotante al terminar
                                  _buscadorController.clear();
                                  _alEscribirBusqueda('');
                                  FocusScope.of(context).unfocus();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.green,
                                      content: Text(
                                        "¡'$titulo' guardada en la lista de la sala!",
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  ); // Ocultamos el teclado en pantalla
                                },
                                child: const Text(
                                  "Añadir",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para el icono de música en la lista
  Widget _iconoMusica(bool destacado) {
    return Container(
      width: 45,
      height: 45,
      color: destacado
          ? const Color(0xFF00FFCC).withOpacity(0.1)
          : Colors.white.withOpacity(0.05),
      child: Icon(
        Icons.music_note,
        color: destacado ? const Color(0xFF00FFCC) : Colors.white54,
        size: 24,
      ),
    );
  }
}
