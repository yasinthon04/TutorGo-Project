import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:tutorgo/pages/widget/deleteCourse.dart';
import 'package:tutorgo/pages/widget/editCourse.dart';
import 'package:tutorgo/pages/widget/header_widget.dart';

import '../../auth.dart';
import '../widget/comment.dart';
import '../widget/commentStream.dart';

class CourseInfoPage extends StatefulWidget {
  final User? user = Auth().currentUser;
  final Map<String, dynamic> courseData;
  final String courseId;
  CourseInfoPage({required this.courseData, required this.courseId});

  @override
  _CourseInfoPageState createState() => _CourseInfoPageState();
}

class _CourseInfoPageState extends State<CourseInfoPage> {
  bool isWaitingForConfirmation = false;
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

  void _viewTutorInformation(BuildContext context) async {
    final String userId = widget.courseData['userId'];

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
    final String courseName = widget.courseData['courseName'] ?? '';
    final String address = widget.courseData['address'] ?? '';
    final String mapUrl = widget.courseData['googleMapsLink'] ?? '';
    final int price = widget.courseData['price'] ?? 0;
    final String contactInfo = widget.courseData['contactInfo'] ?? '';
    final String province = widget.courseData['province'] ?? '';
    final String userId = widget.courseData['userId'] ?? '';
    final String courseImage = widget.courseData['imageName'] ?? '';
    final String category = widget.courseData['category'] ?? '';
    final List<String> days =
        List<String>.from(widget.courseData['date'] ?? []);
    final List<Map<String, dynamic>> times =
        List<Map<String, dynamic>>.from(widget.courseData['time'] ?? []);
    final User? user = Auth().currentUser;
    final bool isCurrentUserCourseCreator = userId == user?.uid;
    final bool isStudent = user != null && !isCurrentUserCourseCreator;
    bool isEnrolled = isStudent &&
        (widget.courseData['enrolledStudents'] ?? []).contains(user!.uid);
    int requestedStudentsCount =
        widget.courseData['requestedStudents']?.length ?? 0;
    int totalStudents =
        getNumberOfStudents(widget.courseData['enrolledStudents'] ?? []);
    int maxStudents = widget.courseData['maxStudents'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Course Information',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
                  widget.courseId,
                  courseName,
                  address,
                  mapUrl,
                  price,
                  contactInfo,
                  province,
                  maxStudents,
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
                    .doc(widget.courseId)
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
                  _showDeleteCourseDialog(context, widget.courseId, courseName);
                }
              },
            ),
          if (isCurrentUserCourseCreator)
            IconButton(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.view_list),
                  if (requestedStudentsCount > 0)
                    Positioned(
                      top: -2,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red, // Customize the color
                        ),
                        child: Text(
                          requestedStudentsCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                _viewListAndRequestOfStudents(context, widget.courseId);
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

            if (widget.courseData['imageName'].isNotEmpty)
              Image.network(
                widget.courseData['imageName'],
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 5),
            GestureDetector(
              onTap: () {
                if (widget.courseData['googleMapsLink'] != null &&
                    widget.courseData['googleMapsLink'].isNotEmpty) {
                  print(
                      'Google Maps Link: ${widget.courseData['googleMapsLink']}');
                  launch(widget.courseData['googleMapsLink']);
                }
              },
              child: Text(
                'Address: $address (Go to Map)',
                style: TextStyle(
                  color: Colors
                      .blue, // Change the color to make it look like a hyperlink
                ),
              ),
            ),

            SizedBox(height: 5),
            Text('Province: $province'),
            SizedBox(height: 5),
            Text('Price/Month: $price'),
            SizedBox(height: 5),
            Text('Contact Information: $contactInfo'),
            SizedBox(height: 5),
            // Display Days of the Week

            Text(
              'Days of the Week:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 5),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
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
            ),

            // Display Time Slots
            SizedBox(height: 5),
            Text(
              'Time:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 5),
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
            // Inside the Column widget
            SizedBox(height: 5),
            Text(
              'Total Students: $totalStudents/$maxStudents',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),

            if (!isCurrentUserCourseCreator && isStudent)
              ElevatedButton(
                onPressed: () async {
                  if ((widget.courseData['requestedStudents'] ?? [])
                      .contains(user!.uid)) {
                    // Show a "Waiting..." dialog or message
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Waiting for Confirmation'),
                          content: Text(
                            'Your enrollment request is pending confirmation.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'OK',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.green,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  } else if (isEnrolled) {
                    _showCancelConfirmation(context, widget.courseId);
                  } else if (isStudent) {
                    int maxStudents = widget.courseData['maxStudents'] ?? 0;
                    int enrolledStudentsCount =
                        (widget.courseData['enrolledStudents'] as List).length;

                    if (enrolledStudentsCount >= maxStudents) {
                      // Show a warning message that enrollment is full
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Enrollment Full'),
                            content: Text(
                              'Sorry, this course is already fully enrolled.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'OK',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.green,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      // Show the enroll confirmation dialog
                      bool shouldEnroll = await _showEnrollConfirmation(
                          context, widget.courseId);

                      if (shouldEnroll) {
                        await FirebaseFirestore.instance
                            .collection('courses')
                            .doc(widget.courseId)
                            .update({
                          'requestedStudents':
                              FieldValue.arrayUnion([user!.uid]),
                        });

                        // Update the button text and style after successful enrollment
                        setState(() {
                          isEnrolled = true;
                        });

                        // Close the dialog
                        Navigator.pop(context);
                      }
                    }
                  }
                },
                child: Text(
                  // Update the button text based on whether a request is pending
                  (widget.courseData['requestedStudents'] ?? [])
                          .contains(user!.uid)
                      ? 'Waiting...'
                      : isEnrolled
                          ? 'Cancel Enrollment'
                          : 'Enroll',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  primary: (widget.courseData['requestedStudents'] ?? [])
                          .contains(user!.uid)
                      ? Colors.grey
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
                      child: Text(
                        'Submit Comment',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.green,
                      ),
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
            CommentStream(courseId: widget.courseId),
          ],
        ),
      ),
    );
  }

  int getNumberOfStudents(List<dynamic> requestedStudents) {
    return requestedStudents.length;
  }

  Future<bool> _showEnrollConfirmation(
      BuildContext context, String courseId) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enroll in Course'),
          content: Text('Are you sure you want to enroll in this course?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                    context, true); // Return true when Enroll is pressed
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
                Navigator.pop(
                    context, false); // Return false when Cancel is pressed
              },
              child: Text(
                'Cancel',
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
                'Cancel',
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

  void _enrollInCourse(BuildContext context, String courseId) async {
    if (widget.user != null) {
      final studentId = widget.user!.uid;

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
    if (widget.user != null) {
      final studentId = widget.user!.uid;

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
    String mapUrl,
    int price,
    String contactInfo,
    String province,
    int maxStudents,
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
          MapUrl: mapUrl,
          Price: price,
          ContactInfo: contactInfo,
          Province: province,
          CourseImage: courseImage,
          Category: category,
          Days: days,
          Times: times,
          MaxStudents: maxStudents,
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
          userId: widget.user?.uid ?? '',
        );
      },
    );
  }

  void _addComment(BuildContext context, String commentContent) async {
    if (widget.user != null) {
      final String studentId = widget.user!.uid;

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
          final courseRef = FirebaseFirestore.instance
              .collection('courses')
              .doc(widget.courseId);

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
    if (widget.user != null) {
      final studentId = widget.user!.uid;

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

  void _viewListAndRequestOfStudents(
      BuildContext context, String courseId) async {
    final courseRef =
        FirebaseFirestore.instance.collection('courses').doc(courseId);

    final courseSnapshot = await courseRef.get();

    if (courseSnapshot.exists) {
      final enrolledStudents = courseSnapshot['enrolledStudents'] ?? [];
      final requestedStudents = courseSnapshot['requestedStudents'] ?? [];

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('List of students',
                style: TextStyle(fontWeight: FontWeight.bold)),
            contentPadding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                  child: Text(
                    'Requested Students',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.left,
                  ),
                ),
                if (requestedStudents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('No students have requested to join.'),
                  )
                else
                  for (String studentId in requestedStudents)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(studentId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error loading student data');
                        }
                        final studentData =
                            snapshot.data?.data() as Map<String, dynamic>? ??
                                {};
                        final studentName =
                            '${studentData['firstname']} ${studentData['lastname']}';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text(studentName),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      _confirmStudentRequest(
                                          courseId, studentId);
                                      _enrollInCourse(context, courseId);
                                      Navigator.pop(context);
                                    },
                                    icon: Icon(Icons.check),
                                    color: Colors.green,
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _removeStudentRequest(
                                          courseId, studentId);
                                      Navigator.pop(context);
                                    },
                                    icon: Icon(Icons.close),
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Text(
                    'Enrolled Students',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.left,
                  ),
                ),
                if (enrolledStudents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('No students are currently enrolled.'),
                  )
                else
                  for (String studentId in enrolledStudents)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(studentId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error loading student data');
                        }
                        final studentData =
                            snapshot.data?.data() as Map<String, dynamic>? ??
                                {};
                        final studentName =
                            '${studentData['firstname']} ${studentData['lastname']}';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text(studentName),
                              trailing: IconButton(
                                onPressed: () {
                                  _confirmDeleteStudent(
                                      context, courseId, studentId);
                                },
                                icon: Icon(Icons.delete),
                                color: Colors.red,
                              ),
                            ),
                          ],
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

  void _confirmDeleteStudent(
      BuildContext context, String courseId, String studentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this student?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).hintColor,
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _deleteStudent(courseId, studentId, () {});
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(primary: Colors.red),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteStudent(
      String courseId, String studentId, VoidCallback refreshCallback) async {
    // Remove the student from the enrolled students list in the course document
    await FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .update({
      'enrolledStudents': FieldValue.arrayRemove([studentId]),
    });

    // Remove the enrolled course from the user's data
    await FirebaseFirestore.instance.collection('users').doc(studentId).update({
      'enrolledCourses': FieldValue.arrayRemove([courseId]),
    });

    // Call the refresh callback to update the UI
    refreshCallback();
  }

  void _confirmStudentRequest(String courseId, String studentId) async {
    final courseRef =
        FirebaseFirestore.instance.collection('courses').doc(courseId);

    try {
      // Remove the student from requestedStudents and add to enrolledStudents
      await courseRef.update({
        'requestedStudents': FieldValue.arrayRemove([studentId]),
        'enrolledStudents': FieldValue.arrayUnion([studentId]),
      });

      // Store courseId in student's data
      final studentRef =
          FirebaseFirestore.instance.collection('users').doc(studentId);

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

  void _launchGoogleMaps(String googleMapsLink) async {
    try {
      if (await canLaunch(googleMapsLink)) {
        await launch(googleMapsLink);
      } else {
        print('Could not launch $googleMapsLink');
      }
    } catch (e) {
      print('Error launching Google Maps: $e');
    }
  }
}
