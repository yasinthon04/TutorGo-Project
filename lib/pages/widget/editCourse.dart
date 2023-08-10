import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:tutorgo/pages/widget/header_widget.dart';

class EditCourse extends StatefulWidget {
  final String courseId;
  final String CourseName;
  final String Address;
  final String Price;
  final String ContactInfo;
  final String Province;
  final String CourseImage;
  final String Category;
  final List<String> Days;
  final List<Map<String, dynamic>> Times;

  EditCourse({
    required this.courseId,
    required this.CourseName,
    required this.Address,
    required this.Price,
    required this.ContactInfo,
    required this.Province,
    required this.CourseImage,
    required this.Category,
    required this.Days,
    required this.Times,
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
  String _selectedCategory = ''; // Default category
  List<String> _selectedDays = []; // Store selected days of the week
  List<TimeOfDay> _selectedTimes = []; // Store selected time slots
  List<DropdownMenuItem<String>> _provinceItems = []; // List of province items
  String? _selectedProvince = ''; // Set an initial value
  File? _imageFile;

  @override
  void initState() {
    print('Received courseId: ${widget.courseId}');
    _courseNameController = TextEditingController(text: widget.CourseName);
    _addressController = TextEditingController(text: widget.Address);
    _priceController = TextEditingController(text: widget.Price);
    _contactInfoController = TextEditingController(text: widget.ContactInfo);
    _imageFile = File(widget.CourseImage);
    _selectedCategory = widget.Category;
    _selectedDays = List<String>.from(widget.Days); // No need for split
    _selectedTimes = _convertTimeMapListToTimeOfDayList(widget.Times);
    _loadProvinces().then((_) {
      setState(() {
        // Set the selected province to the current province if available
        if (_provinceItems.isNotEmpty) {
          _selectedProvince = _provinceItems[0].value;
          if (_provinceItems.any((item) => item.value == widget.Province)) {
            _selectedProvince = widget.Province;
          }
        }
      });
    });
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
    print('Using courseId in _submitForm: ${widget.courseId}');
    if (_formKey.currentState!.validate()) {
      // Get the form field values
      String courseName = _courseNameController.text;
      String contactInfo = _contactInfoController.text;
      String address = _addressController.text;
      String price = _priceController.text;

      List<Map<String, dynamic>> timeData =
          _convertTimeOfDayList(_selectedTimes);

      // Update image if selected
      String imageUrl = widget.CourseImage; // Get the existing image URL
      if (_imageFile != null) {
        String imageName = DateTime.now().microsecondsSinceEpoch.toString();
        firebase_storage.Reference storageRef = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('coursePicture')
            .child(imageName);
        await storageRef.putFile(_imageFile!);
        imageUrl = await storageRef.getDownloadURL();
      }
      String currentCourseId = widget.courseId;
      if (_selectedProvince != null && _selectedProvince!.isNotEmpty) {
        print('courseId: ${widget.courseId}');
        print('imageUrl: $imageUrl');
        print('selectedProvince: $_selectedProvince');
        // Update the course data in Firestore
        try {
          await FirebaseFirestore.instance
              .collection('courses')
              .doc(currentCourseId)
              .update({
            'courseName': courseName,
            'contactInfo': contactInfo,
            'address': address,
            'category': _selectedCategory,
            'province': _selectedProvince,
            'price': price,
            'date': _selectedDays,
            'time': timeData,
            'imageName': imageUrl,
          });
        } catch (error) {
          print('Firestore Update Error: $error');
        }
      } else {
        print("Selected province is null or empty.");
      }

      // Close the dialog
      Navigator.pop(context);
    }
  }

  List<TimeOfDay> _convertTimeMapListToTimeOfDayList(
      List<Map<String, dynamic>> times) {
    return times.map((timeMap) {
      return TimeOfDay(hour: timeMap['hour'], minute: timeMap['minute']);
    }).toList();
  }

  List<TimeOfDay> _convertTimeDataToList(String times) {
    List<String> timeStrings =
        times.split(','); // Assuming times are comma-separated
    return timeStrings.map((timeString) {
      List<String> parts = timeString.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }).toList();
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
      print("Loaded province data: $provincesData"); // Debug print
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
          'Edit Course ',
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
            Form(
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
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    items:
                        ['Math', 'Science', 'English', 'Social', 'Thai', 'Art']
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
                    value: _selectedProvince ??
                        '', // Use an empty string as default value
                    onChanged: (newValue) {
                      setState(() {
                        _selectedProvince = newValue!;
                      });
                    },
                    items: _provinceItems, // Use the populated list here
                    decoration: InputDecoration(labelText: 'Select Province'),
                  ),
                  SizedBox(height: 10),
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
          ],
        ),
      ),
    );
  }
}
