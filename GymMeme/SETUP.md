# GymType — Setup Guide

## Step 1: Prerequisites

```bash
# Install Flutter (if not installed)
# https://docs.flutter.dev/get-started/install

flutter --version    # Confirm: 3.19+
dart --version       # Confirm: 3.2+
```

## Step 2: Scaffold the Flutter project

Run this FIRST in the GymMeme directory:

```bash
flutter create . --org com.gymtype --project-name gymtype --platforms android,ios
```

This generates the native Android/iOS project files. Your lib/ files already exist.

## Step 3: Install dependencies

```bash
flutter pub get
```

## Step 4: Generate Drift code

```bash
# Delete the hand-written stub and regenerate properly:
flutter pub run build_runner build --delete-conflicting-outputs
```

## Step 5: Firebase Setup

### 5a. Create Firebase project
1. Go to console.firebase.google.com
2. Create project: "gymtype"
3. Enable: Authentication, Firestore, Storage

### 5b. Add Android app
1. Package name: `com.gymtype.app`
2. Download `google-services.json`
3. Replace `android/app/google-services.json` with downloaded file

### 5c. Configure Firebase in Flutter
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_PROJECT_ID
```
This auto-generates `lib/firebase_options.dart` — replace the placeholder.

### 5d. Enable Anonymous Auth
Firebase Console → Authentication → Sign-in method → Anonymous → Enable

### 5e. Firestore Security Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own doc
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    // Memes: anyone can read active public memes, auth required to write
    match /memes/{memeId} {
      allow read: if resource.data.isPublic == true && resource.data.status == 'active';
      allow create: if request.auth != null;
      allow update: if request.auth != null && (
        request.auth.uid == resource.data.creatorId ||
        // Allow upvote/report increments from anyone authenticated
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['upvotes', 'reportCount', 'status'])
      );
    }
    // Reports: auth required to create, no reads
    match /reports/{reportId} {
      allow create: if request.auth != null;
    }
  }
}
```

### 5f. Firebase Storage Rules
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /memes/{userId}/{memeId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId
        && request.resource.size < 5 * 1024 * 1024  // 5MB max
        && request.resource.contentType.matches('image/.*');
    }
  }
}
```

## Step 6: AdMob Setup

1. Go to apps.admob.com
2. Create app "GymType"
3. Create 3 ad units: Banner, Interstitial, Rewarded
4. Replace test IDs in `lib/core/constants/app_constants.dart`
5. Replace App ID in `android/app/src/main/AndroidManifest.xml`

## Step 7: android/app/build.gradle changes

Add to `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdkVersion 21      // Required for ML Kit
        targetSdkVersion 34
        multiDexEnabled true  // Required for Firebase
    }
}
```

Add to project-level `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

Add at bottom of `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

## Step 8: Run

```bash
flutter run
```

## Step 9: Add real meme templates

Replace the 1x1 placeholder PNGs in `assets/templates/` with real meme templates.
Recommended size: 1080x1080px, PNG format.

Free sources:
- imgflip.com/memetemplates (for gym-related memes)
- Create custom ones with Canva

---

## Build Order (MVP Priority)

1. ✅ Run `flutter create .` + `flutter pub get`
2. ✅ Set up Firebase + replace `google-services.json` + `firebase_options.dart`
3. ✅ Run `build_runner` for Drift
4. ✅ Replace placeholder ad IDs
5. ✅ Add real template images
6. ✅ `flutter run` — app should launch
7. Take quiz → verify archetype saves to Hive
8. Log a session → verify saves to SQLite
9. Create a meme → verify saves to gallery
10. Check Weekly Report loads from DB

---

## File Structure Summary

```
lib/
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase config (replace with real)
├── core/
│   ├── theme/app_theme.dart           # Material 3 theme
│   ├── router/app_router.dart         # Navigation routes
│   └── constants/app_constants.dart   # App-wide constants
├── data/
│   ├── models/                        # Pure Dart data classes
│   │   ├── user_model.dart
│   │   ├── meme_model.dart
│   │   ├── archetype_model.dart
│   │   └── activity_log_model.dart
│   ├── local/
│   │   ├── database.dart              # Drift schema definition
│   │   └── database.g.dart            # Generated code (run build_runner)
│   └── remote/
│       └── firestore_service.dart     # Firestore CRUD
├── services/
│   ├── auth_service.dart              # Firebase Auth (anonymous)
│   ├── storage_service.dart           # Firebase Storage upload
│   ├── face_detection_service.dart    # ML Kit face detection
│   ├── share_service.dart             # share_plus wrapper
│   └── ad_service.dart               # AdMob + BannerAdWidget
├── features/
│   ├── archetypes/
│   │   ├── data/archetype_data.dart   # 6 archetypes + 8 quiz questions
│   │   ├── providers/archetype_provider.dart
│   │   └── screens/
│   │       ├── quiz_screen.dart       # 8-question quiz
│   │       └── archetype_result_screen.dart  # Shareable result card
│   ├── meme_creator/
│   │   ├── providers/meme_provider.dart
│   │   └── screens/
│   │       ├── template_grid_screen.dart  # Template picker + image upload
│   │       └── meme_canvas_screen.dart    # Drag captions + export
│   ├── activity_log/
│   │   ├── providers/activity_log_provider.dart
│   │   └── screens/
│   │       ├── daily_log_screen.dart      # Mood + archetype self-tag
│   │       └── weekly_report_screen.dart  # Shareable weekly card
│   ├── feed/
│   │   ├── providers/feed_provider.dart
│   │   └── screens/feed_screen.dart       # Community feed + report
│   └── profile/
│       └── screens/profile_screen.dart    # Dashboard + settings
└── widgets/
    └── main_scaffold.dart             # Bottom nav + FAB
```
