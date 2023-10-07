import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
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
  late FocusNode _searchFocusNode;
  bool _showCategories = true;
  List<String> _provinces = []; // List to store provinces
  String _selectedProvince = 'Bangkok'; // Currently selected province
  String _selectedCategory = '';
  User? user;
  String studentId = '';

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    studentId = user?.uid ?? '';
    _searchFocusNode = FocusNode();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _loadProvinces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    setState(() {
      _showCategories = !_searchFocusNode.hasFocus;
      if (!_showCategories) {
        _searchStream = null;
      }
    });
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

  Future<void> _loadProvinces() async {
    // Load provinces from provinces.json
    final String data = await DefaultAssetBundle.of(context)
        .loadString('lib/assets/provinces.json');
    final List<dynamic> jsonList = json.decode(data);

    setState(() {
      _provinces = jsonList.cast<String>();
    });
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
                      studentId: studentId,
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

  Widget _buildCategoryCard(BuildContext context, String category) {
    final isSelected =
        category == _selectedCategory; // Check if the category is selected

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category; // Update the selected category
          _searchStream = FirebaseFirestore.instance
              .collection('courses')
              .where('category', isEqualTo: category)
              .snapshots();
        });
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: isSelected
                  ? [
                      Colors.blue, // Change to the desired selected colors
                      Colors.green,
                    ]
                  : [
                      Theme.of(context).primaryColor,
                      Theme.of(context).hintColor,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          height: 40,
          width: 100,
          child: Center(
            child: Text(
              category,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProvinceCard(BuildContext context, String province) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _searchStream = FirebaseFirestore.instance
              .collection('courses')
              .where('province', isEqualTo: province)
              .snapshots();
        });
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.green,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              province,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Course Search',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,),
          
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
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search for a course...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _onSearchChanged(),
            ),
          ),
          if (_showCategories)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildCategoryCard(context, 'Math'),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildCategoryCard(context, 'Science'),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildCategoryCard(context, 'English'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildCategoryCard(context, 'Social'),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildCategoryCard(context, 'Thai'),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildCategoryCard(context, 'Art'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'Province',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(), // Adds flexible space to push the dropdown to the right
                      Align(
                        alignment: Alignment.centerRight,
                        child: DropdownButton<String>(
                          value: _selectedProvince,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedProvince = newValue!;
                              _searchStream = FirebaseFirestore.instance
                                  .collection('courses')
                                  .where('province',
                                      isEqualTo: _selectedProvince)
                                  .snapshots();
                            });
                          },
                          items: _provinces
                              .map<DropdownMenuItem<String>>(
                                (String province) => DropdownMenuItem<String>(
                                  value: province,
                                  child: Text(province),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }
}
