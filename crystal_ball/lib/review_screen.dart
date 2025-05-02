import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart'; // adjust path as needed

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final bookNameController = TextEditingController();
  final reviewController = TextEditingController();
  int rating = 0;
  List<Map<String, dynamic>> userReviews = [];

  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    fetchUserReviews();
  }

  Future<void> fetchUserReviews() async {
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('bookReviews')
        .where('userId', isEqualTo: currentUser!.uid)
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      userReviews = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> submitReview() async {
    final name = bookNameController.text.trim();
    final review = reviewController.text.trim();

    if (name.isEmpty || review.isEmpty || rating == 0 || currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields and rating!')),
      );
      return;
    }

    final newReview = {
      'bookTitle': name,
      'userId': currentUser!.uid,
      'review': review,
      'rating': rating,
      'timestamp': Timestamp.now(),
    };

    DatabaseService.instance.createReviews(
      currentUser!.uid,
      review,
      "User Review",
      name,
      rating,
    );

    bookNameController.clear();
    reviewController.clear();

    setState(() {
      rating = 0;
      userReviews.insert(0, newReview);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted!')),
    );
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => buildStar(index + 1)),
            ),
            const SizedBox(height: 30),

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
            const Text(
              'Your Past Reviews',
              style: TextStyle(
                fontSize: 26,
                fontFamily: 'Josefin Slab',
                color: Color(0xFF3C3A79),
              ),
            ),
            const SizedBox(height: 10),
            ...userReviews.map((review) => Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: const Color(0xFFAEA7C4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                title: Text(
                  review['bookTitle'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(review['review'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    review['rating'] ?? 0,
                    (_) => const Icon(Icons.star, color: Colors.amber, size: 16),
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
