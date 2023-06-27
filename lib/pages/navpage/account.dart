import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tutorgo/auth.dart';
import 'package:tutorgo/pages/widget/header_widget.dart';
import 'package:flutter/services.dart';
import 'package:tutorgo/pages/login.dart';
import 'package:tutorgo/pages/register.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  double _drawerIconSize = 24;
  double _drawerFontSize = 17;
  final User? user = Auth().currentUser;

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _userHeadinfo() {
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

          return Column(
            children: [
              Text(
                '$fname $lname',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                'Role: $role',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
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
              title: Text("email"),
              subtitle: Text(email),
            ),
            ListTile(
              leading: Icon(Icons.text_format),
              title: Text("Name"),
              subtitle: Text(fname + ' ' + lname),
            ),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text("Phone"),
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
            backgroundColor: Colors.purple.withOpacity(0.2),
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
        actions: [
          Container(
            margin: EdgeInsets.only(
              top: 16,
              right: 16,
            ),
            child: Stack(
              children: <Widget>[
                Icon(Icons.notifications),
                Positioned(
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '5',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [
                0.0,
                1.0
              ],
                  colors: [
                Theme.of(context).primaryColor.withOpacity(0.2),
                Theme.of(context).hintColor.withOpacity(0.5),
              ])),
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 1.0],
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).hintColor,
                    ],
                  ),
                ),
                child: Container(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    "FlutterTutorial.Net",
                    style: TextStyle(
                        fontSize: 25,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.screen_lock_landscape_rounded,
                  size: _drawerIconSize,
                  color: Theme.of(context).hintColor,
                ),
                title: Text(
                  'Splash Screen',
                  style: TextStyle(
                      fontSize: 17, color: Theme.of(context).hintColor),
                ),
                onTap: () {
                  //Navigator.push(context, MaterialPageRoute(builder: (context) => SplashScreen(title: "Splash Screen")));
                },
              ),
              ListTile(
                leading: Icon(Icons.login_rounded,
                    size: _drawerIconSize, color: Theme.of(context).hintColor),
                title: Text(
                  'Login Page',
                  style: TextStyle(
                      fontSize: _drawerFontSize,
                      color: Theme.of(context).hintColor),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
              ),
              Divider(
                color: Theme.of(context).primaryColor,
                height: 1,
              ),
              ListTile(
                leading: Icon(Icons.person_add_alt_1,
                    size: _drawerIconSize, color: Theme.of(context).hintColor),
                title: Text(
                  'Registration Page',
                  style: TextStyle(
                      fontSize: _drawerFontSize,
                      color: Theme.of(context).hintColor),
                ),
                onTap: () {
                  //Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrationPage()),);
                },
              ),
              Divider(
                color: Theme.of(context).primaryColor,
                height: 1,
              ),
              ListTile(
                leading: Icon(
                  Icons.password_rounded,
                  size: _drawerIconSize,
                  color: Theme.of(context).hintColor,
                ),
                title: Text(
                  'Forgot Password Page',
                  style: TextStyle(
                      fontSize: _drawerFontSize,
                      color: Theme.of(context).hintColor),
                ),
                onTap: () {
                  // Navigator.push( context, MaterialPageRoute(builder: (context) => ForgotPasswordPage()),);
                },
              ),
              Divider(
                color: Theme.of(context).primaryColor,
                height: 1,
              ),
              ListTile(
                leading: Icon(
                  Icons.verified_user_sharp,
                  size: _drawerIconSize,
                  color: Theme.of(context).hintColor,
                ),
                title: Text(
                  'Verification Page',
                  style: TextStyle(
                      fontSize: _drawerFontSize,
                      color: Theme.of(context).hintColor),
                ),
                onTap: () {
                  //Navigator.push( context, MaterialPageRoute(builder: (context) => ForgotPasswordVerificationPage()), );
                },
              ),
              Divider(
                color: Theme.of(context).primaryColor,
                height: 1,
              ),
              ListTile(
                leading: Icon(
                  Icons.logout_rounded,
                  size: _drawerIconSize,
                  color: Theme.of(context).hintColor,
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                      fontSize: _drawerFontSize,
                      color: Theme.of(context).hintColor),
                ),
                onTap: () {
                  SystemNavigator.pop();
                },
              ),
            ],
          ),
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
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(width: 5, color: Colors.white),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: const Offset(5, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  _userHeadinfo(),
                  // Text(
                  //   'User name: ',
                  //   style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  // ),
                  // SizedBox(
                  //   height: 20,
                  // ),
                  // Text(
                  //   'Role: ',
                  //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  // ),
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
                                      // tiles: [
                                      //   ListTile(
                                      //     leading: Icon(Icons.email),
                                      //     title: Text("Email"),
                                      //     subtitle:
                                      //         Text(user?.email ?? 'User email'),
                                      //   ),
                                      //   ListTile(
                                      //     leading: Icon(Icons.text_format),
                                      //     title: Text("Name"),
                                      //     subtitle: Text(user?.displayName ??
                                      //         'User firstname '),
                                      //   ),
                                      //   ListTile(
                                      //     leading: Icon(Icons.phone),
                                      //     title: Text("Phone"),
                                      //     subtitle: Text(user?.phoneNumber ??
                                      //         'User phone'),
                                      //   ),
                                      //   ListTile(
                                      //     leading: Icon(Icons.person),
                                      //     title: Text("Role"),
                                      //     //subtitle: Text(user?.role ?? 'User role'),
                                      //   ),
                                      // ],
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
                  _signOutButton(),
                ],
              ),
            )
          ],
        ),
      ),
    );

    // @override
    // Widget build(BuildContext context) {
    //   return Scaffold(
    //     appBar: AppBar(
    //       title: _title(),
    //     ),
    //     body: Container(
    //       height: double.infinity,
    //       width: double.infinity,
    //       padding: const EdgeInsets.all(20),
    //       child: Column(
    //         crossAxisAlignment: CrossAxisAlignment.center,
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: <Widget>[
    //           _userUid(),
    //           _signOutButton(),
    //         ],
    //       ),
    //     ),
    //   );
  }
}
