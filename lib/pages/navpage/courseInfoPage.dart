import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorgo/pages/widget/deleteCourse.dart';
import 'package:tutorgo/pages/widget/editCourse.dart';
import 'package:tutorgo/pages/widget/header_widget.dart';

import '../../auth.dart';

class CourseInfoPage extends StatelessWidget {
  final User? user = Auth().currentUser;
  final Map<String, dynamic> courseData;
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

  CourseInfoPage({required this.courseData});

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
    final String courseId = courseData['courseId'] ?? '';
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
              onPressed: () {
                _showDeleteCourseDialog(
                  context,
                  courseId,
                  courseName,
                );
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
              'Course Name: ${courseData['courseName']}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 10),
            Text('Address: ${courseData['address']}'),
            SizedBox(height: 10),
            Text('Province: ${courseData['province']}'),
            SizedBox(height: 10),
            Text('Price/Month: ${courseData['price']}'),
            SizedBox(height: 10),
            Text('Contact Information: ${courseData['contactInfo']}'),
            SizedBox(height: 20),
            // Display Days of the Week
            SizedBox(height: 20),
            Text(
              'Days of the Week:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                courseData['date'].length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Chip(
                    label: Text(courseData['date'][index]),
                  ),
                ),
              ),
            ),
            // Display Time Slots
            SizedBox(height: 20),
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
                    'Start: ${_formatTime(courseData['time'][0]['hour'], courseData['time'][0]['minute'])}',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Text(
                    'End: ${_formatTime(courseData['time'][1]['hour'], courseData['time'][1]['minute'])}',
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
          ],
        ),
      ),
    );
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
          courseId: courseId,
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
          courseId: courseId,
          courseName: courseName,
          userId: user?.uid ?? '',
        );
      },
    );
  }
}
