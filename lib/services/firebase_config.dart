import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  // Return null by default - this makes the initializeApp() call fallback to using
  // the platform configuration files (GoogleService-Info.plist and google-services.json)
  static FirebaseOptions? get platformOptions => null;
}
