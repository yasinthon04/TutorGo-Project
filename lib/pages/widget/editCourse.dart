import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:tutorgo/pages/widget/header_widget.dart';
import 'package:flutter/widgets.dart' show NetworkImage;

class EditCourse extends StatefulWidget {
  final String CourseId;
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
    required this.CourseId,
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
  TextEditingController _contactInfoController = TextEditingController();
  String _selectedCategory = ''; // Default category
  List<String> _selectedDays = []; // Store selected days of the week
  List<TimeOfDay> _selectedTimes = []; // Store selected time slots
  List<DropdownMenuItem<String>> _provinceItems = []; // List of province items
  String? _selectedProvince = ''; // Set an initial value
  File? _imageFile;
  double _selectedPrice = 0;

  @override
  void initState() {
    _loadCourseData();
    _courseNameController = TextEditingController(text: widget.CourseName);
    _addressController = TextEditingController(text: widget.Address);
    _selectedPrice = double.tryParse(widget.Price) ?? 0;
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
    _contactInfoController.dispose();

    super.dispose();
  }

  Future<void> _loadCourseData() async {
    // Fetch necessary data from Firestore
    // For example, fetch course data based on widget.courseId
    DocumentSnapshot courseSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.CourseId)
        .get();

    Map<String, dynamic> courseData =
        courseSnapshot.data() as Map<String, dynamic>;
    String imageUrl = courseData['imageName']; // Get the existing image URL

    // Create a temporary File object to hold the image
    File tempImageFile = File('');

    // Download the image and store it in the temporary file
    try {
      tempImageFile = File(await DefaultCacheManager()
          .getSingleFile(imageUrl)
          .then((value) => value.path));
    } catch (error) {
      print('Error downloading image: $error');
    }
    setState(() {
      _courseNameController =
          TextEditingController(text: courseData['courseName']);
      _addressController = TextEditingController(text: courseData['address']);
      _selectedPrice = double.tryParse(courseData['price']) ?? 0;
      _contactInfoController =
          TextEditingController(text: courseData['contactInfo']);
      _selectedProvince = courseData['province'];
      _imageFile = tempImageFile;
      _selectedCategory = courseData['category'];
      _selectedDays = List<String>.from(courseData['date']);
      _selectedTimes = _convertTimeMapListToTimeOfDayList(courseData['time']);
    });
  }

  void _submitForm() async {
    print('Using courseId in _submitForm: ${widget.CourseId}');

    if (_formKey.currentState!.validate()) {
      // Get the form field values
      String courseName = _courseNameController.text;
      String contactInfo = _contactInfoController.text;
      String address = _addressController.text;
      String selectedPriceText = NumberFormat.currency(
        locale: 'en_US', // Change locale as needed
        symbol: '฿',
      ).format(_selectedPrice);

      List<Map<String, dynamic>> timeData =
          _convertTimeOfDayList(_selectedTimes);
      List<String> enrolledStudents = [];
      List<String> requestedStudents = [];

      // Update image if selected
      String imageUrl = widget.CourseImage; // Get the existing image URL
      if (_imageFile != null && _imageFile!.absolute.existsSync()) {
        String imageName = DateTime.now().microsecondsSinceEpoch.toString();
        firebase_storage.Reference storageRef = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('coursePicture')
            .child(imageName);
        await storageRef.putFile(_imageFile!);
        imageUrl = await storageRef.getDownloadURL();
      } else {
        print("Image file does not exist or is null.");
      }
      String currentCourseId = widget.CourseId;
      if (_selectedProvince != null && _selectedProvince!.isNotEmpty) {
        // Update the course data in Firestore
        try {
          await FirebaseFirestore.instance
              .collection('courses')
              .doc(widget.CourseId)
              .update({
            'courseName': courseName,
            'contactInfo': contactInfo,
            'address': address,
            'category': _selectedCategory,
            'province': _selectedProvince,
            'price': selectedPriceText,
            'date': _selectedDays,
            'time': timeData,
            'imageName': imageUrl,
            'userId': FirebaseAuth.instance.currentUser?.uid,
            'enrolledStudents': enrolledStudents,
            'requestedStudents': requestedStudents,
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

  List<TimeOfDay> _convertTimeMapListToTimeOfDayList(List<dynamic> times) {
    // Change the parameter type to List<dynamic>
    return times.map((timeMap) {
      if (timeMap is Map<String, dynamic>) {
        // Check if timeMap is a valid map
        return TimeOfDay(hour: timeMap['hour'], minute: timeMap['minute']);
      } else {
        // Handle the case when the timeMap is not in the expected format
        // For example, return a default TimeOfDay or log an error
        return TimeOfDay(hour: 0, minute: 0);
      }
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
    final isSelected = _selectedDays.contains(day);
    return Row(
      children: [
        Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value!) {
                _selectedDays.add(day);
              } else {
                _selectedDays.remove(day);
              }
            });
          },
          activeColor:
              isSelected ? Colors.green : Colors.grey, // Change color here
        ),
        Text(
          day,
          style: TextStyle(
            color:
                isSelected ? Colors.green : Colors.black, // Change color here
          ),
        ),
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
                    Slider(
                      value: _selectedPrice,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedPrice = newValue;
                        });
                      },
                      min: 0,
                      max: 9999,
                      divisions: 9999,
                      label: NumberFormat.currency(
                        locale: 'en_US', // Change locale as needed
                        symbol: '฿',
                      ).format(_selectedPrice),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _selectedPrice != null
                          ? NumberFormat.currency(
                              locale: 'en_US', // Change locale as needed
                              symbol: '฿',
                              decimalDigits: 0, // Display 0 decimal digits
                            ).format(_selectedPrice)
                          : '0 ฿',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Container(
                      height: 200,
                      width: 200,
                      child: _imageFile != null
                          ? Image.file(_imageFile!)
                          : widget.CourseImage.isNotEmpty
                              ? Image.network(
                                  widget.CourseImage,
                                  fit: BoxFit.cover,
                                )
                              : Placeholder(),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: 20), // Add some spacing above the section

                        // Select Days of the Week
                        Text(
                          'Select days of the week:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8, // Adjust the spacing between checkboxes
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
                        SizedBox(
                            height: 20), // Add some spacing below the section

                        // Select Time Slots
                        Text(
                          'Select time slots:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Column(
                          children: [
                            for (int i = 0; i < 2; i++) _buildTimePicker(i),
                          ],
                        ),
                        SizedBox(
                            height: 20), // Add some spacing below the section
                      ],
                    ),
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
            )
          ],
        ),
      ),
    );
  }
}
