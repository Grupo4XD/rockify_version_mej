import 'package:http/http.dart' as http;
import 'dart:convert';

class Peticionesapi {
  //1. Obtener la cancion actual
  static Future<Map<String, dynamic>?> ObtenerCancionActual(token) async {
    List<String> canciones;

    if (token == null) return null;

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
  
}
