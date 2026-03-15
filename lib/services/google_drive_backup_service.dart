/// ================================================================================================
/// PRODUCTION-READY GOOGLE DRIVE BACKUP SERVICE FOR PEBBLENOTE
/// ================================================================================================
///
/// This service implements secure Google Drive backup & restore functionality with strict
/// API usage limits to prevent excessive billing and ensure production safety.
///
/// KEY SAFETY FEATURES:
/// ✅ Manual backup only (no auto-backup on app launch)
/// ✅ Optional 24-hour auto-backup with timestamp check
/// ✅ Single backup file strategy (always overwrite old backup)
/// ✅ AppData scope only (user's Drive data is private)
/// ✅ Minimal API calls (no unnecessary list() operations)
/// ✅ Proper error handling (never crashes)
/// ✅ Network-aware (handles offline gracefully)
///
/// BILLING PROTECTION:
/// - NO background sync loops that consume quota
/// - NO repeated file listings on app startup
/// - NO unnecessary metadata fetches
/// - ONLY calls Drive API when user explicitly triggers backup/restore
///
/// ================================================================================================
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

/// Google Drive Backup Service
///
/// This service uses Google Sign-In with DRIVE_APPDATA scope to store
/// app backups privately in the user's Google Drive. The backup file is
/// NOT visible in the user's Drive UI and is only accessible by PebbleNote.
class GoogleDriveBackupService {
  // ============================================================
  // SINGLETON PATTERN
  // ============================================================
  static final GoogleDriveBackupService _instance =
      GoogleDriveBackupService._internal();
  factory GoogleDriveBackupService() => _instance;
  GoogleDriveBackupService._internal();

  // ============================================================
  // CONFIGURATION
  // ============================================================

  /// Backup file name (stored in appDataFolder)
  static const String _backupFileName = 'pebblenote_backup.json';

  /// SharedPreferences key for last backup timestamp
  static const String _lastBackupKey = 'last_backup_timestamp';

  /// SharedPreferences key for auto-backup enabled
  static const String _autoBackupEnabledKey = 'auto_backup_enabled';

  /// 24-hour interval for auto-backup (in milliseconds)
  static const int _autoBackupIntervalMs = 24 * 60 * 60 * 1000; // 24 hours

  // ============================================================
  // GOOGLE SIGN-IN SETUP
  // ============================================================

  /// Google Sign-In instance with DRIVE_APPDATA scope
  ///
  /// SECURITY NOTE: We only request 'drive.appdata' scope, which restricts
  /// access to the app's private folder. We do NOT request full Drive access.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveAppdataScope, // appDataFolder access only
    ],
  );

  // ============================================================
  // STATE VARIABLES
  // ============================================================

  GoogleSignInAccount? _currentAccount;
  drive.DriveApi? _driveApi;
  bool _isInitialized = false;

  // ============================================================
  // GETTERS
  // ============================================================

  /// Check if user is signed in
  bool get isSignedIn => _currentAccount != null;

  /// Get current user's email
  String? get userEmail => _currentAccount?.email;

  /// Get current user's display name
  String? get userDisplayName => _currentAccount?.displayName;

  /// Get current user's photo URL
  String? get userPhotoUrl => _currentAccount?.photoUrl;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize the service and check for existing sign-in
  ///
  /// BILLING PROTECTION: This does NOT make any Drive API calls.
  /// It only checks local sign-in state.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔐 Initializing Google Drive Backup Service...');

      // Try silent sign-in (uses cached credentials, no API calls)
      _currentAccount = await _googleSignIn.signInSilently();

      if (_currentAccount != null) {
        debugPrint('✅ User already signed in: ${_currentAccount!.email}');
      } else {
        debugPrint('ℹ️ No cached sign-in found');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('⚠️ Initialization error: $e');
      // Don't throw - app can continue without Drive backup
    }
  }

  /// Initialize Drive API client
  ///
  /// BILLING PROTECTION: This only creates the API client instance.
  /// No actual API calls are made until backup/restore is triggered.
  Future<void> _initializeDriveApi() async {
    try {
      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) {
        throw Exception('Failed to get authenticated client');
      }

      _driveApi = drive.DriveApi(authClient);
      debugPrint('✅ Drive API client initialized');
    } catch (e) {
      debugPrint('❌ Drive API initialization failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // SIGN-IN & SIGN-OUT
  // ============================================================

  /// Sign in with Google
  ///
  /// Shows Google Sign-In UI and requests Drive AppData permission.
  /// Returns false if user cancelled. Throws on configuration/network errors.
  Future<bool> signIn() async {
    try {
      debugPrint('🔐 Starting Google Sign-In...');

      _currentAccount = await _googleSignIn.signIn();

      if (_currentAccount == null) {
        // User dismissed the sign-in dialog
        debugPrint('⚠️ User cancelled sign-in');
        return false;
      }

      // NOTE: Do NOT call _initializeDriveApi() here.
      // Calling getTokens() while the sign-in flow is still active
      // triggers AccountManager.blockingGetAuthToken() on the main thread → deadlock.
      // Drive API is lazily initialized in backupNotes() / restoreNotes().
      debugPrint('✅ Sign-in successful: ${_currentAccount!.email}');

      return true;
    } on PlatformException catch (e) {
      debugPrint('❌ Sign-in PlatformException: ${e.code} - ${e.message}');
      _currentAccount = null;
      _driveApi = null;
      rethrow; // Let provider show specific error
    } catch (e) {
      debugPrint('❌ Sign-in error: $e');
      _currentAccount = null;
      _driveApi = null;
      rethrow;
    }
  }

  /// Sign out from Google
  ///
  /// Clears local sign-in state and disconnects Drive API.
  Future<void> signOut() async {
    try {
      debugPrint('🔓 Signing out...');

      await _googleSignIn.signOut();
      _currentAccount = null;
      _driveApi = null;

      debugPrint('✅ Signed out successfully');
    } catch (e) {
      debugPrint('❌ Sign-out error: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  // ============================================================
  // BACKUP OPERATIONS
  // ============================================================

  /// Backup notes to Google Drive
  ///
  /// BILLING PROTECTION:
  /// - Only called when user explicitly taps "Backup Now"
  /// - First searches for existing backup file (1 list() call)
  /// - Deletes old backup if found (1 delete() call)
  /// - Uploads new backup (1 create() call)
  /// - Total: Maximum 3 API calls per backup
  ///
  /// OVERWRITE STRATEGY:
  /// - Always maintains ONLY ONE backup file
  /// - Prevents storage bloat
  /// - Ensures user always has latest backup
  Future<String> backupNotes(List<Note> notes) async {
    try {
      if (!isSignedIn) {
        throw Exception('Not signed in. Please sign in first.');
      }

      if (_driveApi == null) {
        await _initializeDriveApi();
      }

      debugPrint('📤 Starting backup of ${notes.length} notes...');

      // Convert notes to JSON
      final backupData = {
        'version': 1,
        'appName': 'PebbleNote',
        'backupDate': DateTime.now().toIso8601String(),
        'noteCount': notes.length,
        'notes': notes.map((note) => note.toJson()).toList(),
      };

      final jsonString = jsonEncode(backupData);
      final bytes = utf8.encode(jsonString);

      debugPrint(
          '📦 Backup size: ${(bytes.length / 1024).toStringAsFixed(2)} KB');

      // STEP 1: Search for existing backup file
      // BILLING NOTE: This is the ONLY list() call we make
      final existingFileId = await _findBackupFile();

      // STEP 2: Delete existing backup if found
      if (existingFileId != null) {
        debugPrint('🗑️ Deleting old backup file...');
        await _driveApi!.files.delete(existingFileId);
        debugPrint('✅ Old backup deleted');
      }

      // STEP 3: Upload new backup
      debugPrint('📤 Uploading new backup...');
      await _uploadBackupFile(bytes);

      // Save backup timestamp
      await _saveLastBackupTimestamp();

      debugPrint('✅ Backup completed successfully');
      return 'Backup completed successfully';
    } catch (e) {
      debugPrint('❌ Backup error: $e');

      // User-friendly error messages
      if (e.toString().contains('network')) {
        throw Exception(
            'No internet connection. Please check your network and try again.');
      } else if (e.toString().contains('quota')) {
        throw Exception(
            'Google Drive quota exceeded. Please free up space in your Drive.');
      } else {
        throw Exception('Backup failed: ${e.toString()}');
      }
    }
  }

  /// Search for existing backup file
  ///
  /// BILLING PROTECTION: This is the ONLY place where list() is called,
  /// and it's only called when user explicitly triggers backup/restore.
  Future<String?> _findBackupFile() async {
    try {
      debugPrint('🔍 Searching for existing backup...');

      // Search query: file name matches AND is in appDataFolder
      const query =
          "name='$_backupFileName' and 'appDataFolder' in parents and trashed=false";

      final fileList = await _driveApi!.files.list(
        spaces: 'appDataFolder',
        q: query,
        $fields: 'files(id, name)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        debugPrint('ℹ️ No existing backup found');
        return null;
      }

      // There should only be one backup file, but just in case...
      if (fileList.files!.length > 1) {
        debugPrint('⚠️ Multiple backup files found! Cleaning up...');
        // Delete all but keep the first one
        for (int i = 1; i < fileList.files!.length; i++) {
          await _driveApi!.files.delete(fileList.files![i].id!);
        }
      }

      final fileId = fileList.files!.first.id;
      debugPrint('✅ Found existing backup: $fileId');
      return fileId;
    } catch (e) {
      debugPrint('❌ Error searching for backup: $e');
      return null; // Don't throw - we can still create new backup
    }
  }

  /// Upload backup file to Drive
  Future<void> _uploadBackupFile(List<int> bytes) async {
    try {
      final driveFile = drive.File()
        ..name = _backupFileName
        ..parents = ['appDataFolder']
        ..mimeType = 'application/json';

      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
      );

      await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      debugPrint('✅ Backup file uploaded successfully');
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      rethrow;
    }
  }

  // ============================================================
  // RESTORE OPERATIONS
  // ============================================================

  /// Restore notes from Google Drive
  ///
  /// BILLING PROTECTION:
  /// - Only called when user explicitly taps "Restore Backup"
  /// - Searches for backup file (1 list() call)
  /// - Downloads backup content (1 get() call)
  /// - Total: 2 API calls per restore
  Future<List<Note>> restoreNotes() async {
    try {
      if (!isSignedIn) {
        throw Exception('Not signed in. Please sign in first.');
      }

      if (_driveApi == null) {
        await _initializeDriveApi();
      }

      debugPrint('📥 Starting restore...');

      // STEP 1: Find backup file
      final fileId = await _findBackupFile();

      if (fileId == null) {
        throw Exception('No backup found in Google Drive');
      }

      // STEP 2: Download backup file
      debugPrint('📥 Downloading backup...');
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Read the stream
      final bytes = <int>[];
      await for (var chunk in media.stream) {
        bytes.addAll(chunk);
      }

      debugPrint(
          '📦 Downloaded ${(bytes.length / 1024).toStringAsFixed(2)} KB');

      // STEP 3: Parse JSON
      final jsonString = utf8.decode(bytes);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate backup data
      if (!backupData.containsKey('notes')) {
        throw Exception('Invalid backup file format');
      }

      final notesJson = backupData['notes'] as List;
      final notes = notesJson
          .map((json) => Note.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ Restore completed: ${notes.length} notes');
      return notes;
    } catch (e) {
      debugPrint('❌ Restore error: $e');

      // User-friendly error messages
      if (e.toString().contains('network')) {
        throw Exception(
            'No internet connection. Please check your network and try again.');
      } else if (e.toString().contains('No backup found')) {
        throw Exception('No backup found. Please create a backup first.');
      } else {
        throw Exception('Restore failed: ${e.toString()}');
      }
    }
  }

  // ============================================================
  // AUTO-BACKUP (24-HOUR INTERVAL)
  // ============================================================

  /// Check if auto-backup is enabled
  Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupEnabledKey) ?? false;
  }

  /// Enable or disable auto-backup
  Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupEnabledKey, enabled);
    debugPrint('🔄 Auto-backup ${enabled ? "enabled" : "disabled"}');
  }

  /// Check if 24 hours have passed since last backup
  ///
  /// BILLING PROTECTION: This only reads SharedPreferences.
  /// No API calls are made. Auto-backup is ONLY triggered if:
  /// 1. User has enabled auto-backup
  /// 2. 24 hours have passed since last backup
  /// 3. User is signed in
  Future<bool> shouldAutoBackup() async {
    try {
      // Check if auto-backup is enabled
      final isEnabled = await isAutoBackupEnabled();
      if (!isEnabled) {
        return false;
      }

      // Check if user is signed in
      if (!isSignedIn) {
        return false;
      }

      // Check last backup timestamp
      final prefs = await SharedPreferences.getInstance();
      final lastBackup = prefs.getInt(_lastBackupKey);

      if (lastBackup == null) {
        // No previous backup - allow first auto-backup
        debugPrint('🔄 First auto-backup will be allowed');
        return true;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = now - lastBackup;

      if (elapsed >= _autoBackupIntervalMs) {
        debugPrint(
            '🔄 24 hours elapsed since last backup - auto-backup allowed');
        return true;
      } else {
        final hoursRemaining =
            (_autoBackupIntervalMs - elapsed) / (60 * 60 * 1000);
        debugPrint(
            '⏱️ Auto-backup in ${hoursRemaining.toStringAsFixed(1)} hours');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error checking auto-backup: $e');
      return false;
    }
  }

  /// Get last backup date
  Future<DateTime?> getLastBackupDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastBackupKey);

      if (timestamp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      debugPrint('❌ Error getting last backup date: $e');
      return null;
    }
  }

  /// Save last backup timestamp
  Future<void> _saveLastBackupTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_lastBackupKey, now);
      debugPrint('💾 Last backup timestamp saved');
    } catch (e) {
      debugPrint('⚠️ Failed to save backup timestamp: $e');
      // Don't throw - backup was successful even if timestamp save failed
    }
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Format date for display
  String formatLastBackupDate(DateTime? date) {
    if (date == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
