import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutorgo/auth.dart';
import 'package:tutorgo/pages/login.dart';
import 'package:tutorgo/pages/navpage/courseInfoPage.dart';
import 'package:tutorgo/pages/widget/header_widget.dart';
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

  Widget _title() {
    return const Text(
      'Home page',
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  Widget _userUid() {
    return Text(user?.email ?? 'User email');
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: _title(),
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
            ],
          ),
        ),
      ),
      actions: [
        FutureBuilder<String>(
          future: getUserRole(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final userRole = snapshot.data!;
              if (userRole == 'Tutor') {
                return IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreateCourse()),
                    );
                  },
                  icon: Icon(Icons.add),
                );
              }
            }
            return SizedBox.shrink();
          },
        ),
      ],
    ),
    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            height: 75,
            child: HeaderWidget(75, false, Icons.house_rounded),
          ),
          SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final userDocs = snapshot.data!.docs;
                return Column(
                  children: userDocs.map((userDoc) {
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final enrolledCourseIds =
                        List<String>.from(userData['enrolledCourses'] ?? []);
                    final userRole = userData['role'];

                    // Check if the user is a student and has enrolled courses
                    if (userRole == 'Student' && enrolledCourseIds.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 15.0),
                            child: Text(
                              'Enrolled Courses for ${userData['firstname']} ${userData['lastname']}',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          _buildEnrolledCoursesGrid(enrolledCourseIds),
                        ],
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  }).toList(),
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return CircularProgressIndicator();
              }
            },
          ),
          SizedBox(height: 20), // Add space between sections
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Text(
                'All Courses',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('courses').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final courseDocs = snapshot.data!.docs;
                return _buildAllCoursesGrid(courseDocs);
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return CircularProgressIndicator(); // Display loading indicator
              }
            },
          ),
          SizedBox(height: 20), // Add some extra space at the bottom
        ],
      ),
    ),
  );
}


  Widget _buildEnrolledCoursesGrid(List<String> enrolledCourseIds) {
    return SizedBox(
      child: GridView.count(
        crossAxisCount: 2, // Adjust as needed
        childAspectRatio: 0.72, // Adjust as needed
        shrinkWrap: true,
        children: enrolledCourseIds.map((courseId) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('courses')
                .doc(courseId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final courseData =
                    snapshot.data!.data() as Map<String, dynamic>;
                final courseName = courseData['courseName'] ?? '';
                final imageName = courseData['imageName'] ?? '';
                final tutorFirstname = courseData['tutorFirstname'] ?? '';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseInfoPage(
                          courseData: courseData,
                          courseId: courseId,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Card(
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              height: 170,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10.0),
                                child: imageName.isNotEmpty
                                    ? Image.network(
                                        imageName,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        'assets/default_image.png',
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
                          ListTile(
                            title: Text(
                              courseName,
                              textAlign: TextAlign.center,
                            ),
                            subtitle: Text(
                              'Tutor: $tutorFirstname',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return SizedBox.shrink();
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAllCoursesGrid(List<QueryDocumentSnapshot> courseDocs) {
    return SizedBox(
      child: GridView.count(
        crossAxisCount: 2, // Adjust as needed
        childAspectRatio: 0.72, // Adjust as needed
        shrinkWrap: true,
        children: courseDocs.map((courseDoc) {
          final courseData = courseDoc.data() as Map<String, dynamic>;
          final courseName = courseData['courseName'] ?? '';
          final imageName = courseData['imageName'] ?? '';
          final tutorFirstname = courseData['tutorFirstname'] ?? '';
          final userId = courseData['userId'] ?? '';
          final courseId = courseDoc.id;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseInfoPage(
                    courseData: courseData,
                    courseId: courseId,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Card(
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        height: 170,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: imageName.isNotEmpty
                              ? Image.network(
                                  imageName,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/default_image.png',
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                    ListTile(
                      title: Text(
                        courseName,
                        textAlign: TextAlign.center,
                      ),
                      subtitle: Text(
                        'Tutor: $tutorFirstname',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
