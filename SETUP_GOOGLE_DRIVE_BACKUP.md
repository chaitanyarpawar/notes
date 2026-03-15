# 🚀 Quick Setup Guide - Google Drive Backup

## Step 1: Install Dependencies

Run this command in your project directory:

```powershell
flutter pub get
```

This will install the new dependencies:
- `googleapis`
- `extension_google_sign_in_as_googleapis_auth`

---

## Step 2: Configure Google Cloud Console

### 2.1 Create/Select Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Name it: `PebbleNote` (or any name you prefer)

### 2.2 Enable Google Drive API
1. In the left sidebar, go to **APIs & Services** → **Library**
2. Search for "Google Drive API"
3. Click on it and press **ENABLE**

### 2.3 Create OAuth 2.0 Credentials

#### For Android:
1. Go to **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Choose **Android** as application type
4. Enter the following:
   - **Name**: `PebbleNote Android`
   - **Package name**: `com.pebblenote.app`
   - **SHA-1 certificate fingerprint**: Get it by running this command:
     
     **For Debug (Development):**
     ```powershell
     keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
     ```
     
     **For Release (Production):**
     ```powershell
     keytool -list -v -keystore "path\to\your\keystore.jks" -alias your-key-alias
     ```
5. Click **CREATE**
6. Copy the **Client ID** (you won't need to paste it anywhere, it's automatically configured)

#### For iOS (Optional):
1. Create another OAuth client ID
2. Choose **iOS** as application type
3. Enter package name: `com.pebblenote.app`
4. Copy the **iOS URL scheme** (looks like: `com.googleusercontent.apps.XXXXXXX`)
5. Add it to `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
           </array>
       </dict>
   </array>
   ```

---

## Step 3: Update AndroidManifest.xml

Open `android/app/src/main/AndroidManifest.xml` and verify these permissions exist:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <application
        android:label="PebbleNote"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Add this meta-data tag inside <application> -->
        <meta-data
            android:name="com.google.android.gms.version"
            android:value="@integer/google_play_services_version" />
        
        <!-- Your existing activity declarations -->
        ...
    </application>
</manifest>
```

---

## Step 4: Test the Implementation

### 4.1 Run the App
```powershell
flutter run
```

### 4.2 Test Sign-In
1. Open the app
2. Navigate to **Settings**
3. Scroll to **Google Drive Backup** section
4. Tap **"Sign in with Google"**
5. Select your Google account
6. Grant permission for "Drive AppData"
7. You should see your profile photo, name, and email

### 4.3 Test Backup
1. Create some notes in the app
2. Go to **Settings** → **Google Drive Backup**
3. Tap **"Backup Now"**
4. Wait for success message: ✅ "Backed up X notes successfully"
5. Check "Last backup" timestamp

### 4.4 Test Restore
1. Create a backup (as above)
2. Create a new test note
3. Tap **"Restore Backup"**
4. Confirm in the dialog
5. Verify that only the backed-up notes remain
6. The new test note should be gone

### 4.5 Test Auto-Backup
1. Enable the **"Auto Backup"** toggle
2. Auto-backup will run once every 24 hours automatically

---

## Step 5: Verify Google Drive Storage

### Check Your Backup:
1. The backup is stored in Google Drive's AppData folder
2. It's **NOT visible** in your Drive UI (this is by design)
3. Only PebbleNote can access it
4. To verify it exists, use the restore function in the app

### File Details:
- **Filename**: `pebblenote_backup.json`
- **Location**: AppData folder (hidden)
- **Format**: JSON
- **Size**: Usually 1-10 KB depending on number of notes

---

## 🐛 Troubleshooting

### Issue: "Sign-in failed"
**Solution:**
- Verify internet connection
- Check that Google Play Services is installed on device
- Ensure OAuth credentials are correctly configured
- Try clearing app data and signing in again

### Issue: "SHA-1 fingerprint doesn't match"
**Solution:**
- Make sure you're using the correct keystore
- Debug builds use `debug.keystore`
- Release builds use your production keystore
- Create separate OAuth clients for debug and release

### Issue: "API not enabled"
**Solution:**
- Go back to Google Cloud Console
- Enable the Google Drive API
- Wait 1-2 minutes for it to activate

### Issue: "Backup failed: Authentication error"
**Solution:**
- Sign out from the app
- Sign in again
- If still fails, revoke app permissions in Google account settings
- Sign in again from scratch

---

## ✅ Verification Checklist

Before deploying to production, verify:

- [ ] Dependencies installed (`flutter pub get`)
- [ ] Google Cloud project created
- [ ] Google Drive API enabled
- [ ] OAuth credentials created for Android
- [ ] OAuth credentials created for iOS (if supporting iOS)
- [ ] SHA-1 fingerprints added to OAuth credentials
- [ ] AndroidManifest.xml updated
- [ ] Sign-in works on test device
- [ ] Backup works on test device
- [ ] Restore works on test device
- [ ] Auto-backup toggle works
- [ ] Error handling tested (no internet, etc.)
- [ ] Privacy notice is visible
- [ ] User profile displays correctly

---

## 📱 Build for Production

When ready for production:

```powershell
# Android
flutter build appbundle --release

# iOS
flutter build ios --release
```

Make sure to use the **release keystore** and ensure you have created an OAuth client for the **release SHA-1 fingerprint**.

---

## 📞 Support

For issues or questions:
1. Check the [Full Documentation](GOOGLE_DRIVE_BACKUP_GUIDE.md)
2. Review code comments in:
   - `lib/services/google_drive_backup_service.dart`
   - `lib/providers/backup_provider.dart`
   - `lib/screens/settings_screen.dart`

---

## 🎉 You're Done!

Your PebbleNote app now has production-ready Google Drive backup and restore functionality!

**What's Next:**
- Test thoroughly on real devices
- Deploy to Play Store / App Store
- Monitor user feedback
- Consider adding more backup options in the future
