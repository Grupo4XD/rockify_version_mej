import 'package:flutter/material.dart';
import 'package:proyecto_rockify/pantallas/pantalla_Oauth.dart';
import 'package:proyecto_rockify/widgets/variables.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PantallaOauth()),
                );
              },
              style: Variables.estiloBotones,
              child: Text('Crear Sala'),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () {},
              style: Variables.estiloBotones,
              child: Text('Unirse a Sala'),
            ),
          ),
        ],
      ),
    );
  }
}
