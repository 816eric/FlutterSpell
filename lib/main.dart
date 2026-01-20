import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/study_page.dart';
import 'screens/my_words_page.dart';
import 'screens/quiz_page.dart';
import 'screens/overflow_menu.dart';
import 'widgets/top_ad_bar.dart';
import 'services/spell_api_service.dart';
import 'screens/settings.dart';
import 'screens/reward_page.dart';
import 'screens/history_page.dart';
import 'screens/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> _getLoggedInUser() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('loggedInUser');
}

void main() {
  runApp(SpellApp());
}

class SpellApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getLoggedInUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }
        final loggedInUser = snapshot.data;
        final bool needsLogin = (loggedInUser == null || loggedInUser.isEmpty || loggedInUser == 'Guest');
        final Widget homeWidget = needsLogin ? const LoginPage() : MainTabController();
        print('SpellApp: launching app, needsLogin=$needsLogin, home=${homeWidget.runtimeType}');
        return MaterialApp(
          title: 'Spell Practice App',
          theme: ThemeData(primarySwatch: Colors.blue),
          home: homeWidget,
          routes: {
            '/login': (context) { print('Route /login builder'); return const LoginPage(); },
            '/home': (context) { print('Route /home builder'); return MainTabController(key: UniqueKey()); },
            '/reward': (context) {
              try {
                final args = ModalRoute.of(context)?.settings.arguments;
                final userName = (args is String && args.isNotEmpty) ? args : "Guest";
                return RewardPage(currentUserName: userName);
              } catch (e, st) {
                print('Error building /reward: $e');
                print(st);
                return Scaffold(body: Center(child: Text('Failed to build RewardPage: $e')));
              }
            },
            '/settings': (context) {
              try {
                return SettingsPage();
              } catch (e, st) {
                print('Error building /settings: $e');
                print(st);
                return Scaffold(body: Center(child: Text('Failed to build SettingsPage: $e')));
              }
            },
            '/history': (context) {
              try {
                final args = ModalRoute.of(context)?.settings.arguments;
                final userName = (args is String && args.isNotEmpty) ? args : "Guest";
                return HistoryPage(currentUserName: userName);
              } catch (e, st) {
                print('Error building /history: $e');
                print(st);
                return Scaffold(body: Center(child: Text('Failed to build HistoryPage: $e')));
              }
            },
          },
        );
      },
    );
  }
}

class MainTabController extends StatefulWidget {
  static final GlobalKey<_MainTabControllerState> mainTabKey = GlobalKey<_MainTabControllerState>();
  static void switchToTab(int index) {
    final state = mainTabKey.currentState;
    if (state != null) {
      state.switchToTab(index);
    }
  }
  MainTabController({Key? key}) : super(key: key ?? mainTabKey);
  @override
  State<MainTabController> createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController> {
  void switchToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  int _selectedIndex = 0;
  String userName = "";
  bool _isUserLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('loggedInUser');
    print('DEBUG _loadUserFromPrefs: savedUser=$savedUser');
    
    if (savedUser != null && savedUser.isNotEmpty && savedUser != 'Guest') {
      // Trust the saved user - no need to verify via API
      // This fixes race condition where getUserProfile might fail before user profile is fully created
      setState(() {
        userName = savedUser;
        _isUserLoaded = true;
      });
      print('DEBUG _loadUserFromPrefs: userName set to $savedUser');
      
      // Optionally verify the profile exists in background (non-blocking)
      try {
        await SpellApiService.getUserProfile(savedUser);
        print('DEBUG _loadUserFromPrefs: getUserProfile succeeded for $savedUser');
      } catch (e) {
        print('DEBUG _loadUserFromPrefs: getUserProfile failed (non-blocking): $e');
        // Don't set to Guest on failure - keep the saved user
      }
    } else {
      setState(() {
        userName = "Guest";
        _isUserLoaded = true;
      });
      print('DEBUG _loadUserFromPrefs: No saved user, set to Guest');
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
    // Always check latest user from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('loggedInUser');
    final isLoggedIn = savedUser != null && savedUser.isNotEmpty && savedUser != 'Guest';
    
    print('DEBUG _onItemTapped: index=$index, savedUser=$savedUser, isLoggedIn=$isLoggedIn');
    
    if (index == 4) { // 'More' tab
      if (isLoggedIn) {
        if (savedUser != userName) {
          print('DEBUG: Updating userName from $userName to $savedUser');
          _onUserLogin(savedUser);
        }
        setState(() => _selectedIndex = index);
      } else {
        // Not logged in - go to login page
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } else if (index == 2 || index == 3) { // My Words, Quiz tabs - require login
      if (isLoggedIn) {
        if (savedUser != userName) {
          print('DEBUG: Updating userName from $userName to $savedUser');
          _onUserLogin(savedUser);
        }
        setState(() => _selectedIndex = index);
      } else {
        // Not logged in - go to login page
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } else {
      // Home (0) and Study (1) tabs - always accessible
      if (isLoggedIn) {
        _onUserLogin(savedUser);
      } else {
        setState(() { userName = "Guest"; });
      }
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wait for user to be loaded before showing content
    if (!_isUserLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text("Spell Practice")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Spell Practice"), bottom: PreferredSize(preferredSize: Size.fromHeight(50), child: TopAdBar())),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, color: Colors.blue), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.school, color: Colors.green), label: "Study"),
          BottomNavigationBarItem(icon: Icon(Icons.book, color: Colors.orange), label: "My Words"),
          BottomNavigationBarItem(icon: Icon(Icons.quiz, color: Colors.purple), label: "Quiz"),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz, color: Colors.teal), label: "More"),
        ],
      ),
    );
  }
}