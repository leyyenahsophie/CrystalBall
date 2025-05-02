import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_service.dart';

class ApiService {

  //fetch books based on genre
  static Future<List<Book>> fetchBooks(String genre) async {
      Map<String, String> genreUrls = {
        'art': 'https://www.googleapis.com/books/v1/volumes?q=subject:art&maxResults=20',
        'biography': 'https://www.googleapis.com/books/v1/volumes?q=subject:biography&maxResults=20',
        'fiction': 'https://www.googleapis.com/books/v1/volumes?q=subject:fiction&maxResults=20',
        'nonfiction': 'https://www.googleapis.com/books/v1/volumes?q=subject:nonfiction&maxResults=20',
        'comics': 'https://www.googleapis.com/books/v1/volumes?q=subject:comics&maxResults=20',
        'drama': 'https://www.googleapis.com/books/v1/volumes?q=subject:drama&maxResults=20',
        'mystery': 'https://www.googleapis.com/books/v1/volumes?q=subject:mystery&maxResults=20',
        'thriller': 'https://www.googleapis.com/books/v1/volumes?q=subject:thriller&maxResults=20'
      };

      final url = genreUrls[genre.toLowerCase()];
      if (url == null) {
        throw Exception('Invalid genre: $genre');
      }

      print('Fetching books for genre: $genre from URL: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List booksQuery = data['items'] ?? [];
        List<Book> books = [];

        for(var book in booksQuery){
          final volumeInfo = book['volumeInfo'];

          final getTitle = volumeInfo['title'] ?? 'No Title';
          final getAuthors = volumeInfo['authors']?.join(', ') ?? 'Unknown Author';
          final getDescription = volumeInfo['description'] ?? 'No Description';
          final getImageUrl = volumeInfo['imageLinks']?['thumbnail'] ?? '';
          final getPublishedDate = volumeInfo['publishedDate'] ?? 'Unknown Date';
          final getGenres = (volumeInfo['categories'] as List?)?.cast<String>() ?? ['Uncategorized'];

          Book addBook = Book(
            title: getTitle,
            author: getAuthors,
            description: getDescription,
            imageUrl: getImageUrl,
            genre: getGenres,
            publishedDate: getPublishedDate,
          );

          books.add(addBook);
        }

        print('Successfully fetched ${books.length} books for genre: $genre');
        return books;
      } else {
        print('Failed to fetch books. Status code: ${response.statusCode}');
        throw Exception('Failed to load $genre books');
      }
    }

Future<List<Map<String, dynamic>>> searchBooks(String query) async {
  final formattedQuery = Uri.encodeComponent(query);
  final url = 'https://www.googleapis.com/books/v1/volumes?q=$formattedQuery';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    List<Map<String, dynamic>> books = [];

    for (var item in data['items'] ?? []) {
      final info = item['volumeInfo'];

      books.add({
        'title': info['title'] ?? 'No title',
        'authors': info['authors']?.join(', ') ?? 'Unknown author',
        'description': info['description'] ?? 'No description',
        'imageURL': info['imageLinks']?['thumbnail'] ?? '',
        'categories': info['categories'] ?? ['Uncategorized'],
        'publishedDate': info['publishedDate'] ?? 'Unknown',
      });
    }

    return books;
  } else {
    throw Exception('Failed to fetch books: ${response.statusCode}');
  }
}

  static Future<List<Book>> fetchAllBooks() async {

    final response = await http.get(
      Uri.parse(
          'https://www.googleapis.com/books/v1/volumes?q=book&maxResults=10'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Book> books = (data['results'] as List)
          .map((bookData) => Book.fromJson(bookData))
          .toList();
      return books;
    } else {
      throw Exception('Failed to load books');
    }
  }
}

class Book{
  final String title;
  final String author;
  final String description;
  final String imageUrl;
  final List<String> genre;
  final String publishedDate;
  final bool wantToRead;
  final bool currentlyReading;
  final bool completed;

  Book({
    required this.title,
    required this.author,
    required this.description,
    required this.imageUrl, 
    required this.genre,
    required this.publishedDate,
    this.wantToRead = false,
    this.currentlyReading = false,
    this.completed = false,
  });

  bool isCategory(Book bookId, String g){
      if(genre.contains(g)){
        return true;
      }
      return false;
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'],
      author: json['author'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      genre: json['genre'],
      publishedDate: json['publishedDate'],
      wantToRead: false,
      currentlyReading: false,
      completed: false,
    );
  }
  

}
