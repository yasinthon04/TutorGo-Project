import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorgo/pages/widget/header_widget.dart';
import 'courseInfoPage.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  Stream<QuerySnapshot>? _searchStream;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    String query = _searchController.text.trim();

    if (query.isNotEmpty) {
      setState(() {
        _searchStream = FirebaseFirestore.instance
            .collection('courses')
            .where('courseName', isGreaterThanOrEqualTo: query)
            .where('courseName', isLessThan: query + 'z')
            .snapshots();
      });
    } else {
      setState(() {
        _searchStream = null;
      });
    }
  }

  Widget _buildSearchResults() {
    if (_searchStream == null) {
      return Center(
        child: Text('Enter a course name to search.'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _searchStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final searchQuery = _searchController.text.trim().toLowerCase();

        final filteredDocs = snapshot.data!.docs.where((doc) {
          final courseData = doc.data() as Map<String, dynamic>;
          final courseName = courseData['courseName'].toString().toLowerCase();
          return courseName.contains(searchQuery);
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Text('No results found.'),
          );
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final courseDoc = filteredDocs[index];
            final courseData = courseDoc.data() as Map<String, dynamic>;
            final courseId = courseDoc.id; // Get the courseId
            final courseName = courseData['courseName'];
            final address = courseData['address'];
            final imageUrl = courseData['imageName'];

            return ListTile(
              leading: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 100,
                      width: 50,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/profile-icon.png',
                      height: 100,
                      width: 50,
                      fit: BoxFit.cover,
                    ),
              title: Text(courseName),
              subtitle: Text(address),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseInfoPage(
                      courseData: courseData,
                      courseId: courseId,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Course Search',
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            height: 75,
            child: HeaderWidget(75, false, Icons.house_rounded),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a course...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _onSearchChanged(),
            ),
          ),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }
}
