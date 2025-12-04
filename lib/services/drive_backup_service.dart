import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Google Drive Backup & Restore service using AppData folder.
/// Scopes: drive.appdata, userinfo.email
class DriveBackupService {
  static final DriveBackupService _instance = DriveBackupService._internal();
  factory DriveBackupService() => _instance;
  DriveBackupService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const [
      'https://www.googleapis.com/auth/drive.appdata',
      'https://www.googleapis.com/auth/userinfo.email',
    ],
  );

  GoogleSignInAccount? _account;
  String? _accessToken;
  DateTime? lastBackupTime;

  // Debounce for auto backup.
  Timer? _debounce;

  Future<GoogleSignInAccount?> login() async {
    try {
      _account = await _googleSignIn.signInSilently();
      _account ??= await _googleSignIn.signIn();
      if (_account == null) return null;

      final auth = await _account!.authentication;
      _accessToken = auth.accessToken;
      return _account;
    } catch (e) {
      debugPrint('Drive login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _googleSignIn.disconnect();
    _account = null;
    _accessToken = null;
  }

  String? get email => _account?.email;
  String? get displayName => _account?.displayName;

  bool get isAuthenticated => _accessToken != null;

  /// List files in AppData folder to find existing backup.
  Future<List<Map<String, dynamic>>> listAppDataFiles() async {
    _ensureToken();
    final uri = Uri.parse(
        'https://www.googleapis.com/drive/v3/files?q=\'appDataFolder\' in parents');
    final res = await http.get(uri, headers: _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('Drive list error: ${res.statusCode} ${res.body}');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final files = (data['files'] as List?) ?? [];
    return files.cast<Map<String, dynamic>>();
  }

  /// Backup notes JSON to Drive AppData folder.
  Future<String> backupNow(List<Map<String, dynamic>> notes) async {
    _ensureToken();
    final payload = {
      'version': 1,
      'lastBackup': DateTime.now().toIso8601String(),
      'notes': notes,
    };
    final jsonBytes = utf8.encode(json.encode(payload));

    final existing = await _findBackupFileId();
    if (existing != null) {
      await _updateBackupFile(existing, jsonBytes);
    } else {
      await _uploadBackupFile(jsonBytes);
    }
    lastBackupTime = DateTime.now();
    return 'Backup Successful';
  }

  /// Debounced auto backup trigger.
  void triggerAutoBackup(
      Future<List<Map<String, dynamic>>> Function() fetchNotes) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () async {
      try {
        final notes = await fetchNotes();
        await backupNow(notes);
      } catch (e) {
        debugPrint('Auto backup failed: $e');
      }
    });
  }

  /// Restore notes from Drive backup JSON.
  Future<Map<String, dynamic>> restore() async {
    _ensureToken();
    final fileId = await _findBackupFileId();
    if (fileId == null) {
      throw Exception('No backup file found in Drive AppData');
    }
    final bytes = await _downloadBackupFile(fileId);
    final content = utf8.decode(bytes);
    final data = json.decode(content) as Map<String, dynamic>;
    if (data['notes'] == null || data['notes'] is! List) {
      throw Exception('Invalid backup JSON');
    }
    return data;
  }

  Future<String?> _findBackupFileId() async {
    final files = await listAppDataFiles();
    for (final f in files) {
      if (f['name'] == 'notes_backup.json') {
        return f['id'] as String?;
      }
    }
    return null;
  }

  Map<String, String> _authHeaders() => {
        'Authorization': 'Bearer $_accessToken',
      };

  void _ensureToken() {
    if (_accessToken == null) {
      throw Exception('Not authenticated. Please login again.');
    }
  }

  /// Create a new backup file.
  Future<void> _uploadBackupFile(List<int> jsonBytes) async {
    final metadata = {
      'name': 'notes_backup.json',
      'parents': ['appDataFolder'],
      'mimeType': 'application/json',
    };

    final uri = Uri.parse(
        'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authHeaders());
    request.fields['metadata'] = json.encode(metadata);
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      jsonBytes,
      filename: 'notes_backup.json',
      contentType: http.MediaType('application', 'json'),
    ));

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 200) {
      throw Exception(
          'Drive upload error: ${response.statusCode} ${response.body}');
    }
  }

  /// Update an existing backup file.
  Future<void> _updateBackupFile(String fileId, List<int> jsonBytes) async {
    final metadata = {
      'mimeType': 'application/json',
    };
    final uri = Uri.parse(
        'https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=multipart');
    final request = http.MultipartRequest('PATCH', uri);
    request.headers.addAll(_authHeaders());
    request.fields['metadata'] = json.encode(metadata);
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      jsonBytes,
      filename: 'notes_backup.json',
      contentType: http.MediaType('application', 'json'),
    ));
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 200) {
      throw Exception(
          'Drive update error: ${response.statusCode} ${response.body}');
    }
  }

  /// Download raw backup file content.
  Future<List<int>> _downloadBackupFile(String fileId) async {
    final uri = Uri.parse(
        'https://www.googleapis.com/drive/v3/files/$fileId?alt=media');
    final res = await http.get(uri, headers: _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('Drive download error: ${res.statusCode} ${res.body}');
    }
    return res.bodyBytes;
  }
}

/// Helper: convert notes to JSON-friendly maps.
abstract class NotesJsonConverter {
  /// Implement this to fetch notes from your repository and convert to maps.
  static List<Map<String, dynamic>> toJsonList(Iterable<dynamic> notes) {
    return notes.map((n) {
      // Expect a Note model with id, title, content, category, createdAt, updatedAt
      // Adjust keys to match your actual model fields.
      return {
        'id': n.id,
        'title': n.title,
        'content': n.content,
        'category': n.category,
        'createdAt': n.createdAt?.toIso8601String(),
        'updatedAt': n.updatedAt?.toIso8601String(),
      };
    }).toList();
  }
}
