import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tutorgo/pages/login.dart';
import 'package:image_picker/image_picker.dart';
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
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();
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

            String profilePicture = userList[index]['profilePicture'] ??
                ''; // Fetch the user's photo URL

            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    NetworkImage(profilePicture), // Display the user's photo
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
                      deleteUser(userList[index]);
                    },
                  ),
                ],
              ),
            );
          },
        ));
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
                    storage.ref().child('profilePictures/$fileName');
                final uploadTask = reference.putFile(File(pickedFile.path));
                final snapshot = await uploadTask.whenComplete(() {});

                if (snapshot.state == TaskState.success) {
                  final downloadUrl = await reference.getDownloadURL();
                  setState(() {
                    photoUrl = downloadUrl; // Update the photo URL
                    userList[index]['profilePicture'] =
                        downloadUrl; // Update the profilePicture field in the user list
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
                    updateUser(
                      userId,
                      updatedFirstname,
                      updatedLastname,
                      updatedEmail,
                      updatedMobile,
                      photoUrl,
                      index, // Pass the updated photo URL
                    );
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

  Future<String> uploadPhotoAndGetUrl(String filePath) async {
    final storage = FirebaseStorage.instance;
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = storage.ref().child('profilePicture').child(fileName);

    final uploadTask = ref.putFile(File(filePath));
    final snapshot = await uploadTask.whenComplete(() {});

    if (snapshot.state == TaskState.success) {
      final photoUrl = await ref.getDownloadURL();
      return photoUrl;
    } else {
      throw Exception('Failed to upload photo');
    }
  }

  void updateUser(
  String userId,
  String? updatedFirstname,
  String? updatedLastname,
  String? updatedEmail,
  String? updatedMobile,
  String? updatedPhotoUrl,
  int index, // Receive the index value
) {
  try {
    FirebaseFirestore.instance.collection('users').doc(userId).update({
      'firstname': updatedFirstname ?? '',
      'lastname': updatedLastname ?? '',
      'email': updatedEmail ?? '',
      'mobile': updatedMobile ?? '',
      'profilePicture': updatedPhotoUrl ?? '',
    }).then((_) {
      setState(() {
        userList[index]['profilePicture'] = updatedPhotoUrl;
      });

      print('User updated successfully');
    }).catchError((error) {
      print('Failed to update user: $error');
    });
  } catch (e) {
    print('Error updating user: $e');
  }
}

  void deleteUser(Map<String, dynamic> userData) {
    print('Delete user: $userData');
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
