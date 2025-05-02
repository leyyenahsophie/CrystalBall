import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';
import 'api_service.dart';
import 'colors.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final TextEditingController _searchController = TextEditingController();
  final reviewController = TextEditingController();
  int rating = 0;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Map<String, dynamic>? _selectedBook;

  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final apiService = ApiService();
      final books = await apiService.searchBooks(query);
      setState(() {
        _searchResults = books.map((book) => {
          'title': book['title'] ?? '',
          'author': book['author'] ?? '',
          'description': book['description'] ?? '',
          'imageUrl': book['imageUrl'] ?? '',
          'genre': book['genre'] ?? [],
          'publishedDate': book['publishedDate'] ?? '',
        }).toList();
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching books: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectBook(Map<String, dynamic> book) {
    setState(() {
      _selectedBook = book;
      _searchResults = [];
      _searchController.clear();
    });
  }

  Future<void> submitReview() async {
    if (_selectedBook == null || reviewController.text.trim().isEmpty || rating == 0 || currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a book, complete the review, and rating!')),
      );
      return;
    }

    try {
      // Get user's display name
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      final displayName = userDoc.data()?['displayName'] ?? 'Anonymous';

      // Create review document
      await FirebaseFirestore.instance.collection('bookReviews').add({
        'bookTitle': _selectedBook!['title'],
        'bookAuthor': _selectedBook!['author'],
        'userId': currentUser!.uid,
        'userName': displayName,
        'review': reviewController.text.trim(),
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
      });

      reviewController.clear();
      setState(() {
        rating = 0;
        _selectedBook = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
      }
    } catch (e) {
      print('Error submitting review: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit review'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for a book...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF3C3A79)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF3C3A79)),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
            ),
            onSubmitted: _performSearch,
          ),
          if (_isSearching)
            const Center(child: CircularProgressIndicator())
          else if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final book = _searchResults[index];
                  return ListTile(
                    title: Text(
                      book['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF3C3A79),
                        fontFamily: 'Josefin Slab',
                      ),
                    ),
                    subtitle: Text(
                      book['author'] ?? 'Unknown Author',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3C3A79),
                        fontFamily: 'Josefin Slab',
                      ),
                    ),
                    onTap: () => _selectBook(book),
                  );
                },
              ),
            ),
          if (_selectedBook != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFAFAAC7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedBook!['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3C3A79),
                            fontFamily: 'Josefin Slab',
                          ),
                        ),
                        Text(
                          _selectedBook!['author'] ?? 'Unknown Author',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF3C3A79),
                            fontFamily: 'Josefin Slab',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF3C3A79)),
                    onPressed: () => setState(() => _selectedBook = null),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFFAEA7C4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF3C3A79),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['userName'] ?? 'Anonymous',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF3C3A79),
                          fontFamily: 'Josefin Slab',
                        ),
                      ),
                      Text(
                        review['bookTitle'] ?? 'Unknown Book',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF3C3A79),
                          fontFamily: 'Josefin Slab',
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    review['rating'] ?? 0,
                    (_) => const Icon(Icons.star, color: Colors.amber, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review['review'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF3C3A79),
                fontFamily: 'Josefin Slab',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              review['timestamp'] != null
                  ? (review['timestamp'] as Timestamp).toDate().toString().split('.')[0]
                  : '',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF3C3A79),
                fontFamily: 'Josefin Slab',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Book Reviews',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Josefin Slab',
          ),
        ),
        backgroundColor: AppColors.primary,
      ),
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
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 30),

            _buildSearchBar(),
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
                fillColor: AppColors.secondary,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent1,
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
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: 50),
            const Text(
              'All Reviews',
              style: TextStyle(
                fontSize: 26,
                fontFamily: 'Josefin Slab',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            if (currentUser == null)
              const Text(
                'Please log in to view your reviews',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Josefin Slab',
                  color: AppColors.textPrimary,
                ),
              )
            else
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookReviews')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final reviews = snapshot.data?.docs
                      .map((doc) => doc.data() as Map<String, dynamic>)
                      .toList() ?? [];

                  if (reviews.isEmpty) {
                    return const Text(
                      'No reviews yet. Submit your first review above!',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Josefin Slab',
                        color: AppColors.textPrimary,
                      ),
                    );
                  }

                  return Column(
                    children: reviews.map((review) => _buildReviewCard(review)).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    reviewController.dispose();
    super.dispose();
  }
}
