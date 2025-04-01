# Expense Tracker App

A Flutter-based expense tracking application that allows users to manage their personal finances by tracking income and expenses, with Google Authentication and data visualization.

## Features

- **User Authentication**: Google Sign-in with Firebase Authentication
- **Finance Management**: Add, edit, and delete income and expense entries
- **Categorization**: Categorize expenses and income (e.g., Food, Travel, Salary, etc.)
- **Data Visualization**: View expense distribution in pie charts
- **Monthly Navigation**: Browse transactions by month
- **Transaction History**: View transaction history with details
- **Data Export**: Export transaction data to CSV files
- **Local Storage**: Store transactions locally using SQLite

## Tech Stack

- **State Management**: Provider
- **Authentication**: Firebase Authentication, Google Sign-in
- **Local Database**: SQLite with SQFlite package
- **UI Components**: Flutter Material Design
- **Charts**: FL Chart for data visualization
- **Cloud Storage**: Firestore for user information
- **Local Storage**: Shared Preferences for session management

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/CipherSchools-Flutter-Assignment.git
   ```

2. Navigate to the project directory:
   ```
   cd CipherSchools-Flutter-Assignment/expense_tracker
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Run the app:
   ```
   flutter run
   ```

## Firebase Setup

To use Firebase features:

1. Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/)
2. Add your Android & iOS apps with the package name: `com.cipherschools.assignment`
3. Download and add the configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
4. Enable Google Authentication in the Firebase Console

## Project Structure

- `lib/models/` - Data models
- `lib/providers/` - State management providers
- `lib/screens/` - UI screens
- `lib/services/` - Business logic and API services
- `lib/database/` - Local database implementation
- `lib/widgets/` - Reusable UI components
- `lib/utils/` - Utility functions and helpers

## Acknowledgments

- [Flutter](https://flutter.dev/)
- [Firebase](https://firebase.google.com/)
- [CipherSchools](https://www.cipherschools.com/)

## License

This project is for educational purposes as part of a CipherSchools assignment.
