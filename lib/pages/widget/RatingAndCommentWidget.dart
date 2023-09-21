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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Display stars based on the average rating
        for (int i = 0; i < averageRating.round(); i++)
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
          '($totalComments comments)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
