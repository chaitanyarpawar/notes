# 🚀 PebbleNote - Complete Play Store Submission Guide

## Pre-Submission Checklist ✅

Before you start, ensure you have:

- [x] Release AAB: `build/app/outputs/bundle/release/app-release.aab` (65.2 MB)
- [x] Version: 1.0.4 (Build 5)
- [x] Unity Ads configured (Game ID: 6046939)
- [ ] Screenshots prepared (2-8 images at 1080x1920px)
- [x] Feature Graphic: `assets/playstore/feature_graphic.png`
- [x] App Icon: `assets/playstore/app_icon_512.png`
- [x] Privacy Policy URL: https://chaitanyarpawar.github.io/notes/privacy-policy
- [x] Release Notes prepared (see RELEASE_NOTES.md)

---

## Step-by-Step Submission Process

### STEP 1: Access Play Console

1. Go to [Google Play Console](https://play.google.com/console/)
2. Sign in with your Google Play Developer account
3. Select **PebbleNote** app from your apps list

---

### STEP 2: Upload the AAB

1. In left sidebar, click **Release** → **Production**
2. Click **Create new release** button
3. Under "App bundles", click **Upload**
4. Select file: `build/app/outputs/bundle/release/app-release.aab`
5. Wait for upload to complete (may take 2-5 minutes)
6. Google Play will analyze the bundle - wait for "Ready to release" status

**Expected Output:**
- ✅ Bundle processed successfully
- ✅ Supported devices: 10,000+ (estimated)
- ✅ APK sizes: ~25-40 MB (varies by device)

---

### STEP 3: Add Release Notes

In the "Release notes" section:

1. Click **Add release notes**
2. Select language: **English (United States)**
3. Paste this text:

```
✨ First Production Release!

🎉 Welcome to PebbleNote - your simple note-taking companion!

What you can do:
• Create beautiful notes with colors
• Set reminders to never forget
• Make checklists for your tasks
• View notes in calendar
• Search and filter easily
• Enjoy dark/light themes

📱 Privacy-focused, offline-first
🎨 Clean, modern design
⚡ Fast and lightweight

Thank you for trying PebbleNote! We'd love your feedback.
```

4. Click **Save**

---

### STEP 4: Configure Rollout (Recommended)

1. Under "Release settings", click **Managed rollout**
2. Set rollout percentage: Start with **20%**
3. This means only 20% of users will get the update initially
4. You can increase it gradually: 20% → 50% → 100%

**Why staged rollout?**
- Monitor crash rates before full release
- Catch critical issues early
- Easy rollback if problems occur
- Industry best practice

---

### STEP 5: Review Release Summary

Check that everything looks correct:

- ✅ Version code: 5
- ✅ Version name: 1.0.4
- ✅ Release notes added
- ✅ Rollout percentage set (optional)
- ✅ No critical warnings

---

### STEP 6: Save and Review

1. Click **Save** button at bottom
2. Click **Review release** button
3. Review all details one final time
4. Look for any warnings or errors

**Common Issues to Check:**
- Target API level (should be 34)
- Permissions declared
- App not debuggable
- Signed with production key

---

### STEP 7: Start Rollout to Production 🎉

1. If everything looks good, click **Start rollout to Production**
2. Confirm the rollout in the dialog
3. Wait for "Release submitted" confirmation

**Timeline:**
- **Immediate:** Release enters review queue
- **1-3 hours:** Usually approved (can take up to 48h)
- **24-48 hours:** Indexed and visible in search
- **3-7 days:** Full visibility across all regions

---

## STEP 8: Complete Store Listing (If Not Done)

While waiting for review, ensure your store listing is complete:

### 8.1 Main Store Listing

Navigate to: **Grow** → **Store presence** → **Main store listing**

**App Details:**
- App name: `PebbleNote`
- Short description: (already set - 67 characters)
- Full description: (already set - see PLAY_STORE_LISTING.md)

**Graphics:**

1. **App Icon** (512x512 PNG)
   - Upload: `assets/playstore/app_icon_512.png`
   - Must be square, no rounded corners

2. **Feature Graphic** (1024x500 JPEG/PNG)
   - Upload: `assets/playstore/feature_graphic.png`
   - Displayed on top of store listing

3. **Phone Screenshots** (1080x1920 minimum)
   - Upload 2-8 screenshots
   - See SCREENSHOT_GUIDE.md for how to create
   - Order matters - first screenshot is most important

**Categorization:**
- Application type: `App`
- Category: `Productivity`

**Contact Details:**
- Email: `chaitanyapawar25@gmail.com`
- Website: (optional)
- Phone: (optional)

Click **Save**

---

### 8.2 Data Safety Section ⚠️ CRITICAL

Navigate to: **Policy** → **App content** → **Data safety**

**IMPORTANT:** You MUST declare Unity Ads data collection or your app will be rejected!

**Data Collection:**
1. Click **Start**
2. Question: "Does your app collect or share any of the required user data types?"
   - Answer: **✅ Yes** (Unity Ads collects data)

3. **Declare these data types:**

   **Location → Coarse location**
   - Collected: Yes
   - Shared: Yes (Unity Technologies)
   - Purpose: Advertising or marketing
   - Ephemeral: No
   - Required: No
   
   **App activity → App interactions**
   - Collected: Yes
   - Shared: Yes (Unity Technologies)
   - Purpose: Advertising or marketing, Analytics
   - Ephemeral: No
   - Required: No
   
   **Device or other IDs → Advertising ID**
   - Collected: Yes
   - Shared: Yes (Unity Technologies)
   - Purpose: Advertising or marketing, Analytics
   - Ephemeral: No
   - Required: No
   
   **App info and performance → Diagnostics**
   - Collected: Yes
   - Shared: Yes (Unity Technologies)
   - Purpose: Analytics, App functionality
   - Ephemeral: No
   - Required: No
   
   **App info and performance → Crash logs**
   - Collected: Yes
   - Shared: No
   - Purpose: Analytics, App functionality
   - Ephemeral: No
   - Required: No

4. For each data type, specify:
   - ✅ Data is processed with encryption in transit
   - ✅ Third party: Unity Technologies

5. Click **Next** and **Submit**

**📋 Detailed Guide:** See [DATA_SAFETY_DECLARATION.md](DATA_SAFETY_DECLARATION.md) for complete step-by-step instructions

---

### 8.3 Content Rating

Navigate to: **Policy** → **App content** → **Content rating**

1. Click **Start questionnaire**
2. Email address: `chaitanyapawar25@gmail.com`
3. Category: `Utility, Productivity, Communication, or Other`

**Answer Questions:**
- Violence: No
- Sexuality: No
- Language: No
- Controlled substances: No
- User interaction: No
- Shares location: No

4. Click **Save questionnaire** → **Submit**

**Expected Rating:** Everyone (all ages)

---

### 8.4 Target Audience

Navigate to: **Policy** → **App content** → **Target audience**

1. Click **Start**
2. Select target age groups: `13+` (or All Ages)
3. Appeal to children: `No`
4. Click **Save**

---

### 8.5 Ads Declaration

Navigate to: **Policy** → **App content** → **Ads**

1. Click **Start**
2. Question: "Does your app contain ads?"
   - Answer: **Yes**
   - ✅ PebbleNote shows Unity Ads

3. Click **Save**

---

### 8.6 Privacy Policy

Navigate to: **Policy** → **App content** → **Privacy policy**

1. Click **Start**
2. Privacy policy URL: `https://chaitanyarpawar.github.io/notes/privacy-policy`
3. Click **Save**

---

### 8.7 Pricing & Distribution

Navigate to: **Grow** → **Store presence** → **Pricing & distribution**

**Pricing:**
- Set as: **Free**
- (Cannot change to paid later)

**Countries:**
- Select **Available worldwide** (recommended)
- Or choose specific countries

**Primarily distributed to:**
- Select: **Google Play**

**Device Categories:**
- ✅ Phone
- ✅ Tablet

**Consent:**
- ✅ Check all consent boxes (content guidelines, export laws, etc.)

Click **Save**

---

## STEP 9: Final Checks Before Going Live

Review these sections in Play Console:

1. **Dashboard** → Check for any warnings or errors
2. **Store presence** → Ensure all sections have green checkmarks
3. **Policy** → All app content sections completed
4. **Release** → Production release is "In Review" or "Published"

**Common Rejection Reasons (Avoid These):**
- ❌ **Incomplete data safety section** (MOST COMMON - must declare Unity Ads data!)
- ❌ Missing privacy policy
- ❌ Device IDs not declared (Advertising ID from Unity Ads)
- ❌ Third-party data sharing not disclosed
- ❌ Low-quality screenshots or graphics
- ❌ Misleading store listing
- ❌ Copyright issues in icon/name
- ❌ Broken functionality
- ❌ Missing content rating

---

## STEP 10: Post-Submission Monitoring

### First 24 Hours

**Monitor:**
1. **Play Console** → **Release** → **Production**
   - Check approval status
   - Look for any policy violations

2. **Quality** → **Android vitals**
   - Crash rate (should be < 1.09%)
   - ANR rate (should be < 0.47%)

3. **Engagement** → **Ratings and reviews**
   - Respond to early reviews
   - Address critical issues quickly

**Unity Ads Dashboard:**
- Go to [Unity Ads Dashboard](https://dashboard.unityads.unity3d.com/)
- Check: Ad requests, impressions, eCPM
- Verify: Game ID 6046939 is showing data

---

### Week 1

**Goals:**
- Maintain crash rate below 1%
- Respond to all 1-star reviews
- Monitor ad performance
- Gather user feedback

**Metrics to Track:**
- Daily active users (DAU)
- Install count
- Average rating
- Ad revenue
- User retention

---

## Rollout Strategy

### Conservative Approach (Recommended for first release)

**Day 1:** 20% rollout
- Monitor for critical issues
- Check crash reports every 6 hours

**Day 3:** 50% rollout (if stable)
- Check metrics are healthy
- ANR rate acceptable
- No major bugs reported

**Day 7:** 100% rollout (if all good)
- Full release to all users
- Continue monitoring

### Aggressive Approach (If confident)

**Day 1:** 100% rollout
- Requires extensive testing beforehand
- Have hotfix ready if needed
- Monitor closely first 48 hours

---

## Emergency Procedures

### If Critical Bug Discovered

**Option 1: Halt Rollout**
1. Go to **Release** → **Production**
2. Click **Pause rollout**
3. Fix bug in code
4. Build new AAB with version 1.0.5+6
5. Create new release

**Option 2: Rollback (if already at 100%)**
1. Not possible in Production track
2. Must push hotfix as new version
3. Build quickly and submit

**Option 3: Remove from Play Store**
1. Go to **Release** → **Production**
2. Click **Deactivate release** (emergency only)

---

## Success Metrics

### Day 1 Goals
- 100+ installs (if you have marketing)
- < 1% crash rate
- 4.0+ star rating
- No critical bugs

### Week 1 Goals
- 500-1000 installs
- 4.0-4.5 star rating
- Positive review trend
- Ad revenue generating

### Month 1 Goals
- 5,000+ installs
- 4.2+ star rating
- Active user base
- Consistent ad revenue
- Plan v1.1.0 features

---

## Marketing & Promotion (Optional)

After going live:

1. **Share on Social Media**
   - Twitter/X
   - Reddit (r/androidapps, r/productivity)
   - Facebook groups
   - LinkedIn

2. **Product Hunt**
   - Submit as new product
   - Can drive 100s of installs

3. **App Review Sites**
   - Contact Android app reviewers
   - Offer promo for coverage

4. **Friends & Family**
   - Ask for installs and reviews
   - Initial reviews boost visibility

---

## Quick Reference Links

**Play Console:**
- Dashboard: https://play.google.com/console/
- Release Management: https://play.google.com/console/u/0/developers/{YOUR_ID}/app/{APP_ID}/tracks/production

**Unity Ads:**
- Dashboard: https://dashboard.unityads.unity3d.com/
- Game ID: 6046939

**Support:**
- Play Console Help: https://support.google.com/googleplay/android-developer
- Unity Ads Support: https://support.unity.com/

---

## Troubleshooting

### "APK not signed correctly"
- **Cause:** Missing or wrong signing key
- **Fix:** Check `android/key.properties` file exists
- **Verify:** Signing config in `android/app/build.gradle`

### "Version code already exists"
- **Cause:** Version not incremented
- **Fix:** Update version in `pubspec.yaml` (next: 1.0.5+6)

### "Icon not transparent-safe"
- **Cause:** Icon has transparent background issues
- **Fix:** Already addressed (using adaptive icons)

### "Missing permissions declaration"
- **Cause:** Permission not in AndroidManifest.xml
- **Fix:** Should already be done, verify in `android/app/src/main/AndroidManifest.xml`

### "Ads not showing"
- **Cause:** Unity Ads needs time to initialize
- **Fix:** Wait 24-48 hours after first install
- **Verify:** Check Unity Dashboard for requests

---

## 🎉 Congratulations!

Once your app is approved and live:

1. ✨ You've launched your first production Android app!
2. 📱 PebbleNote is now available to millions of users
3. 💰 You've monetized with Unity Ads
4. 🚀 You can now iterate and improve

**What's Next?**
- Monitor user feedback
- Plan v1.1.0 features
- Marketing & promotion
- Build user base
- Iterate based on data

**Good luck with your launch! 🚀**

---

## Need Help?

**Email:** chaitanyapawar25@gmail.com

**Common Questions:**
1. How long until approved? → Usually 1-3 hours, max 48 hours
2. When will ads show revenue? → 24-48 hours after first install
3. How to update app? → Create new release with higher version code
4. Can I change price later? → No, free apps stay free forever
5. How to get more installs? → ASO optimization, marketing, social media

**📚 Additional Resources:**
- RELEASE_NOTES.md - Version history and release notes
- SCREENSHOT_GUIDE.md - How to create great screenshots
- PLAY_STORE_LISTING.md - Complete store listing content
- PRIVACY_POLICY.md - App privacy policy

---

*This guide was created for PebbleNote v1.0.4 production launch on February 16, 2026*
