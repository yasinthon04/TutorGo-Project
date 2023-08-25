import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String content;
  final String studentId;
  final String firstName; // Add this field
  final double rating;
  final DateTime timestamp;

  Comment({
    required this.content,
    required this.studentId,
    required this.firstName, // Initialize in the constructor
    required this.rating,
    required this.timestamp,
  });
}

class CommentSection extends StatelessWidget {
  final List<Comment> comments;

  CommentSection({required this.comments});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return ListTile(
              title: Text(comment.content),
              subtitle: Text(
                'By Student ${comment.studentId} on ${comment.timestamp.toString()}',
              ),
            );
          },
        ),
      ],
    );
  }
}
