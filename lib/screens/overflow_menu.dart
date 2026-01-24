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
        if (!isLoggedIn)
          ListTile(
            leading: const Icon(Icons.account_circle, color: Colors.grey),
            title: const Text("User Account"),
            subtitle: const Text("Login required"),
            onTap: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ListTile(
          leading: Icon(Icons.card_giftcard, color: isLoggedIn ? Colors.pink : Colors.grey),
          title: const Text("Rewards & Redeem"),
          subtitle: isLoggedIn ? null : const Text("Login required"),
          onTap: () {
            if (isLoggedIn) {
              Navigator.of(context).pushNamed('/reward', arguments: userName);
            } else {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
        ),
        ListTile(
          leading: Icon(Icons.history, color: isLoggedIn ? Colors.indigo : Colors.grey),
          title: const Text("Login History"),
          subtitle: isLoggedIn ? null : const Text("Login required"),
          onTap: () {
            if (isLoggedIn) {
              Navigator.of(context).pushNamed('/history', arguments: userName);
            } else {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
        ),
        ListTile(
          leading: Icon(Icons.book_outlined, color: isLoggedIn ? Colors.green : Colors.grey),
          title: const Text("Study History"),
          subtitle: isLoggedIn ? null : const Text("Login required"),
          onTap: () {
            if (isLoggedIn) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => StudyHistoryPage(userName: userName),
                ),
              );
            } else {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
        ),
        ListTile(
          leading: Icon(Icons.lightbulb_outline, color: isLoggedIn ? Colors.amber : Colors.grey),
          title: const Text("Study Suggestions"),
          subtitle: isLoggedIn ? null : const Text("Login required"),
          onTap: () {
            if (isLoggedIn) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => StudySuggestionPage(userName: userName),
                ),
              );
            } else {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
        ),
        ListTile(
          leading: Icon(Icons.emoji_events, color: isLoggedIn ? Colors.orange : Colors.grey),
          title: const Text("Leaderboard"),
          subtitle: isLoggedIn ? null : const Text("Login required"),
          onTap: () {
            if (isLoggedIn) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LeaderboardPage(currentUserName: userName),
                ),
              );
            } else {
              Navigator.of(context).pushReplacementNamed('/login');
            }
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