import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/models/user_model.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/providers/firestore_provider.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final FirebaseAuth? _firebaseAuth;
  final bool firebaseInitialized;
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  
  // Constructor
  AuthProvider({this.firebaseInitialized = false}) : 
    _authService = AuthService(),
    _firebaseAuth = firebaseInitialized ? FirebaseAuth.instance : null;
  
  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null || (_firebaseAuth != null && _firebaseAuth!.currentUser != null);
  
  // Initialize auth state
  Future<void> initializeAuth() async {
    if (!firebaseInitialized) {
      _error = "Firebase not initialized. Limited functionality available.";
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Check if Firebase user is signed in
      final firebaseUser = _firebaseAuth?.currentUser;
      
      if (firebaseUser != null) {
        // Try to get user from Firestore
        try {
          final userModel = await _authService.getUserFromFirestore(firebaseUser.uid);
          if (userModel != null) {
            _user = userModel;
          } else {
            // Create a basic user model from Firebase user
            _user = UserModel(
              uid: firebaseUser.uid,
              name: firebaseUser.displayName ?? 'User',
              email: firebaseUser.email ?? '',
              photoUrl: firebaseUser.photoURL,
              phoneNumber: firebaseUser.phoneNumber,
            );
          }
        } catch (e) {
          // If Firestore fails, create user from Firebase Auth
          _user = UserModel(
            uid: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'User',
            email: firebaseUser.email ?? '',
            photoUrl: firebaseUser.photoURL,
            phoneNumber: firebaseUser.phoneNumber,
          );
        }
      } else {
        // Check if user ID is stored in preferences
        final userId = await _authService.getUserIdFromPrefs();
        
        if (userId != null) {
          try {
            final userModel = await _authService.getUserFromFirestore(userId);
            if (userModel != null) {
              _user = userModel;
            }
          } catch (e) {
            // Cannot authenticate, clear stored user ID
            // This happens if the token is expired or invalid
            _user = null;
          }
        }
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Google Sign In
  Future<bool> signInWithGoogle(BuildContext context) async {
    if (!firebaseInitialized) {
      _error = "Cannot sign in: Firebase not initialized";
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final userModel = await _authService.signInWithGoogle();
      
      if (userModel != null) {
        _user = userModel;
        _error = null;
        notifyListeners();
        
        // Load Firestore data for the user
        final firestoreProvider = Provider.of<FirestoreProvider>(context, listen: false);
        await firestoreProvider.loadUserData(userModel.uid);
        
        return true;
      } else {
        // If user model is null but Firebase user exists, create from Firebase
        final firebaseUser = _firebaseAuth?.currentUser;
        if (firebaseUser != null) {
          _user = UserModel(
            uid: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'User',
            email: firebaseUser.email ?? '',
            photoUrl: firebaseUser.photoURL,
            phoneNumber: firebaseUser.phoneNumber,
          );
          _error = null;
          notifyListeners();
          
          // Load Firestore data for the user
          final firestoreProvider = Provider.of<FirestoreProvider>(context, listen: false);
          await firestoreProvider.loadUserData(firebaseUser.uid);
          
          return true;
        }
        
        _error = "Google sign-in failed";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Sign Out
  Future<void> signOut(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.signOut();
      _user = null;
      _error = null;
      
      // Clear Firestore data
      final firestoreProvider = Provider.of<FirestoreProvider>(context, listen: false);
      await firestoreProvider.signOut();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 