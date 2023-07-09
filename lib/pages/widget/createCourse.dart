import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';

class CreateCourse extends StatefulWidget {
  @override
  _CreateCourseState createState() => _CreateCourseState();
}

class _CreateCourseState extends State<CreateCourse> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();
  File? _imageFile;

  @override
  void dispose() {
    _courseNameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Get the form field values
      String courseName = _courseNameController.text;
      String address = _addressController.text;
      String price = _priceController.text;
      String contactInfo = _contactInfoController.text;

      // Upload image to Firebase Storage
      if (_imageFile != null) {
        String imageName = DateTime.now().microsecondsSinceEpoch.toString();
        firebase_storage.Reference storageRef =
            firebase_storage.FirebaseStorage.instance.ref().child(imageName);
        await storageRef.putFile(_imageFile!);
        String imageUrl = await storageRef.getDownloadURL();

        // Save the course data to Firestore
        await FirebaseFirestore.instance.collection('courses').add({
          'courseName': courseName,
          'address': address,
          'price': price,
          'contactInfo': contactInfo,
          'imageName': imageUrl,
          'userId': FirebaseAuth.instance.currentUser?.uid,
        });
      }

      // Close the dialog
      Navigator.pop(context);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedImage = await ImagePicker().pickImage(source: source);
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Course'),
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              child: Text('Add Image Course'),
            ),
            if (_imageFile != null)
              Image.file(
                _imageFile!,
                height: 150,
                width: 150,
              ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: _submitForm,
          child: Text('Submit'),
        ),
      ],
    );
  }
}
