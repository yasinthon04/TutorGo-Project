import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PostCourse extends StatefulWidget {
  @override
  _PostCourseState createState() => _PostCourseState();
}

class _PostCourseState extends State<PostCourse> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController _googleMapsLinkController =
      TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String _selectedCategory = 'Math';
  File? _imageFile;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage != null) {
        setState(() {
          _imageFile = File(pickedImage.path);
        });
      }
    } catch (error) {
      print("Error picking image: $error");
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      String courseName = _courseNameController.text;
      String contactInfo = _contactInfoController.text;
      String address = addressController.text;
      // int price = int.tryParse(_priceController.text ?? '0') ?? 0;
      int price = int.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;
      String googleMapsLink = _googleMapsLinkController.text;
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (_imageFile != null) {
        String imageName = DateTime.now().microsecondsSinceEpoch.toString();
        firebase_storage.Reference storageRef = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('postCoursePicture')
            .child(imageName);
        await storageRef.putFile(_imageFile!);
        String imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance.collection('postCourse').add({
          'courseName': courseName,
          'contactInfo': contactInfo,
          'price': price,
          'address': address,
          'googleMapsLink': googleMapsLink,
          'imageUrl': imageUrl,
          'userId': userId,
        });
      }
      Navigator.of(context).pop(); // Close the dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Post Course Information',
        style: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _courseNameController,
                decoration: InputDecoration(labelText: 'Course Name'),
                validator: (value) {
                  if (value!.trim().isEmpty) {
                    return "Course Name cannot be empty";
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
                items: ['Math', 'Science', 'English', 'Social', 'Thai', 'Art']
                    .map<DropdownMenuItem<String>>(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                decoration: InputDecoration(labelText: 'Select Category'),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price',
                ),
                validator: (value) {
                  if (value!.trim().isEmpty) {
                    return "Price cannot be empty";
                  }

                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _contactInfoController,
                decoration: InputDecoration(labelText: 'Contact Information'),
                validator: (value) {
                  if (value!.trim().isEmpty) {
                    return "Contact Information cannot be empty";
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'Address'),
                validator: (value) {
                  if (value!.trim().isEmpty) {
                    return "Address cannot be empty";
                  }
                  if (value.length > 35) {
                    return "Address should not exceed 35 characters";
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _googleMapsLinkController,
                decoration:
                    InputDecoration(labelText: 'Google Maps Link (Optional)'),
              ),
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                child: Text(
                  'Select Image',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  primary: Theme.of(context).hintColor,
                ),
              ),
              if (_imageFile != null)
                Container(
                  padding: EdgeInsets.all(10.0),
                  child: Image.file(
                    _imageFile!,
                    width: 200,
                    height: 200,
                  ),
                ),
            ],
          ),
        ),
      ),
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
        ElevatedButton(
          onPressed: _submitForm,
          child: Text(
            'Create',
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
                  primary: Colors.green,
                ),
        ),
      ],
    );
  }
}
