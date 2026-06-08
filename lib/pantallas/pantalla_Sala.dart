import 'package:flutter/material.dart';

class PantallaSala extends StatefulWidget {

  final String token;
  const PantallaSala({super.key,required this.token});

  @override
  State<PantallaSala> createState() => _PantallaSalaState();
}

class _PantallaSalaState extends State<PantallaSala> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Text("Felicidades recibiste el token ${widget.token}",style: TextStyle(color: Colors.black),)
    );
  }
}