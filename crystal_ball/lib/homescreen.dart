import 'package:crystal_ball/colors.dart';
import 'package:flutter/material.dart';
import 'colors.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreenPage extends StatefulWidget {
  const HomeScreenPage({super.key});

  @override
  State<HomeScreenPage> createState() => _HomeScreenPageState();
}

class _HomeScreenPageState extends State<HomeScreenPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Map<String, dynamic>? _selectedBook;
  Map<String, List<Map<String, dynamic>>> _mostRecentBooks = {
    'wantToRead': [],
    'currentlyReading': [],
    'completed': [],
  };
  List<Map<String, dynamic>> _recommendedBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendedBooks();
    _loadMostRecentBooks();
  }

  Future<void> _loadRecommendedBooks() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _isLoading = true;
        });
        
        final books = await DatabaseService.instance.getRecommendedBooks(user.uid);
        print('Loaded ${books.length} recommended books in homescreen');
        
        setState(() {
          _recommendedBooks = books;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading recommended books: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMostRecentBooks() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final books = await DatabaseService.instance.getMostRecentBooks(user.uid);
        setState(() {
          _mostRecentBooks = books;
        });
      }
    } catch (e) {
      print('Error loading most recent books: $e');
    }
  }

  void _showBookDetailsPopup(Map<String, dynamic> book) {
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
          
          // Reload books to reflect changes
          await _loadRecommendedBooks();
          await _loadMostRecentBooks();
          
          setState(() {
            _isLoading = false;
          });
          
          // Show success message
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

      // Add books to user's collection
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        for (var book in _searchResults) {
          await DatabaseService.instance.addBookToCollection(
            user.uid,
            book,
          );
        }
      }
    } catch (e) {
      print('Error searching books: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _updateSearchResultStatus(Map<String, dynamic> book, String status) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _isLoading = true;
        });
        
        // Update the book's status in the search results
        final index = _searchResults.indexWhere((b) => b['title'] == book['title']);
        if (index != -1) {
          setState(() {
            _searchResults[index] = {
              ..._searchResults[index],
              'wantToRead': status == 'Want to Read',
              'currentlyReading': status == 'Currently Reading',
              'completed': status == 'Completed',
            };
          });
        }

        await DatabaseService.instance.updateBookStatus(
          user.uid,
          book['title'],
          status,
        );
        
        // Reload books to reflect changes
        await _loadRecommendedBooks();
        await _loadMostRecentBooks();
        
        setState(() {
          _isLoading = false;
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

  String _getCurrentStatus(Map<String, dynamic> book) {
    if (book['completed'] == true) return 'Completed';
    if (book['currentlyReading'] == true) return 'Currently Reading';
    if (book['wantToRead'] == true) return 'Want to Read';
    return 'Not Interested';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homePageBkg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Welcome Greeting
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final displayName = snapshot.data?['displayName'] ?? 'Reader';
                      return Text(
                        'Welcome, $displayName',
                        style: const TextStyle(
                          fontSize: 28,
                          color: AppColors.textPrimary,
                          fontFamily: 'Josefin Slab',
                          shadows: [Shadow(offset: Offset(0, 2), blurRadius: 2, color: Colors.black26)],
                        ),
                      );
                    },
                  ),
                ),
                _buildSearchBar(),
                Expanded(
                  child: _isSearching
                      ? const Center(child: CircularProgressIndicator())
                      : _searchResults.isNotEmpty
                          ? _buildSearchResults()
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle("Recent Activity"),
                                  _buildCombinedBooksSection(),
                                  _sectionTitle("Recommended Books"),
                                  _buildRecommendedBooksGrid(),
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
          color: AppColors.textPrimary,
          fontFamily: 'Josefin Slab',
          shadows: [Shadow(offset: Offset(0, 2), blurRadius: 2, color: Colors.black26)],
        ),
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    return Container(
      width: 160,
      height: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.accent3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _selectedBook = book;
                });
              },
              icon: const Icon(Icons.info_outline, size: 20, color: AppColors.textPrimary),
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
                if (book['imageUrl'] != null && book['imageUrl'].isNotEmpty)
                  Image.network(
                    book['imageUrl'],
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.book, size: 60, color: AppColors.textPrimary),
                  )
                else
                  const Icon(Icons.book, size: 60, color: AppColors.textPrimary),
                const SizedBox(height: 8),
                Text(
                  book['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
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

  Widget _buildSearchResultCard(Map<String, dynamic> book, {bool showDropdown = false}) {
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
                            color: AppColors.accent3,
                            child: const Icon(Icons.book, size: 60, color: AppColors.textPrimary),
                          ),
                    ),
                  )
                else
                  Container(
                    width: 120,
                    height: 180,
                    color: AppColors.accent3,
                    child: const Icon(Icons.book, size: 60, color: AppColors.textPrimary),
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
                          color: AppColors.textPrimary,
                          fontFamily: 'Josefin Slab',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Author: ${book['authors'] ?? 'Unknown'}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          fontFamily: 'Josefin Slab',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Published: ${book['publishedDate'] ?? 'Unknown'}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          fontFamily: 'Josefin Slab',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Genre: ${(book['categories'] as List?)?.join(', ') ?? 'Uncategorized'}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          fontFamily: 'Josefin Slab',
                        ),
                      ),
                      if (showDropdown) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _getCurrentStatus(book),
                            isExpanded: true,
                            underline: const SizedBox(),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
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
                                _updateSearchResultStatus(book, newValue);
                              }
                            },
                          ),
                        ),
                      ],
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
                      color: AppColors.textPrimary,
                      fontFamily: 'Josefin Slab',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book['description'],
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
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
                      color: AppColors.textPrimary,
                      fontFamily: 'Josefin Slab',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
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
                              color: AppColors.accent3,
                              child: const Icon(Icons.book, size: 60, color: AppColors.textPrimary),
                            ),
                      ),
                    )
                  else
                    Container(
                      width: 120,
                      height: 180,
                      color: AppColors.accent3,
                      child: const Icon(Icons.book, size: 60, color: AppColors.textPrimary),
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
                            color: AppColors.textPrimary,
                            fontFamily: 'Josefin Slab',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Author: ${book['authors'] ?? 'Unknown'}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            fontFamily: 'Josefin Slab',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Published: ${book['publishedDate'] ?? 'Unknown'}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            fontFamily: 'Josefin Slab',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Genre: ${(book['categories'] as List?)?.join(', ') ?? 'Uncategorized'}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
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
                        color: AppColors.textPrimary,
                        fontFamily: 'Josefin Slab',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book['description'],
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontFamily: 'Josefin Slab',
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _getCurrentStatus(book),
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
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

  Widget _buildSearchBar() {
    return Padding(
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
          prefixIcon: const Icon(Icons.search, color: AppColors.textPrimary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textPrimary),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
              : null,
        ),
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildSearchResultCard(_searchResults[index], showDropdown: true);
      },
    );
  }

  Widget _buildCombinedBooksSection() {
    // Combine all books into a single list
    List<Map<String, dynamic>> allBooks = [];
    
    // Add completed books
    allBooks.addAll(_mostRecentBooks['completed'] ?? []);
    // Add currently reading books
    allBooks.addAll(_mostRecentBooks['currentlyReading'] ?? []);
    // Add want to read books
    allBooks.addAll(_mostRecentBooks['wantToRead'] ?? []);
    
    // Sort by timestamp if available, otherwise keep original order
    allBooks.sort((a, b) {
      final aTime = a['timestamp'] ?? 0;
      final bTime = b['timestamp'] ?? 0;
      return bTime.compareTo(aTime);
    });
    
    // Take only the first 3 books
    allBooks = allBooks.take(3).toList();
    
    if (allBooks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No recent activity',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontFamily: 'Josefin Slab',
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allBooks.length,
        itemBuilder: (context, index) {
          final book = allBooks[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildBookCard(book),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedBooksGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_recommendedBooks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No recommended books available',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontFamily: 'Josefin Slab',
          ),
        ),
      );
    }
    
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: _recommendedBooks.map((book) => _buildBookCard(book)).toList(),
    );
  }
}