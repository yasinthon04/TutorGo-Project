import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorgo/pages/widget/deleteCourse.dart';
import 'package:tutorgo/pages/widget/editCourse.dart';
import 'package:tutorgo/pages/widget/header_widget.dart';

import '../../auth.dart';
import '../widget/comment.dart';
import '../widget/commentStream.dart';

class CourseInfoPage extends StatelessWidget {
  final User? user = Auth().currentUser;
  final Map<String, dynamic> courseData;
  final String courseId;
  final TextEditingController _commentController = TextEditingController();
  List<Comment> courseComments = [];

  String _formatTime(int hour, int minute) {
    final period = hour < 12 ? 'AM' : 'PM';
    final hourOfDay = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;

    final formattedTime =
        '$hourOfDay:${minute.toString().padLeft(2, '0')} $period';
    return formattedTime;
  }

  CourseInfoPage({required this.courseData, required this.courseId});

  void _viewTutorInformation(BuildContext context) async {
    final String userId = courseData['userId'];

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
                Text('Name : $tutorFirstname $tutorLastname'),
                SizedBox(height: 10),
                Text('Email : $tutorEmail'),
                SizedBox(height: 10),
                Text('Mobile : $tutorMobile'),
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
                  primary: Theme.of(context).hintColor,
                ),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String courseName = courseData['courseName'] ?? '';
    final String address = courseData['address'] ?? '';
    final String price = courseData['price'] ?? '';
    final String contactInfo = courseData['contactInfo'] ?? '';
    final String province = courseData['province'] ?? '';
    final String userId = courseData['userId'] ?? '';
    final String courseImage = courseData['imageName'] ?? '';
    final String category = courseData['category'] ?? '';
    final List<String> days = List<String>.from(courseData['date'] ?? []);
    final List<Map<String, dynamic>> times =
        List<Map<String, dynamic>>.from(courseData['time'] ?? []);
    final User? user = Auth().currentUser;
    final bool isCurrentUserCourseCreator = userId == user?.uid;
    final bool isStudent = user != null && !isCurrentUserCourseCreator;
    final bool isEnrolled =
        isStudent && (courseData['enrolledStudents'] ?? []).contains(user!.uid);
    print('courseId: $courseId');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Course Information',
          style: TextStyle(color: Colors.white),
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
              ],
            ),
          ),
        ),
        actions: <Widget>[
          if (isCurrentUserCourseCreator)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                _showEditCourseDialog(
                  context,
                  courseId,
                  courseName,
                  address,
                  price,
                  contactInfo,
                  province,
                  courseImage,
                  category,
                  days,
                  times,
                );
              },
            ),
          if (isCurrentUserCourseCreator)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                final courseSnapshot = await FirebaseFirestore.instance
                    .collection('courses')
                    .doc(courseId)
                    .get();

                final courseData =
                    courseSnapshot.data() as Map<String, dynamic>;
                final enrolledStudents =
                    (courseData['enrolledStudents'] ?? []) as List;

                if (enrolledStudents.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Cannot Delete Course'),
                        content: Text(
                            'There are students currently enrolled in this course.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  _showDeleteCourseDialog(context, courseId, courseName);
                }
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

            if (courseData['imageName'].isNotEmpty)
              Image.network(
                courseData['imageName'],
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              )
            else
              Image.asset(
                'assets/default_image.png',
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 20),
            Text(
              'Course Name: $courseName',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 10),
            Text('Address: $address'),
            SizedBox(height: 10),
            Text('Province: $province'),
            SizedBox(height: 10),
            Text('Price/Month: $price'),
            SizedBox(height: 10),
            Text('Contact Information: $contactInfo'),
            SizedBox(height: 10),
            // Display Days of the Week

            Text(
              'Days of the Week:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                days.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Chip(
                    label: Text(days[index]),
                  ),
                ),
              ),
            ),
            // Display Time Slots
            SizedBox(height: 10),
            Text(
              'Time:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 10),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Text(
                    'Start: ${_formatTime(times[0]['hour'], times[0]['minute'])}',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Text(
                    'End: ${_formatTime(times[1]['hour'], times[1]['minute'])}',
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => _viewTutorInformation(context),
              child: Text(
                'View Tutor Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                if (isStudent && !isEnrolled) {
                  _showEnrollConfirmation(context, courseId);
                } else if (isEnrolled) {
                  _showCancelConfirmation(context, courseId);
                }
              },
              child: Text(
                isEnrolled ? 'Cancel Enrollment' : 'Enroll',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                primary:
                    isEnrolled ? Colors.red : Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEnrollConfirmation(BuildContext context, String courseId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enroll in Course'),
          content: Text('Are you sure you want to enroll in this course?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _enrollInCourse(context, courseId);
              },
              child: Text(
                'Enroll',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.green,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      _addComment(context, value);
                    },
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (_commentController.text.isNotEmpty) {
                        _addComment(context, _commentController.text);
                        _commentController.clear();
                      }
                    },
                    child: Text('Submit Comment'),
                  ),
                  CommentSection(comments: courseComments),
                  CommentStream(courseId: courseId),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCancelConfirmation(BuildContext context, String courseId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel Enrollment'),
          content: Text('Are you sure you want to cancel your enrollment?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelEnrollment(context, courseId);
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
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

  void _enrollInCourse(BuildContext context, String courseId) async {
    if (user != null) {
      final studentId = user!.uid;

      print('courseId: $courseId');
      print('studentId: $studentId');

      try {
        final studentRef =
            FirebaseFirestore.instance.collection('users').doc(studentId);

        final courseRef =
            FirebaseFirestore.instance.collection('courses').doc(courseId);

        await studentRef.update({
          'enrolledCourses': FieldValue.arrayUnion([courseId]),
        });

        await courseRef.update({
          'enrolledStudents': FieldValue.arrayUnion([studentId]),
        });

        // Show success message or navigate to a different screen.
      } catch (error) {
        print('Error enrolling student: $error');
      }
    } else {
      // Handle the case when the user is not authenticated.
      // You might want to show a login prompt or navigate to the login screen.
    }
  }

  void _cancelEnrollment(BuildContext context, String courseId) async {
    if (user != null) {
      final studentId = user!.uid;

      try {
        final studentRef =
            FirebaseFirestore.instance.collection('users').doc(studentId);

        final courseRef =
            FirebaseFirestore.instance.collection('courses').doc(courseId);

        await studentRef.update({
          'enrolledCourses': FieldValue.arrayRemove([courseId]),
        });

        await courseRef.update({
          'enrolledStudents': FieldValue.arrayRemove([studentId]),
        });

        // Show success message or navigate to a different screen.
      } catch (error) {
        print('Error canceling enrollment: $error');
      }
    }
  }

  void _showEditCourseDialog(
    BuildContext context,
    String courseId,
    String courseName,
    String address,
    String price,
    String contactInfo,
    String province,
    String courseImage,
    String category,
    List<String> days,
    List<Map<String, dynamic>> times,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditCourse(
          CourseId: courseId,
          CourseName: courseName,
          Address: address,
          Price: price,
          ContactInfo: contactInfo,
          Province: province,
          CourseImage: courseImage,
          Category: category,
          Days: days,
          Times: times,
        );
      },
    );
  }

  void _showDeleteCourseDialog(
      BuildContext context, String courseId, String courseName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteCourse(
          CourseId: courseId,
          CourseName: courseName,
          userId: user?.uid ?? '',
        );
      },
    );
  }

  void _addComment(BuildContext context, String commentContent) async {
    if (user != null) {
      final String studentId = user!.uid;

      try {
        // Fetch the user's first name
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .get();
        final firstName = userDoc['firstname'] as String?;

        if (firstName != null) {
          final Comment comment = Comment(
            content: commentContent,
            studentId: studentId,
            firstName: firstName,
            timestamp: DateTime.now(),
          );

          // Add the comment to Firebase
          final courseRef =
              FirebaseFirestore.instance.collection('courses').doc(courseId);

          final commentDoc = courseRef.collection('comments').doc();
          await commentDoc.set({
            'content': comment.content,
            'studentId': comment.studentId,
            'firstName': comment.firstName,
            'timestamp': comment.timestamp,
          });

          // Clear the comment input field and update the UI
          _commentController.clear();
          courseComments.add(comment);
        }
      } catch (error) {
        print('Error adding comment: $error');
      }
    } else {
      // Handle the case when the user is not authenticated.
      // You might want to show a login prompt or navigate to the login screen.
    }
  }
}
