import 'package:flutter/material.dart';
import 'package:tutorgo/auth.dart';
import 'package:tutorgo/pages/navpage/account.dart';
import 'package:tutorgo/pages/navpage/home.dart';
import 'package:tutorgo/pages/navpage/schedule.dart';
import 'package:tutorgo/pages/navpage/search.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Widget> pages = [
    HomePage(),
    SearchPage(),
    SchedulePage(),
    AccountPage(),
  ];
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).hintColor,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 6),
            child: GNav(
                backgroundColor: Colors.transparent, // Set this to transparent
                color: Colors.white,
                activeColor: Colors.white,
                tabBackgroundColor:
                    Theme.of(context).primaryColor, // Set this to transparent
                gap: 8,
                selectedIndex: currentIndex,
                onTabChange: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                padding: EdgeInsets.all(12),
                tabs: const [
                  GButton(
                    icon: Icons.home,
                    text: 'Home',
                  ),
                  GButton(
                    icon: Icons.search,
                    text: 'Search',
                  ),
                  GButton(
                    icon: Icons.calendar_today,
                    text: 'Schedule',
                  ),
                  GButton(
                    icon: Icons.person,
                    text: 'Profile',
                  ),
                ]),
          )),
    );
  }
}
