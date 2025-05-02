import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';
import 'colors.dart';

class ProfilePage extends StatefulWidget {
  final String currentEmail;
  final String currentName;
  
  const ProfilePage({
    super.key, 
    required this.currentEmail,
    required this.currentName,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool updated = false;
  bool isLoading = true;
  Map<String, dynamic>? userData;
  Set<String> selectedGenres = {};

  final List<String> genres = [
    'ART',
    'BIOGRAPHY',
    'FICTION',
    'NONFICTION',
    'GRAPHIC NOVELS',
    'ROMANCE',
    'MYSTERY',
    'THRILLER',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            userData = data;
            // Convert genres to uppercase and ensure they match the UI format
            final genresList = (data?['genres'] as List<dynamic>?)?.map((g) => g.toString().toUpperCase()) ?? [];
            selectedGenres = Set<String>.from(genresList);
            print('Loaded genres: $selectedGenres'); // Debug print
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        filled: true,
        fillColor: AppColors.secondary,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      );

  Future<void> _submitUpdate() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;

      if (user != null && userId != null) {
        final db = DatabaseService.instance;
        bool hasChanges = false;

        try {
          // Update email if changed and not empty
          if (values['email'] != null && 
              values['email'].toString().isNotEmpty && 
              values['email'] != user.email) {
            await db.changeEmail(values['email']);
            hasChanges = true;
          }

          // Update password if changed and not empty
          if (values['password'] != null && values['password'].toString().isNotEmpty) {
            await db.changePassword(values['password']);
            hasChanges = true;
          }

          // Update display name if changed and not empty
          if (values['name'] != null && 
              values['name'].toString().isNotEmpty && 
              values['name'] != userData?['displayName']) {
            await db.changeDisplayName(userId, values['name']);
            hasChanges = true;
          }

          // Update genres
          final newSelectedGenres = Set<String>.from(
            genres.where((genre) => values[genre] == true)
          );

          // Update genres in Firestore directly
          await FirebaseFirestore.instance.collection('users').doc(userId).update({
            'genres': newSelectedGenres.toList(),
          });
          
          // Update local state
          setState(() {
            selectedGenres = newSelectedGenres;
          });
          
          hasChanges = true;

          if (hasChanges) {
            await _loadUserData();
            setState(() => updated = true);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        } catch (e) {
          print('Update failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Update failed: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final initialValues = {
      'email': userData?['email'] ?? '',
      'name': userData?['displayName'] ?? '',
    };
    
    // Initialize checkbox values based on selectedGenres
    for (String genre in genres) {
      initialValues[genre] = selectedGenres.contains(genre);
    }

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
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 32,
                    fontFamily: 'Island Moments',
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 40),
                FormBuilder(
                  key: _formKey,
                  initialValue: initialValues,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Email + Password
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Email', style: TextStyle(fontSize: 20, color: AppColors.textPrimary, fontFamily: 'Josefin Slab')),
                                const SizedBox(height: 8),
                                FormBuilderTextField(
                                  name: 'email',
                                  decoration: _fieldDecoration('Enter your email'),
                                  validator: FormBuilderValidators.compose([
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
                                const Text('Password', style: TextStyle(fontSize: 20, color: AppColors.textPrimary, fontFamily: 'Josefin Slab')),
                                const SizedBox(height: 8),
                                FormBuilderTextField(
                                  name: 'password',
                                  obscureText: true,
                                  decoration: _fieldDecoration('Enter your password'),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Name', style: TextStyle(fontSize: 20, color: AppColors.textPrimary, fontFamily: 'Josefin Slab')),
                      ),
                      const SizedBox(height: 8),
                      FormBuilderTextField(
                        name: 'name',
                        decoration: _fieldDecoration('Enter your name'),
                      ),

                      const SizedBox(height: 30),

                      const Text('Favorite Genres', style: TextStyle(fontSize: 22, fontFamily: 'Josefin Slab', color: AppColors.textPrimary)),
                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: genres.map((genre) {
                          return Container(
                            width: 200,
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
                                  initialValue: selectedGenres.contains(genre),
                                  builder: (field) => Checkbox(
                                    value: field.value ?? false,
                                    onChanged: (val) {
                                      field.didChange(val);
                                      setState(() {
                                        if (val == true) {
                                          selectedGenres.add(genre);
                                        } else {
                                          selectedGenres.remove(genre);
                                        }
                                      });
                                    },
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
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: 180,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Update',
                            style: TextStyle(
                              fontSize: 20,
                              color: AppColors.textPrimary,
                              fontFamily: 'Josefin Slab',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
