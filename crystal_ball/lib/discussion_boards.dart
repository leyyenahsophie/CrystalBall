import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'colors.dart';

class DiscussionBoardPage extends StatefulWidget {
  const DiscussionBoardPage({Key? key}) : super(key: key);

  @override
  State<DiscussionBoardPage> createState() => _DiscussionBoardPageState();
}

class _DiscussionBoardPageState extends State<DiscussionBoardPage> {
  final List<String> boards = ['The Alchemist', '1984', 'Pride & Prejudice'];
  String selectedBoard = 'The Alchemist';
  final TextEditingController messageController = TextEditingController();

  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    FirebaseFirestore.instance
        .collection('discussionBoards')
        .doc(selectedBoard)
        .collection('messages')
        .add({
      'text': text,
      'user': 'You',
      'timestamp': FieldValue.serverTimestamp(),
    });

    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFACAAC7),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Discussion Boards',
            style: TextStyle(
              fontSize: 32,
              color: Color(0xFF3C3A79),
              fontFamily: 'Josefin Slab',
            ),
          ),

          // Active Boards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 16,
              children: boards.map((board) {
                return GestureDetector(
                  onTap: () => setState(() => selectedBoard = board),
                  child: Container(
                    width: 100,
                    height: 120,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedBoard == board
                            ? const Color(0xFF3C3A79)
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
                        color: Color(0xFF3C3A79),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),
          Text(
            'Board: $selectedBoard',
            style: const TextStyle(
              fontSize: 26,
              fontFamily: 'Josefin Slab',
              color: Color(0xFF3C3A79),
            ),
          ),

          // Chat Display
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
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
                          backgroundColor: Color(0xFFACAAC7),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          msg['text'] ?? '',
                          style: const TextStyle(
                            color: Color(0xFF3C3A79),
                            fontFamily: 'Josefin Slab',
                          ),
                        ),
                        subtitle: Text(
                          (msg['timestamp'] as Timestamp?) != null
                              ? msg['timestamp']
                                  .toDate()
                                  .toLocal()
                                  .toString()
                                  .split('.')[0]
                              : '',
                          style: const TextStyle(fontSize: 12),
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
                      fillColor: const Color(0xFFD3C9D1),
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
                    backgroundColor: const Color(0xFF5B5B5B),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
