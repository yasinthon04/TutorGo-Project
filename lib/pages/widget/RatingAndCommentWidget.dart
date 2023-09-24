import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RatingAndCommentWidget extends StatelessWidget {
  final double averageRating;
  final int totalComments;

  RatingAndCommentWidget({
    required this.averageRating,
    required this.totalComments,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      
      children: [
        // Display stars based on the average rating
          Icon(
            Icons.star,
            color: Colors.amber,
            size: 24,
          ),
        Text(
          ' ${averageRating.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 10), // Add some spacing between rating and total comments
        Text(
          '($totalComments Reviews)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 129, 129, 129),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
