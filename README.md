# GymType 🏋️

> *The only gym app that rewards self-awareness with laughter.*

A fun, privacy-safe Flutter app for gym culture enthusiasts. Create memes, discover your gym archetype, track your sessions, and share your weekly personality report — without taking yourself too seriously.

---

## Features

### Archetype Quiz
8-question personality quiz that scores you across 6 gym archetypes. Result is a shareable card with your archetype, description, and score breakdown.

| Archetype | Emoji | Vibe |
|---|---|---|
| Mirror Addict | 🪞 | Every set ends with a flex check |
| Ego Lifter | 🏋️ | Form is optional when you're this strong |
| Social Scroller | 📱 | Technically at the gym, spiritually on TikTok |
| Equipment Camper | ⛺ | That machine is mine until I leave |
| Over-Stretcher | 🧘 | Warm-up takes longer than the workout |
| Supplement Scientist | 🧪 | 6 shakers, 1 workout |

### Meme Creator
- Pick from 6 bundled templates or upload your own photo
- Drag-and-drop top/bottom captions directly on the canvas
- Adjustable font size
- Export to gallery or share directly to WhatsApp / Instagram Stories
- Face detection gate — warns before any image with a face goes public

### Daily Session Log
- Mood selector (Beast Mode / Focused / Lazy / Distracted / Social)
- Archetype self-tag — "Today I was a..."
- Duration slider, exercise type chips, hashtag tags
- Optional notes (300 chars)
- Stored locally in SQLite via Drift — no account required

### Weekly Personality Report
- Auto-generated from the week's logs
- Shows dominant archetype + mood breakdown with progress bars
- Exportable as a shareable story card
- Shareable via `share_plus`

### Community Feed
- Browse public memes (anonymised by default)
- Upvote memes
- One-tap report with category picker
- Auto-hides memes that hit 3 reports pending review

### Privacy & Safety
- Face detection runs on-device (ML Kit) before any upload
- Public sharing blocked if a face is detected and user doesn't confirm it's them
- Anonymous by default — no username shown on public memes
- Full data deletion from settings (local + remote)
- No location data collected, ever

---

## Tech Stack

| Category | Library | Version |
|---|---|---|
| Framework | Flutter | 3.x |
| State management | flutter_riverpod | ^2.4.9 |
| Auth | firebase_auth | ^4.17.4 |
| Database (remote) | cloud_firestore | ^4.15.5 |
| Storage (remote) | firebase_storage | ^11.6.5 |
| Database (local) | drift (SQLite) | ^2.18.0 |
| Key-value cache | hive_flutter | ^1.1.0 |
| Image picking | image_picker | ^1.0.7 |
| Canvas export | screenshot | ^2.3.0 |
| Gallery save | image_gallery_saver | ^2.0.3 |
| Image compression | flutter_image_compress | ^2.1.0 |
| Face detection | google_mlkit_face_detection | ^0.10.0 |
| Sharing | share_plus | ^7.2.2 |
| Ads | google_mobile_ads | ^4.0.0 |
| Charts | fl_chart | ^0.68.0 |

---

## Project Structure

```
lib/
├── main.dart                                   # App entry, Firebase + Hive init
├── firebase_options.dart                       # Firebase config (replace with real)
│
├── core/
│   ├── constants/app_constants.dart            # AdMob IDs, Firestore paths, Hive keys
│   ├── router/app_router.dart                  # All named routes
│   └── theme/app_theme.dart                    # Material 3 light + dark theme
│
├── data/
│   ├── models/
│   │   ├── user_model.dart                     # UserModel + copyWith + toMap/fromMap
│   │   ├── meme_model.dart                     # MemeModel + MemeCaption
│   │   ├── archetype_model.dart                # ArchetypeModel
│   │   └── activity_log_model.dart             # ActivityLogModel + GymMood + WeeklyReportData
│   ├── local/
│   │   ├── database.dart                       # Drift schema (ActivityLogs, LocalMemes tables)
│   │   └── database.g.dart                     # Generated — run build_runner to regenerate
│   └── remote/
│       └── firestore_service.dart              # Firestore CRUD (users, memes, reports)
│
├── services/
│   ├── auth_service.dart                       # Firebase anonymous auth + providers
│   ├── storage_service.dart                    # Firebase Storage upload + compression
│   ├── face_detection_service.dart             # ML Kit on-device face detection
│   ├── share_service.dart                      # share_plus wrapper (memes + reports)
│   └── ad_service.dart                         # AdMob interstitial + BannerAdWidget
│
├── features/
│   ├── archetypes/
│   │   ├── data/archetype_data.dart            # 6 archetypes + 8 quiz questions (static data)
│   │   ├── providers/archetype_provider.dart   # QuizNotifier + ArchetypeNotifier (Hive)
│   │   └── screens/
│   │       ├── quiz_screen.dart                # Animated 8-question quiz
│   │       └── archetype_result_screen.dart    # Shareable result card + score breakdown
│   │
│   ├── meme_creator/
│   │   ├── providers/meme_provider.dart        # DraftMemeNotifier + MemeService (save/upload)
│   │   └── screens/
│   │       ├── template_grid_screen.dart       # Template picker + image upload + face check
│   │       └── meme_canvas_screen.dart         # Drag captions + font size + export
│   │
│   ├── activity_log/
│   │   ├── providers/activity_log_provider.dart # Drift queries + WeeklyReportData generator
│   │   └── screens/
│   │       ├── daily_log_screen.dart           # Mood / archetype / duration / tags
│   │       └── weekly_report_screen.dart       # Report card + shareable export
│   │
│   ├── feed/
│   │   ├── providers/feed_provider.dart        # Firestore public memes + upvote + report
│   │   └── screens/feed_screen.dart            # Community feed + report dialog
│   │
│   └── profile/
│       └── screens/profile_screen.dart         # Archetype card + stats + quick actions + settings
│
└── widgets/
    └── main_scaffold.dart                      # Bottom NavigationBar + IndexedStack + FAB
```

---

## Getting Started

### Prerequisites

- Flutter SDK 3.19 or later — [install guide](https://docs.flutter.dev/get-started/install)
- Android Studio or VS Code with Flutter extension
- A Firebase project (free Spark plan is sufficient for MVP)
- A Google AdMob account (optional for local testing — test IDs are pre-wired)

### 1. Scaffold native project files

```bash
cd /path/to/GymMeme
flutter create . --org com.gymtype --project-name gymtype --platforms android,ios
flutter pub get
```

> This generates the `android/` and `ios/` native project files. Your `lib/` source is already in place.

### 2. Regenerate Drift database code

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Set up Firebase

#### 3a. Create project
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create project → name it `gymtype`
3. Enable these services:
   - **Authentication** → Sign-in method → Anonymous → Enable
   - **Firestore Database** → Create in production mode
   - **Storage** → Get started

#### 3b. Connect your app
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure — this auto-generates lib/firebase_options.dart
flutterfire configure --project=YOUR_PROJECT_ID
```

#### 3c. Add Android config
- Download `google-services.json` from Firebase Console → Project Settings → Android
- Replace `android/app/google-services.json` with the downloaded file

#### 3d. Firestore security rules

Paste into Firebase Console → Firestore → Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /memes/{memeId} {
      allow read: if resource.data.isPublic == true && resource.data.status == 'active';
      allow create: if request.auth != null;
      allow update: if request.auth != null && (
        request.auth.uid == resource.data.creatorId ||
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['upvotes', 'reportCount', 'status'])
      );
    }
    match /reports/{reportId} {
      allow create: if request.auth != null;
    }
  }
}
```

#### 3e. Firebase Storage rules

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /memes/{userId}/{memeId} {
      allow read: if true;
      allow write: if request.auth != null
        && request.auth.uid == userId
        && request.resource.size < 5 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }
  }
}
```

### 4. Android build.gradle changes

In `android/app/build.gradle`, confirm:
```gradle
android {
    defaultConfig {
        minSdkVersion 21        // Required for ML Kit
        targetSdkVersion 34
        multiDexEnabled true    // Required for Firebase
    }
}
```

In `android/build.gradle` (project-level):
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

At the bottom of `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 5. Replace placeholder values

| File | What to replace |
|---|---|
| `lib/core/constants/app_constants.dart` | AdMob banner, interstitial, rewarded ad unit IDs |
| `android/app/src/main/AndroidManifest.xml` | AdMob Application ID |
| `assets/templates/*.png` | Replace 1×1 placeholders with real meme template images (1080×1080px recommended) |

### 6. Run

```bash
flutter run
```

---

## Configuration Reference

### AdMob IDs (`lib/core/constants/app_constants.dart`)

```dart
// Replace test IDs with real IDs from apps.admob.com before release
static const String bannerAdUnitId = 'ca-app-pub-XXXX/XXXX';
static const String interstitialAdUnitId = 'ca-app-pub-XXXX/XXXX';
static const String rewardedAdUnitId = 'ca-app-pub-XXXX/XXXX';
```

The test IDs currently wired in are Google's official test IDs — ads will display during development but earn no revenue. Swap before Play Store submission.

### Meme Templates

Add real templates to `assets/templates/`. Each file maps to a `MemeTemplate` entry in [template_grid_screen.dart](lib/features/meme_creator/screens/template_grid_screen.dart):

```dart
const kTemplates = [
  MemeTemplate(id: 't1', name: 'Mirror Check',   assetPath: 'assets/templates/mirror_check.png',   archetypeId: 'mirror_addict'),
  MemeTemplate(id: 't2', name: 'Too Heavy',       assetPath: 'assets/templates/too_heavy.png',      archetypeId: 'ego_lifter'),
  // ... add more here
];
```

---

## Privacy & Ethics

This app is built privacy-first:

- **No tracking other people.** The face detection gate blocks public sharing of images containing detected faces unless the user confirms it is themselves.
- **Anonymous by default.** Creator identity is hidden from the public feed. No username is required.
- **No location data.** Location permissions are never requested.
- **Self-only tracking.** Activity logs are personal and stored locally first.
- **Right to delete.** One-tap data deletion in Settings removes all local and Firestore data.
- **Report system.** Any public meme can be reported. Three reports auto-hides the content pending review.
- **No comments.** The feed has upvotes and reports only — no text comments to reduce harassment surface area.

---

## Roadmap

### MVP (current)
- [x] Archetype quiz (8 questions, 6 archetypes)
- [x] Shareable archetype result card
- [x] Daily session log (mood, archetype tag, duration, tags)
- [x] Meme creator (templates + custom image, draggable captions)
- [x] Save to gallery + share
- [x] Weekly report card
- [x] Community feed (anonymised)
- [x] Report system
- [x] Face detection privacy gate
- [x] Anonymous Firebase auth
- [x] AdMob (banner + interstitial)

### Phase 2
- [ ] AI caption suggestions (Gemini Flash API)
- [ ] Push notifications (streak reminders, weekly report)
- [ ] Custom avatar builder (no real faces needed)
- [ ] Archetype leaderboard
- [ ] Video meme support (short clips)
- [ ] Premium subscription (ad-free + more templates)

### Phase 3
- [ ] iOS release (Flutter codebase is already cross-platform)
- [ ] Gym brand partnership packs
- [ ] Advanced analytics dashboard
- [ ] Referral system

---

## Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Follow the existing folder structure — one feature per folder under `lib/features/`
4. Run `flutter analyze` before submitting a PR
5. All new screens must pass a face detection check before enabling public sharing

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

*Built with Flutter. Powered by gym culture and mild self-awareness.*
