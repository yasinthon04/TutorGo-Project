import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tutorgo/pages/login.dart';
import '../auth.dart';

class Admin extends StatefulWidget {
  const Admin({Key? key}) : super(key: key);

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  List<Map<String, dynamic>> userList = [];
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('firstname')
          .get();
      List<Map<String, dynamic>> users = snapshot.docs.map((doc) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        userData['userId'] = doc.id; // Add the userId field
        return userData;
      }).toList();
      setState(() {
        userList = users;
      });
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  Future<void> refreshUsers() async {
    setState(() {
      userList = []; // Clear the user list before fetching again
    });
    await fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> studentList = [];
    List<Map<String, dynamic>> adminList = [];
    List<Map<String, dynamic>> tutorList = [];

    // Separate the users based on role
    for (var user in userList) {
      if (user['role'] == 'Student') {
        studentList.add(user);
      } else if (user['role'] == 'admin') {
        adminList.add(user);
      } else if (user['role'] == 'Tutor') {
        tutorList.add(user);
      }
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Admin",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          actions: [
            IconButton(
              onPressed: refreshUsers,
              icon: Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: () {
                logout(context);
              },
              icon: Icon(Icons.logout),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Students'),
              Tab(text: 'Tutors'),
              Tab(text: 'Admins'),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            buildUserList(studentList),
            buildUserList(tutorList),
            buildUserList(adminList),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: addUser,
          child: Icon(Icons.add, color: Colors.white),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget buildUserList(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return Center(child: Text('No users found'));
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        String firstname = users[index]['firstname'] ?? 'N/A';
        String lastname = users[index]['lastname'] ?? 'N/A';
        String fullName = '$firstname $lastname';
        String email = users[index]['email'] ?? 'N/A';
        String profilePicture = users[index]['profilePicture'] ?? '';

        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              ExpansionTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(profilePicture),
                ),
                title: Text(fullName),
                subtitle: Text(email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (users[index]['role'] == 'Student' ||
                        users[index]['role'] ==
                            'Tutor') // Show icons only for Student and Tutor roles
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          editUser(users[index], index);
                        },
                        color: Colors.blue,
                      ),
                    if (users[index]['role'] == 'Student' ||
                        users[index]['role'] ==
                            'Tutor') // Show icons only for Student and Tutor roles
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          deleteUser(users[index]['userId']);
                        },
                        color: Colors.red,
                      ),
                  ],
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Role: ${users[index]['role']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        if (users[index]['role'] ==
                            'Tutor') // Show courses only for tutors
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('courses')
                                .where('userId',
                                    isEqualTo: users[index]['userId'])
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('Error loading courses');
                              } else {
                                final courseDocs = snapshot.data!.docs;
                                if (courseDocs.isNotEmpty) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Courses:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      ...courseDocs.map((courseDoc) {
                                        final courseData = courseDoc.data()
                                            as Map<String, dynamic>;
                                        final courseName =
                                            courseData['courseName'] ?? '';

                                        return ListTile(
                                          title: Text(courseName),
                                          onTap: () {
                                            showCourseInfo(courseData);
                                          },
                                          trailing: IconButton(
                                            icon: Icon(Icons.delete),
                                            onPressed: () {
                                              deleteCourse(
                                                  context, courseDoc.id);
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  );
                                } else {
                                  return Text('No courses found');
                                }
                              }
                            },
                          ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void addUser() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController emailController = TextEditingController();
        final TextEditingController passwordController =
            new TextEditingController();
        final TextEditingController firstnameController =
            TextEditingController();
        final TextEditingController lastnameController =
            TextEditingController();
        final TextEditingController mobileController = TextEditingController();
        String? selectedRole;
        String? photoUrl;

        Future<void> addPhoto() async {
          final picker = ImagePicker();
          final pickedFile =
              await picker.pickImage(source: ImageSource.gallery);

          if (pickedFile != null) {
            try {
              final storage = FirebaseStorage.instance;
              final fileName = DateTime.now().millisecondsSinceEpoch.toString();
              final reference = storage.ref().child('profilePicture/$fileName');
              final uploadTask = reference.putFile(File(pickedFile.path));
              final snapshot = await uploadTask;

              if (snapshot.state == TaskState.success) {
                final downloadUrl = await reference.getDownloadURL();
                setState(() {
                  photoUrl = downloadUrl;
                });
              } else {
                print('Failed to upload photo');
              }
            } catch (e) {
              print('Error uploading photo: $e');
            }
          }
        }

        return AlertDialog(
          title: Text('Add User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl!) : null,
                  radius: 40,
                ),
                ElevatedButton(
                  onPressed: addPhoto,
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                  ),
                  child: Text(
                    'Add Photo',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                  ),
                  controller: emailController,
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                  ),
                  controller: passwordController,
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'First Name',
                  ),
                  controller: firstnameController,
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                  ),
                  controller: lastnameController,
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Mobile',
                  ),
                  controller: mobileController,
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Role',
                  ),
                  value: selectedRole,
                  items: [
                    DropdownMenuItem(
                      value: 'Student',
                      child: Text('Student'),
                    ),
                    DropdownMenuItem(
                      value: 'Tutor',
                      child: Text('Tutor'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String email = emailController.text;
                String password = passwordController.text;
                String firstname = firstnameController.text;
                String lastname = lastnameController.text;
                String mobile = mobileController.text;

                createUser(email, password, firstname, lastname, mobile,
                    selectedRole!, photoUrl);
                Navigator.of(context).pop();
              },
              child: Text(
                'Add',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.green,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).hintColor,
              ),
            ),
          ],
        );
      },
    );
  }

  void createUser(String email, String password, String firstname,
      String lastname, String mobile, String? role, String? photoUrl) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userId = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'email': email,
        'firstname': firstname,
        'lastname': lastname,
        'mobile': mobile,
        'role': role,
        'profilePicture': photoUrl,
      });
      print('User created successfully');
    } catch (e) {
      print('Failed to create user: $e');
    }
  }

  void editUser(Map<String, dynamic> userData, int index) {
    String? userId = userData['userId'] as String?;
    if (userId != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          _firstnameController.text = userData['firstname'];
          _lastnameController.text = userData['lastname'];
          _emailController.text = userData['email'];
          _mobileController.text = userData['mobile'];
          String photoUrl = userData['profilePicture'] ?? '';
          String selectedRole = userData['role'] ?? '';

          Future<void> updatePhoto() async {
            final picker = ImagePicker();
            final pickedFile =
                await picker.pickImage(source: ImageSource.gallery);

            if (pickedFile != null) {
              try {
                final storage = FirebaseStorage.instance;
                final fileName =
                    DateTime.now().millisecondsSinceEpoch.toString();
                final reference =
                    storage.ref().child('profilePicture/$fileName');
                final uploadTask = reference.putFile(File(pickedFile.path));
                final snapshot = await uploadTask;

                if (snapshot.state == TaskState.success) {
                  final downloadUrl = await reference.getDownloadURL();
                  setState(() {
                    photoUrl = downloadUrl;
                    userList[index]['profilePicture'] = downloadUrl;
                  });
                  updateUser(userId, {
                    'profilePicture': downloadUrl,
                  });
                } else {
                  print('Failed to upload photo');
                }
              } catch (e) {
                print('Error uploading photo: $e');
              }
            }
          }

          return AlertDialog(
            title: Text('Edit User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(photoUrl),
                    radius: 40,
                  ),
                  ElevatedButton(
                    onPressed: updatePhoto,
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                    ),
                    child: Text(
                      'Edit Photo',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'First Name',
                    ),
                    controller: _firstnameController,
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                    ),
                    controller: _lastnameController,
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                    ),
                    controller: _emailController,
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Mobile',
                    ),
                    controller: _mobileController,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Role',
                    ),
                    value: selectedRole,
                    items: [
                      DropdownMenuItem(
                        value: 'Student',
                        child: Text('Student'),
                      ),
                      DropdownMenuItem(
                        value: 'Tutor',
                        child: Text('Tutor'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  String updatedEmail = _emailController.text;
                  String updatedFirstname = _firstnameController.text;
                  String updatedLastname = _lastnameController.text;
                  String updatedMobile = _mobileController.text;

                  if (userId != null) {
                    updateUser(userId, {
                      'email': updatedEmail,
                      'firstname': updatedFirstname,
                      'lastname': updatedLastname,
                      'mobile': updatedMobile,
                      'role': selectedRole, // Update the role field
                    });
                  }

                  Navigator.of(context).pop();
                },
                child: Text(
                  'Save',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  primary: Colors.green,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  primary: Theme.of(context).hintColor,
                ),
              ),
            ],
          );
        },
      );
    } else {
      print('User ID not found in userData');
    }
  }

  Future<void> updateUser(
      String userId, Map<String, dynamic> updatedData) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(updatedData);
      print('User updated successfully');
    } catch (e) {
      print('Failed to update user: $e');
    }
  }

  void deleteUser(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this user?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).hintColor,
              ),
            ),
            TextButton(
              onPressed: () {
                deleteConfirmedUser(userId);
                Navigator.of(context).pop();
              },
              child: Text(
                'Delete',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  void deleteConfirmedUser(String userId) {
    try {
      FirebaseFirestore.instance.collection('users').doc(userId).delete();
      print('User deleted successfully');
    } catch (e) {
      print('Failed to delete user: $e');
    }
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(),
      ),
    );
  }

  void showCourseInfo(Map<String, dynamic> courseData) {
    String courseName = courseData['courseName'] ?? '';
    String address = courseData['address'] ?? '';
    String price = courseData['price'] ?? '';
    String contactInfo = courseData['contactInfo'] ?? '';
    String courseImage = courseData['imageName'] ?? ''; // Add this line

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Course Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (courseImage.isNotEmpty) // Add this condition
                Image.network(courseImage),
              SizedBox(
                height: 10,
              ), // Display the course image
              Text('Course Name: $courseName'),
              Text('Address: $address'),
              Text('Price: $price'),
              Text('Contact Information: $contactInfo'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void deleteCourse(BuildContext context, String courseId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this course?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                'Cancel',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).hintColor,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('courses')
                      .doc(courseId)
                      .delete();
                  print('Course deleted successfully');
                  Navigator.pop(context); // Close the dialog
                } catch (e) {
                  print('Failed to delete course: $e');
                }
              },
              child: Text(
                'Delete',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }
}
