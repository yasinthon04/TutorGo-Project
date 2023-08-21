import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late User _user;
  List<Map<String, dynamic>> _enrolledCourses = [];

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _fetchEnrolledCourses();
  }

  Future<void> _fetchEnrolledCourses() async {
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .get();
    final userData = userSnapshot.data() as Map<String, dynamic>?;

    final enrolledCourses = userData?['enrolledCourses'] ?? [];

    final courseSnapshots = await Future.wait(
      enrolledCourses.map<Future<DocumentSnapshot>>(
        (courseId) => FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .get(),
      ),
    );

    setState(() {
      _enrolledCourses = courseSnapshots
          .map(
            (courseSnapshot) => courseSnapshot.data() as Map<String, dynamic>,
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(_user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("An error occurred"),
            );
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;

          final bool isStudent = userData?['role'] == 'student';
          final List<dynamic> enrolledCourses =
              userData?['enrolledCourses'] ?? [];

          if (isStudent && enrolledCourses.isEmpty) {
            return Center(
              child: Text("You are not enrolled in any courses."),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text('Schedule'),
            ),
            body: ListView.builder(
              itemCount: _enrolledCourses.length,
              itemBuilder: (context, index) {
                final courseData = _enrolledCourses[index];
                final courseName = courseData['courseName'];
                final days = courseData['date'] ?? [];
                final times = courseData['time'] ?? [];

                final formattedTimes = times.map((time) {
                  final courseTime =
                      TimeOfDay(hour: time['hour'], minute: time['minute']);
                  return '${courseTime.format(context)}';
                }).join(' - ');

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Course: $courseName',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        Text('Days: ${days.join(', ')}'),
                        Text('Times: $formattedTimes'),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        });
  }
}
