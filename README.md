# WordLune Mobile 📚

Modern AI-powered vocabulary learning app built with Flutter and Firebase.

## ✨ Features

- **AI-Powered Translation**: Google Translate + Gemini AI fallback
- **Smart Word Management**: Organized lists and categories
- **Beautiful UI**: Modern dark/light themes with animations
- **Curved Navigation**: Smooth and intuitive navigation
- **Progress Tracking**: Visual charts and statistics
- **Offline Support**: Works without internet for saved words

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Firebase account
- Gemini AI API key

### Installation

1. **Clone the repository**
```bash
git clone <repository_url>
cd wordlune_mobile
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Setup Environment Variables**
   - Copy `.env.example` to `.env`
   - Fill in your API keys:

```bash
cp .env.example .env
```

Edit `.env` file:
```env
# Firebase Configuration
FIREBASE_API_KEY=your_firebase_api_key_here
FIREBASE_PROJECT_ID=your_project_id_here
FIREBASE_MESSAGING_SENDER_ID=your_sender_id_here
FIREBASE_APP_ID=your_app_id_here

# Gemini AI Configuration
GEMINI_API_KEY=your_gemini_api_key_here
```

4. **Configure Firebase**
   - Create a new Firebase project
   - Enable Authentication and Firestore
   - Download `google-services.json` for Android
   - Place it in `android/app/`

5. **Run the app**
```bash
flutter run
```

## 📱 App Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
│   ├── word.dart
│   ├── word_list.dart
│   └── list_word.dart
├── screens/                  # UI screens
│   ├── dashboard_screen.dart
│   ├── words_screen.dart
│   ├── word_lists_screen.dart
│   ├── login_screen.dart
│   └── register_screen.dart
└── services/                 # Business logic
    ├── firestore_service.dart
    └── gemini_service.dart
```

## 🔐 Security

- All API keys are stored in `.env` file
- `.env` is added to `.gitignore`
- Firebase security rules protect user data
- Environment variables with fallback values

## 🎨 Themes

- **Light Theme**: Clean and modern
- **Dark Theme**: Soft, eye-friendly colors
- **Automatic**: Follows system preference

## 📊 Firestore Structure

```
/data/{userId}/
├── words/           # User's words
├── lists/           # Custom word lists
└── listWords/       # Words in lists
```

## 🤖 AI Features

- **Google Translate**: Primary translation service
- **Gemini AI**: Fallback + example sentences
- **Smart Fallback**: Automatic service switching

## 📦 Dependencies

- `flutter_dotenv`: Environment variables
- `firebase_core` & `cloud_firestore`: Backend
- `google_fonts`: Typography
- `curved_navigation_bar`: Navigation
- `translator`: Google Translate
- `http`: API requests

## 🛠️ Development

```bash
# Run tests
flutter test

# Build APK
flutter build apk

# Analyze code
flutter analyze
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
