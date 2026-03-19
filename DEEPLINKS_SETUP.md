# Deep Links Setup Guide

Deep links let the app open directly when users tap `https://app.promptreel.ai/...` links.
Without this setup, Android/iOS silently opens a browser instead.

---

## Android App Links — `assetlinks.json`

### Get your SHA-256 fingerprint

**From a release keystore:**
```bash
keytool -list -v \
  -keystore promptreel-release.jks \
  -alias promptreel \
  -storepass YOUR_STORE_PASSWORD \
  | grep SHA256
```

**From Google Play Console (after uploading):**
Go to: Release → Setup → App integrity → App signing key certificate → Copy SHA-256

**For debug builds:**
```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  | grep SHA256
```

### Paste it into `.well-known/assetlinks.json`:
Replace `REPLACE_WITH_YOUR_SHA256_FINGERPRINT` with the actual value, e.g.:
```
"14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5"
```

### Verify it works
After deploying, visit:
```
https://app.promptreel.ai/.well-known/assetlinks.json
```
Must return valid JSON with no redirect.

Then test with:
```bash
adb shell am start -a android.intent.action.VIEW \
  -c android.intent.category.BROWSABLE \
  -d "https://app.promptreel.ai/home"
```
The app should open directly (not the browser).

---

## iOS Universal Links — `apple-app-site-association`

### Get your Team ID
1. Go to [developer.apple.com](https://developer.apple.com)
2. Account → Membership → Team ID (10-character string like `AB12CD34EF`)

### Edit `.well-known/apple-app-site-association`:
Replace `YOUR_TEAM_ID` with your actual Team ID, e.g.:
```json
"appID": "AB12CD34EF.com.chastechgroup.promptreel"
```

### Enable Associated Domains in Xcode
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Signing & Capabilities
3. Click `+` → Add **Associated Domains**
4. Add: `applinks:app.promptreel.ai`

The `Info.plist` already has:
```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:app.promptreel.ai</string>
</array>
```

### Verify
After deploying, visit:
```
https://app.promptreel.ai/.well-known/apple-app-site-association
```
Must return valid JSON, served as `application/json`, with no redirect.

---

## GitHub Pages note

GitHub Pages serves `.well-known/` correctly but you must ensure the folder
is **not** in `.gitignore`. The `_headers` file in `website/` sets the correct
`Content-Type: application/json` for `assetlinks.json`.

If you use a custom domain (e.g. `app.promptreel.ai`), add a `CNAME` file:
```bash
echo "app.promptreel.ai" > website/CNAME
```
