import 'package:flutter/material.dart';

class TopAdBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: Colors.amberAccent,
      alignment: Alignment.center,
      child: Text("📢 Great deals on our new app!", style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}