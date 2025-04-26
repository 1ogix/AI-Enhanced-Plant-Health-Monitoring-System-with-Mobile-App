# AI-Enhanced Plant Health Monitoring System with Mobile App

A Flutter application for monitoring plant health metrics through a connected ESP32 device with Firebase integration.

## Features

- Real-time monitoring of temperature, soil moisture, and plant health
- Historical data visualization
- Plant health diagnostics
- Integration with ESP32 sensor hardware

## Setup Instructions

### Firebase Configuration (Important Security Step)

For security reasons, the Firebase configuration files are not included in the repository. To set up Firebase:

#### For iOS:

1. Download the `GoogleService-Info.plist` file from your Firebase Console:

   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Go to Project Settings
   - Select the iOS app
   - Download the `GoogleService-Info.plist` file

2. Place the file in your project:
   - Copy the downloaded file to `ios/Runner/` directory
   - Add it to your Xcode project by opening Xcode:
     ```
     open ios/Runner.xcworkspace
     ```
   - Right-click on Runner in the project navigator
   - Select "Add Files to 'Runner'"
   - Navigate to and select the GoogleService-Info.plist file
   - Ensure "Copy items if needed" is checked
   - Click "Add"

#### For Android:

1. Download the `google-services.json` file from your Firebase Console
2. Place it in the `android/app/` directory

3. Make sure your Firebase Realtime Database security rules are properly configured to secure your data.

### Note:

- Never commit your `GoogleService-Info.plist` or `google-services.json` files to version control (they're already in .gitignore)
- The Firebase configuration should match the ESP32 firmware configuration to ensure proper communication

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
