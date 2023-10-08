import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tutorgo/pages/widget/header_widget.dart';
import 'package:tutorgo/pages/widget/editPost.dart';

class PostCourseInfoPage extends StatelessWidget {
  final Map<String, dynamic> postCourseData;
  final String? postCourseId;

  const PostCourseInfoPage({required this.postCourseData, this.postCourseId});

  bool get isStudent {
    return postCourseData['userId'] == FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Post Information',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
        actions: <Widget>[
          if (isStudent)
            IconButton(
              onPressed: () {
                // Navigate to the edit page
                if (postCourseId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPostPage(
                        postCourseData: postCourseData,
                        postCourseId:
                            postCourseId, // Pass the postCourseId here
                      ),
                    ),
                  );
                } else {
                  print('Invalid postCourseId');
                }
              },
              icon: Icon(
                Icons.edit, // Change to your desired icon
                color: Colors.white,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        // Wrap the content in SingleChildScrollView
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 75,
              child: HeaderWidget(75, false, Icons.house_rounded),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                        10), // Adjust the radius as needed
                    child: Image.network(
                      postCourseData['imageUrl'] ?? '',
                      height: 250,
                      width: 350,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Course Name: ${postCourseData['courseName']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                  ),
                  SizedBox(height: 5),
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Price: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        TextSpan(
                          text: '${postCourseData['price']} ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5),
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Address: ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Change the color if needed
                              fontSize: 16),
                        ),
                        TextSpan(
                          text: '${postCourseData['address']}',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize:
                                  16 // Change the color to make it look like a hyperlink
                              ),
                          children: <InlineSpan>[
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  if (postCourseData['googleMapsLink'] !=
                                          null &&
                                      postCourseData['googleMapsLink']
                                          .isNotEmpty) {
                                    print(
                                        'Google Maps Link: ${postCourseData['googleMapsLink']}');
                                    launch(postCourseData['googleMapsLink']);
                                  }
                                },
                                child: Icon(
                                  Icons.map, // Replace with the icon you want
                                  color: Theme.of(context).hintColor,
                                  // Change the color if needed
                                  size: 23, // Adjust the size as needed
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5),
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Contact Info: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        TextSpan(
                          text: '${postCourseData['contactInfo']} ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
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
}
