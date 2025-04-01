#!/bin/bash

# Exit on error
set -e

echo "=== Building Expense Tracker App ==="

# Make sure we're in the right directory
cd "$(dirname "$0")"

# Check flutter installation
if ! command -v flutter &> /dev/null; then
  echo "Flutter is not installed. Please install Flutter first."
  exit 1
fi

# Get dependencies
echo "=== Getting dependencies ==="
flutter pub get

# Run doctor to check for issues
echo "=== Checking for issues ==="
flutter doctor

# Build options
echo "=== Choose build option ==="
echo "1) Run in debug mode"
echo "2) Build for web"
echo "3) Build for Android"
echo "4) Build for iOS"
echo "5) Exit"

read -p "Choose an option (1-5): " option

case $option in
  1)
    echo "=== Running in debug mode ==="
    flutter run
    ;;
  2)
    echo "=== Building for web ==="
    flutter build web
    echo "Build complete. Files located in build/web/"
    ;;
  3)
    echo "=== Building for Android ==="
    flutter build apk
    echo "Build complete. APK located in build/app/outputs/flutter-apk/app-release.apk"
    ;;
  4)
    echo "=== Building for iOS ==="
    flutter build ios
    echo "Build complete. iOS app ready for archiving in Xcode."
    ;;
  5)
    echo "Exiting..."
    exit 0
    ;;
  *)
    echo "Invalid option. Exiting..."
    exit 1
    ;;
esac

echo "=== Build process completed ===" 