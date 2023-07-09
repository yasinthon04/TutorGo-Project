import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:tutorgo/auth.dart';
import 'package:tutorgo/pages/navpage/account.dart';
import 'package:tutorgo/pages/widget/header_widget.dart';
import 'package:flutter/services.dart';
import 'package:tutorgo/pages/login.dart';
import 'package:tutorgo/pages/register.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class updateProfilePage extends StatefulWidget {
  const updateProfilePage({Key? key}) : super(key: key);

  @override
  _updateProfilePageState createState() => _updateProfilePageState();
}

class _updateProfilePageState extends State<updateProfilePage> {
  File? _imageFile;
  final User? user = Auth().currentUser;
  final Reference storageReference =
      FirebaseStorage.instance.ref().child('profilePicture');

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  void _updateUserData(String updatedEmail, String updatedFirstname,
      String updatedLastname, String updatedPhone) {
    FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
      'email': updatedEmail,
      'firstname': updatedFirstname,
      'lastname': updatedLastname,
      'mobile': updatedPhone,
    }).then((value) {
      // Data successfully updated
      print('User data updated successfully');
    }).catchError((error) {
      // Error occurred while updating data
      print('Failed to update user data: $error');
    });
  }

  Widget _userInfo() {
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Text('No data available');
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          String email = userData['email'] ?? 'User email';
          String firstname = userData['firstname'] ?? 'User firstname';
          String lastname = userData['lastname'] ?? 'User lastname';
          String phone = userData['mobile'] ?? 'User mobile';

          _emailController.text = email;
          _firstnameController.text = firstname;
          _lastnameController.text = lastname;
          _phoneController.text = phone;

          return Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'Email', prefixIcon: Icon(Icons.email)),
              ),
              TextFormField(
                controller: _firstnameController,
                decoration: const InputDecoration(
                    labelText: 'Firstname',
                    prefixIcon: Icon(Icons.text_format)),
              ),
              TextFormField(
                controller: _lastnameController,
                decoration: const InputDecoration(
                    labelText: 'Lastname', prefixIcon: Icon(Icons.text_format)),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                    labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
              ),
            ],
          );
        });
  }

  Widget _title() {
    return const Text('Edit Profile');
  }

  Widget _userUid() {
    return Text(
      user?.email ?? 'User email',
      style: Theme.of(context).textTheme.bodyText2,
    );
  }

  void _uploadImage(File imageFile) async {
    // Create a unique filename for the image
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();

    // Create a reference to the file in Firebase storage
    Reference fileReference = storageReference.child(fileName);

    // Upload the file to Firebase storage
    UploadTask uploadTask = fileReference.putFile(imageFile);

    // Get the download URL of the uploaded file
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
    String downloadURL = await taskSnapshot.ref.getDownloadURL();

    // Update the user's profile picture URL in Firestore
    FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
      'profilePicture': downloadURL,
    }).then((value) {
      // Data successfully updated
      print('Profile picture uploaded successfully');
    }).catchError((error) {
      // Error occurred while updating data
      print('Failed to upload profile picture: $error');
    });

    setState(() {
      _imageFile = imageFile;
    });
  }

  Future<File?> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Profile",
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
              ])),
        ),
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              height: 100,
              child: HeaderWidget(100, false, Icons.house_rounded),
            ),
            Container(
              alignment: Alignment.center,
              margin: EdgeInsets.fromLTRB(25, 10, 25, 10),
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Column(
                children: <Widget>[
                  Container(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: ClipOval(
                                  child: _imageFile != null
                                      ? Image.file(_imageFile!,
                                          fit: BoxFit.cover)
                                      : StreamBuilder<DocumentSnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(user?.uid)
                                              .snapshots(),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasError) {
                                              return Text(
                                                  'Error: ${snapshot.error}');
                                            }

                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return CircularProgressIndicator();
                                            }

                                            if (!snapshot.hasData ||
                                                snapshot.data == null) {
                                              return Image.asset(
                                                  'assets/profile-icon.png',
                                                  fit: BoxFit.cover);
                                            }

                                            var userData = snapshot.data!
                                                .data() as Map<String, dynamic>;

                                            String? profilePicture =
                                                userData['profilePicture'];

                                            if (profilePicture != null) {
                                              return Image.network(
                                                profilePicture,
                                                fit: BoxFit.cover,
                                              );
                                            } else {
                                              return Image.asset(
                                                  'assets/profile-icon.png',
                                                  fit: BoxFit.cover);
                                            }
                                          },
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: () async {
                                    File? imageFile = await _pickImage();
                                    if (imageFile != null) {
                                      _uploadImage(imageFile);
                                    }
                                  },
                                  child: Container(
                                    width: 35,
                                    height: 35,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      color: Colors.yellow,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                      )),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      children: <Widget>[
                        Container(
                          padding:
                              const EdgeInsets.only(left: 8.0, bottom: 4.0),
                          alignment: Alignment.topLeft,
                          child: Text(
                            "User Information",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Form(
                          child: Container(
                            alignment: Alignment.topLeft,
                            padding: EdgeInsets.all(15),
                            child: Column(
                              children: <Widget>[
                                Column(
                                  children: <Widget>[
                                    ...ListTile.divideTiles(
                                      color: Colors.grey,
                                      tiles: [
                                        _userInfo(),
                                      ],
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                        onPressed: () {
                          // Get the updated values from the TextFormField widgets
                          String updatedEmail = _emailController.text;
                          String updatedFirstname = _firstnameController.text;
                          String updatedLasttname = _lastnameController.text;
                          String updatedPhone = _phoneController.text;

                          // Call the method to update the user data
                          _updateUserData(updatedEmail, updatedFirstname,
                              updatedLasttname, updatedPhone);
                          Navigator.pop(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AccountPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow,
                            side: BorderSide.none,
                            shape: const StadiumBorder()),
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Colors.black),
                        )),
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