# Contributing to PromptReel AI

Thanks for your interest in contributing! Here's everything you need to get started.

---

## 🏗 Project Structure

```
promptreel-ai/
├── .github/           — CI/CD workflows, issue & PR templates
├── backend/           — Python FastAPI (deploy to Render)
├── frontend/          — Flutter app (Android + iOS)
│   ├── android/       — Android-specific config
│   ├── ios/           — iOS-specific config (Xcode project)
│   └── lib/           — All Dart source code
└── website/           — Static marketing site (GitHub Pages)
```

---

## ⚙️ Local Setup

### Backend
```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env          # fill in your keys
uvicorn main:app --reload
```

### Flutter (Android)
```bash
cd frontend
flutter pub get
flutter run                   # connects to a running emulator/device
```

### Flutter (iOS) — macOS only
```bash
cd frontend/ios
pod install
cd ..
flutter run -d "iPhone 15"   # or open ios/Runner.xcworkspace in Xcode
```

### Website
Just open `website/index.html` in a browser, or run:
```bash
cd website
python -m http.server 8080
```

---

## 🔄 Git Workflow

1. Fork the repo and create a feature branch: `git checkout -b feat/my-feature`
2. Make your changes — **never remove existing features, only add/fix**
3. Commit with conventional commits: `feat:`, `fix:`, `docs:`, `chore:`
4. Push and open a Pull Request using the provided template
5. One approval required before merge to `main`

---

## 🔐 Security Rules

- **Never commit secrets** — `.env`, `*.jks`, `key.properties`, `GoogleService-Info.plist`
- All secrets live in GitHub Actions Secrets or Render environment variables
- See `SECRETS_SETUP.md` for the full guide

---

## 🐛 Reporting Bugs

Use the Bug Report issue template. Include logs, device info, and reproduction steps.

---

## 📝 Code Style

- **Dart/Flutter**: follow `flutter_lints` rules, `dart format` before committing
- **Python**: PEP 8, `ruff check .` passes, type hints on all public functions
- **HTML/CSS/JS**: keep website self-contained in `website/`, no build step required
