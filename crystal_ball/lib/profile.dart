import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class ProfilePage extends StatelessWidget {
  final String currentEmail;
  final String currentName;

  const ProfilePage({
    super.key,
    required this.currentEmail,
    required this.currentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4D3EC),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            width: 650,
            decoration: BoxDecoration(
              color: const Color(0xFFF5E9F0),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(4, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'PROFILE',
                  style: TextStyle(
                    fontSize: 32,
                    fontFamily: 'Josefin Slab',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3C3A79),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Current Email: $currentEmail\nCurrent Name: $currentName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Josefin Slab',
                    color: Color(0xFF3C3A79),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 26,
                    fontFamily: 'Josefin Slab',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3C3A79),
                  ),
                ),
                const SizedBox(height: 24),
                const ProfileForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool updated = false;

  final List<String> genres = [
    'ART',
    'COOKBOOKS',
    'FICTION',
    'TRAVEL',
    'SPORTS',
    'ROMANCE',
    'MYSTERY',
    'THRILLER',
  ];

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        filled: true,
        fillColor: const Color(0xFFACAAC7),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      );

  void _submitUpdate() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      print('Updated Profile Info: $values');
      setState(() => updated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Email + Password Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Email',
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFF3C3A79),
                          fontFamily: 'Josefin Slab',
                        )),
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'email',
                      decoration: _fieldDecoration('Enter your email'),
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
                          fontSize: 20,
                          color: Color(0xFF3C3A79),
                          fontFamily: 'Josefin Slab',
                        )),
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'password',
                      obscureText: true,
                      decoration: _fieldDecoration('Enter your password'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Name field
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Name',
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF3C3A79),
                fontFamily: 'Josefin Slab',
              ),
            ),
          ),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'name',
            decoration: _fieldDecoration('Enter your name'),
          ),

          const SizedBox(height: 30),

          const Text(
            'Favorite Genres',
            style: TextStyle(
              fontSize: 22,
              fontFamily: 'Josefin Slab',
              color: Color(0xFF3C3A79),
            ),
          ),
          const SizedBox(height: 16),

          // Genre grid
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: genres.map((genre) {
              return FormBuilderFieldOption(
                value: genre,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xA33C3A79),
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
                          side: const BorderSide(color: Colors.white),
                          checkColor: Colors.white,
                          activeColor: const Color(0xFF3C3A79),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        genre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'Sedan SC',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 30),

          // Update button
          SizedBox(
            width: 180,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFACAAC7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Update',
                style: TextStyle(
                  fontSize: 20,
                  color: Color(0xFF3C3A79),
                  fontFamily: 'Josefin Slab',
                ),
              ),
            ),
          ),

          if (updated)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Profile updated!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
