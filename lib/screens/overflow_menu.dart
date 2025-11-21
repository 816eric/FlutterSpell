import 'package:flutter/material.dart';
import 'settings.dart';
import 'leaderboard_page.dart';
import 'study_history_page.dart';
import 'study_suggestion_page.dart';


class OverflowMenu extends StatelessWidget {
  final String userName;
  final void Function(String userName)? onLogin;
  final VoidCallback? onLogout;
  const OverflowMenu({required this.userName, this.onLogin, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.card_giftcard),
          title: const Text("Rewards & Redeem"),
          onTap: () {
            Navigator.of(context).pushNamed('/reward', arguments: userName);
          },
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text("Login History"),
          onTap: () {
            Navigator.of(context).pushNamed('/history', arguments: userName);
          },
        ),
        ListTile(
          leading: const Icon(Icons.book_outlined),
          title: const Text("Study History"),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => StudyHistoryPage(userName: userName),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.lightbulb_outline),
          title: const Text("Study Suggestions"),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => StudySuggestionPage(userName: userName),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.emoji_events),
          title: const Text("Leaderboard"),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => LeaderboardPage(currentUserName: userName),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text("Settings"),
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