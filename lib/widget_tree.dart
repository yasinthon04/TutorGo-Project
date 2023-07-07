import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tutorgo/auth.dart';
import 'package:tutorgo/pages/login.dart';
import 'package:tutorgo/pages/navpage/mainpage.dart';
import 'package:tutorgo/roles/admin.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({Key? key}) : super(key: key);

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

// class _WidgetTreeState extends State<WidgetTree> {
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder(
//       stream: Auth().authStateChanges,
//       builder: (context, snapshot) {
//         if (snapshot.hasData && snapshot.data == "admin") {
//           print(snapshot.data);
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => Admin(),
//             ),
//           );
//         }
//         if (snapshot.hasData) {
//           print(snapshot.data);
//           return MainPage();
//         } else {
//           return LoginPage();
//         }
//       },
//     );
//   }
// }

class _WidgetTreeState extends State<WidgetTree> {
  User? user = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: Auth().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator or splash screen while checking the authentication state
          return CircularProgressIndicator();
        }
        if (snapshot.hasData) {
          User? user = snapshot.data;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show a loading indicator or placeholder while fetching user data
                return CircularProgressIndicator();
              }
              if (snapshot.hasData && snapshot.data!.exists) {
                String role = snapshot.data!.get('role');
                if (role == 'admin') {
                  // Navigate to the Admin page
                  return Admin();
                } else {
                  // Navigate to the Main page
                  return MainPage();
                }
              } else {
                // User document does not exist, handle accordingly
                return LoginPage();
              }
            },
          );
        } else {
          // User is not authenticated, navigate to the Login page
          return LoginPage();
        }
      },
    );
  }
}
