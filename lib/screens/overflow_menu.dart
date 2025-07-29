import 'package:flutter/material.dart';

class OverflowMenu extends StatelessWidget {
  final String userName;
  const OverflowMenu({required this.userName});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(title: Text("Rewards")),
        ListTile(title: Text("History")),
        ListTile(title: Text("Leaderboard")),
        ListTile(title: Text("Settings")),
      ],
    );
  }
}