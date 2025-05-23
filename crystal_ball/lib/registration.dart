import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'colors.dart';
import 'main.dart';
import 'database_service.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            margin: const EdgeInsets.all(24),
            width: 600,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(4, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: BackButton(),
                ),
                const Text(
                  'Crystal Ball',
                  style: TextStyle(
                    fontSize: 32,
                    fontFamily: 'Island Moments',
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 40),
                RegisterForm(auth: FirebaseAuth.instance),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  final FirebaseAuth auth;
  const RegisterForm({super.key, required this.auth});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _success = false;
  bool _initial = true;
  String? _userEmail;

  void _register() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      try {
        final data = _formKey.currentState!.value;
        final uid = await DatabaseService.instance.addLogin(
          data['email'],
          data['password'],
        );
        
        if (uid != null) {
          // Add selected genres to user document
          final selectedGenres = (data['genres'] as List<dynamic>?)?.cast<String>() ?? [];
          for (final genre in selectedGenres) {
            await DatabaseService.instance.addGenres(uid, genre);
          }
          
          setState(() {
            _success = true;
            _initial = false;
            _userEmail = data['email'];
          });
          
          // Navigate to login page on success
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        } else {
          setState(() {
            _success = false;
            _initial = false;
          });
        }
      } catch (e) {
        print('Registration error: $e');
        setState(() {
          _success = false;
          _initial = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        filled: true,
        fillColor: AppColors.secondary,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          // Email + Password row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Email',
                        style: TextStyle(
                            fontSize: 22,
                            color: AppColors.textPrimary,
                            fontFamily: 'Josefin Slab')),
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'email',
                      decoration: _inputDecoration('Enter your email'),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.email(),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Password',
                        style: TextStyle(
                            fontSize: 22,
                            color: AppColors.textPrimary,
                            fontFamily: 'Josefin Slab')),
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'password',
                      obscureText: true,
                      decoration: _inputDecoration('Enter your password'),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.minLength(6),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          const Text(
            'Favorite Genres',
            style: TextStyle(
              fontSize: 22,
              fontFamily: 'Josefin Slab',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // Genre grid with consistent spacing
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              for (final genre in [
                'ART',
                'BIOGRAPHY',
                'FICTION',
                'NONFICTION',
                'GRAPHIC NOVELS',
                'ROMANCE',
                'MYSTERY',
                'THRILLER',
              ])
                Container(
                  width: 200, // Fixed width for consistent spacing
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.accent1,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FormBuilderField<bool>(
                        name: genre,
                        builder: (field) => Checkbox(
                          value: field.value ?? false,
                          onChanged: (val) => field.didChange(val),
                          side: const BorderSide(color: AppColors.textSecondary),
                          checkColor: AppColors.textSecondary,
                          activeColor: AppColors.accent1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          genre,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 18,
                            fontFamily: 'Sedan SC',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: 180,
            height: 50,
            child: ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Register',
                style: TextStyle(
                  fontSize: 20,
                  color: AppColors.textPrimary,
                  fontFamily: 'Josefin Slab',
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
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
              'Login here if you have an account!',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
                fontFamily: 'Josefin Slab',
              ),
            ),
          ),
          if (!_initial)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _success
                    ? 'Successfully registered $_userEmail'
                    : 'Registration failed',
                style: TextStyle(
                    color: _success ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold),
              ),
            )
        ],
      ),
    );
  }
}
