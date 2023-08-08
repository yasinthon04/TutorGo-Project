import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
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
  final TextEditingController _contactInfoController = TextEditingController();
  String _selectedCategory = 'Math'; // Default category
  List<String> _selectedDays = []; // Store selected days of the week
  List<TimeOfDay> _selectedTimes = []; // Store selected time slots
  List<DropdownMenuItem<String>> _provinceItems = []; // List of province items
  String _selectedProvince = ''; // Selected province
  int _selectedPrice = 0; // Selected price
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadProvinces(); // Load provinces when initializing the widget
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Get the form field values
      String courseName = _courseNameController.text;
      String contactInfo = _contactInfoController.text;

      List<Map<String, dynamic>> timeData =
          _convertTimeOfDayList(_selectedTimes);

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
          'category': _selectedCategory,
          'province': _selectedProvince,
          'price': _selectedPrice,
          'date': _selectedDays,
          'time': timeData,
          'imageName': imageUrl,
          'userId': FirebaseAuth.instance.currentUser?.uid,
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
      String data = await rootBundle.loadString('assets/provinces.json');
      List<dynamic> provincesData = json.decode(data);
      print("Loaded province data: $provincesData"); // Debug print
      setState(() {
        _provinceItems =
            provincesData.map<DropdownMenuItem<String>>((province) {
          return DropdownMenuItem<String>(
            value: province['name'],
            child: Text(province['name']),
          );
        }).toList();
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
        title: Text('Create Course'),
      ),
      body: SingleChildScrollView(
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
                decoration: InputDecoration(labelText: 'Contact Information'),
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
              DropdownButtonFormField<String>(
                value: _selectedProvince,
                onChanged: (newValue) {
                  setState(() {
                    _selectedProvince = newValue!;
                  });
                },
                items: _provinceItems,
                decoration: InputDecoration(labelText: 'Select Province'),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0 ฿'),
                  Text('9,999 ฿'),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  // Customize the appearance of the slider
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 20.0),
                ),
                child: Slider(
                  value: _selectedPrice.toDouble(),
                  min: 0,
                  max: 9999,
                  onChanged: (value) {
                    setState(() {
                      _selectedPrice = value.toInt();
                    });
                  },
                  divisions: 9999,
                  label: 'Price: $_selectedPrice baht',
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _pickImage(
                    ImageSource.gallery), // Opens image picker from gallery
                child: Text('Select Image'),
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
    );
  }
}
