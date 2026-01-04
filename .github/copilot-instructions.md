# PebbleNote - AI Coding Agent Instructions

## Project Overview
PebbleNote is a cross-platform Flutter note-taking app with reminders, checklists, and Google Drive backup. The app uses an orange-themed Material 3 UI and supports both light/dark modes.

## Architecture

### Layer Structure
```
lib/
├── main.dart          # App entry, MultiProvider setup, GoRouter config
├── models/            # Hive-annotated data models (Note, ChecklistItem)
├── providers/         # ChangeNotifier state management (4 providers)
├── screens/           # Full-page UI components
├── services/          # Platform services (Hive, Ads, Notifications)
├── utils/             # Constants, theme definitions
└── widgets/           # Reusable UI components
```

### State Management Pattern
- **Provider + ChangeNotifier** for all state management
- Providers are initialized in `main.dart` via `MultiProvider`
- Access state with `context.read<T>()` (one-time) or `context.watch<T>()` (reactive)

### Data Flow
1. **Notes**: `NotesProvider` ↔ `HiveService` (Hive box: `notes_box`)
2. **Checklists**: `ChecklistProvider` ↔ `SharedPreferences` (key: `checklist_{noteId}`)
3. **Settings**: `SettingsProvider` / `ThemeProvider` ↔ `SharedPreferences`

### Navigation
- Uses `go_router` with named routes defined in `main.dart`
- Route pattern: `/note/new`, `/note/:id`, `/checklist/new`, `/checklist/:id`
- Pass category via query params: `?category=Work`

## Key Patterns

### Model Changes (Hive)
When modifying `lib/models/note.dart`:
1. Add `@HiveField(n)` annotation with next available index
2. Run `flutter pub run build_runner build --delete-conflicting-outputs`
3. This regenerates `note.g.dart` adapter

### Creating New Providers
Follow pattern in `lib/providers/notes_provider.dart`:
```dart
class MyProvider extends ChangeNotifier {
  // Private state with underscore prefix
  List<Item> _items = [];
  
  // Public getters (never expose private state directly)
  List<Item> get items => _items;
  
  // Async operations update state then call notifyListeners()
  Future<void> loadData() async {
    _items = await _service.fetch();
    notifyListeners();
  }
}
```

### Note Colors
Defined as `NoteColor` enum in `lib/models/note.dart`. Map to actual colors via `AppTheme.noteColorsLight/Dark` in `lib/utils/app_theme.dart`.

### Notification Scheduling
`NotificationService` uses FNV-1a hash for stable notification IDs from note UUIDs. Always store `notificationId` on the Note model before saving to enable cancellation.

## Build & Run

```bash
# Get dependencies
flutter pub get

# Run on connected device
flutter run

# Build release APK
flutter build apk --release

# Regenerate Hive adapters after model changes
flutter pub run build_runner build --delete-conflicting-outputs

# Generate app icons after changing assets/icon/icon.png
flutter pub run flutter_launcher_icons
```

## Testing
```bash
flutter test                    # Run all tests
flutter test test/widget_test.dart  # Run specific test
```

## Conventions

### File Naming
- Screens: `*_screen.dart`
- Providers: `*_provider.dart`
- Services: `*_service.dart`
- Widgets: Descriptive lowercase with underscores

### Debug Logging
Use emoji prefixes for log filtering:
- `💾` - Storage operations
- `📝` - Note editor
- `📋` - Checklist operations
- `🎯` - Router/navigation
- `✅` - Success
- `❌` - Errors
- `⚠️` - Warnings

### AdMob Integration
Test ad unit IDs are in `lib/utils/constants.dart`. Replace with production IDs before release. Check `SettingsProvider.removeAds` before showing ads.

## External Dependencies
- **Hive**: Local NoSQL storage for notes
- **SharedPreferences**: Lightweight key-value storage for settings/checklists
- **flutter_local_notifications**: Reminder scheduling with timezone support
- **google_mobile_ads**: Monetization (banner, interstitial, rewarded)
- **go_router**: Declarative routing with deep linking support

## Common Tasks

### Add a new screen
1. Create `lib/screens/my_screen.dart`
2. Add route in `_router` GoRouter config in `main.dart`
3. Navigate with `context.go('/my-route')` or `context.push('/my-route')`

### Add new note field
1. Add field to `Note` class with `@HiveField(nextIndex)`
2. Add to `copyWith()` method
3. Regenerate adapters
4. Update `NotesProvider.createNote()` and `updateNote()`
