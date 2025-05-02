import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      return userCredential.user?.uid;
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

      // Store additional user data in Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'displayName': email,
        'genres': [],
        'readingList': {
          'wantToRead' : [],
          'currentlyReading' : [],
          'finishedReading': [],
        },
        'recommendations':[],
        'activeDiscussionBoards': [],
      });
      
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

  // Task methods
  Future<void> addTask(String userId, String taskName) async {
    try {
      await _firestore.collection('tasks').add({
        'userId': userId,
        'taskName': taskName,
        'isCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'isCompleted': isCompleted,
      });
    } catch (e) {
      print('Error toggling task: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
} 