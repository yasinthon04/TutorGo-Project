import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tutorgo/auth.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final User? user = Auth().currentUser;

  Future<void> signOut() async {
    await Auth().signOut();
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
            backgroundColor: Colors.red.withOpacity(0.6),
            side: BorderSide.none,
            shape: const StadiumBorder()),
        child: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _title(),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(
              height: 10,
            ),
            _userUid(),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    side: BorderSide.none,
                    shape: const StadiumBorder()),
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            _signOutButton(),
          ],
        ),
      ),
    );
  }
}
