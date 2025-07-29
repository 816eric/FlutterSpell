import 'package:flutter/material.dart';
import 'settings.dart';


class OverflowMenu extends StatelessWidget {
  final String userName;
  final void Function(String userName)? onLogin;
  final VoidCallback? onLogout;
  const OverflowMenu({required this.userName, this.onLogin, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(title: Text("Rewards")),
        ListTile(title: Text("History")),
        ListTile(title: Text("Leaderboard")),
        ListTile(
          title: Text("Settings"),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SettingsPage(
                  onLogin: onLogin ?? (_) {},
                ),
              ),
            ).then((value) {
              if (value == 'logout' && onLogout != null) {
                onLogout!();
              }
            });
          },
        ),
      ],
    );
  }
}