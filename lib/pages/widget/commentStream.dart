import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import the intl package for DateFormat
import '../widget/comment.dart';

class CommentStream extends StatelessWidget {
  final String courseId;

  CommentStream({required this.courseId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final commentDocs = snapshot.data?.docs ?? [];
        final comments = commentDocs.map((commentDoc) {
          final commentData = commentDoc.data() as Map<String, dynamic>;
          final content = commentData['content'] as String?;
          final firstName = commentData['firstName'] as String?;
          final rating = commentData['rating'] as double?;
          final timestamp = commentData['timestamp'] as Timestamp?;

          if (content != null &&
              firstName != null &&
              timestamp != null &&
              rating != null) {
            final comment = Comment(
              content: content,
              firstName: firstName,
              timestamp: timestamp.toDate(),
              rating: rating,
              studentId: '', // You might need to get this from the comment data
            );

            final formattedDate =
                DateFormat('MMM d, yyyy - h:mm a').format(comment.timestamp);

            return Column(
              children: [
                ListTile(
                  title: Text(
                    comment.firstName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    comment.content,
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${comment.rating}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(), // Add a separator line after each ListTile
              ],
            );
          }

          return Container(); // Return an empty container for invalid comments
        }).toList();

        return Column(
          children: comments,
        );
      },
    );
  }
}
