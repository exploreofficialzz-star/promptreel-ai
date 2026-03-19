# SETUP_REQUIRED.md
# The only two things you need to update in this project
# Both can be done from your phone — no terminal needed

---

## 1️⃣ Android Deep Links — SHA-256 Fingerprint

**File to edit:** `website/.well-known/assetlinks.json`

**Replace:** `PLACEHOLDER_REPLACE_WITH_YOUR_KEYSTORE_SHA256`

**How to get your SHA-256 without a terminal:**

**Option A — From Google Play Console (easiest):**
1. Go to play.google.com/console
2. Select your app → Release → Setup → App integrity
3. Under "App signing key certificate" copy the SHA-256 fingerprint
4. Paste it into `assetlinks.json`

**Option B — From GitHub Actions (automatic):**
After your first release build runs in GitHub Actions, the signed APK's
fingerprint can be retrieved from:
1. Go to your repo → Actions → The Android build run
2. Look for the signing step output — it prints the SHA-256

**What it looks like:**
```
14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5
```

> ✅ The app works without this. Deep links just open the browser instead
> of directly opening the app. Everything else works perfectly.

---

## 2️⃣ iOS Universal Links — Apple Team ID

**File to edit:** `website/.well-known/apple-app-site-association`

**Replace both:** `YOURTEAMID` with your 10-character Team ID

**How to get your Team ID from your phone:**
1. Go to developer.apple.com in your browser
2. Tap your name (top right) → Membership
3. Copy the "Team ID" — it's a 10-character string like `AB12CD34EF`
4. Replace `YOURTEAMID` in the file with your actual Team ID

**What it looks like:**
```json
"appID": "AB12CD34EF.com.chastechgroup.promptreel"
```

> ✅ The app works without this. iOS Universal Links just won't auto-open
> the app from web URLs. Everything else works perfectly including payments.

---

## Everything else is already set up ✅

- App icon: generated ✅
- Android icons (all densities): generated ✅
- iOS icons (all sizes): generated ✅
- Web icons: generated ✅
- Backend: ready to deploy to Render ✅
- GitHub Actions: Android + iOS + Website CI/CD ✅
- GitHub Pages website: ready to deploy ✅
- Database migrations: Alembic ready ✅
- Tests: 19 backend tests ready ✅
