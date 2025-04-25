# AI-Enhanced Plant Health Monitoring System with Mobile App

A Flutter application for monitoring plant health metrics through a connected ESP32 device with Firebase integration.

## Features

- Real-time monitoring of temperature, soil moisture, and plant health
- Historical data visualization
- Plant health diagnostics
- Integration with ESP32 sensor hardware

## Setup Instructions

### Firebase Configuration (Important Security Step)

For security reasons, the Firebase configuration file is not included in the repository. To set up Firebase:

1. Copy the template file:

   ```
   cp lib/services/firebase_config_template.dart lib/services/firebase_config.dart
   ```

2. Update `lib/services/firebase_config.dart` with your actual Firebase project values:
   - API Key
   - App ID
   - Messaging Sender ID
   - Project ID
   - Database URL
   - Storage Bucket

You can find these values in your Firebase Console under Project Settings.

3. Make sure your Firebase Realtime Database security rules are properly configured to secure your data.

### Note:

- Never commit your `firebase_config.dart` file to version control (it's already in .gitignore)
- The configuration should match the ESP32 firmware configuration to ensure proper communication

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
