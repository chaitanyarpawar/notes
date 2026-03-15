/// ================================================================================================
/// BACKUP PROVIDER - STATE MANAGEMENT FOR GOOGLE DRIVE BACKUP
/// ================================================================================================
///
/// This provider manages the state of Google Drive backup operations including:
/// - User authentication state
/// - Backup/restore operations progress
/// - Auto-backup settings
/// - Last backup timestamp
///
/// Used by the Settings screen to display UI and trigger backup/restore operations.
/// ================================================================================================
library;

import 'package:flutter/foundation.dart';
import '../services/google_drive_backup_service.dart';
import '../models/note.dart';

/// Backup operation states
enum BackupState {
  idle,
  signingIn,
  signingOut,
  backingUp,
  restoring,
  error,
}

/// Backup Provider
///
/// Manages all backup-related state and operations.
/// Notifies listeners when state changes so UI can update.
class BackupProvider extends ChangeNotifier {
  final GoogleDriveBackupService _backupService = GoogleDriveBackupService();

  // ============================================================
  // STATE VARIABLES
  // ============================================================

  BackupState _state = BackupState.idle;
  String? _errorMessage;
  DateTime? _lastBackupDate;
  bool _autoBackupEnabled = false;
  bool _isInitialized = false;

  // ============================================================
  // GETTERS
  // ============================================================

  BackupState get state => _state;
  String? get errorMessage => _errorMessage;
  DateTime? get lastBackupDate => _lastBackupDate;
  bool get autoBackupEnabled => _autoBackupEnabled;
  bool get isInitialized => _isInitialized;

  /// Check if user is signed in
  bool get isSignedIn => _backupService.isSignedIn;

  /// Get user email
  String? get userEmail => _backupService.userEmail;

  /// Get user display name
  String? get userDisplayName => _backupService.userDisplayName;

  /// Get user photo URL
  String? get userPhotoUrl => _backupService.userPhotoUrl;

  /// Check if currently performing any operation
  bool get isLoading =>
      _state == BackupState.signingIn ||
      _state == BackupState.signingOut ||
      _state == BackupState.backingUp ||
      _state == BackupState.restoring;

  /// Get formatted last backup date
  String get formattedLastBackupDate =>
      _backupService.formatLastBackupDate(_lastBackupDate);

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize the provider
  ///
  /// This should be called once when the app starts.
  /// It checks for existing sign-in and loads settings.
  ///
  /// BILLING PROTECTION: No Drive API calls are made during initialization.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔄 Initializing BackupProvider...');

      // Initialize backup service (checks for cached sign-in)
      await _backupService.initialize();

      // Load settings
      await _loadSettings();

      _isInitialized = true;
      notifyListeners();

      debugPrint('✅ BackupProvider initialized');
    } catch (e) {
      debugPrint('❌ BackupProvider initialization error: $e');
      // Don't throw - app can continue without backup
    }
  }

  /// Load backup settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      _autoBackupEnabled = await _backupService.isAutoBackupEnabled();
      _lastBackupDate = await _backupService.getLastBackupDate();
      debugPrint(
          '📋 Settings loaded: autoBackup=$_autoBackupEnabled, lastBackup=$_lastBackupDate');
    } catch (e) {
      debugPrint('⚠️ Error loading settings: $e');
    }
  }

  // ============================================================
  // SIGN-IN & SIGN-OUT
  // ============================================================

  /// Sign in with Google
  Future<bool> signIn() async {
    try {
      _setState(BackupState.signingIn);
      _errorMessage = null;

      final success = await _backupService.signIn();

      if (success) {
        await _loadSettings();
        _setState(BackupState.idle);
        return true;
      } else {
        // User dismissed the sign-in dialog (tapped back)
        _errorMessage = null; // No error — user chose to cancel
        _setState(BackupState.idle);
        return false;
      }
    } on Object catch (e) {
      final errStr = e.toString();
      if (errStr.contains('ApiException: 10') ||
          errStr.contains('DEVELOPER_ERROR') ||
          errStr.contains('sign_in_failed')) {
        // ApiException 10 = DEVELOPER_ERROR = release SHA-1 not in Firebase
        _errorMessage =
            'Sign-in failed: Release SHA-1 not registered in Firebase. '
            'Add B0:A8:8E:6E:91:55:8F:E3:F0:26:F3:FB:CF:BE:6E:99:47:64:14:45 '
            'to Firebase Console → Project Settings → Your app → SHA certificates, '
            'then re-download google-services.json.';
      } else if (errStr.contains('network_error') ||
          errStr.contains('NETWORK_ERROR')) {
        _errorMessage =
            'No internet connection. Please check your network and try again.';
      } else {
        _errorMessage = 'Sign-in failed. Please try again. ($errStr)';
      }
      _setState(BackupState.error);
      debugPrint('❌ Sign-in error: $e');
      return false;
    }
  }

  /// Sign out from Google
  Future<bool> signOut() async {
    try {
      _setState(BackupState.signingOut);
      _errorMessage = null;

      await _backupService.signOut();

      _setState(BackupState.idle);
      return true;
    } catch (e) {
      _errorMessage = 'Sign-out failed: ${e.toString()}';
      _setState(BackupState.error);
      debugPrint('❌ Sign-out error: $e');
      return false;
    }
  }

  // ============================================================
  // BACKUP OPERATIONS
  // ============================================================

  /// Backup notes to Google Drive
  ///
  /// This should be called when user taps "Backup Now" button.
  ///
  /// BILLING PROTECTION: Only makes API calls when explicitly triggered by user.
  Future<bool> backupNotes(List<Note> notes) async {
    if (!isSignedIn) {
      _errorMessage = 'Please sign in first';
      _setState(BackupState.error);
      return false;
    }

    try {
      _setState(BackupState.backingUp);
      _errorMessage = null;

      await _backupService.backupNotes(notes);

      // Update last backup date
      _lastBackupDate = await _backupService.getLastBackupDate();

      _setState(BackupState.idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setState(BackupState.error);
      debugPrint('❌ Backup error: $e');
      return false;
    }
  }

  /// Restore notes from Google Drive
  ///
  /// This should be called when user taps "Restore Backup" button.
  /// Returns the list of restored notes, or null if failed.
  ///
  /// BILLING PROTECTION: Only makes API calls when explicitly triggered by user.
  Future<List<Note>?> restoreNotes() async {
    if (!isSignedIn) {
      _errorMessage = 'Please sign in first';
      _setState(BackupState.error);
      return null;
    }

    try {
      _setState(BackupState.restoring);
      _errorMessage = null;

      final notes = await _backupService.restoreNotes();

      _setState(BackupState.idle);
      return notes;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setState(BackupState.error);
      debugPrint('❌ Restore error: $e');
      return null;
    }
  }

  // ============================================================
  // AUTO-BACKUP
  // ============================================================

  /// Toggle auto-backup setting
  Future<void> toggleAutoBackup() async {
    try {
      _autoBackupEnabled = !_autoBackupEnabled;
      await _backupService.setAutoBackupEnabled(_autoBackupEnabled);
      notifyListeners();
      debugPrint('🔄 Auto-backup toggled: $_autoBackupEnabled');
    } catch (e) {
      debugPrint('❌ Error toggling auto-backup: $e');
    }
  }

  /// Check if auto-backup should be performed
  ///
  /// BILLING PROTECTION: This only checks SharedPreferences.
  /// No API calls are made. Returns true only if:
  /// - Auto-backup is enabled
  /// - User is signed in
  /// - 24 hours have passed since last backup
  Future<bool> shouldAutoBackup() async {
    return await _backupService.shouldAutoBackup();
  }

  /// Perform auto-backup if conditions are met
  ///
  /// This can be called when app starts or resumes.
  /// It will only perform backup if all conditions are met.
  Future<void> performAutoBackupIfNeeded(List<Note> notes) async {
    try {
      final should = await shouldAutoBackup();

      if (should) {
        debugPrint('🔄 Performing auto-backup...');
        await backupNotes(notes);
        debugPrint('✅ Auto-backup completed');
      }
    } catch (e) {
      debugPrint('⚠️ Auto-backup failed: $e');
      // Don't show error to user for auto-backup failures
    }
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Set state and notify listeners
  void _setState(BackupState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    if (_state == BackupState.error) {
      _state = BackupState.idle;
    }
    notifyListeners();
  }
}
