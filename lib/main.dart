import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/study_page.dart';
import 'screens/my_words_page.dart';
import 'screens/quiz_page.dart';
import 'screens/overflow_menu.dart';
import 'widgets/top_ad_bar.dart';
import 'services/spell_api_service.dart';
import 'screens/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(SpellApp());
}

class SpellApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spell Practice App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MainTabController(),
      onGenerateRoute: (settings) {
        if (settings.name == '/settings') {
          // Find the nearest MainTabControllerState to get the onLogin callback
          return MaterialPageRoute(
            builder: (context) {
              final mainTabState = context.findAncestorStateOfType<_MainTabControllerState>();
              return SettingsPage(
                onLogin: (userName) {
                  if (mainTabState != null) {
                    mainTabState._onUserLogin(userName);
                  }
                  Navigator.of(context).pop();
                },
              );
            },
          );
        }
        return null;
      },
    );
  }
}

class MainTabController extends StatefulWidget {
  @override
  State<MainTabController> createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController> {

  int _selectedIndex = 0;
  String userName = "";

  @override
  void initState() {
    super.initState();
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('loggedInUser');
    if (savedUser != null && savedUser.isNotEmpty && savedUser != 'Guest') {
      try {
        await SpellApiService.getUserProfile(savedUser);
        setState(() {
          userName = savedUser;
        });
      } catch (_) {
        setState(() {
          userName = "Guest";
        });
      }
    } else {
      setState(() {
        userName = "Guest";
      });
    }
  }

  Future<void> _ensureValidUserName() async {
    String name = userName;
    if (name.isEmpty) {
      setState(() {
        userName = "Guest";
      });
      return;
    }
    try {
      // Try to fetch profile, fallback to Guest if fails
      await SpellApiService.getUserProfile(name);
    } catch (_) {
      setState(() {
        userName = "Guest";
      });
    }
  }

  void _onUserLogin(String newUserName) async {
    String name = newUserName.trim();
    if (name.isEmpty) name = "Guest";
    try {
      await SpellApiService.getUserProfile(name);
      setState(() {
        userName = name;
      });
    } catch (_) {
      setState(() {
        userName = "Guest";
      });
    }
  }

  void _onUserLogout() {
    setState(() {
      userName = "Guest";
    });
  }

  List<Widget> get _pages => [
        HomePage(key: ValueKey(userName), userName: userName),
        StudyPage(userName: userName),
        MyWordsPage(userName: userName),
        QuizPage(userName: userName),
        OverflowMenu(
          userName: userName,
          onLogin: _onUserLogin,
          onLogout: _onUserLogout,
        ),
      ];

  void _onItemTapped(int index) async {
    if (index == 4) { // 'More' tab
      // Always check latest user from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedUser = prefs.getString('loggedInUser');
      final isLoggedIn = savedUser != null && savedUser.isNotEmpty && savedUser != 'Guest';
      if (isLoggedIn) {
        if (savedUser != userName) {
          _onUserLogin(savedUser);
        }
        setState(() => _selectedIndex = index);
      } else {
        await Navigator.of(context).pushNamed('/settings');
        // After returning from settings, always reload user from SharedPreferences
        final prefs2 = await SharedPreferences.getInstance();
        final savedUser2 = prefs2.getString('loggedInUser');
        if (savedUser2 != null && savedUser2.isNotEmpty && savedUser2 != 'Guest') {
          _onUserLogin(savedUser2);
        } else {
          setState(() { userName = "Guest"; });
        }
        setState(() => _selectedIndex = 0); // Always go to Home after settings
      }
    } else {
      // If switching to Home tab, always reload user from SharedPreferences
      if (index == 0) {
        final prefs = await SharedPreferences.getInstance();
        final savedUser = prefs.getString('loggedInUser');
        if (savedUser != null && savedUser.isNotEmpty && savedUser != 'Guest') {
          _onUserLogin(savedUser);
        } else {
          setState(() { userName = "Guest"; });
        }
      }
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Spell Practice"), bottom: PreferredSize(preferredSize: Size.fromHeight(50), child: TopAdBar())),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: "Study"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "My Words"),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: "Quiz"),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "More"),
        ],
      ),
    );
  }
}