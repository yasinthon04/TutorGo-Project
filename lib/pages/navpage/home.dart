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

  void _viewTutorInformation(String userId) async {
    final tutorSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (tutorSnapshot.exists) {
      final tutorData = tutorSnapshot.data() as Map<String, dynamic>;
      final tutorFirstname = tutorData['firstname'] ?? '';
      final tutorLastname = tutorData['lastname'] ?? '';
      final tutorEmail = tutorData['email'] ?? '';
      final tutorMobile = tutorData['mobile'] ?? '';
      final tutorImage = tutorData['profilePicture'] ?? '';

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Tutor Information',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tutorImage.isNotEmpty)
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(tutorImage),
                  ),
                SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: 'Name : ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: tutorFirstname,
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                      TextSpan(
                        text: ' ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: tutorLastname,
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: 'Email : ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: tutorEmail,
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: 'Mobile : ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: tutorMobile,
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  primary:
                      Theme.of(context).hintColor, // Set the button color here
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _showCourseInfoDialog(
    String courseName,
    String address,
    String price,
    String contactInfo,
    String province,
    String userId,
    String courseId,
    bool isCurrentUserCourseCreator,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Course Information',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: 'Course Name: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: courseName,
                      style: TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: 'Address: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: address,
                      style: TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: 'Price: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: price,
                      style: TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: 'Contact Information: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: contactInfo,
                      style: TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
        );
      },
    );
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

  // Future<void> _signOutButton() async {
  //   await signOut();
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(builder: (context) => LoginPage()),
  //   );
  // }

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
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 75,
              child: HeaderWidget(75, false, Icons.house_rounded),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Text(
                  'For you',
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
              stream:
                  FirebaseFirestore.instance.collection('courses').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final courseDocs = snapshot.data!.docs;
                  return SizedBox(
                    height: MediaQuery.of(context).size.height -
                        250, // Adjust the height as needed
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      children: courseDocs.map((courseDoc) {
                        final courseData =
                            courseDoc.data() as Map<String, dynamic>;
                        final courseName = courseData['courseName'] ?? '';
                        final address = courseData['address'] ?? '';
                        final price = courseData['price'] ?? '';
                        final contactInfo = courseData['contactInfo'] ?? '';
                        final imageName = courseData['imageName'] ?? '';
                        final userId = courseData['userId'] ?? '';
                        final courseId = courseDoc.id;

                        // Check if the current user is the creator of the course
                        final bool isCurrentUserCourseCreator =
                            userId == user?.uid;

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final tutorData =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              final tutorFirstname =
                                  tutorData['firstname'] ?? '';

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CourseInfoPage(
                                          courseData: courseData),
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
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
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
                            } else {
                              return SizedBox.shrink();
                            }
                          },
                        );
                      }).toList(),
                    ),
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
