import 'package:crystal_ball/colors.dart';
import 'package:flutter/material.dart';
import 'colors.dart';

class HomeScreenPage extends StatelessWidget {
  final List<String> mostRecent = ['Book A', 'Book B', 'Book C'];
  final List<String> topRecommendations = ['Book D', 'Book E', 'Book F', 'Book G'];


  HomeScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFACAAC7),
      body: Column(
        children: [
          // Top bar
          Container(
            color: const Color(0xFFD3C9D1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            width: double.infinity,
            child: const Text(
              'Crystal Ball',
              style: TextStyle(
                fontSize: 36,
                color: Color(0xFF3C3A79),
                fontFamily: 'Island Moments',
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Reading List',
            style: TextStyle(
              fontSize: 28,
              fontFamily: 'Josefin Slab',
              color: Color(0xFF3C3A79),
              shadows: [Shadow(offset: Offset(0, 2), blurRadius: 2, color: Colors.black26)],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Want to Read
                  _sectionTitle("Most Recent"),
                  _bookGrid(mostRecent),

                  const SizedBox(height: 20),

                  // Currently Reading
                  _sectionTitle("Top Recommendations"),
                  _bookGrid(topRecommendations),
                ],
              ),
            ),
          ),

          // Bottom bar
          Container(
            height: 60,
            width: double.infinity,
            color: const Color(0xFFD3C9D1),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 26,
          color: Color(0xFF3C3A79),
          fontFamily: 'Josefin Slab',
          shadows: [Shadow(offset: Offset(0, 2), blurRadius: 2, color: Colors.black26)],
        ),
      ),
    );
  }

  Widget _bookGrid(List<String> books) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: books.map((book) => _bookCard(book)).toList(),
    );
  }

  Widget _bookCard(String title) {
    return Container(
      width: 160,
      height: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed:(){

              },
              icon: Icon(Icons.info_outline, size: 20, color: AppColors.textPrimary),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: IconButton(
              onPressed: () {
                // Add your edit functionality here
              },
              icon: Icon(Icons.edit, size: 20, color: AppColors.textPrimary),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ),
          ),
          Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF3C3A79),
                fontFamily: 'Josefin Slab',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

