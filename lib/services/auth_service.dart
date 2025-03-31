import 'package:expense_tracker/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Check if user is already authenticated
  Future<User?> get currentUser async {
    return _auth.currentUser;
  }
  
  // Google Sign In
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null;
      }
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Once signed in, get the UserCredential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      
      if (user != null) {
        // Check if user exists in Firestore
        final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
        
        final UserModel userModel = UserModel(
          id: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          photoUrl: user.photoURL,
        );
        
        if (!docSnapshot.exists) {
          // Create new user document in Firestore
          await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
        }
        
        // Store user ID in SharedPreferences
        await _saveUserIdToPrefs(user.uid);
        
        return userModel;
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
    
    return null;
  }
  
  // Save user ID to SharedPreferences
  Future<void> _saveUserIdToPrefs(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }
  
  // Get user ID from SharedPreferences
  Future<String?> getUserIdFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }
  
  // Get user from Firestore
  Future<UserModel?> getUserFromFirestore(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return UserModel.fromMap({'id': docSnapshot.id, ...data});
      }
    } catch (e) {
      print('Error getting user from Firestore: $e');
    }
    
    return null;
  }
  
  // Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
    } catch (e) {
      print('Error signing out: $e');
    }
  }
} 