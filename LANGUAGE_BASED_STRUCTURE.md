# Language-Based Data Structure Implementation

## Overview

This implementation adds language-based separation to the WordLune app, allowing users to organize their vocabulary learning by language. The data structure has been updated to use the format:

```
data/{userId}/{language}/lists/{listId}/words/{wordId}
```

## Key Changes

### 1. New Services

#### LanguagePreferenceService
- Manages user's selected learning language
- Provides language code conversion (e.g., 'Turkish' → 'tr')
- Stores language preference in SharedPreferences
- Supports 12 languages: Turkish, English, German, French, Spanish, Italian, Portuguese, Russian, Japanese, Korean, Chinese, Arabic

#### MigrationService
- Migrates existing data from old structure to new language-based structure
- Handles both words and lists migration
- Provides cleanup functionality for old data

### 2. Updated Models

#### Word Model
- Added `language` field to track the language of each word
- Updated all factory methods and serialization methods

#### WordList Model
- Added `language` field to track the language of each list
- Updated all factory methods and serialization methods

### 3. Updated FirestoreService

#### Collection References
- `_userWordsCollection` and `_userListsCollection` now return `Future<CollectionReference>`
- Collections are dynamically created based on user's selected language
- Path format: `data/{userId}/{languageCode}/words` and `data/{userId}/{languageCode}/lists`

#### Updated Methods
All methods that interact with collections have been updated to handle the async nature of the new collection references.

### 4. Updated Settings Screen

#### Language Selection
- Added "Learning Language" section in settings
- Users can select their learning language from a dropdown
- Language preference is persisted and used throughout the app

#### Data Migration
- Added "Migrate Data" option in settings
- Allows users to migrate existing data to the new structure
- Includes safety checks and error handling

## Data Structure

### Old Structure
```
data/{userId}/words/{wordId}
data/{userId}/lists/{listId}/words/{wordId}
```

### New Structure
```
data/{userId}/{language}/words/{wordId}
data/{userId}/{language}/lists/{listId}/words/{wordId}
```

Where `{language}` is the language code (e.g., 'tr', 'en', 'de').

## Migration Process

1. **Check Migration Need**: The app checks if old data structure exists
2. **User Selection**: User selects their learning language in settings
3. **Data Migration**: Existing words and lists are migrated to the new structure
4. **Language Assignment**: All migrated data is assigned the selected language
5. **Cleanup**: Old data can be cleaned up after successful migration

## Usage

### Setting Learning Language
```dart
// Set user's learning language
await LanguagePreferenceService.setSelectedLanguage('German');

// Get current language
String language = await LanguagePreferenceService.getSelectedLanguage();
```

### Adding Words with Language
```dart
// Words are automatically assigned the user's selected language
await firestoreService.addWord('hello', category: 'Good');
```

### Creating Lists with Language
```dart
// Lists are automatically assigned the user's selected language
String listId = await firestoreService.createList('My German Words');
```

## Benefits

1. **Language Separation**: Users can learn multiple languages without data mixing
2. **Scalability**: Easy to add new languages in the future
3. **Organization**: Clear separation of vocabulary by language
4. **User Experience**: Users only see content for their selected language
5. **Data Integrity**: Language information is preserved with each word and list

## Testing

Run the language structure tests:
```bash
flutter test test/language_based_structure_test.dart
```

## Future Enhancements

1. **Multi-language Support**: Allow users to learn multiple languages simultaneously
2. **Language Switching**: Quick language switching without data migration
3. **Cross-language Features**: Translation between different languages
4. **Language-specific Settings**: Different settings per language
5. **Progress Tracking**: Separate progress tracking per language 