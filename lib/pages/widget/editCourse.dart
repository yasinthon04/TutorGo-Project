import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditCourse extends StatefulWidget {
  final String courseId;
  final String courseName;
  final String address;
  final String price;
  final String contactInfo;

  EditCourse({
    required this.courseId,
    required this.courseName,
    required this.address,
    required this.price,
    required this.contactInfo,
  });

  @override
  _EditCourseState createState() => _EditCourseState();
}

class _EditCourseState extends State<EditCourse> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _courseNameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _contactInfoController = TextEditingController();

  @override
  void initState() {
    _courseNameController = TextEditingController(text: widget.courseName);
    _addressController = TextEditingController(text: widget.address);
    _priceController = TextEditingController(text: widget.price);
    _contactInfoController = TextEditingController(text: widget.contactInfo);
    super.initState();
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Get the updated form field values
      String courseName = _courseNameController.text;
      String address = _addressController.text;
      String price = _priceController.text;
      String contactInfo = _contactInfoController.text;

      try {
        // Update the course information in Firestore
        await FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .update({
          'courseName': courseName,
          'address': address,
          'price': price,
          'contactInfo': contactInfo,
        });

        // Close the dialog
        Navigator.pop(context);
      } catch (e) {
        print('Error updating course information: $e');
        // Show an error message or handle the error accordingly
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Course'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _courseNameController,
              decoration: InputDecoration(labelText: 'Course Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a course name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(labelText: 'Address'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an address';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'Price'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _contactInfoController,
              decoration: InputDecoration(labelText: 'Contact Information'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter contact information';
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
          child: Text('Save'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }
}
