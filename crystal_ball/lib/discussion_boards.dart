import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'colors.dart';
import 'database_service.dart';
import 'api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiscussionBoardPage extends StatefulWidget {
  const DiscussionBoardPage({Key? key}) : super(key: key);

  @override
  State<DiscussionBoardPage> createState() => _DiscussionBoardPageState();
}

class _DiscussionBoardPageState extends State<DiscussionBoardPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? selectedBoard;
  List<String> _userBoards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserBoards();
  }

  Future<void> _loadUserBoards() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final boards = await DatabaseService.instance.getUserBoards(user.uid);
        setState(() {
          _userBoards = boards;
          if (boards.isNotEmpty) {
            selectedBoard = boards.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user boards: $e');
      setState(() {
        _isLoading = false;
      });
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
    } catch (e) {
      print('Error searching books: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _joinBoard(String boardTitle) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await DatabaseService.instance.joinDiscussionBoard(user.uid, boardTitle);
        await _loadUserBoards();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Joined discussion board: $boardTitle'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error joining board: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join discussion board'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || selectedBoard == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await DatabaseService.instance.addMessageToBoard(
          selectedBoard!,
          user.uid,
          text,
        );
        messageController.clear();
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Discussion Boards',
            style: TextStyle(
              fontSize: 32,
              color: AppColors.textPrimary,
              fontFamily: 'Josefin Slab',
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
                fillColor: AppColors.secondary,
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
          ),

          // Search Results or Active Boards
          if (_isSearching)
            const Center(child: CircularProgressIndicator())
          else if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final book = _searchResults[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      title: Text(book['title']),
                      subtitle: Text(book['author']),
                      trailing: ElevatedButton(
                        onPressed: () => _joinBoard(book['title']),
                        child: const Text('Join Discussion'),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Active Boards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 16,
                      children: _userBoards.map((board) {
                        return GestureDetector(
                          onTap: () => setState(() => selectedBoard = board),
                          child: Container(
                            width: 100,
                            height: 120,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedBoard == board
                                    ? AppColors.accent1
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              board,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Josefin Slab',
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  if (selectedBoard != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Board: $selectedBoard',
                      style: const TextStyle(
                        fontSize: 26,
                        fontFamily: 'Josefin Slab',
                        color: AppColors.textPrimary,
                      ),
                    ),

                    // Chat Display
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('discussionBoards')
                              .doc(selectedBoard)
                              .collection('messages')
                              .orderBy('timestamp', descending: false)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final docs = snapshot.data!.docs;
                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final msg = docs[index];
                                return ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: AppColors.secondary,
                                    child: Icon(Icons.person, color: AppColors.textPrimary),
                                  ),
                                  title: Text(
                                    msg['userName'] ?? 'Anonymous',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Josefin Slab',
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg['text'] ?? '',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Josefin Slab',
                                        ),
                                      ),
                                      Text(
                                        (msg['timestamp'] as Timestamp?) != null
                                            ? msg['timestamp']
                                                .toDate()
                                                .toLocal()
                                                .toString()
                                                .split('.')[0]
                                            : '',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),

                    // Message Input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                filled: true,
                                fillColor: AppColors.secondary,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: sendMessage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent1,
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(16),
                            ),
                            child: const Icon(Icons.send, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    messageController.dispose();
    super.dispose();
  }
}
