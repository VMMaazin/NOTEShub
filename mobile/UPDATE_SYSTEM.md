# NOTEShub — In-App Update System Documentation (v1.0.1)

This document provides a comprehensive technical guide to the automatic in-app update checking and installation mechanism implemented in NOTEShub.

---

## 1. Architectural Overview & Workflow

The update system is composed of four decoupled components:

1. **`UpdateInfoModel`** ([`lib/core/models/update_info_model.dart`](file:///c:/Users/AsusTUFA15/Desktop/NotesHub/mobile/lib/core/models/update_info_model.dart)):
   - Strongly-typed JSON deserializer with security constraints.
   - Strictly enforces HTTPS URLs for APK downloads.
   - Evaluates version superiority using integer `versionCode` comparisons (not string comparisons).
2. **`UpdateService`** ([`lib/core/services/update_service.dart`](file:///c:/Users/AsusTUFA15/Desktop/NotesHub/mobile/lib/core/services/update_service.dart)):
   - Background execution: Runs asynchronously on app startup without delaying UI rendering.
   - Platform guard: Executes exclusively on Android installations.
   - Resiliency: 5-second network timeout. Suppresses all socket exceptions, 404s, or invalid JSON, guaranteeing NOTEShub never crashes if the update server is unavailable.
   - 6-Hour Throttle: Successful checks are cached locally via `SharedPreferences`.
   - Session Deduplication: Memory tracker ensures users are not prompted multiple times during a single active app session.
   - Package Validation: Before launching installation, inspects the file length (> 100 KB) and checks for ZIP/APK magic signature bytes (`0x50, 0x4B, 0x03, 0x04` / `PK\x03\x04`). Rejects HTML error pages masquerading as APKs.
   - Package Installer Invocation: Hands over the validated file to Android's native `PackageInstaller` via `OpenFilex.open(path, type: 'application/vnd.android.package-archive')`.
3. **`UpdateDialog`** ([`lib/features/update/presentation/update_dialog.dart`](file:///c:/Users/AsusTUFA15/Desktop/NotesHub/mobile/lib/features/update/presentation/update_dialog.dart)):
   - Styled with the Royal Academic Glassmorphism palette (Deep Midnight Navy, Champagne text, Antique Metallic Gold buttons).
   - Displays current version, latest version, and release notes.
   - Shows live download progress bar with percentage and formatted byte counts.
   - Supports download cancellation and permission recovery banners.
4. **`version.json`** ([`version.json`](file:///c:/Users/AsusTUFA15/Desktop/NotesHub/mobile/version.json)):
   - Small, publicly hosted metadata file.

---

## 2. Update Metadata Specification

The metadata file resides at:
`https://raw.githubusercontent.com/VMMaazin/NOTEShub/main/mobile/version.json`

```json
{
  "version": "1.0.1",
  "versionCode": 2,
  "apkUrl": "https://github.com/VMMaazin/NOTEShub/releases/latest/download/NOTEShub-v1.0.1.apk",
  "forceUpdate": false,
  "releaseNotes": "• In-app update checker and automatic installer\n• Modern Android installation flow with permission guidance\n• Royal Academic Glassmorphism update dialog\n• Performance optimizations and stability fixes"
}
```

### Field Definitions:
- `version` *(string, required)*: Semantic display version (e.g. `"1.0.2"`).
- `versionCode` *(integer, required)*: Monotonically increasing Android build number. Updates are triggered only when `remote.versionCode > installed.versionCode`.
- `apkUrl` *(string, required)*: Direct HTTPS download URL pointing to the release APK.
- `forceUpdate` *(boolean, required)*: When `true`, hides the "Remind Me Later" option and prevents dismissal until updated.
- `releaseNotes` *(string, required)*: Bullet points describing improvements in the release.

---

## 3. How to Publish a Future Update (Step-by-Step)

When ready to publish a new release (e.g. version `1.0.2`):

### Step 1: Increment Version in `pubspec.yaml`
Update [`mobile/pubspec.yaml`](file:///c:/Users/AsusTUFA15/Desktop/NotesHub/mobile/pubspec.yaml):
```yaml
version: 1.0.2+3
```
*(Increments versionName to `1.0.2` and versionCode to `3`).*

Also update constants in [`mobile/lib/core/constants/app_constants.dart`](file:///c:/Users/AsusTUFA15/Desktop/NotesHub/mobile/lib/core/constants/app_constants.dart):
```dart
static const String appVersion = '1.0.2';
static const int appVersionCode = 3;
```

### Step 2: Build the Signed Release APK
Build using the exact existing release signing keystore:
```bash
cd mobile
flutter build apk --release --no-pub
```
Verify the output signature:
```bash
apksigner verify --verbose --print-certs build/app/outputs/flutter-apk/app-release.apk
```

> [!CRITICAL]
> **Preserve the Release Keystore**: You MUST sign every future release using the exact same keystore (`noteshub_release.jks`). Android will reject updates with `INSTALL_FAILED_UPDATE_INCOMPATIBLE` if signed with a different key.

### Step 3: Publish to GitHub Releases
1. Create a release tag `v1.0.2` on GitHub (`https://github.com/VMMaazin/NOTEShub/releases/new`).
2. Attach `app-release.apk` renamed to `NOTEShub-v1.0.2.apk`.
3. Publish the release.

### Step 4: Update `version.json`
Update [`mobile/version.json`](file:///c:/Users/AsusTUFA15/Desktop/NotesHub/mobile/version.json) on `main`:
```json
{
  "version": "1.0.2",
  "versionCode": 3,
  "apkUrl": "https://github.com/VMMaazin/NOTEShub/releases/download/v1.0.2/NOTEShub-v1.0.2.apk",
  "forceUpdate": false,
  "releaseNotes": "• Summary of changes for 1.0.2"
}
```
Commit and push to `main`. Within 6 hours (or on clean launch), all existing v1.0.0 and v1.0.1 installations will detect the update and prompt the user to install it.

---

## 4. Mandatory Updates (`forceUpdate: true`)

To enforce a mandatory update (e.g., when API breaking changes or critical security patches occur):
1. In `version.json`, set `"forceUpdate": true`.
2. The in-app dialog will:
   - Render a prominent crimson `MANDATORY` badge.
   - Hide the "Remind Me Later" button.
   - Disable Android back-button / barrier dismissal (`PopScope(canPop: false)`).
   - Only allow the user to proceed by downloading and applying the update.

---

## 5. Android Installation Permissions (`REQUEST_INSTALL_PACKAGES`)

- **Manifest Declaration**: Configured in [`mobile/android/app/src/main/AndroidManifest.xml`](file:///c:/Users/AsusTUFA15/Desktop/NotesHub/mobile/android/app/src/main/AndroidManifest.xml):
  ```xml
  <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
  ```
- **Android 8.0+ (API 26+) Security Model**:
  1. The first time a user updates NOTEShub, Android OS intercepts the intent and displays a system dialog:
     > *"For your security, your phone is not allowed to install unknown apps from this source."*
  2. The dialog includes a direct link to **Settings**.
  3. The user toggles the switch: **"Allow from this source"**.
  4. Returning to NOTEShub immediately launches the package installer prompt asking:
     > *"Do you want to update this app? You will not lose any data."*
  5. The user taps **Update**, and Android installs the new version seamlessly.

---

## 6. How to Test Updates Locally

1. Install an older version (e.g. version 1.0.0, `versionCode = 1`) on your phone or emulator:
   ```bash
   adb install mobile/release/NOTEShub-v1.0.0.apk
   ```
2. In your update server or local test mock, configure `versionCode: 2` (or higher).
3. Open NOTEShub on the device.
4. As soon as the home screen renders, the background check discovers `versionCode = 2 > 1` and presents the Royal Academic Glassmorphism update dialog.
5. Tap **Download and Update**. Verify progress reaches 100%, integrity is validated, and Android's package installer screen appears.

