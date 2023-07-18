import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tutorgo/auth.dart';
import 'package:tutorgo/pages/navpage/update_profile.dart';
import 'package:tutorgo/pages/widget/header_widget.dart';
import 'package:flutter/services.dart';
import 'package:tutorgo/pages/login.dart';
import 'package:tutorgo/pages/register.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final User? user = Auth().currentUser;

  Future<void> signOut() async {
    await Auth().signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  Widget _userHeadinfo() {
    if (user == null) {
      // User is not authenticated
      return Text('User not authenticated');
    }

    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Text('No data available');
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          String fname = userData['firstname'] ?? 'User firstname';
          String lname = userData['lastname'] ?? 'User lastname';
          String role = userData['role'] ?? 'User role';
          String imageName = userData['profilePicture'] ?? 'User Image';

          return Column(
            children: [
              if (imageName.isNotEmpty && Uri.parse(imageName).isAbsolute)
                ClipOval(
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: Image.network(
                      imageName,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                ClipOval(
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: Container(
                        color: Colors.white,
                        child: Image.asset(
                          'assets/profile-icon.png',
                          fit: BoxFit.cover,
                        )),
                  ),
                ),
              SizedBox(height: 10),
              Text(
                '$fname $lname',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          );
        });
  }

  Widget _userInfo() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Text('No data available');
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;

        String email = userData['email'] ?? 'User email';
        String fname = userData['firstname'] ?? 'User firstname';
        String lname = userData['lastname'] ?? 'User lastname';
        String phone = userData['mobile'] ?? 'User mobile';
        String role = userData['role'] ?? 'User role';

        return Column(
          children: [
            ListTile(
              leading: Icon(Icons.mail),
              title: Text("Email"),
              subtitle: Text(email),
            ),
            ListTile(
              leading: Icon(Icons.text_format),
              title: Text("Name"),
              subtitle: Text(fname + ' ' + lname),
            ),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text("Mobile"),
              subtitle: Text(phone),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text("Role"),
              subtitle: Text(role),
            ),
          ],
        );
      },
    );
  }

  Widget _title() {
    return const Text('Account page');
  }

  Widget _userUid() {
    return Text(
      user?.email ?? 'User email',
      style: Theme.of(context).textTheme.bodyText2,
    );
  }

  Widget _signOutButton() {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        onPressed: signOut,
        style: ElevatedButton.styleFrom(
            primary: Theme.of(context).hintColor,
            side: BorderSide.none,
            shape: const StadiumBorder()),
        child: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile Page",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0.5,
        iconTheme: IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                Theme.of(context).primaryColor,
                Theme.of(context).hintColor,
              ])),
        ),
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              height: 100,
              child: HeaderWidget(100, false, Icons.house_rounded),
            ),
            Container(
              alignment: Alignment.center,
              margin: EdgeInsets.fromLTRB(25, 10, 25, 10),
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 10,
                  ),
                  _userHeadinfo(),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      children: <Widget>[
                        Container(
                          padding:
                              const EdgeInsets.only(left: 8.0, bottom: 4.0),
                          alignment: Alignment.topLeft,
                          child: Text(
                            "User Information",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Card(
                          child: Container(
                            alignment: Alignment.topLeft,
                            padding: EdgeInsets.all(15),
                            child: Column(
                              children: <Widget>[
                                Column(
                                  children: <Widget>[
                                    ...ListTile.divideTiles(
                                      color: Colors.grey,
                                      tiles: [
                                        _userInfo(),
                                      ],
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => updateProfilePage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow,
                            side: BorderSide.none,
                            shape: const StadiumBorder()),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(color: Colors.black),
                        )),
                  ),
                  _signOutButton(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
