import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../navpage/home.dart';

class DeleteCourse extends StatefulWidget {
  final String CourseId;
  final String CourseName;
  final String userId;

  DeleteCourse({required this.CourseId, required this.CourseName, required this.userId});

  @override
  _DeleteCourseState createState() => _DeleteCourseState();
}

class _DeleteCourseState extends State<DeleteCourse> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _courseNameController = TextEditingController();

  @override
  void dispose() {
    _courseNameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Get the entered course name
      final enteredCourseName = _courseNameController.text;

      // Check if the entered course name matches the actual course name and the user ID matches
      if (enteredCourseName == widget.CourseName && widget.userId == FirebaseAuth.instance.currentUser?.uid) {
        try {
          // Delete the course document from Firestore
          await FirebaseFirestore.instance
              .collection('courses')
              .doc(widget.CourseId)
              .delete();

          // Close the dialog
          Navigator.pop(context);
        } catch (error) {
          // Handle any errors that occurred during deletion
          print('Error deleting course: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete the course')),
          );
        }
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
      } else {
        // Show an error message for incorrect course name or unauthorized user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Incorrect course name or unauthorized user')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Delete Course'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to delete the course?'),
            SizedBox(height: 10),
            TextFormField(
              controller: _courseNameController,
              decoration: InputDecoration(labelText: 'Course Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the course name to confirm';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: _submitForm,
          child: Text(
            'Delete',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            primary: Colors.red, // Set the button color here
          ),
        ),
        ElevatedButton(
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
            primary: Theme.of(context).hintColor, // Set the button color here
          ),
        ),
      ],
    );
  }
}
