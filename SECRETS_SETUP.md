# 🔐 Secrets & Environment Setup Guide
> PromptReel AI — chAs Tech Group

This document explains **every secret** the project needs, where to get it,
and how to add it to GitHub Actions and Render.

---

## 📋 Quick Reference Table

| Secret Name | Used By | Required? |
|---|---|---|
| `KEYSTORE_BASE64` | Android CI signing | ✅ For release builds |
| `KEY_ALIAS` | Android CI signing | ✅ For release builds |
| `KEY_PASSWORD` | Android CI signing | ✅ For release builds |
| `STORE_PASSWORD` | Android CI signing | ✅ For release builds |
| `FLW_PUBLIC_KEY` | Android/iOS build | ✅ Production |
| `IOS_CERTIFICATE_BASE64` | iOS CI signing | ✅ For iOS builds |
| `IOS_CERTIFICATE_PASSWORD` | iOS CI signing | ✅ For iOS builds |
| `IOS_KEYCHAIN_PASSWORD` | iOS CI signing | Any string |
| `IOS_PROVISIONING_PROFILE_BASE64` | iOS CI | ✅ For iOS builds |
| `APPLE_TEAM_ID` | iOS CI | ✅ For iOS builds |
| `APPLE_ID` | TestFlight upload | ✅ For TestFlight |
| `APP_SPECIFIC_PASSWORD` | TestFlight upload | ✅ For TestFlight |
| `RENDER_DEPLOY_HOOK_URL` | Backend auto-deploy | ✅ Recommended |

---

## 🤖 Android Signing Secrets

### Step 1 — Generate your keystore (one-time, keep it forever)
```bash
keytool -genkeypair \
  -v \
  -keystore promptreel-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias promptreel \
  -storepass YOUR_STORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD \
  -dname "CN=PromptReel AI, OU=chAs Tech Group, O=chAs Tech Group, L=Lagos, S=Lagos, C=NG"
```

### Step 2 — Encode it to base64
```bash
# macOS/Linux
base64 -i promptreel-release.jks | tr -d '\n' | pbcopy
# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("promptreel-release.jks")) | clip
```

### Step 3 — Add GitHub Secrets
Go to: **GitHub repo → Settings → Secrets and variables → Actions → New repository secret**

| Name | Value |
|---|---|
| `KEYSTORE_BASE64` | Output of step 2 |
| `KEY_ALIAS` | `promptreel` (or whatever alias you chose) |
| `KEY_PASSWORD` | Your `keypass` value |
| `STORE_PASSWORD` | Your `storepass` value |

---

## 🍎 iOS Signing Secrets

### Prerequisites
- Active Apple Developer account ($99/year)
- Distribution certificate + provisioning profile from Apple Developer Portal

### Step 1 — Export your .p12 certificate
1. Open **Keychain Access** on Mac
2. Find your "Apple Distribution" certificate
3. Right-click → Export → Save as `.p12` with a password
4. Encode: `base64 -i cert.p12 | tr -d '\n'`

### Step 2 — Export provisioning profile
1. Download from Apple Developer Portal → Profiles
2. Encode: `base64 -i profile.mobileprovision | tr -d '\n'`

### Step 3 — Add GitHub Secrets

| Name | Value |
|---|---|
| `IOS_CERTIFICATE_BASE64` | Encoded .p12 |
| `IOS_CERTIFICATE_PASSWORD` | Your .p12 export password |
| `IOS_KEYCHAIN_PASSWORD` | Any strong random string |
| `IOS_PROVISIONING_PROFILE_BASE64` | Encoded .mobileprovision |
| `APPLE_TEAM_ID` | Found in Apple Developer account (10-char string) |
| `APPLE_ID` | Your Apple ID email |
| `APP_SPECIFIC_PASSWORD` | Generate at appleid.apple.com → App-Specific Passwords |

---

## 💳 Flutterwave

1. Log in to [dashboard.flutterwave.com](https://dashboard.flutterwave.com)
2. Go to **Settings → API Keys**
3. Add to GitHub Secrets:
   - `FLW_PUBLIC_KEY` — your `FLWPUBK_LIVE-...` key
4. Add to Render environment variables:
   - `FLUTTERWAVE_PUBLIC_KEY`
   - `FLUTTERWAVE_SECRET_KEY` — your `FLWSECK_LIVE-...` key
   - `FLUTTERWAVE_WEBHOOK_HASH` — from Flutterwave Webhook settings

---

## 🖥️ Render Backend

### Deploy Hook (for auto-deploy on push to main)
1. Go to your Render service → **Settings → Deploy Hook**
2. Copy the URL
3. Add to GitHub Secrets as `RENDER_DEPLOY_HOOK_URL`

### Environment Variables (set in Render dashboard)
```
DATABASE_URL=postgresql+asyncpg://...
SECRET_KEY=<generate with: python -c "import secrets; print(secrets.token_hex(32))">
GEMINI_API_KEY=...
GROQ_API_KEY=...
OPENAI_API_KEY=...
ANTHROPIC_API_KEY=...
FLUTTERWAVE_SECRET_KEY=...
FLUTTERWAVE_PUBLIC_KEY=...
FLUTTERWAVE_WEBHOOK_HASH=...
RESEND_API_KEY=...
```

---

## 🌐 GitHub Pages Setup

1. Go to **GitHub repo → Settings → Pages**
2. Source: **GitHub Actions**
3. The `deploy_website.yml` workflow will publish `website/` automatically on every push to `main`
4. Your site will be live at: `https://YOUR_USERNAME.github.io/promptreel-ai/`

> **Custom domain**: Add a `CNAME` file to `website/` with your domain (e.g., `promptreel.ai`),
> then configure DNS with your registrar.

---

## 🔑 Local Development

Copy the backend `.env.example` and fill it in:
```bash
cp backend/.env.example backend/.env
# Edit backend/.env with your actual values
```

For Android local signing, create `frontend/android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=promptreel
storeFile=../app/promptreel-release.jks
```

> ⚠️ **Never commit** `.env`, `key.properties`, or any `.jks` file. They are all in `.gitignore`.
