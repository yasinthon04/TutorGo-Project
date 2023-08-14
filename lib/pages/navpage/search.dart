import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
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
    return GestureDetector(
      onTap: () {
        setState(() {
          _searchStream = FirebaseFirestore.instance
              .collection('courses')
              .where('category', isEqualTo: category)
              .snapshots();
        });
      },
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            category,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            province,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCategoryCard(context, 'Math'),
                    _buildCategoryCard(context, 'Science'),
                    _buildCategoryCard(context, 'English'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCategoryCard(context, 'Social'),
                    _buildCategoryCard(context, 'Thai'),
                    _buildCategoryCard(context, 'Art'),
                  ],
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButton<String>(
                    value: _selectedProvince,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedProvince = newValue!;
                        _searchStream = FirebaseFirestore.instance
                            .collection('courses')
                            .where('province', isEqualTo: _selectedProvince)
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
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }
}
