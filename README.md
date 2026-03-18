# PromptReel AI 🎬

> **Turn simple ideas into complete AI video production plans.**
> Made with ❤️ by chAs Tech Group

---

## 📁 FULL PROJECT FILE TREE

```
promptreel-ai/
│
├── .github/
│   └── workflows/
│       └── build_android.yml          ← CI/CD: builds APK + AAB on push/tag
│
├── .gitignore                         ← Covers Python, Flutter, secrets
│
├── backend/                           ← Python FastAPI — deploy to Render
│   ├── .env.example                   ← Copy to .env and fill secrets
│   ├── Procfile                       ← Render process definition
│   ├── render.yaml                    ← One-click Render deploy config
│   ├── requirements.txt               ← All Python dependencies
│   ├── config.py                      ← Pydantic settings (env vars)
│   ├── database.py                    ← Async SQLAlchemy + PostgreSQL
│   ├── main.py                        ← FastAPI app entry point
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py                    ← User model (free/creator/studio)
│   │   └── project.py                 ← VideoProject model (stores AI output)
│   ├── routers/
│   │   ├── __init__.py
│   │   ├── auth.py                    ← Register, Login, JWT refresh, /me
│   │   ├── generate.py                ← POST /generate — core AI endpoint
│   │   ├── projects.py                ← CRUD projects + stats
│   │   └── export.py                  ← Download ZIP / SRT / TXT
│   └── services/
│       ├── __init__.py
│       ├── ai_service.py              ← OpenAI → Gemini → Claude fallback chain
│       └── export_service.py          ← ZIP package builder (12 files)
│
└── frontend/                          ← Flutter — Android / iOS / Web
    ├── pubspec.yaml                   ← All Flutter dependencies
    ├── android/
    │   ├── build.gradle               ← Project-level Gradle (Kotlin 1.9.23)
    │   ├── settings.gradle            ← Module includes
    │   ├── gradle.properties          ← JVM args, AndroidX, R8
    │   ├── gradle/
    │   │   └── wrapper/
    │   │       └── gradle-wrapper.properties  ← Gradle 8.4
    │   └── app/
    │       ├── build.gradle           ← App-level: minSdk 23, R8, signing
    │       ├── proguard-rules.pro     ← Keep rules for release
    │       └── src/main/
    │           ├── AndroidManifest.xml           ← Permissions, AdMob, deep links
    │           ├── kotlin/com/chastechgroup/
    │           │   └── promptreel/
    │           │       └── MainActivity.kt       ← Flutter entry point
    │           └── res/
    │               ├── drawable/
    │               │   └── launch_background.xml ← Dark splash screen
    │               ├── drawable-v21/
    │               │   └── launch_background.xml ← Vector splash (API 21+)
    │               ├── values/
    │               │   ├── strings.xml           ← App name
    │               │   └── styles.xml            ← Launch + Normal theme
    │               └── xml/
    │                   ├── network_security_config.xml  ← HTTPS enforcement
    │                   └── file_paths.xml               ← FileProvider paths
    └── lib/
        ├── main.dart                  ← App entry: AdMob init, ProviderScope
        ├── config/
        │   └── app_config.dart        ← API URL, AdMob IDs, content options
        ├── theme/
        │   └── app_theme.dart         ← Full design system (colors, type, shadows)
        ├── router/
        │   └── app_router.dart        ← GoRouter with auth redirect guards
        ├── models/
        │   ├── user_model.dart        ← UserModel with plan helpers
        │   └── project_model.dart     ← VideoResult + all nested models
        ├── services/
        │   └── api_service.dart       ← Dio HTTP client with auto token refresh
        ├── providers/
        │   ├── auth_provider.dart     ← Riverpod auth state (login/register/logout)
        │   ├── generate_provider.dart ← Form state + generation state
        │   └── projects_provider.dart ← Project list + CRUD state
        ├── screens/
        │   ├── auth/
        │   │   └── login_screen.dart  ← Login + Register (single screen toggle)
        │   ├── home/
        │   │   └── home_screen.dart   ← Dashboard: stats, quick ideas, recent
        │   ├── create/
        │   │   └── create_screen.dart ← 3-step wizard: idea → settings → review
        │   ├── results/
        │   │   └── results_screen.dart ← Tabbed: Overview/Script/Scenes/Prompts/SEO/Export
        │   ├── projects/
        │   │   └── projects_screen.dart ← Project list with search + delete
        │   ├── tools/
        │   │   └── tools_screen.dart  ← Affiliate tools marketplace
        │   └── settings/
        │       ├── settings_screen.dart ← Profile, plan, app settings
        │       └── plans_screen.dart    ← Subscription upgrade UI
        └── widgets/
            └── common/
                ├── app_button.dart       ← Gradient button + variants
                ├── app_card.dart         ← GlowCard, StatCard, AppCard
                ├── prompt_copy_card.dart ← One-tap copy + expand/collapse
                └── section_selector.dart ← Option chips + toggle rows
```

---

## 🚀 QUICK START — 5 STEPS

### Step 1 — Clone & Structure
```bash
git clone https://github.com/YOUR_USERNAME/promptreel-ai.git
cd promptreel-ai
```

### Step 2 — Backend Setup
```bash
cd backend
cp .env.example .env
# Edit .env — set DATABASE_URL + at least one AI API key
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### Step 3 — Flutter Setup
```bash
cd frontend
flutter pub get
# Set your API URL in lib/config/app_config.dart → baseUrl
flutter run                      # debug on device/emulator
flutter build apk --release      # build APK
```

### Step 4 — Deploy Backend to Render
1. Push to GitHub
2. Go to [render.com](https://render.com) → New → Blueprint
3. Point to your repo — `render.yaml` auto-configures everything
4. Add env vars in Render dashboard: `OPENAI_API_KEY`, `GEMINI_API_KEY`, `ANTHROPIC_API_KEY`

### Step 5 — CI/CD (GitHub Actions)
Every push to `main` automatically builds the APK.
Every `v*.*.*` tag creates a GitHub Release with APK + AAB attached.

---

## 🔑 ENVIRONMENT VARIABLES

### Backend `.env`
| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | ✅ | `postgresql+asyncpg://user:pass@host/db` |
| `SECRET_KEY` | ✅ | Random 64-char hex string |
| `OPENAI_API_KEY` | One of these | GPT-4o-mini (primary AI) |
| `GEMINI_API_KEY` | One of these | Gemini 1.5 Flash (fallback) |
| `ANTHROPIC_API_KEY` | One of these | Claude Haiku (fallback) |
| `DEBUG` | ❌ | `false` in production |
| `CORS_ORIGINS` | ❌ | JSON array of allowed origins |

### GitHub Secrets (for CI/CD signing)
| Secret | Description |
|---|---|
| `KEYSTORE_BASE64` | Base64-encoded `.jks` keystore file |
| `STORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Key alias inside keystore |
| `KEY_PASSWORD` | Key password |
| `API_BASE_URL` | Your Render backend URL |

---

## 🔨 GENERATING A KEYSTORE (one-time)
```bash
keytool -genkey -v \
  -keystore promptreel-release.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias promptreel \
  -dname "CN=PromptReel AI, OU=chAs Tech Group, O=chAs Tech Group, L=City, ST=State, C=US"

# Encode for GitHub secret:
base64 -i promptreel-release.jks | pbcopy   # macOS
base64 promptreel-release.jks               # Linux

# Create frontend/android/key.properties (NEVER commit this file):
echo "storeFile=../promptreel-release.jks" > frontend/android/key.properties
echo "storePassword=YOUR_STORE_PASSWORD" >> frontend/android/key.properties
echo "keyAlias=promptreel" >> frontend/android/key.properties
echo "keyPassword=YOUR_KEY_PASSWORD" >> frontend/android/key.properties
```

---

## 🏗️ BUILD COMMANDS

```bash
# ── Flutter ──────────────────────────────────────────────────────
flutter pub get                          # Install dependencies
flutter analyze                          # Static analysis
flutter test                             # Run tests

# Debug build
flutter run -d android                   # Run on Android device
flutter run -d chrome                    # Run as web app

# Release builds
flutter build apk --release              # Split APK (for direct install)
flutter build apk --split-per-abi        # Separate APKs per CPU arch
flutter build appbundle --release        # AAB for Google Play
flutter build web --release              # Web build

# With custom API URL
flutter build apk --release \
  --dart-define=API_BASE_URL=https://your-backend.onrender.com

# ── Backend ──────────────────────────────────────────────────────
cd backend
uvicorn main:app --reload               # Development
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4  # Production

# Database migration (if schema changes):
# Uses SQLAlchemy's create_all on startup — no manual migration needed
```

---

## 📡 API ENDPOINTS

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/` | ❌ | App info |
| `GET` | `/health` | ❌ | Health check |
| `POST` | `/api/auth/register` | ❌ | Create account |
| `POST` | `/api/auth/login` | ❌ | Sign in → JWT |
| `POST` | `/api/auth/refresh` | ❌ | Refresh access token |
| `GET` | `/api/auth/me` | ✅ | Current user info |
| `POST` | `/api/generate/` | ✅ | Generate video plan |
| `GET` | `/api/generate/preview` | ✅ | Preview scene count |
| `GET` | `/api/projects/` | ✅ | List user projects |
| `GET` | `/api/projects/:id` | ✅ | Get project + result |
| `DELETE` | `/api/projects/:id` | ✅ | Delete project |
| `GET` | `/api/projects/stats/summary` | ✅ | User statistics |
| `GET` | `/api/export/:id/zip` | ✅ | Download ZIP package |
| `GET` | `/api/export/:id/srt` | ✅ | Download SRT subtitles |
| `GET` | `/api/export/:id/script` | ✅ | Download script TXT |
| `GET` | `/api/plans` | ❌ | Subscription plan info |

---

## 💳 PAYMENT INTEGRATION

### Paystack (African + International cards)
1. Create account at [paystack.com](https://paystack.com)
2. Add your public key to `app_config.dart`
3. Replace the `_handleSelect()` URL in `plans_screen.dart` with your Paystack payment link

### LemonSqueezy (Global SaaS)
1. Create account at [lemonsqueezy.com](https://lemonsqueezy.com)
2. Create products for Creator ($15) and Studio ($35) plans
3. Update payment URLs in `plans_screen.dart`

---

## 📢 ADMOB SETUP

1. Create account at [admob.google.com](https://admob.google.com)
2. Create an Android app → get your **App ID**
3. Create ad units: Banner, Rewarded, Native
4. Replace ALL test IDs in `lib/config/app_config.dart`:
```dart
static const String admobAppIdAndroid = 'ca-app-pub-XXXXXXXX~XXXXXXXXXX';
static const String bannerAdUnitAndroid = 'ca-app-pub-XXXXXXXX/XXXXXXXXXX';
static const String rewardedAdUnitAndroid = 'ca-app-pub-XXXXXXXX/XXXXXXXXXX';
```
5. Replace `admobAppId` in `android/app/build.gradle` → `manifestPlaceholders`

---

## 🎨 DESIGN SYSTEM

| Token | Value | Usage |
|---|---|---|
| `AppColors.background` | `#0A0A0F` | Screen backgrounds |
| `AppColors.primary` | `#FFB830` | Amber — CTAs, accents |
| `AppColors.secondary` | `#00E5CC` | Teal — secondary accents |
| `AppColors.surface` | `#12121A` | Cards, panels |
| Font: Display | **Syne ExtraBold** | Headers, titles |
| Font: Body | **Inter** | Body text, labels |
| Font: Code | **JetBrains Mono** | Prompts, code |

---

## 🗺️ APP NAVIGATION

```
/login          → LoginScreen (register + sign in)
/home           → HomeScreen (dashboard)
/create         → CreateScreen (3-step wizard)
/results/:id    → ResultsScreen (6-tab results)
/projects       → ProjectsScreen (history)
/tools          → ToolsScreen (affiliate marketplace)
/settings       → SettingsScreen
/settings/plans → PlansScreen (upgrade)
```

---

## 📦 WHAT THE AI GENERATES (per plan)

| Output | Free | Creator | Studio |
|---|---|---|---|
| Video titles (6 platforms) | ✅ | ✅ | ✅ |
| Viral hook | ✅ | ✅ | ✅ |
| Full narration script | ✅ | ✅ | ✅ |
| Scene breakdown | ✅ | ✅ | ✅ |
| AI video prompts | ✅ | ✅ | ✅ |
| YouTube SEO pack | ✅ | ✅ | ✅ |
| Hashtags (30+) | ✅ | ✅ | ✅ |
| Thumbnail prompt | ✅ | ✅ | ✅ |
| SRT subtitle script | ✅ | ✅ | ✅ |
| Image prompts (4 tools) | ✅ | ✅ | ✅ |
| Voice-over script (timed) | ✅ | ✅ | ✅ |
| ZIP package export | ❌ | ✅ | ✅ |
| 10–20 min videos | ❌ | ✅ | ✅ |
| Batch planner | ❌ | ✅ | ✅ |
| Team collaboration | ❌ | ❌ | ✅ |

---

## 🔧 ADDING MISSING ASSETS

After cloning, create these directories and add your assets:
```bash
mkdir -p frontend/assets/{images,animations,icons,fonts}

# Download Syne font from Google Fonts:
# https://fonts.google.com/specimen/Syne
# Place in frontend/assets/fonts/:
#   Syne-Regular.ttf
#   Syne-Medium.ttf
#   Syne-SemiBold.ttf
#   Syne-Bold.ttf
#   Syne-ExtraBold.ttf

# Add your app icon (1024x1024 PNG) at:
frontend/assets/images/app_icon.png

# Generate launcher icons:
flutter pub add flutter_launcher_icons
# Configure in pubspec.yaml, then:
flutter pub run flutter_launcher_icons
```

---

## 🧩 TECH STACK  

| Layer | Technology |
|---|---|
| Mobile/Web Frontend | Flutter 3.22 (Dart) |
| State Management | Riverpod 2.x |
| Navigation | GoRouter 14.x |
| HTTP Client | Dio 5.x |
| Backend | Python 3.11 + FastAPI |
| Database | PostgreSQL (async via asyncpg) |
| ORM | SQLAlchemy 2.0 async |
| Auth | JWT (python-jose + bcrypt) |
| AI — Primary | OpenAI GPT-4o-mini |
| AI — Fallback 1 | Google Gemini 1.5 Flash |
| AI — Fallback 2 | Anthropic Claude Haiku |
| Hosting | Render (auto-deploy from GitHub) |
| Ads | Google AdMob |
| Payments | Paystack + LemonSqueezy |
| CI/CD | GitHub Actions |

---

## 📄 LICENSE

Proprietary — © 2024 chAs Tech Group. All rights reserved.

---

*PromptReel AI — Made with ❤️ by chAs Tech Group*
