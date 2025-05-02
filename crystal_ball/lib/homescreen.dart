import 'package:crystal_ball/colors.dart';
import 'package:flutter/material.dart';
import 'colors.dart';
import 'api_service.dart';

class HomeScreenPage extends StatefulWidget {
  const HomeScreenPage({super.key});

  @override
  State<HomeScreenPage> createState() => _HomeScreenPageState();
}

class _HomeScreenPageState extends State<HomeScreenPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    try {
      final results = await ApiService().searchBooks(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error performing search')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for books...',
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
          ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_isSearching)
            Expanded(
              child: _searchResults.isEmpty
                  ? const Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF3C3A79),
                          fontFamily: 'Josefin Slab',
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        return _buildSearchResultCard(_searchResults[index]);
                      },
                    ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("Most Recent"),
                    _bookGrid(['Book A', 'Book B', 'Book C']),
                    const SizedBox(height: 20),
                    _sectionTitle("Top Recommendations"),
                    _bookGrid(['Book D', 'Book E', 'Book F', 'Book G']),
                  ],
                ),
              ),
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
              onPressed: () {},
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

  Widget _buildSearchResultCard(Map<String, dynamic> book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Image
                if (book['imageURL'] != null && book['imageURL'].isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      book['imageURL'],
                      width: 120,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            width: 120,
                            height: 180,
                            color: Colors.grey[300],
                            child: const Icon(Icons.book, size: 60),
                          ),
                    ),
                  )
                else
                  Container(
                    width: 120,
                    height: 180,
                    color: Colors.grey[300],
                    child: const Icon(Icons.book, size: 60),
                  ),
                const SizedBox(width: 16),
                // Book Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3C3A79),
                          fontFamily: 'Josefin Slab',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Author: ${book['authors'] ?? 'Unknown'}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF3C3A79),
                          fontFamily: 'Josefin Slab',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Published: ${book['publishedDate'] ?? 'Unknown'}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF3C3A79),
                          fontFamily: 'Josefin Slab',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Genre: ${(book['categories'] as List?)?.join(', ') ?? 'Uncategorized'}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF3C3A79),
                          fontFamily: 'Josefin Slab',
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Reading Status Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFACAAC7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: 'Want to Read',
                          isExpanded: true,
                          underline: const SizedBox(),
                          style: const TextStyle(
                            color: Color(0xFF3C3A79),
                            fontSize: 16,
                            fontFamily: 'Josefin Slab',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Want to Read',
                              child: Text('Want to Read'),
                            ),
                            DropdownMenuItem(
                              value: 'Currently Reading',
                              child: Text('Currently Reading'),
                            ),
                            DropdownMenuItem(
                              value: 'Completed',
                              child: Text('Completed'),
                            ),
                          ],
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              // TODO: Update book status in database
                              print('Status changed to: $newValue');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Book Description
            if (book['description'] != null && book['description'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3C3A79),
                      fontFamily: 'Josefin Slab',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book['description'],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF3C3A79),
                      fontFamily: 'Josefin Slab',
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

