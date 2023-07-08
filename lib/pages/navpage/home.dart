import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutorgo/auth.dart';
import 'package:tutorgo/pages/login.dart';
import '../widget/createCourse.dart';
import '../widget/editCourse.dart';
import '../widget/deleteCourse.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = Auth().currentUser;

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Future<String> getUserRole() async {
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .get();

    final userData = userSnapshot.data() as Map<String, dynamic>;
    final role = userData['role'] as String;

    return role;
  }

  void _showCourseInfoDialog(String courseName, String address, String price,
      String contactInfo, String userId, String courseId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Course Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Course Name: $courseName'),
              Text('Address: $address'),
              Text('Price: $price'),
              Text('Contact Information: $contactInfo'),
            ],
          ),
          actions: [
            if (userId ==
                user?.uid) // Show edit and delete buttons for the current user
              ElevatedButton(
                onPressed: () {
                  // Handle edit button action
                  Navigator.pop(context);
                  _showEditCourseDialog(
                      courseId, courseName, address, price, contactInfo);
                },
                child: Text('Edit'),
              ),
            if (userId ==
                user?.uid) // Show edit and delete buttons for the current user
              ElevatedButton(
                onPressed: () {
                  // Handle delete button action
                  Navigator.pop(context);
                  _showDeleteCourseDialog(courseId, courseName);
                },
                child: Text('Delete'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showEditCourseDialog(
      String courseId, String courseName, String address, String price, String contactInfo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditCourse(
          courseId: courseId,
          courseName: courseName,
          address: address,
          price: price,
          contactInfo: contactInfo,
        );
      },
    );
  }

  void _showDeleteCourseDialog(String courseId, String courseName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteCourse(
          courseId: courseId,
          courseName: courseName,
          userId: user?.uid ?? '',
        );
      },
    );
  }

  Widget _title() {
    return const Text('Home page');
  }

  Widget _userUid() {
    return Text(user?.email ?? 'User email');
  }

  Future<void> _signOutButton() async {
    await signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
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
            _userUid(),
            SizedBox(height: 20),
            FutureBuilder<String>(
              future: getUserRole(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final userRole = snapshot.data!;
                  if (userRole == 'Tutor') {
                    return ElevatedButton(
                      onPressed: () {
                        // Show the create course form
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return CreateCourse();
                          },
                        );
                      },
                      child: const Text(
                        'Create Course',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                }
                return SizedBox.shrink();
              },
            ),
            SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('courses').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final courseDocs = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: courseDocs.length,
                    itemBuilder: (context, index) {
                      final courseData =
                          courseDocs[index].data() as Map<String, dynamic>;
                      final courseName = courseData['courseName'] ?? '';
                      final address = courseData['address'] ?? '';
                      final price = courseData['price'] ?? '';
                      final contactInfo = courseData['contactInfo'] ?? '';
                      final imageName = courseData['imageName'] ?? '';
                      final userId = courseData['userId'] ?? '';
                      final courseId = courseDocs[index].id;

                      return Card(
                        child: ListTile(
                          leading: imageName.isNotEmpty
                              ? Image.network(imageName)
                              : Image.asset('assets/default_image.png'),
                          title: Text(courseName),
                          onTap: () {
                            _showCourseInfoDialog(courseName, address, price,
                                contactInfo, userId, courseId);
                          },
                        ),
                      );
                    },
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signOutButton,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.2),
                side: BorderSide.none,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
