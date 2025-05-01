//only accessible if user clicks on write a review button

import 'package:flutter/material.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final bookNameController = TextEditingController();
  final reviewController = TextEditingController();
  int rating = 0;

  void submitReview() {
    final name = bookNameController.text.trim();
    final review = reviewController.text.trim();

    if (name.isEmpty || review.isEmpty || rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields and rating!')),
      );
      return;
    }

    // You could send to Firebase here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Submitted: $name\nRating: $rating\nReview: $review'),
        duration: const Duration(seconds: 2),
      ),
    );

    bookNameController.clear();
    reviewController.clear();
    setState(() => rating = 0);
  }

  Widget buildStar(int starIndex) {
    return GestureDetector(
      onTap: () => setState(() => rating = starIndex),
      child: Icon(
        Icons.star,
        size: 40,
        color: starIndex <= rating ? Colors.amber : Colors.grey.shade300,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3C9D1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text(
              'Crystal Ball',
              style: TextStyle(
                fontSize: 48,
                fontFamily: 'Island Moments',
                color: Color(0xFF3C3A79),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Submit Your Review',
              style: TextStyle(
                fontSize: 32,
                fontFamily: 'Josefin Slab',
                color: Color(0xFF3C3A79),
              ),
            ),
            const SizedBox(height: 30),

            // Book name input
            TextField(
              controller: bookNameController,
              decoration: InputDecoration(
                hintText: 'Book Name',
                filled: true,
                fillColor: const Color(0xFFAFAAC7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),

            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => buildStar(index + 1)),
            ),
            const SizedBox(height: 30),

            // Review text
            TextField(
              controller: reviewController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Write your review...',
                filled: true,
                fillColor: const Color(0xA33C3A79),
                hintStyle: const TextStyle(color: Colors.white60),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 40),

            // Submit button
            ElevatedButton(
              onPressed: submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8982AB),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Submit',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Josefin Slab',
                  color: Color(0xFFE4D3EC),
                ),
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
