import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:tutorgo/auth.dart';
import 'package:tutorgo/pages/login.dart';
import 'package:tutorgo/pages/navpage/PostCoursePage.dart';
import 'package:tutorgo/pages/navpage/courseInfoPage.dart';
import 'package:tutorgo/pages/widget/header_widget.dart';
import 'package:tutorgo/pages/widget/postCourse.dart';
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
      extendBody: true,
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
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        PostCoursePage()), // Navigate to PostCoursePage
              );
            },
            icon: Icon(Icons.newspaper), // Icon for navigating to PostCoursePage
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
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final userRole = userData['role'];
                  final enrolledCourseIds =
                      List<String>.from(userData['enrolledCourses'] ?? []);
                  if (userRole == 'Student') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 15.0),
                            child: Text(
                              'Enrolled Courses for ${userData['firstname']}',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        if (enrolledCourseIds.isNotEmpty)
                          _buildEnrolledCoursesGrid(
                              user!.uid, enrolledCourseIds)
                        else
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Text(
                              'You are not enrolled in any courses.',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign
                                  .left, // Align the text to the left within its container
                            ),
                          ),
                      ],
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
            _buildMyCoursesSection(),
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
            SingleChildScrollView(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('courses')
                    .snapshots(),
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
            ),
            SizedBox(height: 20), // Add some extra space at the bottom
          ],
        ),
      ),
    );
  }

  Widget _buildMyCoursesSection() {
    return FutureBuilder<String>(
      future: getUserRole(),
      builder: (context, roleSnapshot) {
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (roleSnapshot.hasError) {
          return Text('Error: ${roleSnapshot.error}');
        }
        final userRole = roleSnapshot.data!;

        if (userRole == 'Tutor') {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: Text(
                    'My Courses',
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
                stream: FirebaseFirestore.instance
                    .collection('courses')
                    .where('userId', isEqualTo: user!.uid)
                    .snapshots(),
                builder: (context, courseSnapshot) {
                  if (courseSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (courseSnapshot.hasError) {
                    return Text('Error: ${courseSnapshot.error}');
                  }

                  final courseDocs = courseSnapshot.data?.docs ?? [];
                  if (courseDocs.isNotEmpty) {
                    // Create a list of Future tasks to fetch course widgets with average ratings
                    final futureCourseWidgets =
                        courseDocs.map((courseDoc) async {
                      final courseData =
                          courseDoc.data() as Map<String, dynamic>;
                      final courseName = courseData['courseName'] ?? '';
                      final imageName = courseData['imageName'] ?? '';
                      final price = courseData['price'] ?? '';
                      final courseId = courseDoc.id;

                      // Fetch comments for the current course from Firestore
                      final commentsSnapshot = await FirebaseFirestore.instance
                          .collection('courses')
                          .doc(courseId)
                          .collection('comments')
                          .get();

                      final commentsData = commentsSnapshot.docs
                          .map((commentDoc) =>
                              commentDoc.data() as Map<String, dynamic>)
                          .toList();

                      double totalRating = 0;
                      int numberOfRatings = 0;

                      for (final commentData in commentsData) {
                        final commentRating = commentData['rating'] as double?;
                        if (commentRating != null) {
                          totalRating += commentRating;
                          numberOfRatings++;
                        }
                      }

                      double averageRating = numberOfRatings > 0
                          ? totalRating / numberOfRatings
                          : 0.0;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CourseInfoPage(
                                courseData: courseData,
                                courseId: courseId,
                                studentId: user!.uid,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Expanded(
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
                                ListTile(
                                  title: Text(
                                    courseName,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    children: [
                                      Text(
                                        'Price: $price',
                                        textAlign: TextAlign.center,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(width: 5),
                                          RatingBarIndicator(
                                            rating: averageRating,
                                            itemBuilder: (context, index) =>
                                                Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                            ),
                                            itemCount: 5,
                                            itemSize: 20.0,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList();

                    // Use Future.wait to await all Future tasks and get a list of Widgets
                    return FutureBuilder<List<Widget>>(
                      future: Future.wait(futureCourseWidgets),
                      builder: (context, widgetSnapshot) {
                        if (widgetSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (widgetSnapshot.hasError) {
                          return Text('Error: ${widgetSnapshot.error}');
                        }
                        final courseWidgets = widgetSnapshot.data ?? [];

                        return CarouselSlider(
                          options: CarouselOptions(
                            aspectRatio: 4 / 3,
                            viewportFraction: 0.6,
                            enlargeCenterPage: true,
                            scrollDirection: Axis.horizontal,
                            autoPlay: true,
                            autoPlayInterval: Duration(seconds: 3),
                            autoPlayAnimationDuration:
                                Duration(milliseconds: 800),
                            autoPlayCurve: Curves.fastOutSlowIn,
                            enableInfiniteScroll: true,
                          ),
                          items: courseWidgets,
                        );
                      },
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        "You don't have your own course",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildEnrolledCoursesGrid(
      String userId, List<String> enrolledCourseIds) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('courses').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final courseDocs = snapshot.data!.docs;
          final enrolledCourses = courseDocs.where((courseDoc) {
            final courseId = courseDoc.id;
            return enrolledCourseIds.contains(courseId);
          }).toList();

          return CarouselSlider(
            options: CarouselOptions(
              aspectRatio: 4 / 3,
              viewportFraction: 0.6,
              enlargeCenterPage: true,
              scrollDirection: Axis.horizontal,
              autoPlay: true,
              autoPlayInterval: Duration(seconds: 3),
              autoPlayAnimationDuration: Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enableInfiniteScroll: true,
            ),
            items: enrolledCourses.map((courseDoc) {
              final courseData = courseDoc.data() as Map<String, dynamic>;
              final courseName = courseData['courseName'] ?? '';
              final imageName = courseData['imageName'] ?? '';
              final price = courseData['price'] ?? '';
              final courseId = courseDoc.id;

              // Fetch comments for the current course from Firestore
              Future<List<Map<String, dynamic>>> fetchComments() async {
                final commentsSnapshot = await FirebaseFirestore.instance
                    .collection('courses')
                    .doc(courseId)
                    .collection('comments')
                    .get();

                final commentsData = commentsSnapshot.docs
                    .map((commentDoc) =>
                        commentDoc.data() as Map<String, dynamic>)
                    .toList();

                return commentsData;
              }

              // Calculate the average rating based on comments
              Future<double> calculateAverageRating() async {
                final commentsData = await fetchComments();
                double totalRating = 0;
                int numberOfRatings = 0;

                for (final commentData in commentsData) {
                  final commentRating = commentData['rating'] as double?;
                  if (commentRating != null) {
                    totalRating += commentRating;
                    numberOfRatings++;
                  }
                }

                return numberOfRatings > 0
                    ? totalRating / numberOfRatings
                    : 0.0;
              }

              return FutureBuilder<double>(
                future: calculateAverageRating(),
                builder: (context, snapshot) {
                  final averageRating = snapshot.data ?? 0.0;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseInfoPage(
                            courseData: courseData,
                            courseId: courseId,
                            studentId: user!.uid,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Expanded(
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
                            ListTile(
                              title: Text(
                                courseName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                children: [
                                  Text(
                                    'Price: $price',
                                    textAlign: TextAlign.center,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(width: 5),
                                      RatingBarIndicator(
                                        rating: averageRating,
                                        itemBuilder: (context, index) => Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                        ),
                                        itemCount: 5,
                                        itemSize: 20.0,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }

  Widget _buildAllCoursesGrid(List<QueryDocumentSnapshot> courseDocs) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
      ),
      itemCount: courseDocs.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // Disable GridView scrolling
      itemBuilder: (context, index) {
        final courseData = courseDocs[index].data() as Map<String, dynamic>;
        final courseName = courseData['courseName'] ?? '';
        final imageName = courseData['imageName'] ?? '';
        final price = courseData['price'] ?? '';
        final courseId = courseDocs[index].id;

        // Fetch comments for the current course from Firestore
        Future<List<Map<String, dynamic>>> fetchComments() async {
          final commentsSnapshot = await FirebaseFirestore.instance
              .collection('courses')
              .doc(courseId)
              .collection('comments')
              .get();

          final commentsData = commentsSnapshot.docs
              .map((commentDoc) => commentDoc.data() as Map<String, dynamic>)
              .toList();

          return commentsData;
        }

        // Calculate the average rating based on comments
        Future<double> calculateAverageRating() async {
          final commentsData = await fetchComments();
          double totalRating = 0;
          int numberOfRatings = 0;

          for (final commentData in commentsData) {
            final commentRating = commentData['rating'] as double?;
            if (commentRating != null) {
              totalRating += commentRating;
              numberOfRatings++;
            }
          }

          return numberOfRatings > 0 ? totalRating / numberOfRatings : 0.0;
        }

        return FutureBuilder<double>(
          future: calculateAverageRating(),
          builder: (context, snapshot) {
            final averageRating = snapshot.data ?? 0.0;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseInfoPage(
                      courseData: courseData,
                      courseId: courseId,
                      studentId: user!.uid,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(10.0),
                          ),
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
                      ListTile(
                        title: Text(
                          courseName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Text('Price: $price'),
                            SizedBox(
                                width:
                                    13), // Add spacing between price and rating
                            RatingBar.builder(
                              initialRating: averageRating,
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: true,
                              itemCount: 5,
                              itemSize: 12.0,
                              itemBuilder: (context, _) => Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              onRatingUpdate: (rating) {
                                // You can add a callback here if needed
                              },
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
