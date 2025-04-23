# Crystal Ball

A Flutter application for AI-powered book recommendations.

## Setup Instructions

### Firebase Configuration

1. Create your own Firebase project:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Click "Add project" and follow the setup steps
   - Enable Authentication and Firestore in your project

2. Configure Firebase in your Flutter project:
   ```bash
   # Install FlutterFire CLI if you haven't already
   dart pub global activate flutterfire_cli

   # Configure Firebase for your project
   flutterfire configure
   ```

3. Set up environment variables:
   - Copy `firebase_options.example.dart` to `firebase_options.dart`
   - Create a `.env` file in the root directory
   - Add your Firebase configuration values to the `.env` file:
     ```
     # Web Configuration
     FIREBASE_WEB_API_KEY=your_web_api_key
     FIREBASE_WEB_APP_ID=your_web_app_id
     FIREBASE_WEB_MESSAGING_SENDER_ID=your_web_messaging_sender_id
     FIREBASE_WEB_PROJECT_ID=your_web_project_id
     FIREBASE_WEB_AUTH_DOMAIN=your_web_auth_domain
     FIREBASE_WEB_STORAGE_BUCKET=your_web_storage_bucket

     # Android Configuration
     FIREBASE_ANDROID_API_KEY=your_android_api_key
     FIREBASE_ANDROID_APP_ID=your_android_app_id
     FIREBASE_ANDROID_MESSAGING_SENDER_ID=your_android_messaging_sender_id
     FIREBASE_ANDROID_PROJECT_ID=your_android_project_id
     FIREBASE_ANDROID_STORAGE_BUCKET=your_android_storage_bucket

     # Windows Configuration
     FIREBASE_WINDOWS_API_KEY=your_windows_api_key
     FIREBASE_WINDOWS_APP_ID=your_windows_app_id
     FIREBASE_WINDOWS_MESSAGING_SENDER_ID=your_windows_messaging_sender_id
     FIREBASE_WINDOWS_PROJECT_ID=your_windows_project_id
     FIREBASE_WINDOWS_AUTH_DOMAIN=your_windows_auth_domain
     FIREBASE_WINDOWS_STORAGE_BUCKET=your_windows_storage_bucket
     ```

4. Install dependencies:
   ```bash
   flutter pub get
   ```

5. Run the app:
   ```bash
   flutter run
   ```

## Important Notes

- Do not share your `.env` file or `firebase_options.dart` as they contain sensitive configuration
- Each developer should use their own Firebase project for development
- The `.env` and `firebase_options.dart` files are gitignored for security reasons

