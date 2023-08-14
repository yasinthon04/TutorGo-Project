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
          final timestamp = commentData['timestamp'] as Timestamp?;

          if (content != null && firstName != null && timestamp != null) {
            final comment = Comment(
              content: content,
              firstName: firstName,
              timestamp: timestamp.toDate(),
              studentId: '', // You might need to get this from the comment data
            );

            final formattedDate = DateFormat('MMM d, yyyy - h:mm a')
                .format(comment.timestamp);

            return ListTile(
              title: Text(comment.firstName),
              subtitle: Text(comment.content),
              trailing: Text(formattedDate),
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
