# PebbleNote - Data Safety Declaration Guide

## ⚠️ Issue: Data Safety Form Rejection

**Problem:** Google Play detected that Unity Ads collects device IDs and other data, but this wasn't declared in your Data Safety form.

**Solution:** Properly declare all data collection in Play Console's Data Safety section.

---

## 📋 What Unity Ads Collects

Unity Ads automatically collects:
1. **Device or other IDs** (Advertising ID, Device ID)
2. **App interactions** (Ad impressions, clicks)
3. **Diagnostic data** (Crash logs, performance)
4. **Location** (Coarse location via IP address)

You MUST declare all of this in the Data Safety form.

---

## 🔧 How to Fix: Step-by-Step Guide

### STEP 1: Go to Data Safety Section

1. Open [Google Play Console](https://play.google.com/console/)
2. Select **PebbleNote** app
3. Go to: **Policy** → **App content** → **Data safety**
4. Click **Start** or **Edit**

---

### STEP 2: Data Collection & Sharing

**Question: "Does your app collect or share any of the required user data types?"**

**Answer:** ✅ **Yes** (Unity Ads collects data)

---

### STEP 3: Declare Data Types Collected

Check the following data types that Unity Ads collects:

#### ✅ Location (Coarse location)
- **Collected:** Yes
- **Shared:** Yes (with Unity Technologies)
- **Purpose:** Advertising or marketing
- **Ephemeral:** No
- **Required:** No
- **User choice:** No

#### ✅ App activity → App interactions
- **Collected:** Yes
- **Shared:** Yes (with Unity Technologies)
- **Purpose:** Advertising or marketing, Analytics
- **Ephemeral:** No
- **Required:** No
- **User choice:** No

#### ✅ Device or other IDs → Advertising ID
- **Collected:** Yes
- **Shared:** Yes (with Unity Technologies)
- **Purpose:** Advertising or marketing, Analytics
- **Ephemeral:** No
- **Required:** No
- **User choice:** No

#### ✅ App info and performance → Crash logs
- **Collected:** Yes
- **Shared:** No
- **Purpose:** Analytics, App functionality
- **Ephemeral:** No
- **Required:** No
- **User choice:** No

#### ✅ App info and performance → Diagnostics
- **Collected:** Yes
- **Shared:** Yes (with Unity Technologies)
- **Purpose:** Analytics, App functionality
- **Ephemeral:** No
- **Required:** No
- **User choice:** No

---

### STEP 4: Data Usage and Handling

For each data type declared above, specify:

**Is this data collected, shared, or both?**
- ✅ Collected
- ✅ Shared with third parties (Unity Technologies)

**Is this data processed ephemerally?**
- ❌ No

**Is this data required for your app, or can users choose whether it's collected?**
- ❌ Data collection is required (for ads to work)
- Users cannot opt out

**Why is this user data collected?**
- ✅ Advertising or marketing
- ✅ Analytics (for ad performance)

---

### STEP 5: Data Security

**Question: "Do you use encryption for user data in transit?"**
- ✅ Yes (Unity Ads uses HTTPS)

**Question: "Do you provide a way for users to request their data be deleted?"**
- ✅ Yes (Users can uninstall the app)
- Or: ❌ No (if you don't have a server-side system)

---

### STEP 6: Review Summary

Your declaration should show:

**Data collected:**
- ✅ Location (coarse)
- ✅ App interactions
- ✅ Device or other IDs (Advertising ID)
- ✅ Diagnostics
- ✅ Crash logs

**Data shared with:**
- Unity Technologies (ad network)

**Purpose:**
- Advertising and marketing
- Analytics
- App functionality

---

## 📝 Complete Data Safety Form Template

Copy this for reference when filling the form:

### Location
```
Type: Coarse location
Collected: Yes
Shared: Yes
Purpose: Advertising or marketing
Ephemeral: No
Required: No
User choice: No
Encryption in transit: Yes
Third party: Unity Technologies
```

### App Interactions
```
Type: App interactions
Collected: Yes
Shared: Yes
Purpose: Advertising or marketing, Analytics
Ephemeral: No
Required: No
User choice: No
Encryption in transit: Yes
Third party: Unity Technologies
```

### Device or Other IDs
```
Type: Advertising ID
Collected: Yes
Shared: Yes
Purpose: Advertising or marketing, Analytics
Ephemeral: No
Required: No
User choice: No
Encryption in transit: Yes
Third party: Unity Technologies
```

### Diagnostics
```
Type: Diagnostics
Collected: Yes
Shared: Yes
Purpose: Analytics, App functionality
Ephemeral: No
Required: No
User choice: No
Encryption in transit: Yes
Third party: Unity Technologies
```

### Crash Logs
```
Type: Crash logs
Collected: Yes
Shared: No (or Yes if using Crashlytics)
Purpose: Analytics, App functionality
Ephemeral: No
Required: No
User choice: No
Encryption in transit: Yes
```

---

## 🎯 Quick Checklist

Before submitting the Data Safety form:

- [ ] Selected "Yes" for data collection
- [ ] Declared **Location** (coarse)
- [ ] Declared **App interactions**
- [ ] Declared **Advertising ID** (Device or other IDs)
- [ ] Declared **Diagnostics**
- [ ] Declared **Crash logs**
- [ ] Specified data is **Collected AND Shared**
- [ ] Named third party: **Unity Technologies**
- [ ] Purpose: **Advertising or marketing, Analytics**
- [ ] Encryption in transit: **Yes**
- [ ] Saved and submitted the form

---

## 🔍 Unity Ads SDK Declaration

Unity Ads is listed in the [Google Play SDK Index](https://play.google.com/sdks). Google can automatically detect it.

**Unity Ads SDK:**
- Package: `com.unity3d.ads`
- Automatically collects: Device IDs, IP address, ad interactions

**This is why Google rejected your app** - they detected Unity Ads but you didn't declare the data it collects.

---

## 📤 After Updating Data Safety

1. **Save** the Data Safety form
2. **Submit** for review
3. **Upload a new release** (Version 1.0.4+5 is fine, no code change needed)
4. Wait for re-review (usually 1-3 hours)

---

## ⚠️ Common Mistakes to Avoid

❌ **Don't say:** "App doesn't collect data" (Unity Ads DOES collect data)

❌ **Don't skip:** Device IDs (Advertising ID) - this is the main issue

❌ **Don't forget:** To declare data is "Shared" with Unity Technologies

✅ **Do declare:** All data types Unity Ads collects (see checklist above)

✅ **Do specify:** Third party as "Unity Technologies"

✅ **Do mention:** Purpose as "Advertising or marketing"

---

## 🆘 If Still Rejected

If your app is rejected again after updating Data Safety:

1. **Check Unity Ads SDK version** matches [Google Play SDK Index](https://play.google.com/sdks)
2. **Review Unity's own guidance:** [Unity Ads Data Privacy](https://docs.unity.com/ads/en-us/manual/DataPrivacy)
3. **Appeal the rejection** with explanation:
   ```
   We have updated our Data Safety declaration to accurately reflect
   the data collected by Unity Ads SDK (Advertising ID, location,
   app interactions, diagnostics). All third-party data sharing with
   Unity Technologies has been disclosed. Our privacy policy has been
   updated accordingly.
   ```

---

## 📞 Additional Resources

**Google Play Help:**
- [Data Safety Section](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Unity Ads in SDK Index](https://play.google.com/sdks)

**Unity Resources:**
- [Unity Ads Privacy Documentation](https://docs.unity.com/ads/en-us/manual/DataPrivacy)
- [Unity Privacy Policy](https://unity.com/legal/privacy-policy)

**Your Privacy Policy:**
- Already updated to reflect Unity Ads (PRIVACY_POLICY.md)
- Hosted at: https://chaitanyarpawar.github.io/notes/privacy-policy

---

## ✅ Summary

**The Fix:**
1. Go to Play Console → Policy → App content → Data safety
2. Declare: Location, App interactions, Advertising ID, Diagnostics, Crash logs
3. Mark as: Collected AND Shared with Unity Technologies
4. Purpose: Advertising or marketing, Analytics
5. Save and submit
6. Upload release again (same version 1.0.4+5 is okay)
7. Wait for approval

**No code changes needed** - just fix the Data Safety form declaration!

---

*Last Updated: February 16, 2026*
*For PebbleNote v1.0.4 (Build 5)*
