import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorgo/pages/navpage/postCourseInfoPage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tutorgo/pages/widget/header_widget.dart';

class PostCoursePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Post',
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
      ),
      body: Column(
        children: [
          Container(
            height: 75,
            child: HeaderWidget(75, false, Icons.house_rounded),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('postCourse')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var postCourses = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true, // Ensure the ListView doesn't scroll itself
                    itemCount: postCourses.length,
                    itemBuilder: (context, index) {
                      var postCourse =
                          postCourses[index].data() as Map<String, dynamic>;
                      String? postCourseId = postCourses[index].id;

                      return GestureDetector(
                        onTap: () {
                          if (postCourseId != null && postCourseId.isNotEmpty) {
                            print('$postCourseId');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostCourseInfoPage(
                                  postCourseData: postCourse,
                                  postCourseId: postCourseId,
                                ),
                              ),
                            );
                          } else {
                            print('Invalid postCourseId');
                          }
                        },
                        child: Card(
                          margin: EdgeInsets.all(16.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Add an Image widget here with the course image
                                Image.network(
                                  postCourse[
                                      'imageUrl'], // Replace with the actual image URL
                                  width: 100.0,
                                  height: 100.0,
                                  fit: BoxFit.cover, // Adjust the fit as needed
                                ),
                                SizedBox(
                                    width:
                                        16.0), // Add spacing between the image and details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Course Name: ${postCourse['courseName']}',
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8.0),
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
                                              text: '${postCourse['price']} ',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 8.0),
                                      RichText(
                                        text: TextSpan(
                                          children: <TextSpan>[
                                            TextSpan(
                                              text: 'Address: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                                fontSize: 16,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '${postCourse['address']} ',
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
                                IconButton(
                                  onPressed: () {
                                    if (postCourse['googleMapsLink'] != null &&
                                        postCourse['googleMapsLink'].isNotEmpty) {
                                      String mapLink =
                                          postCourse['googleMapsLink'];
                                      launch(mapLink);
                                    }
                                  },
                                  icon: Icon(
                                    Icons.pin_drop_rounded,
                                    color: Theme.of(context).hintColor,
                                    size: 40.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
