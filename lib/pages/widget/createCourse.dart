import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:tutorgo/pages/widget/header_widget.dart';

class CreateCourse extends StatefulWidget {
  @override
  _CreateCourseState createState() => _CreateCourseState();
}

class _CreateCourseState extends State<CreateCourse> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController _googleMapsLinkController =
      TextEditingController();

  String _selectedCategory = 'Math'; // Default category
  List<String> _selectedDays = []; // Store selected days of the week
  List<TimeOfDay> _selectedTimes = []; // Store selected time slots
  List<DropdownMenuItem<String>> _provinceItems = []; // List of province items
  String? _selectedProvince = ''; // Selected province
  File? _imageFile;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    _selectedProvince =
        _provinceItems.isNotEmpty ? _provinceItems[0].value : '';
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _contactInfoController.dispose();
    addressController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Get the form field values
      String courseName = _courseNameController.text;
      String contactInfo = _contactInfoController.text;
      String address = addressController.text;
      String price = priceController.text;
      String googleMapsLink = _googleMapsLinkController.text;

      List<Map<String, dynamic>> timeData =
          _convertTimeOfDayList(_selectedTimes);
      List<String> enrolledStudents = [];
      List<String> requestedStudents = [];

      // Upload image to Firebase Storage
      if (_imageFile != null) {
        String imageName = DateTime.now().microsecondsSinceEpoch.toString();
        firebase_storage.Reference storageRef = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('coursePicture')
            .child(imageName);
        await storageRef.putFile(_imageFile!);
        String imageUrl = await storageRef.getDownloadURL();

        // Save the course data to Firestore
        await FirebaseFirestore.instance.collection('courses').add({
          'courseName': courseName,
          'contactInfo': contactInfo,
          'address': address,
          'category': _selectedCategory,
          'province': _selectedProvince,
          'price': price,
          'date': _selectedDays,
          'time': timeData,
          'imageName': imageUrl,
          'googleMapsLink': googleMapsLink,
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'enrolledStudents': enrolledStudents,
          'requestedStudents': requestedStudents,
        });
      }

      // Close the dialog
      Navigator.pop(context);
    }
  }

  List<Map<String, dynamic>> _convertTimeOfDayList(List<TimeOfDay> times) {
    return times.map((time) {
      return {
        'hour': time.hour,
        'minute': time.minute,
      };
    }).toList();
  }

  Future<void> _loadProvinces() async {
    try {
      String data = await rootBundle.loadString('lib/assets/provinces.json');
      List<dynamic> provincesData = json.decode(data);
      // print("Loaded province data: $provincesData"); // Debug print
      setState(() {
        _provinceItems =
            provincesData.map<DropdownMenuItem<String>>((province) {
          return DropdownMenuItem<String>(
            value: province as String, // Ensure province is treated as a String
            child: Text(province),
          );
        }).toList();
        _selectedProvince =
            _provinceItems.isNotEmpty ? _provinceItems[0].value : '';
      });
    } catch (error) {
      print("Error loading provinces: $error"); // Debug print
    }
  }

  Widget _buildDayCheckBox(String day) {
    return Row(
      children: [
        Checkbox(
          value: _selectedDays.contains(day),
          onChanged: (value) {
            setState(() {
              if (value!) {
                _selectedDays.add(day);
              } else {
                _selectedDays.remove(day);
              }
            });
          },
        ),
        Text(day),
      ],
    );
  }

  Widget _buildTimePicker(int index) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () => _selectTime(context, index),
          child: Text(
            'Select Time ${index + 1}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            primary: Theme.of(context).hintColor,
          ),
        ),
        SizedBox(width: 10),
        Text(
          'Time ${index + 1}: ${_selectedTimes.length > index ? _selectedTimes[index].format(context) : "Not selected"}',
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimes.length > index
          ? _selectedTimes[index]
          : TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      setState(() {
        if (_selectedTimes.length > index) {
          _selectedTimes[index] = picked;
        } else {
          _selectedTimes.add(picked);
        }
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage != null) {
        setState(() {
          _imageFile = File(pickedImage.path);
          _selectedImage = File(pickedImage.path);
        });
        print("Image picked: ${_imageFile?.path}"); // Debug print
      }
    } catch (error) {
      print("Error picking image: $error"); // Debug print
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Course ',
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
              padding: EdgeInsets.symmetric(
                  horizontal: 50), // Add horizontal padding
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
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedCategory = newValue!;
                        });
                      },
                      items: [
                        'Math',
                        'Science',
                        'English',
                        'Social',
                        'Thai',
                        'Art'
                      ]
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
                    DropdownButtonFormField<String>(
                      value: _selectedProvince,
                      onChanged: (newValue) {
                        print("Selected province: $newValue"); // Debug print
                        setState(() {
                          _selectedProvince = newValue!;
                        });
                      },
                      items: _provinceItems,
                      decoration: InputDecoration(labelText: 'Select Province'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: priceController,
                      decoration: InputDecoration(labelText: 'Price'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    if (_selectedImage != null)
                      Image.file(
                        _selectedImage!,
                        width: 200, // Adjust the width as needed
                        height: 200, // Adjust the height as needed
                      ),
                    ElevatedButton(
                      onPressed: () => _pickImage(ImageSource
                          .gallery), // Opens image picker from gallery
                      child: Text(
                        'Select Image',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Theme.of(context).hintColor,
                      ),
                    ),
                    
                    SizedBox(height: 10),
                    Text('Select Days of the Week:'),
                    Column(
                      children: [
                        _buildDayCheckBox('Sunday'),
                        _buildDayCheckBox('Monday'),
                        _buildDayCheckBox('Tuesday'),
                        _buildDayCheckBox('Wednesday'),
                        _buildDayCheckBox('Thursday'),
                        _buildDayCheckBox('Friday'),
                        _buildDayCheckBox('Saturday'),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text('Select Time Slots:'),
                    for (int i = 0; i < 2; i++) _buildTimePicker(i),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _submitForm,
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
