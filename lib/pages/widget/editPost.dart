import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tutorgo/pages/navpage/PostCoursePage.dart';
import 'package:tutorgo/pages/widget/header_widget.dart';

class EditPostPage extends StatefulWidget {
  final Map<String, dynamic> postCourseData;
  final String? postCourseId;

  const EditPostPage({required this.postCourseData, this.postCourseId});

  @override
  _EditPostPageState createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _courseNameController;
  late TextEditingController _addressController;
  late TextEditingController _contactInfoController;
  late TextEditingController _priceController;
  late TextEditingController _googleMapsLinkController;
  late TextEditingController _imageUrlController;
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    _courseNameController =
        TextEditingController(text: widget.postCourseData['courseName']);
    _addressController =
        TextEditingController(text: widget.postCourseData['address']);
    _contactInfoController =
        TextEditingController(text: widget.postCourseData['contactInfo']);
    _priceController =
        TextEditingController(text: widget.postCourseData['price'].toString());
    _googleMapsLinkController =
        TextEditingController(text: widget.postCourseData['googleMapsLink']);
    _imageUrlController =
        TextEditingController(text: widget.postCourseData['imageUrl']);
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _addressController.dispose();
    _contactInfoController.dispose();
    _priceController.dispose();
    _googleMapsLinkController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _updatePostCourseData() async {
    print('Post Course ID: ${widget.postCourseData['postCourseId']}');
    print('Data to update: ${{
      'courseName': _courseNameController.text,
      'address': _addressController.text,
      'contactInfo': _contactInfoController.text,
      'price': int.tryParse(_priceController.text) ?? 0,
      'googleMapsLink': _googleMapsLinkController.text,
      'imageUrl': _imageUrlController.text,
    }}');
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User is not authenticated.');
      return;
    }

    // Check if the userId in postCourseData matches the authenticated user's ID
    if (widget.postCourseData['userId'] != user.uid) {
      print('User is not authorized to edit this post.');
      return;
    }

    try {
      if (_pickedImage != null) {
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('postCoursePicture')
            .child('postCourseImage${DateTime.now()}.jpg');

        // Upload the image with correct content type
        UploadTask uploadTask = ref.putFile(
          File(_pickedImage!.path),
          SettableMetadata(
              contentType: 'image/jpeg'), // Adjust content type if needed
        );

        TaskSnapshot taskSnapshot = await uploadTask;
        String imageUrl = await taskSnapshot.ref.getDownloadURL();

        setState(() {
          _imageUrlController.text = imageUrl;
        });
      }

      await FirebaseFirestore.instance
          .collection('postCourse')
          .doc(widget.postCourseId)
          .update({
        'courseName': _courseNameController.text,
        'address': _addressController.text,
        'contactInfo': _contactInfoController.text,
        'price': int.tryParse(_priceController.text) ?? 0,
        'googleMapsLink': _googleMapsLinkController.text,
        'imageUrl': _imageUrlController.text,
      });
      // Close the edit page and return to the previous screen
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PostCoursePage()),
      );
    } catch (e) {
      print('Error updating document: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _pickedImage = pickedImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Post',
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _courseNameController,
                      decoration: InputDecoration(labelText: 'Course Name'),
                      validator: (value) {
                        if (value!.trim().isEmpty) {
                          return "Course Name cannot be empty";
                        }
                        if (value.length > 35) {
                          return "Course Name should not exceed 35 characters";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _contactInfoController,
                      keyboardType: TextInputType.number,
                      decoration:
                          InputDecoration(labelText: 'Contact Information'),
                      validator: (value) {
                        if (value!.trim().isEmpty) {
                          return "Contact Information cannot be empty";
                        }
                        if (value.length != 10) {
                          return "Contact Information should be 10 digits";
                        }
                        return null;
                      },
                    ),
                    
                    TextFormField(
                      controller: _addressController,
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
                    TextFormField(
                      controller:
                          _googleMapsLinkController, // Add a TextEditingController
                      decoration: InputDecoration(
                          labelText:
                              'Google Maps Link(Example: https://goo.gl/maps/KiYNop6sMFmdZeM38)'),
                      validator: (value) {
                        if (value!.trim().isEmpty) {
                          return "Google Maps Link cannot be empty";
                        }
                        // You can add more validation logic here if needed
                        return null;
                      },
                    ),
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
                    SizedBox(height: 20),
                    if (_imageUrlController.text.isNotEmpty)
                      Image.network(
                        _imageUrlController.text,
                        height: 100.0,
                        width: 100.0,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: Text('Upload New Image',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Theme.of(context).hintColor,
                      ),),
                    
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _updatePostCourseData,
                          child: Text(
                            'Save',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.green,
                          ),
                        ),
                        SizedBox(width: 10), // Add spacing between buttons
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
                            primary: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
