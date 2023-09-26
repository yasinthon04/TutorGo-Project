import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorgo/pages/widget/header_widget.dart';

class ScheduleInfoPage extends StatefulWidget {
  final Map<String, dynamic> courseData;

  const ScheduleInfoPage({required this.courseData});

  @override
  _ScheduleInfoPageState createState() => _ScheduleInfoPageState();
}

class _ScheduleInfoPageState extends State<ScheduleInfoPage> {
  late String courseName;
  late String imageName;
  late String mapUrl;
  late String currentUserId;

  bool get isCurrentUserTutor {
    return widget.courseData['userId'] == currentUserId;
  }

  @override
  void initState() {
    super.initState();
    courseName = widget.courseData['courseName'] ?? '';
    imageName = widget.courseData['imageName'] ?? '';
    mapUrl = widget.courseData['googleMapLink'] ?? '';
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Schedule Information',
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Name:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
          ),
          Text(
            courseName,
            style: TextStyle(fontSize: 16.0),
          ),
          SizedBox(height: 20.0),
          Image.network(
            widget
                .courseData['imageName'], // Assuming imageName is the image URL
            width: 200.0,
            height: 200.0,
          ),
          SizedBox(height: 20.0),
          Text(
            'Google Map:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
          ),
          GestureDetector(
            onTap: () {
              if (widget.courseData['googleMapsLink'] != null &&
                  widget.courseData['googleMapsLink'].isNotEmpty) {
                print(
                    'Google Maps Link: ${widget.courseData['googleMapsLink']}');
                launch(widget.courseData['googleMapsLink']);
              }
            },
            child: Icon(
              Icons.map_sharp,
              color: Theme.of(context).hintColor,
              size: 50,
            ),
          ),
          SizedBox(
            height: 20,
          ),
          if (isCurrentUserTutor)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Add Chapter',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
