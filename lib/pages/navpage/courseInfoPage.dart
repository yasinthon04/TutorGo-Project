import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseInfoPage extends StatelessWidget {
  final Map<String, dynamic> courseData;

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Course Information'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
            Text('Price/Month: ${courseData['price']}'),
            SizedBox(height: 10),
            Text('Contact Information: ${courseData['contactInfo']}'),
            SizedBox(height: 20),
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
}
