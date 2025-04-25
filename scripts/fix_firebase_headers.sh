#!/bin/bash

# Define the directories where the problematic Firebase header files are located
FIREBASE_DB_DIR="/Users/alananthonyrubi/.pub-cache/hosted/pub.dev/firebase_database-10.5.7/ios/Classes"
FIREBASE_AUTH_DIR="/Users/alananthonyrubi/.pub-cache/hosted/pub.dev/firebase_auth-4.16.0/ios/Classes"

# Function to fix a given file
fix_file() {
  local file=$1
  if [ -f "$file" ]; then
    echo "Fixing file: $file"
    # Instead of using @import, we'll use a framework-style import that's more compatible
    sed -i '' 's/@import Firebase;/#import "Firebase.h"/g' "$file"
    sed -i '' 's/#import <Firebase\/Firebase.h>/#import "Firebase.h"/g' "$file"
  else
    echo "File not found: $file"
  fi
}

# Fix Firebase Database header files
echo "Fixing Firebase Database header files..."
fix_file "$FIREBASE_DB_DIR/FLTFirebaseDatabaseObserveStreamHandler.h"
fix_file "$FIREBASE_DB_DIR/FLTFirebaseDatabasePlugin.h"
fix_file "$FIREBASE_DB_DIR/FLTFirebaseDatabaseUtils.h"

# Fix Firebase Auth header files
echo "Fixing Firebase Auth header files..."
fix_file "$FIREBASE_AUTH_DIR/Public/FLTFirebaseAuthPlugin.h"
fix_file "$FIREBASE_AUTH_DIR/Private/FLTAuthStateChannelStreamHandler.h"
fix_file "$FIREBASE_AUTH_DIR/Private/FLTIdTokenChannelStreamHandler.h"
fix_file "$FIREBASE_AUTH_DIR/Private/FLTPhoneNumberVerificationStreamHandler.h" 
fix_file "$FIREBASE_AUTH_DIR/Private/PigeonParser.h"

echo "Done fixing Firebase header files."