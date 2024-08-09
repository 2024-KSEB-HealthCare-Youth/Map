import 'package:flutter/material.dart';

class HospitalMarker extends StatelessWidget {
  final String name;

  HospitalMarker({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Icon(Icons.local_hospital, color: Colors.red),
          Text(name, style: TextStyle(fontSize: 12, color: Colors.black)),
        ],
      ),
    );
  }
}
