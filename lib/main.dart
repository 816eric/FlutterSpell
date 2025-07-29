import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/study_page.dart';
import 'screens/my_words_page.dart';
import 'screens/quiz_page.dart';
import 'screens/overflow_menu.dart';
import 'widgets/top_ad_bar.dart';

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

  void _onUserLogin(String newUserName) {
    setState(() {
      userName = newUserName;
    });
  }

  void _onUserLogout() {
    setState(() {
      userName = "";
    });
  }

  List<Widget> get _pages => [
        HomePage(userName: userName),
        StudyPage(userName: userName),
        MyWordsPage(userName: userName),
        QuizPage(userName: userName),
        OverflowMenu(
          userName: userName,
          onLogin: _onUserLogin,
          onLogout: _onUserLogout,
        ),
      ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

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