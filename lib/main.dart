import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:expense_tracker/providers/firestore_provider.dart';
import 'package:expense_tracker/screens/auth_screen.dart';
import 'package:expense_tracker/screens/home_screen.dart';
import 'package:expense_tracker/utils/theme_utils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseInitialized = false;
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    firebaseInitialized = true;
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
    // Continue with the app even if Firebase fails to initialize
  }
  
  runApp(ExpenseTrackerApp(firebaseInitialized: firebaseInitialized));
}

class ExpenseTrackerApp extends StatelessWidget {
  final bool firebaseInitialized;
  
  const ExpenseTrackerApp({
    super.key, 
    this.firebaseInitialized = false
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(firebaseInitialized: firebaseInitialized)),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => FirestoreProvider()),
      ],
      child: MaterialApp(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    
    // Initialize authentication and Firestore state
    Future.microtask(() {
      Provider.of<AuthProvider>(context, listen: false).initializeAuth();
      Provider.of<FirestoreProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final firestoreProvider = Provider.of<FirestoreProvider>(context);
    
    // Show loading screen while authentication or Firestore is being initialized
    if (authProvider.isLoading || firestoreProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Show error if there's an issue with Firestore
    if (firestoreProvider.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Error: ${firestoreProvider.error}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  firestoreProvider.clearError();
                  firestoreProvider.initialize();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Return home screen if user is authenticated, otherwise return auth screen
    return authProvider.isAuthenticated
        ? const HomeScreen()
        : const AuthScreen();
  }
}
