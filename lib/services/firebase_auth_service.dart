import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseAuthService {
  // Singleton pattern
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;

  // Lazy initialization of Firebase Auth
  FirebaseAuth? _auth;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // Getter for auth that initializes on demand
  FirebaseAuth get auth {
    if (_auth == null) {
      try {
        if (Firebase.apps.isEmpty) {
          print(
              'Error getting FirebaseAuth instance: Firebase not initialized');
          throw Exception('Firebase not initialized');
        }
        _auth = FirebaseAuth.instance;
      } catch (e) {
        print('Error getting FirebaseAuth instance: $e');
        throw Exception(
            'Firebase Auth not initialized. Make sure Firebase.initializeApp() is called first.');
      }
    }
    return _auth!;
  }

  // Current user with error handling
  User? get currentUser {
    try {
      if (_auth == null) {
        if (Firebase.apps.isEmpty) {
          print('Error getting current user: Firebase not initialized');
          return null;
        }
        try {
          _auth = FirebaseAuth.instance;
        } catch (e) {
          print('Error initializing auth instance: $e');
          return null;
        }
      }
      return _auth?.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  bool get isLoggedIn => currentUser != null;

  // Private constructor
  FirebaseAuthService._internal();

  // Initialize method to be called after Firebase.initializeApp()
  Future<void> initialize() async {
    if (_isInitialized) {
      print('FirebaseAuthService already initialized');
      return;
    }

    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        print(
            'Cannot initialize FirebaseAuthService - Firebase.initializeApp() was not called or failed');
        return;
      }

      // Initialize auth if needed
      _auth = FirebaseAuth.instance;
      _isInitialized = true;
      print('FirebaseAuthService initialized successfully');
    } catch (e) {
      print('Error initializing FirebaseAuthService: $e');
      _isInitialized = false;
      // Don't rethrow to allow app to continue
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      if (!_isInitialized && Firebase.apps.isEmpty) {
        print('Cannot sign in - Firebase is not initialized');
        throw Exception(
            'Firebase not initialized. Please configure Firebase and restart the app.');
      }

      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (_auth != null) {
        await _auth!.signOut();
      } else {
        print('Cannot sign out - Auth is not initialized');
      }
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Register new user
  Future<User?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      if (!_isInitialized && Firebase.apps.isEmpty) {
        print('Cannot register - Firebase is not initialized');
        return null;
      }

      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error registering user: $e');
      return null;
    }
  }

  // Get the current user's ID (will be used as a unique identifier for database)
  String? get userId => currentUser?.uid;

  // Stream to listen for auth state changes
  Stream<User?> get authStateChanges {
    try {
      if (_auth == null) {
        if (Firebase.apps.isEmpty) {
          print('Cannot get auth state changes - Firebase not initialized');
          return Stream.value(null);
        }
        try {
          _auth = FirebaseAuth.instance;
        } catch (e) {
          print('Error initializing auth for state changes: $e');
          return Stream.value(null);
        }
      }
      return _auth!.authStateChanges();
    } catch (e) {
      print('Error getting auth state changes: $e');
      return Stream.value(null);
    }
  }
}
