import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/backup_provider.dart';
import '../utils/constants.dart';
import '../providers/notes_provider.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: const SettingsTabContent(),
    );
  }
}

class SettingsTabContent extends StatelessWidget {
  const SettingsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, SettingsProvider, BackupProvider>(
      builder:
          (context, themeProvider, settingsProvider, backupProvider, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Google Drive Backup Section
            _buildSectionTitle('Google Drive Backup'),
            const _GoogleBackupSection(),
            const SizedBox(height: 24),

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
            _buildSettingsTile(
              title: 'Test Notification',
              subtitle: 'Schedule a test reminder in 10 seconds',
              leading: Icon(
                Icons.notifications_active_outlined,
                color: Theme.of(context).primaryColor,
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _testNotification(context),
            ),
            _buildSettingsTile(
              title: 'Test Instant Notification',
              subtitle: 'Show a notification RIGHT NOW (no scheduling)',
              leading: const Icon(Icons.flash_on, color: Colors.orange),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _testInstantNotification(context),
            ),
            _buildSettingsTile(
              title: 'Fix: Battery Optimization',
              subtitle:
                  'Exempt app from battery saving (required for reminders)',
              leading:
                  const Icon(Icons.battery_charging_full, color: Colors.green),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _fixBatteryOptimization(context),
            ),
            _buildSettingsTile(
              title: 'Fix: Alarm Permission',
              subtitle: 'Grant exact alarm permission (Android 12+)',
              leading: const Icon(Icons.alarm, color: Colors.blue),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _fixAlarmPermission(context),
            ),
            _buildSettingsTile(
              title: 'Reminder Diagnostics',
              subtitle: 'Check what is blocking reminders',
              leading: const Icon(Icons.bug_report_outlined, color: Colors.red),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showReminderDiagnostics(context),
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

            const SizedBox(height: 32),

            // App branding
            Center(
              child: Column(
                children: [
                  // New app icon from assets
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/icon/icon_home.png',
                      width: 72,
                      height: 72,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Capture Your Thoughts',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32), // Space below text
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black54, size: 20),
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
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      trailing: trailing,
      onTap: onTap,
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

  void _testNotification(BuildContext context) async {
    try {
      await NotificationService.scheduleTestReminder(
        title: 'PebbleNote Test',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Test reminder scheduled! Should appear in 10 seconds.'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to schedule test notification: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _testInstantNotification(BuildContext context) async {
    try {
      await NotificationService.showInstantNotification(
        'PebbleNote ✅',
        'Notifications are working! Reminders will fire at the scheduled time.',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Instant notification sent! Check your notification shade.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Instant notification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _fixBatteryOptimization(BuildContext context) async {
    final isExempt = await NotificationService.isIgnoringBatteryOptimizations();
    if (!context.mounted) return;
    if (isExempt) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Already exempt from battery optimization!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Battery Optimization'),
          content: const Text(
            'To receive reminders reliably, PebbleNote needs to be exempt from battery optimization.\n\n'
            'A system dialog will appear. Tap "Allow" to enable reliable reminders.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await NotificationService.requestIgnoreBatteryOptimizations();
              },
              child: const Text('Fix It'),
            ),
          ],
        ),
      );
    }
  }

  void _fixAlarmPermission(BuildContext context) async {
    final canExact = await NotificationService.canScheduleExactAlarms();
    if (!context.mounted) return;
    if (canExact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Exact alarm permission already granted!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Alarm Permission'),
          content: const Text(
            'PebbleNote needs "Alarms & Reminders" permission to fire notifications at the exact time.\n\n'
            'Tap "Open Settings", find PebbleNote in the list, and enable it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await NotificationService.openAlarmSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

  void _showReminderDiagnostics(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final isExempt = await NotificationService.isIgnoringBatteryOptimizations();
    final canExact = await NotificationService.canScheduleExactAlarms();

    if (!context.mounted) return;
    Navigator.pop(context); // close loading

    final batteryOk = isExempt;
    final alarmOk = canExact;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reminder Diagnostics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _diagRow(
                batteryOk,
                'Battery Optimization Exempt',
                batteryOk
                    ? 'Reminders fire even in background'
                    : 'App may be killed — tap "Fix" to fix'),
            const SizedBox(height: 12),
            _diagRow(
                alarmOk,
                'Exact Alarm Permission',
                alarmOk
                    ? 'Reminders fire at exact time'
                    : 'Reminders may be delayed 5-15 min'),
            const SizedBox(height: 16),
            if (!batteryOk || !alarmOk)
              const Text(
                '⚠️ Fix the issues above to get reliable reminders.',
                style: TextStyle(color: Colors.orange, fontSize: 13),
              )
            else
              const Text(
                '✅ All good! Reminders should work correctly.',
                style: TextStyle(color: Colors.green, fontSize: 13),
              ),
          ],
        ),
        actions: [
          if (!batteryOk)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await NotificationService.requestIgnoreBatteryOptimizations();
              },
              child: const Text('Fix Battery'),
            ),
          if (!alarmOk)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await NotificationService.openAlarmSettings();
              },
              child: const Text('Fix Alarm'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _diagRow(bool ok, String label, String detail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(ok ? Icons.check_circle : Icons.cancel,
            color: ok ? Colors.green : Colors.red, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text(detail,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
      ],
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
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showColorThemePicker(BuildContext context) {
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
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) => Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom +
                    16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Choose Primary Color',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: colors.map((c) {
                      final selected =
                          themeProvider.primaryColor.value == c.value;
                      return GestureDetector(
                        onTap: () {
                          themeProvider.setPrimaryColor(c);
                          // Don't close immediately - let user see the change
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: selected ? 50 : 44,
                          height: selected ? 50 : 44,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Colors.black87
                                  : Colors.transparent,
                              width: selected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: selected ? 0.3 : 0.2,
                                ),
                                blurRadius: selected ? 8 : 6,
                                spreadRadius: selected ? 1 : 0,
                              ),
                            ],
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ================================================================================================
/// GOOGLE BACKUP SECTION - PRODUCTION-READY UI
/// ================================================================================================
///
/// This section implements the complete Google Drive backup UI with:
/// - Sign-in/sign-out with user profile display
/// - Manual backup button
/// - Restore backup button
/// - Auto-backup toggle
/// - Last backup timestamp display
/// - Loading states and error handling
/// - User-friendly confirmation dialogs
///
/// FOLLOWS ALL REQUIREMENTS FROM THE SPECIFICATION
/// ================================================================================================

class _GoogleBackupSection extends StatelessWidget {
  const _GoogleBackupSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<BackupProvider>(
      builder: (context, backupProvider, child) {
        return Container(
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.cloud_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cloud Backup',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Sync your notes to Google Drive',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sign-in or User Profile Section
                if (!backupProvider.isSignedIn) ...[
                  // Not signed in - show sign-in button
                  _buildSignInButton(context, backupProvider),
                ] else ...[
                  // Signed in - show user profile and backup options
                  _buildUserProfile(context, backupProvider),
                  const Divider(height: 32, thickness: 1),
                  _buildBackupOptions(context, backupProvider),
                ],

                // Privacy notice
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Backups are stored privately in your Google Drive and are not accessible by PebbleNote.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Sign-in button (shown when user is not signed in)
  Widget _buildSignInButton(
    BuildContext context,
    BackupProvider backupProvider,
  ) {
    final isLoading = backupProvider.state == BackupState.signingIn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed:
              isLoading ? null : () => _handleSignIn(context, backupProvider),
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Image.asset(
                  'assets/icon/google_logo.png',
                  width: 20,
                  height: 20,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.login, color: Colors.white),
                ),
          label: Text(
            isLoading ? 'Signing in...' : 'Sign in with Google',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (backupProvider.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            backupProvider.errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ],
      ],
    );
  }

  /// User profile section (shown when user is signed in)
  Widget _buildUserProfile(
    BuildContext context,
    BackupProvider backupProvider,
  ) {
    return Row(
      children: [
        // Profile photo
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: backupProvider.userPhotoUrl != null
              ? NetworkImage(backupProvider.userPhotoUrl!)
              : null,
          child: backupProvider.userPhotoUrl == null
              ? const Icon(Icons.person, size: 32, color: Colors.grey)
              : null,
        ),
        const SizedBox(width: 16),

        // User info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                backupProvider.userDisplayName ?? 'User',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                backupProvider.userEmail ?? '',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Sign out button
        TextButton(
          onPressed: backupProvider.isLoading
              ? null
              : () => _handleSignOut(context, backupProvider),
          child: const Text('Sign Out'),
        ),
      ],
    );
  }

  /// Backup options section (shown when user is signed in)
  Widget _buildBackupOptions(
    BuildContext context,
    BackupProvider backupProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Backup Now button
        ElevatedButton.icon(
          onPressed: backupProvider.isLoading
              ? null
              : () => _handleBackupNow(context, backupProvider),
          icon: backupProvider.state == BackupState.backingUp
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.cloud_upload_outlined),
          label: Text(
            backupProvider.state == BackupState.backingUp
                ? 'Backing up...'
                : 'Backup Now',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Restore Backup button
        OutlinedButton.icon(
          onPressed: backupProvider.isLoading
              ? null
              : () => _handleRestoreBackup(context, backupProvider),
          icon: backupProvider.state == BackupState.restoring
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                )
              : const Icon(Icons.cloud_download_outlined),
          label: Text(
            backupProvider.state == BackupState.restoring
                ? 'Restoring...'
                : 'Restore Backup',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).primaryColor,
            side: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Last backup info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'Last backup: ${backupProvider.formattedLastBackupDate}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Auto-backup toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.autorenew,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto Backup',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Backup once every 24 hours',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Switch(
                value: backupProvider.autoBackupEnabled,
                onChanged: backupProvider.isLoading
                    ? null
                    : (value) => backupProvider.toggleAutoBackup(),
                activeThumbColor: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),

        // Error message
        if (backupProvider.state == BackupState.error &&
            backupProvider.errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    backupProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // EVENT HANDLERS
  // ============================================================

  /// Handle sign-in
  Future<void> _handleSignIn(
    BuildContext context,
    BackupProvider backupProvider,
  ) async {
    final success = await backupProvider.signIn();

    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Signed in successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Handle sign-out
  Future<void> _handleSignOut(
    BuildContext context,
    BackupProvider backupProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? Your backups will remain in Google Drive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await backupProvider.signOut();

      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Handle backup now
  Future<void> _handleBackupNow(
    BuildContext context,
    BackupProvider backupProvider,
  ) async {
    // Get notes from provider
    final notesProvider = context.read<NotesProvider>();
    final notes = notesProvider.notes;

    if (notes.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ No notes to backup'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final success = await backupProvider.backupNotes(notes);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Backed up ${notes.length} notes successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Error is already shown in the UI, just clear it after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (context.mounted) {
            backupProvider.clearError();
          }
        });
      }
    }
  }

  /// Handle restore backup
  Future<void> _handleRestoreBackup(
    BuildContext context,
    BackupProvider backupProvider,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'This will replace all your local notes with the backup from Google Drive. '
          'This action cannot be undone.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Perform restore
    final restoredNotes = await backupProvider.restoreNotes();

    if (context.mounted) {
      if (restoredNotes != null) {
        // Replace all notes in the provider
        final notesProvider = context.read<NotesProvider>();
        await notesProvider.restoreFromBackup(restoredNotes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Restored ${restoredNotes.length} notes successfully',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Error is already shown in the UI, just clear it after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (context.mounted) {
            backupProvider.clearError();
          }
        });
      }
    }
  }
}
