# Force Update Feature Setup Guide

This guide explains how to set up and use the force update feature in the Invoice Generator app.

## Overview

The app uses a **Hybrid Approach** combining:
- **Firebase Realtime Database** for version configuration
- **TestFairy** for app distribution and download URLs

When a new version is released, you can configure it in Firebase to force users to update or show an optional update dialog.

## Firebase Realtime Database Setup

### 1. Database Structure

Create the following structure in your Firebase Realtime Database:

```
app_version/
  ├── minRequiredVersion: "1.0.2"
  ├── minRequiredBuild: 2
  ├── latestVersion: "1.0.3"
  ├── latestBuild: 5
  ├── forceUpdate: true
  ├── updateMessage: "A new version is available with exciting features and bug fixes. Please update to continue."
  └── updateUrl: "https://testfairy.com/app/download/YOUR_APP_ID"
```

### 2. Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Realtime Database**
4. Click **Add Node** (or use the data editor)
5. Create a node named `app_version` at the root level
6. Add the following fields:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `minRequiredVersion` | String | Minimum version required (semantic version) | "1.0.2" |
| `minRequiredBuild` | Number | Minimum build number required | 2 |
| `latestVersion` | String | Latest available version | "1.0.3" |
| `latestBuild` | Number | Latest build number | 5 |
| `forceUpdate` | Boolean | If true, blocks app usage until updated | true |
| `updateMessage` | String | Message to show in update dialog | "Please update..." |
| `updateUrl` | String | TestFairy download URL | "https://..." |

### 3. Security Rules

Add the following rules to your Firebase Realtime Database rules:

```json
{
  "rules": {
    "app_version": {
      ".read": true,
      ".write": false
    },
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid",
        // ... existing rules
      }
    }
  }
}
```

**Note**: `app_version` should be readable by everyone (no authentication required) so the app can check versions before login. However, writing should be restricted (only admins/yourself).

## TestFairy Setup

### 1. Get Your TestFairy App URL

1. Log in to [TestFairy Dashboard](https://www.testfairy.com/)
2. Select your app
3. Navigate to the app's distribution page
4. Copy the public download URL (e.g., `https://testfairy.com/app/download/YOUR_APP_ID`)

### 2. Update Firebase with TestFairy URL

Update the `updateUrl` field in Firebase with your TestFairy download URL.

## Version Comparison Logic

The app uses semantic versioning (e.g., `1.0.2`) and build numbers (e.g., `2`):

- **Version Format**: `MAJOR.MINOR.PATCH` (e.g., `1.0.2`)
- **Build Number**: Integer (e.g., `2`)

### Update Required Conditions

An update is required if **ALL** of the following are true:
1. `forceUpdate` is `true` in Firebase
2. Current app version < `minRequiredVersion` OR
   (Current app version == `minRequiredVersion` AND Current build < `minRequiredBuild`)

### Examples

**Example 1: Force Update Required**
- Current App: Version `1.0.1`, Build `5`
- Firebase: `minRequiredVersion: "1.0.2"`, `minRequiredBuild: 2`, `forceUpdate: true`
- **Result**: Update required ✅

**Example 2: Build Update Required**
- Current App: Version `1.0.2`, Build `1`
- Firebase: `minRequiredVersion: "1.0.2"`, `minRequiredBuild: 2`, `forceUpdate: true`
- **Result**: Update required ✅

**Example 3: No Update Required**
- Current App: Version `1.0.3`, Build `10`
- Firebase: `minRequiredVersion: "1.0.2"`, `minRequiredBuild: 2`, `forceUpdate: true`
- **Result**: No update required ❌

## How to Release a New Version

### Step 1: Update App Version

In `pubspec.yaml`, update the version:

```yaml
version: 1.0.3+5  # Version 1.0.3, Build 5
```

### Step 2: Build and Upload to TestFairy

1. Build your app:
   ```bash
   flutter build apk  # For Android
   flutter build ios  # For iOS
   ```
2. Upload the build to TestFairy
3. Get the TestFairy download URL

### Step 3: Update Firebase

Update the `app_version` node in Firebase:

```json
{
  "minRequiredVersion": "1.0.3",
  "minRequiredBuild": 5,
  "latestVersion": "1.0.3",
  "latestBuild": 5,
  "forceUpdate": true,
  "updateMessage": "New version 1.0.3 is now available with improved features and bug fixes. Please update to continue using the app.",
  "updateUrl": "https://testfairy.com/app/download/YOUR_NEW_APP_URL"
}
```

### Step 4: Test

1. Install an older version of the app
2. Launch the app
3. Verify that the update dialog appears
4. Click "Update Now" and verify it opens TestFairy

## Force Update vs Optional Update

### Force Update (`forceUpdate: true`)
- User **cannot** dismiss the dialog
- Back button is disabled
- App is blocked until updated
- Use when: Critical bug fixes, security updates, breaking API changes

### Optional Update (`forceUpdate: false` or not set)
- User can dismiss the dialog
- App continues to work
- Use when: New features, minor improvements

**Note**: Currently, the app only shows force update dialogs. Optional update dialogs can be enabled by modifying `VersionCheckManager.checkAndShowUpdateDialog()` to set `showOnlyIfForceUpdate: false`.

## Periodic Version Checking

The app checks for updates:
1. **On app startup** (in `AuthWrapper`)
2. **Periodically** (optional, can be added to Dashboard)

To add periodic checking, call this method periodically:

```dart
VersionCheckManager.checkAndShowUpdateDialog(
  context,
  showOnlyIfForceUpdate: true,
);
```

## Troubleshooting

### Issue: Update dialog doesn't appear

**Solutions**:
1. Check Firebase Realtime Database connection
2. Verify `app_version` node exists and has correct structure
3. Check app logs for errors: `Error fetching app version: ...`
4. Verify version comparison logic matches your version format

### Issue: Update URL doesn't open

**Solutions**:
1. Verify `updateUrl` in Firebase is a valid URL
2. Test the URL manually in a browser
3. Check device internet connection
4. Verify TestFairy link is publicly accessible

### Issue: Dialog appears even when app is up to date

**Solutions**:
1. Check version format in `pubspec.yaml` (should match Firebase format)
2. Verify build number is correct (number after `+` in `version: 1.0.2+2`)
3. Check Firebase `minRequiredVersion` and `minRequiredBuild` values

## Testing Checklist

- [ ] Firebase `app_version` node created
- [ ] Security rules allow read access to `app_version`
- [ ] TestFairy URL added to Firebase
- [ ] Version comparison works correctly
- [ ] Force update dialog appears for old versions
- [ ] Update button opens TestFairy URL
- [ ] Back button is disabled during force update
- [ ] App continues normally when version is up to date
- [ ] App handles Firebase connection errors gracefully

## Support

If you encounter issues:
1. Check Firebase Console for `app_version` data
2. Verify app version in `pubspec.yaml`
3. Check device logs for errors
4. Test Firebase connection separately

