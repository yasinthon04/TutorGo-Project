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

  List<Map<String, String>> chapters = [];

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

  void _addChapter() {
    setState(() {
      chapters.add({'chapterNo': '', 'chapterName': ''});
    });
  }

  void _removeChapter(int index) {
    setState(() {
      chapters.removeAt(index);
    });
  }

  Future<void> _addChapterToCourseData() async {
    try {
      String courseId = widget.courseData['courseId'];

      // Ensure the chapters have valid data before updating
      List<Map<String, String>> validChapters = chapters.map((chapter) {
        String chapterNo = chapter['chapterNo'] ?? ''; // Handle null chapterNo
        String chapterName =
            chapter['chapterName'] ?? ''; // Handle null chapterName

        return {'chapterNo': chapterNo, 'chapterName': chapterName};
      }).toList();

      // Remove chapters with null or empty chapter numbers or names
      validChapters.removeWhere((chapter) =>
          chapter['chapterNo']!.isEmpty || chapter['chapterName']!.isEmpty);

      // Update the 'chapters' field in the Firestore document
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .update({'chapters': validChapters});

      print('Chapter data updated successfully for document ID: $courseId');
    } catch (e) {
      print('Error updating chapter data: $e');
    }
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
          Container(
            height: 75,
            child: HeaderWidget(75, false, Icons.house_rounded),
          ),
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
            ...chapters.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, String> chapter = entry.value;

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Chapter ${index + 1}',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            chapters[index]['chapterNo'] = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Chapter Name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            chapters[index]['chapterName'] = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        _removeChapter(index);
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          // Button to add a new chapter
          if (isCurrentUserTutor)
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton(
                onPressed: _addChapter,
                child: Text('Add Chapter'),
              ),
            ),
          if (isCurrentUserTutor)
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton(
                onPressed: _addChapterToCourseData,
                child: Text('Submit Chapter'),
              ),
            ),
        ],
      ),
    );
  }
}
