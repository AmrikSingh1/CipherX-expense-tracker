import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/models/user_model.dart';
import 'package:expense_tracker/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  
  // Initialize auth state
  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Check if user is already signed in
      final userId = await _authService.getUserIdFromPrefs();
      
      if (userId != null) {
        final userModel = await _authService.getUserFromFirestore(userId);
        if (userModel != null) {
          _user = userModel;
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
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final userModel = await _authService.signInWithGoogle();
      
      if (userModel != null) {
        _user = userModel;
        _error = null;
        notifyListeners();
        return true;
      } else {
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
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.signOut();
      _user = null;
      _error = null;
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