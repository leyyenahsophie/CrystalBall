import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<List<Book>> fetchBooks(String genre) async {
      String artUrl = '';
      String biographyUrl = '';
      String fictionUrl = '';
      String nonFictionUrl = '';
      String graphicNovelUrl = '';
      String romanceUrl = '';
      String mysteryUrl = '';
      String ThrillerUrl = '';

    final response = await http.get(
      Uri.parse(
          'https://opentdb.com/api.php?amount=10&category=9&difficulty=easy&type=multiple'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Question> questions = (data['results'] as List)
          .map((questionData) => Question.fromJson(questionData))
          .toList();
      return questions;
    } else {
      throw Exception('Failed to load questions');
    }
  }
}

class Book{
}
