import 'package:expense_tracker/models/user_model.dart';
import 'package:expense_tracker/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn;
  final FirestoreService _firestoreService;
  
  // Constructor
  AuthService() : 
    _auth = FirebaseAuth.instance is FirebaseAuth ? FirebaseAuth.instance : null,
    _googleSignIn = GoogleSignIn(),
    _firestoreService = FirestoreService();
  
  // Initialize Firestore persistence
  Future<void> initialize() async {
    try {
      await _firestoreService.setupPersistence();
      await _firestoreService.initializeDefaultCategories();
    } catch (e) {
      print("Error initializing Firestore: $e");
      // Continue even if initialization fails
    }
  }
  
  // Check if user is already authenticated
  Future<User?> get currentUser async {
    return _auth?.currentUser;
  }
  
  // Google Sign In
  Future<UserModel?> signInWithGoogle() async {
    if (_auth == null) {
      throw Exception("Firebase Auth is not initialized");
    }
    
    try {
      print("Starting Google Sign In process");
      
      // Begin interactive sign in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print("Google Sign In aborted by user");
        return null;
      }
      
      print("Got Google user: ${googleUser.email}");
      
      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print("Got Google auth tokens");
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      print("Created credential, signing in with Firebase");
      
      // Sign in to Firebase with the Google Auth credential
      final UserCredential authResult = await _auth!.signInWithCredential(credential);
      final User? user = authResult.user;
      
      if (user == null) {
        print("Firebase user is null after sign in");
        return null;
      }
      
      print("Firebase sign in successful: ${user.uid}");
      
      // Create user model from Firebase User
      UserModel userModel = UserModel(
        uid: user.uid,
        name: user.displayName ?? 'User',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        phoneNumber: user.phoneNumber,
      );
      
      // Try to save user to Firestore, but continue even if it fails
      try {
        // Check if user exists in Firestore, if not create a new user
        UserModel? existingUser = await _firestoreService.getUser(user.uid);
        
        if (existingUser == null) {
          print("Creating new user in Firestore");
          // Save user to Firestore
          await _firestoreService.saveUser(userModel);
          
          // Initialize user settings
          await _firestoreService.getUserSettings(user.uid);
        } else {
          print("User already exists in Firestore");
          userModel = existingUser;
        }
      } catch (e) {
        print("Error accessing Firestore: $e");
        // Continue with authentication even if Firestore fails
        // This makes the app usable even when Firestore is not available
      }
      
      // Save user ID to SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.uid);
      
      print("Google Sign In completed successfully");
      return userModel;
    } catch (e) {
      print("Error in Google Sign In: $e");
      return null;
    }
  }
  
  // Get user ID from SharedPreferences
  Future<String?> getUserIdFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }
  
  // Get user from Firestore
  Future<UserModel?> getUserFromFirestore(String userId) async {
    try {
      return await _firestoreService.getUser(userId);
    } catch (e) {
      print("Error getting user from Firestore: $e");
      // If Firestore is unavailable, create a basic user model from Firebase Auth
      User? currentUser = _auth?.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        return UserModel(
          uid: currentUser.uid,
          name: currentUser.displayName ?? 'User',
          email: currentUser.email ?? '',
          photoUrl: currentUser.photoURL,
          phoneNumber: currentUser.phoneNumber,
        );
      }
      return null;
    }
  }
  
  // Email/Password Sign In
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    if (_auth == null) {
      throw Exception("Firebase Auth is not initialized");
    }
    
    try {
      print("Starting Email/Password Sign In process");
      
      // Sign in with email and password
      final UserCredential authResult = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = authResult.user;
      
      if (user == null) {
        print("Firebase user is null after sign in");
        return null;
      }
      
      print("Firebase sign in successful: ${user.uid}");
      
      // Try to get user from Firestore
      try {
        UserModel? userModel = await _firestoreService.getUser(user.uid);
        
        if (userModel != null) {
          // Save user ID to SharedPreferences for persistence
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', user.uid);
          
          return userModel;
        }
      } catch (e) {
        print("Error accessing Firestore: $e");
      }
      
      // If user doesn't exist in Firestore or there was an error, create a basic user model
      UserModel userModel = UserModel(
        uid: user.uid,
        name: user.displayName ?? 'User',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        phoneNumber: user.phoneNumber,
      );
      
      // Try to save user to Firestore
      try {
        await _firestoreService.saveUser(userModel);
      } catch (e) {
        print("Error saving user to Firestore: $e");
      }
      
      // Save user ID to SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.uid);
      
      print("Email/Password Sign In completed successfully");
      return userModel;
    } catch (e) {
      print("Error in Email/Password Sign In: $e");
      return null;
    }
  }
  
  // Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      if (_auth != null) {
        await _auth!.signOut();
      }
      
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
    } catch (e) {
      print("Error signing out: $e");
      throw e;
    }
  }
} 