import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings.dart';
import 'leaderboard_page.dart';
import 'study_history_page.dart';
import 'study_suggestion_page.dart';
import 'user_account_page.dart';
import 'legal_page.dart';


class OverflowMenu extends StatelessWidget {
  final String userName;
  final void Function(String userName)? onLogin;
  final VoidCallback? onLogout;
  const OverflowMenu({required this.userName, this.onLogin, this.onLogout});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = userName.isNotEmpty && userName != 'Guest';
    print('DEBUG OverflowMenu.build: userName=$userName, isLoggedIn=$isLoggedIn');

    return ListView(
      children: [
        if (isLoggedIn)
          ListTile(
            leading: const Icon(Icons.account_circle, color: Colors.blue),
            title: const Text("User Account"),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserAccountPage(userName: userName),
                ),
              );
            },
          ),
        ListTile(
          leading: const Icon(Icons.card_giftcard, color: Colors.pink),
          title: const Text("Rewards & Redeem"),
          onTap: () {
            Navigator.of(context).pushNamed('/reward', arguments: userName);
          },
        ),
        ListTile(
          leading: const Icon(Icons.history, color: Colors.indigo),
          title: const Text("Login History"),
          onTap: () {
            Navigator.of(context).pushNamed('/history', arguments: userName);
          },
        ),
        ListTile(
          leading: const Icon(Icons.book_outlined, color: Colors.green),
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
          leading: const Icon(Icons.lightbulb_outline, color: Colors.amber),
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
          leading: const Icon(Icons.emoji_events, color: Colors.orange),
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
          leading: const Icon(Icons.settings, color: Colors.blueGrey),
          title: const Text("Settings"),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SettingsPage(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.gavel, color: Colors.orange),
          title: const Text("Legal"),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LegalPage(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.menu_book, color: Colors.purple),
          title: const Text("User Manual"),
          trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.blue),
          onTap: () async {
            final uri = Uri.parse('https://aispell.pages.dev/user-manual.html');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.feedback, color: Colors.teal),
          title: const Text("Suggestions & Testimonials"),
          subtitle: const Text("Send us your feedback"),
          trailing: const Icon(Icons.email, size: 18, color: Colors.red),
          onTap: () async {
            final uri = Uri.parse('mailto:713.zhao@gmail.com?subject=Spell%20App%20Feedback');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
        ),
      ],
    );
  }
}