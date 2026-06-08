import 'package:http/http.dart' as http;
import 'dart:convert';

class Peticionesapi {
  //1. Obtener la cancion actual
  // ignore: non_constant_identifier_names
  static Future<Map<String, dynamic>?> ObtenerCancionActual(String token) async {

    final Uri url = Uri.parse(
      'https://api.spotify.com/v1/me/player/currently-playing',
    );

    try {
      final respuesta = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Spotify regresa 200 si hay música sonando, o 204 si el reproductor está pausado/vacío
      if (respuesta.statusCode == 200) {
        return jsonDecode(respuesta.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Error al obtener la cancion actual $e");
      return null;
    }
  }

  //2. Obtener las peticiones
  static Future<Map<String, dynamic>?> obtenerColaReproduccion(
    String token,
  ) async {
    final url = Uri.parse('https://api.spotify.com/v1/me/player/queue');
    try {
      final respuesta = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (respuesta.statusCode == 200) {
        return jsonDecode(respuesta.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Error obteniendo la cola: $e");
      return null;
    }
  }

  // 3. Añadir una canción a la cola mediante su ID o URI de Spotify
  static Future<bool> anadirCancionACola(
    String token,
    String uriCancion,
  ) async {
    // Spotify pide la URI como un parámetro de consulta (Query Parameter)
    final url = Uri.parse(
      'https://api.spotify.com/v1/me/player/queue?uri=$uriCancion',
    );
    try {
      final respuesta = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      // Para añadir a la cola, Spotify responde con 204 (No Content) si fue exitoso
      return respuesta.statusCode == 204;
    } catch (e) {
      print("Error al añadir a la cola: $e");
      return false;
    }
  }

  // 4. Saltar a la siguiente canción (Next)
  static Future<bool> saltarSiguienteCancion(String token) async {
    final url = Uri.parse('https://api.spotify.com/v1/me/player/next');
    try {
      final respuesta = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      // Spotify responde 204 cuando salta la canción con éxito
      return respuesta.statusCode == 204;
    } catch (e) {
      print("Error al dar Next: $e");
      return false;
    }
  }
}
