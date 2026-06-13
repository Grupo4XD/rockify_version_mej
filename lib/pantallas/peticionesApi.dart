import 'package:http/http.dart' as http;
import 'dart:convert';

class Peticionesapi {
  //1. Obtener la cancion actual
  // ignore: non_constant_identifier_names
  static Future<Map<String, dynamic>?> ObtenerCancionActual(
    String token,
  ) async {
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
      
      if (respuesta.statusCode == 204) return null;
      // Spotify regresa 200 si hay música sonando, o 204 si el reproductor está pausado/vacío
      if (respuesta.statusCode == 200) {
        return jsonDecode(respuesta.body);
      }
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
    // Acoplamos el parámetro ?uri= al final de la URL usando el identificador de la canción
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

  // 5. Buscar canciones en Spotify
  static Future<List<dynamic>?> buscarCanciones(
    String token,
    String query,
  ) async {
    // Reemplazamos los espacios del texto por %20 para que sea una URL válida
    final String queryFormateado = Uri.encodeComponent(query);

    // Armamos la URL indicando que buscamos "track" (canciones) y con un límite de 10 resultados
    final url = Uri.parse(
      'https://api.spotify.com/v1/search?q=$queryFormateado&type=track&limit=10',
    );

    try {
      final respuesta = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (respuesta.statusCode == 200) {
        final datosDecodificados = jsonDecode(respuesta.body);
        // Spotify devuelve un objeto "tracks", y dentro de este, una lista "items"
        return datosDecodificados['tracks']['items'] as List<dynamic>;
      } else {
        print("Error en la búsqueda. Código: ${respuesta.statusCode}");
        return null;
      }
    } catch (e) {
      print("Excepción al buscar canción: $e");
      return null;
    }
  }
}