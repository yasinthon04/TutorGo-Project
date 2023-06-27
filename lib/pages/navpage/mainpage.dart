import 'package:flutter/material.dart';
import 'package:tutorgo/auth.dart';
import 'package:tutorgo/pages/navpage/account.dart';
import 'package:tutorgo/pages/navpage/home.dart';
import 'package:tutorgo/pages/navpage/schedule.dart';
import 'package:tutorgo/pages/navpage/search.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List pages = [
    HomePage(),
    SearchPage(),
    SchedulePage(),
    AccountPage(),
  ];
  int currentIndex = 0;

  void onTap(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        onTap: onTap,
        currentIndex: currentIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey.withOpacity(0.5),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Schedule"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "My Account"),
        ],
      ),
    );
  }
}