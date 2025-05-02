import 'package:crystal_ball/colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import 'colors.dart';

class ReadingListPage extends StatefulWidget {
  const ReadingListPage({super.key});

  @override
  State<ReadingListPage> createState() => _ReadingListPageState();
}

class _ReadingListPageState extends State<ReadingListPage> {
  Map<String, List<Map<String, dynamic>>> _readingLists = {
    'wantToRead': [],
    'currentlyReading': [],
    'completed': [],
  };
  bool _isLoading = false;
  Map<String, dynamic>? _selectedBook;

  @override
  void initState() {
    super.initState();
    _loadReadingLists();
  }

  Future<void> _loadReadingLists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final books = await DatabaseService.instance.getMostRecentBooks(user.uid);
        setState(() {
          _readingLists = {
            'wantToRead': books['wantToRead'] ?? [],
            'currentlyReading': books['currentlyReading'] ?? [],
            'completed': books['completed'] ?? [],
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading reading lists: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showBookDetails(Map<String, dynamic> book) {
    setState(() {
      _selectedBook = book;
    });
  }

  void _hideBookDetails() {
    setState(() {
      _selectedBook = null;
    });
  }

  Future<void> _updateBookStatus(String status) async {
    if (_selectedBook != null) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          setState(() {
            _isLoading = true;
          });

          await DatabaseService.instance.updateBookStatus(
            user.uid,
            _selectedBook!['title'],
            status,
          );

          await _loadReadingLists();

          setState(() {
            _isLoading = false;
            _selectedBook = null;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Book status updated to: $status'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        print('Error updating book status: $e');
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update book status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getCurrentStatus(Map<String, dynamic> book) {
    if (book['completed'] == true) return 'Completed';
    if (book['currentlyReading'] == true) return 'Currently Reading';
    if (book['wantToRead'] == true) return 'Want to Read';
    return 'Not Interested';
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
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
              onPressed: () => _showBookDetails(book),
              icon: Icon(Icons.info_outline, size: 20, color: AppColors.textPrimary),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (book['imageURL'] != null && book['imageURL'].isNotEmpty)
                  Image.network(
                    book['imageURL'],
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.book, size: 60),
                  )
                else
                  const Icon(Icons.book, size: 60),
                const SizedBox(height: 8),
                Text(
                  book['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3C3A79),
                    fontFamily: 'Josefin Slab',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookDetailsPopup(Map<String, dynamic> book) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Book Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3C3A79),
                      fontFamily: 'Josefin Slab',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _hideBookDetails,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFACAAC7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _getCurrentStatus(book),
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
                    DropdownMenuItem(
                      value: 'Not Interested',
                      child: Text('Not Interested'),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _updateBookStatus(newValue);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFACAAC7),
      body: Stack(
        children: [
          Column(
            children: [
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Want to Read
                  _sectionTitle("Want to Read"),
                            if (_readingLists['wantToRead']?.isNotEmpty ?? false)
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: _readingLists['wantToRead']!
                                    .map((book) => _buildBookCard(book))
                                    .toList(),
                              )
                            else
                              const _emptyListMessage("No books in Want to Read"),

                  const SizedBox(height: 20),

                  // Currently Reading
                  _sectionTitle("Currently Reading"),
                            if (_readingLists['currentlyReading']?.isNotEmpty ?? false)
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: _readingLists['currentlyReading']!
                                    .map((book) => _buildBookCard(book))
                                    .toList(),
                              )
                            else
                              const _emptyListMessage("No books in Currently Reading"),

                  const SizedBox(height: 20),

                            // Completed
                            _sectionTitle("Completed"),
                            if (_readingLists['completed']?.isNotEmpty ?? false)
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: _readingLists['completed']!
                                    .map((book) => _buildBookCard(book))
                                    .toList(),
                              )
                            else
                              const _emptyListMessage("No books in Completed"),
                ],
              ),
            ),
          ),
            ],
          ),
          if (_selectedBook != null)
            _buildBookDetailsPopup(_selectedBook!),
        ],
      ),
    );
  }
}

class _emptyListMessage extends StatelessWidget {
  final String message;

  const _emptyListMessage(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF3C3A79),
          fontFamily: 'Josefin Slab',
        ),
      ),
    );
  }
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
