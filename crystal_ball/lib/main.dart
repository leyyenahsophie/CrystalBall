import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'colors.dart';
import 'review_screen.dart';
import 'registration.dart';
import 'profile.dart';
import 'reading_list.dart';
import 'discussion_boards.dart';
import 'homescreen.dart';


void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('Starting app initialization...');

    try {
      await dotenv.load(fileName: ".env");
      print('Environment variables loaded successfully');
      print(
        'Firebase Web API Key: ${dotenv.env['FIREBASE_WEB_API_KEY']?.substring(0, 5)}...',
      );
    } catch (e) {
      print('Error loading .env file: $e');
      rethrow;
    }

    try {
      print('Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
      rethrow;
    }

    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('Fatal error during initialization: $e');
    print('Stack trace: $stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Failed to initialize app: $e')),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CrystalBall',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homePageBkg, // Light purple background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Crystal Ball',
              style: TextStyle(fontSize:100, fontWeight: FontWeight.bold, fontFamily: 'Island Moments', color:AppColors.textPrimary),
            ),
            Image(
              image: const AssetImage('assets/images/crystal_ball.png'),
              width: MediaQuery.of(context).size.width * 0.5,
              height: MediaQuery.of(context).size.height * 0.5,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text('Sign In', style: TextStyle(color: AppColors.textPrimary, fontSize: 40, fontFamily: 'Island Moments')),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainRegisterPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text('Register', style: TextStyle(color: AppColors.textPrimary, fontSize: 40, fontFamily: 'Island Moments')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 853,
          height: 1094,
          decoration: const BoxDecoration(color: Color(0xFFE3D3EB)),
          child: Stack(
            children: [
              Positioned(
                left: 214,
                top: 28,
                child: SizedBox(
                  width: 275,
                  height: 74,
                  child: Text(
                    'Crystal Ball',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF3C3A79),
                      fontSize: 36,
                      fontFamily: 'Island Moments',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 260,
                top: 180,
                child: EmailPasswordForm(auth: FirebaseAuth.instance),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainRegisterPage extends StatelessWidget {
  const MainRegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const RegisterPage();
  }
}

class LoggedInPage extends StatefulWidget {
  const LoggedInPage({Key? key}) : super(key: key);

  @override
  State<LoggedInPage> createState() => _LoggedInPageState();
}

class _LoggedInPageState extends State<LoggedInPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD3C9D1),
        title: const Text(
          'Crystal Ball',
          style: TextStyle(
            fontSize: 36,
            color: Color(0xFF3C3A79),
            fontFamily: 'Island Moments',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SplashScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: [
          // Home Page
          const HomeScreenPage(),
          // Reading List Page
          Center(
            child: ReadingListPage(),
          ),
          // Review Screen
          Center(
            child: ReviewPage(),
          ),
          // Discussion Board Page
          Center(
            child: DiscussionBoardPage(),
          ),
          // Profile Page
          Center(
            child: ProfilePage(
              currentEmail: user?.email ?? '',
              currentName: user?.email ?? '',
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavyBar(
        selectedIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() => _currentIndex = index);
          _pageController.jumpToPage(index);
        },
        items: [
          BottomNavyBarItem(
            icon: const Icon(Icons.home),
            title: const Text("Home"),
            activeColor: const Color(0xFFC33149),
          ),
          BottomNavyBarItem(
            icon: const Icon(Icons.book),
            title: const Text("Reading List"),
            activeColor: const Color(0xFFA8C256),
          ),
          BottomNavyBarItem(
            icon: const Icon(Icons.rate_review),
            title: const Text("Review Screen"),
            activeColor: const Color(0xFF495867),
          ),
          BottomNavyBarItem(
            icon: const Icon(Icons.forum),
            title: const Text("Discussion Board"),
            activeColor: const Color(0xFF495867),
          ),
          BottomNavyBarItem(
            icon: const Icon(Icons.person),
            title: const Text("Profile"),
            activeColor: const Color(0xFF495867),
          ),
        ],
      ),
    );
  }
}

class EmailPasswordForm extends StatefulWidget {
  EmailPasswordForm({Key? key, required this.auth}) : super(key: key);
  final FirebaseAuth auth;

  @override
  _EmailPasswordFormState createState() => _EmailPasswordFormState();
}

class _EmailPasswordFormState extends State<EmailPasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _success = false;
  bool _initialState = true;
  String? _userEmail;

  void _login() async {
    try {
      await widget.auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() {
        _success = true;
        _userEmail = _emailController.text;
        _initialState = false;
      });
      if (_success) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoggedInPage()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _success = false;
        _initialState = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Email',
            style: TextStyle(
              color: Color(0xFF3C3A79),
              fontSize: 36,
              fontFamily: 'Josefin Slab',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 315,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xA33C3A79),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextFormField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter email',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter some text';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Password',
            style: TextStyle(
              color: Color(0xFF3C3A79),
              fontSize: 36,
              fontFamily: 'Josefin Slab',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 315,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xA33C3A79),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextFormField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter password',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter some text';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 261,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _login();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFACAAC7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  color: Color(0xFF3C3A79),
                  fontSize: 28,
                  fontFamily: 'Josefin Slab',
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Register here if you don\'t have an account!',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
                fontFamily: 'Josefin Slab',
              ),
            ),
          ),
          Container(
            alignment: Alignment.center,
            child: Text(
              _initialState
                  ? 'Please Login'
                  : _success
                  ? 'Successfully logged in $_userEmail'
                  : 'Login failed',
              style: TextStyle(color: _success ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
