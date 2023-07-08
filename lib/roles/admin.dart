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
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin"),
        actions: [
          IconButton(
            onPressed: refreshUsers, // Call the refresh function
            icon: Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: userList.length,
        itemBuilder: (context, index) {
          String firstname = userList[index]['firstname'] ?? 'N/A';
          String lastname = userList[index]['lastname'] ?? 'N/A';
          String fullName = '$firstname $lastname';

          String email = userList[index]['email'] ?? 'N/A';

          String profilePicture = userList[index]['profilePicture'] ?? '';

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(profilePicture),
            ),
            title: Text(fullName),
            subtitle: Text(email),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    editUser(userList[index], index);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteUser(userList[index]['userId']);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(photoUrl),
                  radius: 40,
                ),
                ElevatedButton(
                  onPressed: updatePhoto,
                  child: Text('Edit Photo'),
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
              ],
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
                    });
                  }

                  Navigator.of(context).pop();
                },
                child: Text('Save'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
            ],
          );
        },
      );
    } else {
      print('User ID not found in userData');
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updatedData) async {
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
}
