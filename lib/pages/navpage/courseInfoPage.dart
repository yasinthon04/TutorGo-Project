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
          if (isCurrentUserCourseCreator)
            IconButton(
              icon: Icon(Icons.view_list),
              onPressed: () {
                _viewRequestedStudents(context, courseId);
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
                'assets/images/logo.png',
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
                if (isEnrolled) {
                  _showCancelConfirmation(
                      context, courseId); // Show cancel confirmation dialog
                } else if (isStudent &&
                    !(courseData['requestedStudents'] ?? [])
                        .contains(user!.uid)) {
                  // Check if the student has already requested enrollment
                  if ((courseData['requestedStudents'] ?? [])
                      .contains(user!.uid)) {
                    // Show a "Waiting..." dialog or message
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Waiting for Confirmation'),
                          content: Text(
                              'Your enrollment request is pending confirmation.'),
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
                    // Show the enroll confirmation dialog
                    _showEnrollConfirmation(context, courseId);
                  }
                }
              },
              child: Text(
                // Update the button text based on whether a request is pending
                (courseData['requestedStudents'] ?? []).contains(user!.uid)
                    ? 'Waiting...'
                    : isEnrolled
                        ? 'Cancel Enrollment'
                        : 'Request Enroll',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                primary: (courseData['requestedStudents'] ?? [])
                        .contains(user!.uid)
                    ? Colors
                        .grey // Show a different color for the "Waiting..." state
                    : isEnrolled
                        ? Colors.red
                        : Theme.of(context).hintColor,
              ),
            ),
            if (isStudent && isEnrolled)
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
                  ],
                ),
              ),
            SizedBox(height: 20),
            Text(
              'Comments',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 10),
            CommentStream(courseId: courseId),
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
                _requestEnrollInCourse(context, courseId);
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
                _cancelEnrollment(context, courseId);
                Navigator.pop(context);
                Navigator.pop(context);
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

      try {
        final studentRef =
            FirebaseFirestore.instance.collection('users').doc(studentId);

        await studentRef.update({
          'enrolledCourses': FieldValue.arrayUnion([courseId]),
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

  void _requestEnrollInCourse(
      BuildContext parentContext, String courseId) async {
    if (user != null) {
      final studentId = user!.uid;

      try {
        final studentRef =
            FirebaseFirestore.instance.collection('users').doc(studentId);

        final courseRef =
            FirebaseFirestore.instance.collection('courses').doc(courseId);

        // Add the student's ID to the list of requested students
        await courseRef.update({
          'requestedStudents': FieldValue.arrayUnion([studentId]),
        });

        // Show the "Waiting for Confirmation" dialog
        showDialog(
          context: parentContext, // Use the provided parentContext here
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Waiting for Confirmation'),
              content: Text('Your enrollment request is pending confirmation.'),
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

        // You can also consider refreshing the UI to reflect the pending status
        // or showing a message on the UI.
      } catch (error) {
        print('Error requesting enrollment: $error');
      }
    } else {
      // Handle the case when the user is not authenticated.
      // You might want to show a login prompt or navigate to the login screen.
    }
  }

  void _viewRequestedStudents(BuildContext context, String courseId) async {
    final courseRef =
        FirebaseFirestore.instance.collection('courses').doc(courseId);

    final courseSnapshot = await courseRef.get();

    if (courseSnapshot.exists) {
      final requestedStudents = courseSnapshot['requestedStudents'] ?? [];

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Requested Students'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (String studentId in requestedStudents)
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(studentId)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text('Error loading student data');
                      }
                      final studentData =
                          snapshot.data?.data() as Map<String, dynamic>? ?? {};
                      final studentName =
                          '${studentData['firstname']} ${studentData['lastname']}';

                      return ListTile(
                        title: Text(studentName),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () {
                                _confirmStudentRequest(courseId, studentId);
                                _enrollInCourse(context, courseId);
                                Navigator.pop(context); // Close the dialog
                              },
                              child: Text('Confirm'),
                            ),
                            TextButton(
                              onPressed: () {
                                _removeStudentRequest(courseId, studentId);
                                Navigator.pop(context); // Close the dialog
                              },
                              child: Text('Remove'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
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
  }

  void _confirmStudentRequest(String courseId, String studentId) async {
  final courseRef = FirebaseFirestore.instance.collection('courses').doc(courseId);

  try {
    // Remove the student from requestedStudents and add to enrolledStudents
    await courseRef.update({
      'requestedStudents': FieldValue.arrayRemove([studentId]),
      'enrolledStudents': FieldValue.arrayUnion([studentId]),
    });

    // Store courseId in student's data
    final studentRef = FirebaseFirestore.instance.collection('users').doc(studentId);

    await studentRef.update({
      'enrolledCourses': FieldValue.arrayUnion([courseId]),
    });
  } catch (error) {
    print('Error confirming student request: $error');
  }
}


  void _removeStudentRequest(String courseId, String studentId) async {
    final courseRef =
        FirebaseFirestore.instance.collection('courses').doc(courseId);

    try {
      // Remove the student from requestedStudents
      await courseRef.update({
        'requestedStudents': FieldValue.arrayRemove([studentId]),
      });
    } catch (error) {
      print('Error removing student request: $error');
    }
  }
}
