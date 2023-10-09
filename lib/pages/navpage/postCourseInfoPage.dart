import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tutorgo/pages/widget/header_widget.dart';
import 'package:tutorgo/pages/widget/editPost.dart';

class PostCourseInfoPage extends StatefulWidget {
  final Map<String, dynamic> postCourseData;
  final String? postCourseId;

  const PostCourseInfoPage({required this.postCourseData, this.postCourseId});

  @override
  _PostCourseInfoPageState createState() => _PostCourseInfoPageState();
}

class _PostCourseInfoPageState extends State<PostCourseInfoPage> {
  bool isEnrolled = false;
  bool get isStudent {
    return widget.postCourseData['userId'] ==
        FirebaseAuth.instance.currentUser?.uid;
  }

  void _enrollInCourse(BuildContext context, String courseId) async {
    if (FirebaseAuth.instance.currentUser != null) {
      final tutorId = FirebaseAuth.instance.currentUser!.uid;

      try {
        final tutorRef =
            FirebaseFirestore.instance.collection('users').doc(tutorId);

        await tutorRef.update({
          'jobEnrolled': FieldValue.arrayUnion([widget.postCourseId]),
        });

        // Show success message or navigate to a different screen.
      } catch (error) {
        print('Error enrolling tutor: $error');
      }
    } else {
      // Handle the case when the user is not authenticated.
      // You might want to show a login prompt or navigate to the login screen.
    }
  }

  void _requestEnrollInCourse(
      BuildContext parentContext, String courseId) async {
    if (FirebaseAuth.instance.currentUser != null) {
      final tutorId = FirebaseAuth.instance.currentUser!.uid;

      try {
        final tutorRef =
            FirebaseFirestore.instance.collection('users').doc(tutorId);

        final courseRef = FirebaseFirestore.instance
            .collection('postCourse')
            .doc(widget.postCourseId);

        // Add the tutor's ID to the list of requested tutors
        await courseRef.update({
          'requestedTutors': FieldValue.arrayUnion([tutorId]),
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

  Future<bool> _showTutorEnrollConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Enroll as Tutor'),
              content: Text(
                'Do you want to enroll as a tutor for this job?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false); // User canceled
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true); // User confirmed
                  },
                  child: Text(
                    'Enroll',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false; // Return false if dialog is dismissed
  }

  void _cancelEnrollment(BuildContext context, String courseId) async {
    if (FirebaseAuth.instance.currentUser != null) {
      final tutorId = FirebaseAuth.instance.currentUser!.uid;

      try {
        final tutorRef =
            FirebaseFirestore.instance.collection('users').doc(tutorId);

        await tutorRef.update({
          'jobEnrolled': FieldValue.arrayRemove([widget.postCourseId]),
        });

        // Show success message or navigate to a different screen.
        setState(() {
          isEnrolled = false;
        });
      } catch (error) {
        print('Error canceling enrollment: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Post Information',
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
          if (isStudent)
            IconButton(
              onPressed: () {
                // Navigate to the edit page
                if (widget.postCourseId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPostPage(
                        postCourseData: widget.postCourseData,
                        postCourseId:
                            widget.postCourseId, // Pass the postCourseId here
                      ),
                    ),
                  );
                } else {
                  print('Invalid postCourseId');
                }
              },
              icon: Icon(
                Icons.edit, // Change to your desired icon
                color: Colors.white,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        // Wrap the content in SingleChildScrollView
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 75,
              child: HeaderWidget(75, false, Icons.house_rounded),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                        10), // Adjust the radius as needed
                    child: Image.network(
                      widget.postCourseData['imageUrl'] ?? '',
                      height: 250,
                      width: 350,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Course Name: ${widget.postCourseData['courseName']}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(height: 5),
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Price: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        TextSpan(
                          text: '${widget.postCourseData['price']} ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5),
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Address: ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Change the color if needed
                              fontSize: 16),
                        ),
                        TextSpan(
                          text: '${widget.postCourseData['address']}',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize:
                                  16 // Change the color to make it look like a hyperlink
                              ),
                          children: <InlineSpan>[
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  if (widget.postCourseData['googleMapsLink'] !=
                                          null &&
                                      widget.postCourseData['googleMapsLink']
                                          .isNotEmpty) {
                                    print(
                                        'Google Maps Link: ${widget.postCourseData['googleMapsLink']}');
                                    launch(widget
                                        .postCourseData['googleMapsLink']);
                                  }
                                },
                                child: Icon(
                                  Icons.map, // Replace with the icon you want
                                  color: Theme.of(context).hintColor,
                                  // Change the color if needed
                                  size: 23, // Adjust the size as needed
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5),
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Contact Info: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        TextSpan(
                          text: '${widget.postCourseData['contactInfo']} ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (isEnrolled) {
                        if (widget.postCourseId != null) {
                          _cancelEnrollment(context, widget.postCourseId!);
                        } else {
                          print('Invalid postCourseId');
                        }
                      } else {
                        bool shouldEnroll =
                            await _showTutorEnrollConfirmation(context);

                        if (shouldEnroll) {
                          if (widget.postCourseId != null) {
                            _enrollInCourse(context, widget.postCourseId!);
                          } else {
                            print('Invalid postCourseId');
                          }
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 10),
                      child: Text(
                        isEnrolled ? 'Cancel Enrollment' : 'Enroll as Tutor',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: isEnrolled
                          ? Color.fromARGB(255, 221, 42, 29)
                          : Theme.of(context).hintColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
