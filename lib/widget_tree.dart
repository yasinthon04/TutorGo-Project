import 'package:flutter/material.dart';
import 'package:tutorgo/auth.dart';
import 'package:tutorgo/pages/login.dart';
import 'package:tutorgo/pages/navpage/mainpage.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({Key? key}) : super(key: key);

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}
  class _WidgetTreeState extends State<WidgetTree> {
    @override
    Widget build(BuildContext context) {
      return StreamBuilder(
        stream: Auth().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return MainPage();
          } else {
            return LoginPage();
          }
        },
      );
    }
  }