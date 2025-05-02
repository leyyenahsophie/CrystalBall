import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'dart:math';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Authentication methods
  Future<String?> verifyLogin(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final uid = userCredential.user?.uid;
      if (uid != null) {
        // Generate new recommended books on login
        await generateRecommendedBooks(uid);
        print('Generated new recommended books for user: $uid');
      }
      
      return uid;
    } on FirebaseAuthException catch (e) {
      print('Login error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected login error: $e');
      return null;
    }
  }

  Future<String?> addLogin(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final uid = userCredential.user?.uid;
      
      if (uid == null) {
        print('Error: User created but UID is null');
        return null;
      }

      // Store additional user data in Firestore
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'displayName': email,
        'genres': [],
        'readingList': {
          'wantToRead': [],
          'currentlyReading': [],
          'completed': [],
        },
        'recommendations': [],
        'activeDiscussionBoards': [],
      });

      // Generate and store recommended books
      await generateRecommendedBooks(uid);
      
      return uid;
    } on FirebaseAuthException catch (e) {
      print('Registration error: ${e.code} - ${e.message}');
      if (e.code == 'email-already-in-use') {
        throw Exception('Email is already in use');
      }
      return null;
    } catch (e) {
      print('Unexpected registration error: $e');
      return null;
    }
  }

  Future<bool> isUsernameTaken(String email) async {
    try {
      final signInMethods = await _auth.fetchSignInMethodsForEmail(email);
      return signInMethods.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

    //change password
  Future<void> changePassword(String newPassword) async{
    try{
      final user = FirebaseAuth.instance.currentUser;
      if (user != null){
        await user.updatePassword(newPassword);
        print("Password updated successfully");
      }else{
        print("Unable to update password.");
      }
    } on FirebaseAuthException catch (e){
      print("Error: ${e.code} - ${e.message}");
      if(e.code == 'required-recent-login'){
        //Prompt user to reauthenticate
        print("Please reauthenticate and try again.");
      }
    }
  }

//change email
  Future<void> changeEmail(String newEmail) async{
    try{
      final user = FirebaseAuth.instance.currentUser;
      if (user != null){
        await user.verifyBeforeUpdateEmail(newEmail);
        print("Email updated successfully");
      }else{
        print("Unable to update email.");
      }
    } on FirebaseAuthException catch (e){
      print("Error: ${e.code} - ${e.message}");
      if(e.code == 'required-recent-login'){
        //Prompt user to reauthenticate
        print("Please reauthenticate and try again.");
      }
    }
  }

//change display name
Future<void> changeDisplayName(String userId, String newName) async{
  try{
    await _firestore.collection('users').doc(userId).update({ 
      'displayName': newName
    });
  } catch (e){
    print('Error updating display name');
    rethrow;
  }
}

//adding new genres
  Future<void> addGenres(String userId, String genreName) async{
    try{
      await _firestore.collection('users').doc(userId).update({
        'genres': FieldValue.arrayUnion([genreName])
      });
    }catch (e) {
      print('Error updating genre(s): $e');
      rethrow;
    }
  }
//removing genres
  Future<void> removeGenres(String userId, String genreName) async{
    try{
      await _firestore.collection('users').doc(userId).update({
        'genres': FieldValue.arrayRemove([genreName])
      });
    }catch (e){
      print('Error removing genre(s): $e');
      rethrow;
    }
  }

//create review
  void createReviews(String userId, String review, String reviewTitle, String bookTitle, int rating) {
   FirebaseFirestore.instance
    .collection('bookReviews')
    .add({
      'bookTitle': bookTitle,
      'userId': userId,
      'review': review,
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Update book status in books collection
  Future<void> updateBookStatus(String userId, String bookTitle, String status) async {
    try {
      // First check if the book exists in the user's books collection
      final bookQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('books')
          .where('title', isEqualTo: bookTitle)
          .get();

      if (bookQuery.docs.isEmpty) {
        print('Book not found in user\'s collection: $bookTitle');
        return;
      }

      final bookDoc = bookQuery.docs.first;
      final bookRef = bookDoc.reference;
      final bookData = bookDoc.data();

      // Update the book's status in the books collection
      await bookRef.update({
        'wantToRead': status == 'Want to Read',
        'currentlyReading': status == 'Currently Reading',
        'completed': status == 'Completed',
      });

      // Get the current reading list
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData == null || userData['readingList'] == null) return;

      final readingList = Map<String, List<dynamic>>.from(userData['readingList']);
      
      // Remove the book from all lists first
      for (var list in readingList.keys) {
        readingList[list] = (readingList[list] as List)
            .where((book) => book['title'] != bookTitle)
            .toList();
      }

      // Add the book to the appropriate list
      if (status == 'Want to Read') {
        readingList['wantToRead'] = [...readingList['wantToRead'] ?? [], bookData];
      } else if (status == 'Currently Reading') {
        readingList['currentlyReading'] = [...readingList['currentlyReading'] ?? [], bookData];
      } else if (status == 'Completed') {
        readingList['completed'] = [...readingList['completed'] ?? [], bookData];
      }

      // Update the reading list
      await _firestore.collection('users').doc(userId).update({
        'readingList': readingList,
      });

    } catch (e) {
      print('Error updating book status: $e');
      rethrow;
    }
  }

  // Add a book to the user's books collection
  Future<void> addBookToCollection(String userId, Map<String, dynamic> book) async {
    try {
      // Check if book already exists
      final existingBook = await _firestore
          .collection('users')
          .doc(userId)
          .collection('books')
          .where('title', isEqualTo: book['title'])
          .get();

      if (existingBook.docs.isEmpty) {
        // Add new book to collection
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('books')
            .add({
          ...book,
          'wantToRead': false,
          'currentlyReading': false,
          'completed': false,
        });
      }
    } catch (e) {
      print('Error adding book to collection: $e');
      rethrow;
    }
  }

  Future<void> generateRecommendedBooks(String userId) async {
    try {
      final List<String> genres = [
        'art',
        'biography',
        'fiction',
        'nonfiction',
        'comics',
        'drama',
        'mystery',
        'thriller'
      ];

      List<Map<String, dynamic>> allRecommendedBooks = [];

      for (String genre in genres) {
        try {
          final books = await ApiService.fetchBooks(genre);
          if (books.isNotEmpty) {
            // Randomly select 2 books from the genre
            final random = Random();
            final selectedBooks = books.length >= 2 
                ? List.generate(2, (_) => books[random.nextInt(books.length)])
                : books;

            for (var book in selectedBooks) {
              final bookData = {
                'title': book.title,
                'author': book.author,
                'description': book.description,
                'imageUrl': book.imageUrl,
                'genre': book.genre,
                'publishedDate': book.publishedDate,
                'wantToRead': false,
                'currentlyReading': false,
                'completed': false,
              };
              
              // Add to recommended books list
              allRecommendedBooks.add(bookData);
              
              // Add to user's books collection
              await addBookToCollection(userId, bookData);
            }
          }
        } catch (e) {
          print('Error fetching books for genre $genre: $e');
        }
      }

      print('Generated ${allRecommendedBooks.length} recommended books');

      // Store recommended books in Firestore
      await _firestore.collection('users').doc(userId).update({
        'recommendations': allRecommendedBooks,
      });

      print('Successfully stored recommended books in Firestore');

    } catch (e) {
      print('Error generating recommended books: $e');
      rethrow;
    }
  }

  // Get recommended books for a user
  Future<List<Map<String, dynamic>>> getRecommendedBooks(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data != null && data['recommendations'] != null) {
        return List<Map<String, dynamic>>.from(data['recommendations']);
      }
      return [];
    } catch (e) {
      print('Error getting recommended books: $e');
      return [];
    }
  }

  // Get most recent books for each category
  Future<Map<String, List<Map<String, dynamic>>>> getMostRecentBooks(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data != null && data['readingList'] != null) {
        final readingList = data['readingList'] as Map<String, dynamic>;
        
        Map<String, List<Map<String, dynamic>>> mostRecent = {
          'wantToRead': [],
          'currentlyReading': [],
          'completed': [],
        };
        
        // Get all books from each category
        if (readingList['wantToRead'] != null) {
          mostRecent['wantToRead'] = List<Map<String, dynamic>>.from(readingList['wantToRead']);
        }
        if (readingList['currentlyReading'] != null) {
          mostRecent['currentlyReading'] = List<Map<String, dynamic>>.from(readingList['currentlyReading']);
        }
        if (readingList['completed'] != null) {
          mostRecent['completed'] = List<Map<String, dynamic>>.from(readingList['completed']);
        }
        
        return mostRecent;
      }
      return {
        'wantToRead': [],
        'currentlyReading': [],
        'completed': [],
      };
    } catch (e) {
      print('Error getting most recent books: $e');
      return {
        'wantToRead': [],
        'currentlyReading': [],
        'completed': [],
      };
    }
  }

  // Get all books from user's collection
  Future<List<Map<String, dynamic>>> getUserBooks(String userId) async {
    try {
      final booksSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('books')
          .get();
      
      return booksSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting user books: $e');
      return [];
    }
  }
} 