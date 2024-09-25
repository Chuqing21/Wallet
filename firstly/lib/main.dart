import 'package:flutter/material.dart';
import 'account.dart';
import 'self_credential_page1.dart';
import 'credentialbtn.dart';
import 'routes.dart';
import 'profile_info.dart';
import 'education_info.dart';
import 'work_info.dart';
import 'quali_info.dart';
import 'softskill_info.dart';
import 'preview_cv.dart';
import 'cvpage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        profileInfoRoute: (context) => const ProfileInfoPage(),
        educationInfoRoute: (context) => const EducationInfoPage(),
        workInfoRoute: (context) => const WorkInfoPage(),
        qualiInfoRoute: (context) => const QualiInfoPage(),
        softSkillInfoRoute: (context) => const SoftSkillInfoPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const SelfCredentialPage1(),
    const ReceiveCre(),
    const CVPage(),
    const Account(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(
            label: 'Wallet',
            icon: Icon(Icons.account_balance_wallet),
          ),
          BottomNavigationBarItem(
            label: 'Certification',
            icon: Icon(Icons.badge),
          ),
          BottomNavigationBarItem(
            label: 'CV',
            icon: Icon(Icons.assignment),
          ),
          BottomNavigationBarItem(
            label: 'Account',
            icon: Icon(Icons.account_circle),
          ),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}
