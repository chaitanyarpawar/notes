import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../providers/notes_provider.dart';
import '../services/drive_backup_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: const SettingsTabContent(),
    );
  }
}

class SettingsTabContent extends StatelessWidget {
  const SettingsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, SettingsProvider>(
      builder: (context, themeProvider, settingsProvider, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Section removed

            // Appearance Section
            _buildSectionTitle('Appearance'),
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Dark Mode removed
                  _buildModernSettingsTile(
                    icon: Icons.text_fields,
                    title: 'Font Size',
                    subtitle: _fontSizeLabel(themeProvider.fontScale),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () => _showFontSizePicker(context),
                  ),
                  _buildDivider(),
                  _buildModernSettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'Color Theme',
                    subtitle: 'Customize colors',
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () => _showColorThemePicker(context),
                  ),
                ],
              ),
            ),

            // Cloud Sync Section removed

            // Preferences Section
            // Preferences - Remove Ads removed

            const SizedBox(height: 24),

            // App Info Section
            _buildSectionTitle('About'),
            _buildSettingsTile(
              title: 'App Version',
              subtitle: AppConstants.appVersion,
              leading: Icon(
                Icons.info_outline,
                color: Theme.of(context).primaryColor,
              ),
            ),
            _buildSettingsTile(
              title: 'Developer',
              subtitle: 'Made with ❤️ for note-taking',
              leading: Icon(
                Icons.person_outline,
                color: Theme.of(context).primaryColor,
              ),
            ),

            const SizedBox(height: 24),

            // Danger Zone
            _buildSectionTitle('Data'),
            _buildSettingsTile(
              title: 'Reset App',
              subtitle: 'Clear all notes and settings',
              leading: const Icon(
                Icons.warning_amber_outlined,
                color: Colors.red,
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showResetDialog(context),
            ),

            const SizedBox(height: 48),

            // App branding
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.note_alt_rounded,
                    size: 48,
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mood-Based Note Taking',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModernSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.black54,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade200,
      indent: 60,
      endIndent: 20,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        leading: leading,
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    const policyText = '• Does not collect personal information\n'
        '• Uses AdMob for advertisements (when ads are enabled)\n'
        '• Does not share your notes with third parties\n\n'
        'All your notes remain private and secure on your device.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(child: Text(policyText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App'),
        content: const Text(
          'This will clear all notes and reset settings. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              // Capture dependencies and navigators before awaits
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final notesProvider = context.read<NotesProvider>();
              final settingsProvider = context.read<SettingsProvider>();
              final theme = context.read<ThemeProvider>();

              // Perform async operations
              await notesProvider.clearAllNotes();
              await settingsProvider.resetSettings();
              await theme.setTheme(false);
              await theme.setFontScale(1.0);
              await theme.setPrimaryColor(const Color(0xFFFF9500));

              // Use captured references; no BuildContext after await
              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('App reset successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  String _fontSizeLabel(double scale) {
    if (scale <= 0.95) return 'Small';
    if (scale >= 1.08) return 'Large';
    return 'Medium';
  }

  void _showFontSizePicker(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Small'),
            trailing: themeProvider.fontScale <= 0.95
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              themeProvider.setFontScale(0.95);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Medium'),
            trailing: (themeProvider.fontScale > 0.95 &&
                    themeProvider.fontScale < 1.08)
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              themeProvider.setFontScale(1.0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Large'),
            trailing: themeProvider.fontScale >= 1.08
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              themeProvider.setFontScale(1.1);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showColorThemePicker(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final colors = <Color>[
      const Color(0xFFFF9500), // Orange
      const Color(0xFF2196F3), // Blue
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF4CAF50), // Green
      const Color(0xFFE91E63), // Pink
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Primary Color',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors.map((c) {
                final selected =
                    themeProvider.primaryColor.toARGB32() == c.toARGB32();
                return GestureDetector(
                  onTap: () {
                    themeProvider.setPrimaryColor(c);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupSection extends StatefulWidget {
  const _BackupSection();

  @override
  State<_BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<_BackupSection> {
  final DriveBackupService _service = DriveBackupService();
  String _status = '';
  bool _loading = false;

  Future<void> _ensureLogin() async {
    if (!_service.isAuthenticated) {
      await _service.login();
      setState(() {});
    }
  }

  Future<void> _backup() async {
    setState(() {
      _loading = true;
      _status = 'Backing up…';
    });
    try {
      await _ensureLogin();
      if (!mounted) return;
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      final notes = notesProvider.notes
          .map((n) => {
                'id': n.id,
                'title': n.title,
                'content': n.content,
                'category': n.category,
                'createdAt': n.createdAt.toIso8601String(),
                'updatedAt': n.updatedAt.toIso8601String(),
              })
          .toList();
      final msg = await _service.backupNow(notes);
      setState(() {
        _status = msg;
      });
    } catch (e) {
      setState(() {
        _status = 'Backup failed: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _restore() async {
    setState(() {
      _loading = true;
      _status = 'Restoring…';
    });
    try {
      await _ensureLogin();
      final data = await _service.restore();
      final notes = (data['notes'] as List).cast<Map<String, dynamic>>();
      // Replace local notes via provider
      if (!mounted) return;
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      await notesProvider.replaceAllFromBackup(notes);
      setState(() {
        _status = 'Restore complete. Notes synced from Drive.';
      });
    } catch (e) {
      setState(() {
        _status = 'Restore failed: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.cloud_sync_outlined, color: Color(0xFFFF9500)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_service.displayName ?? 'Not signed in',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(_service.email ?? '',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Text(
              _service.lastBackupTime != null
                  ? 'Last backup: ${_service.lastBackupTime}'
                  : 'No backups yet',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _backup,
              child: const Text('Backup Now'),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _loading ? null : _restore,
              child: const Text('Restore Now'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_status.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _status,
              style: TextStyle(
                color: _status.toLowerCase().contains('failed')
                    ? Colors.red
                    : Colors.green,
              ),
            ),
          ),
      ],
    );
  }
}
