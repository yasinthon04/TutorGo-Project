import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'login.dart';
import 'package:tutorgo/common/theme_helper.dart';
import 'package:tutorgo/pages/widget/header_widget.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as Path;

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  _RegisterState();

  bool showProgress = false;
  bool visible = false;

  final _formkey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final TextEditingController passwordController = new TextEditingController();
  final TextEditingController firstname = new TextEditingController();
  final TextEditingController lastname = new TextEditingController();
  final TextEditingController emailController = new TextEditingController();
  final TextEditingController mobile = new TextEditingController();

  File? file;
  var options = [
    'Student',
    'Tutor',
  ];
  var _currentItemSelected = "Student";
  var role = "Student";

  bool checkedValue = false;
  bool checkboxValue = false;

  File? selectedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              height: 200,
              child: HeaderWidget(180, false, Icons.person_add_alt_1_rounded),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(25, 50, 25, 10),
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(
                    'Register', // Replace with your desired text
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  Form(
                    key: _formkey,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            selectImage();
                          },
                          child: Stack(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  border:
                                      Border.all(width: 5, color: Colors.white),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 20,
                                      offset: const Offset(5, 5),
                                    ),
                                  ],
                                ),
                                child: selectedImage != null
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        child: Image.file(
                                          selectedImage!,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        color: Colors.grey.shade300,
                                        size: 80.0,
                                      ),
                              ),
                              Container(
                                padding: EdgeInsets.fromLTRB(80, 80, 0, 0),
                                child: Icon(
                                  Icons.add_circle,
                                  color: Colors.grey.shade700,
                                  size: 25.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Container(
                          child: TextFormField(
                            controller: firstname,
                            decoration: ThemeHelper().textInputDecoration(
                                'First Name', 'Enter your first name'),
                            // validator: (value) {
                            //   if (value!.length == 0) {
                            //     return "Firstname cannot be empty";
                            //   } else {
                            //     return ("Please enter a valid firstname");
                            //   }
                            // },
                            onChanged: (value) {},
                            keyboardType: TextInputType.emailAddress,
                          ),
                          decoration: ThemeHelper().inputBoxDecorationShaddow(),
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        Container(
                          child: TextFormField(
                            controller: lastname,
                            decoration: ThemeHelper().textInputDecoration(
                                'Last Name', 'Enter your last name'),
                            // validator: (value) {
                            //   if (value!.length == 0) {
                            //     return "Lastname cannot be empty";
                            //   } else {
                            //     return ("Please enter a valid lastname");
                            //   }
                            // },
                            onChanged: (value) {},
                            keyboardType: TextInputType.emailAddress,
                          ),
                          decoration: ThemeHelper().inputBoxDecorationShaddow(),
                        ),
                        SizedBox(height: 20.0),
                        Container(
                          child: TextFormField(
                            controller: emailController,
                            decoration: ThemeHelper().textInputDecoration(
                                "E-mail address", "Enter your email"),
                            validator: (value) {
                              if (value!.length == 0) {
                                return "Email cannot be empty";
                              }
                              if (!RegExp(
                                      "^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+.[a-z]")
                                  .hasMatch(value)) {
                                return ("Please enter a valid email");
                              } else {
                                return null;
                              }
                            },
                            onChanged: (value) {},
                            keyboardType: TextInputType.emailAddress,
                          ),
                          decoration: ThemeHelper().inputBoxDecorationShaddow(),
                        ),
                        SizedBox(height: 20.0),
                        Container(
                          child: TextFormField(
                            controller: mobile,
                            decoration: ThemeHelper().textInputDecoration(
                                "Mobile Number", "Enter your mobile number"),
                            keyboardType: TextInputType.phone,
                            // validator: (value) {
                            //   if (value!.length == 0) {
                            //     return "Mobile cannot be empty";
                            //   } else {
                            //     return ("Please enter a valid mobile");
                            //   }
                            // },
                            onChanged: (value) {},
                          ),
                          decoration: ThemeHelper().inputBoxDecorationShaddow(),
                        ),
                        SizedBox(height: 20.0),
                        Container(
                          child: TextFormField(
                            obscureText: true,
                            controller: passwordController,
                            decoration: ThemeHelper().textInputDecoration(
                                "Password*", "Enter your password"),
                            validator: (value) {
                              RegExp regex = new RegExp(r'^.{6,}$');
                              if (value!.isEmpty) {
                                return "Password cannot be empty";
                              }
                              if (!regex.hasMatch(value)) {
                                return ("please enter valid password min. 6 character");
                              } else {
                                return null;
                              }
                            },
                            onChanged: (value) {},
                          ),
                          decoration: ThemeHelper().inputBoxDecorationShaddow(),
                        ),
                        SizedBox(height: 15.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Role : ",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            DropdownButton<String>(
                              dropdownColor: Colors.grey,
                              isDense: true,
                              isExpanded: false,
                              iconEnabledColor:
                                  const Color.fromARGB(255, 14, 8, 8),
                              focusColor: const Color.fromARGB(255, 19, 12, 12),
                              items: options.map((String dropDownStringItem) {
                                return DropdownMenuItem<String>(
                                  value: dropDownStringItem,
                                  child: Text(
                                    dropDownStringItem,
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newValueSelected) {
                                setState(() {
                                  _currentItemSelected = newValueSelected!;
                                  role = newValueSelected;
                                });
                              },
                              value: _currentItemSelected,
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        FormField<bool>(
                          builder: (state) {
                            return Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Checkbox(
                                        value: checkboxValue,
                                        onChanged: (value) {
                                          setState(() {
                                            checkboxValue = value!;
                                            state.didChange(value);
                                          });
                                        }),
                                    Text(
                                      "I accept all terms and conditions.",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    state.errorText ?? '',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Theme.of(context).errorColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              ],
                            );
                          },
                          validator: (value) {
                            if (!checkboxValue) {
                              return 'You need to accept terms and conditions';
                            } else {
                              return null;
                            }
                          },
                        ),
                        SizedBox(height: 20.0),
                        Container(
                          decoration:
                              ThemeHelper().buttonBoxDecoration(context),
                          child: ElevatedButton(
                            style: ThemeHelper().buttonStyle(),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(40, 10, 40, 10),
                              child: Text(
                                "Register".toUpperCase(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                showProgress = true;
                              });
                              signUp(emailController.text,
                                  passwordController.text, role);
                            },
                          ),
                        ),
                        SizedBox(height: 30.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void selectImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedImage != null) {
        selectedImage = File(pickedImage.path);
      }
    });
  }

  void signUp(String email, String password, String role) async {
  if (_formkey.currentState!.validate()) {
    try {
      setState(() {
        showProgress = true;
      });
      
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      if (selectedImage != null) {
        String imageName = Path.basename(selectedImage!.path);
        Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('profilePicture')
            .child(userCredential.user!.uid)
            .child(imageName);
        UploadTask uploadTask = storageReference.putFile(selectedImage!);
        await uploadTask.whenComplete(() async {
          String imageUrl = await storageReference.getDownloadURL();
          await postDetailsToFirestore(email, role, imageUrl);
        });
      } else {
        await postDetailsToFirestore(email, role, '');
      }
      
    } catch (e) {
      // Handle the error and return a value
      print('Error occurred during sign up: $e');
      setState(() {
        showProgress = false;
      });
      return null; // Or return a specific value
    }
  }
}


  postDetailsToFirestore(String email, String role, String imageUrl) async {
  var user = _auth.currentUser;
  CollectionReference ref = FirebaseFirestore.instance.collection('users');
  ref.doc(user?.uid).set({
    'firstname': firstname.text,
    'lastname': lastname.text,
    'email': emailController.text,
    'mobile': mobile.text,
    'role': role,
    'profilePicture': imageUrl, // Add the image URL here
  });
  Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (context) => LoginPage()));
}

}
