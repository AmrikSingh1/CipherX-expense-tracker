# Firebase Configuration

To complete the Firebase configuration for the Expense Tracker app, follow these steps:

## 1. Create Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and follow the setup wizard
3. Enter a project name (e.g., "Expense Tracker")
4. Configure Google Analytics (optional)
5. Wait for the project to be created

## 2. Android Configuration

1. In the Firebase Console, click on the Android icon to add an Android app
2. Enter package name: `com.cipherschools.assignment`
3. Enter app nickname (optional, e.g., "Expense Tracker")
4. Enter SHA-1 certificate fingerprint (for Google Sign-in):
   - Get the debug SHA-1 using this command:
     ```
     cd android && ./gradlew signingReport
     ```
5. Click "Register app"
6. Download the `google-services.json` file
7. Replace the placeholder file at `android/app/google-services.json` with the downloaded file

## 3. iOS Configuration

1. In the Firebase Console, click on the iOS icon to add an iOS app
2. Enter bundle ID: `com.cipherschools.assignment`
3. Enter app nickname (optional, e.g., "Expense Tracker")
4. Enter App Store ID (optional)
5. Click "Register app"
6. Download the `GoogleService-Info.plist` file
7. Replace the placeholder file at `ios/Runner/GoogleService-Info.plist` with the downloaded file
8. Update the URL scheme in `ios/Runner/Info.plist` with your actual client ID from the downloaded `GoogleService-Info.plist`

## 4. Enable Authentication

1. In the Firebase Console, go to "Authentication"
2. Click on "Get started"
3. Enable the "Google" sign-in method:
   - Click on "Google" in the list
   - Toggle the "Enable" switch
   - Enter your support email
   - Click "Save"

## 5. Set up Firestore Database

1. In the Firebase Console, go to "Firestore Database"
2. Click on "Create database"
3. Choose "Start in production mode" or "Start in test mode" (for development)
4. Select a database location close to your users
5. Click "Enable"

## 6. Test the Configuration

1. Run the app on a device or emulator
2. Try to sign in with Google
3. If there are any issues, check the console logs for error messages

## Common Issues and Troubleshooting

### Google Sign-in Issues

- Make sure SHA-1 fingerprint is correctly added to Firebase
- Check that `google-services.json` is properly placed in the project
- For iOS, verify that URL schemes are set correctly in Info.plist

### Firestore Issues

- Check Firebase rules if you're having permission issues
- Ensure internet permission is in the Android manifest

### Build Issues

- Ensure Google Services plugin is applied in build.gradle files
- Check that minSdkVersion is set to at least 21 for Android

## Security Note

Remember to set up proper security rules for Firestore before deploying to production. Default rules in test mode allow anyone to read and write all data, which is not secure for production use. 