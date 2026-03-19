# Changelog — PromptReel AI

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [1.1.0] — 2025-03-19

### Added
- Full iOS support: Xcode project, AppDelegate, Info.plist, Podfile, LaunchScreen
- GitHub Pages marketing website with full SEO, PWA manifest, and security headers
- GitHub Actions CI/CD: Android build + release, iOS build + TestFlight, backend deploy, website deploy
- Privacy Policy and Terms of Service pages
- Security: ATS (iOS), network_security_config (Android), CSP headers (website)
- `.gitignore` covering Python, Flutter, Android, iOS, secrets
- `CHANGELOG.md` and `SECRETS_SETUP.md` documentation
- iOS `ExportOptions.plist` for App Store archive export
- `CONTRIBUTING.md` and issue/PR templates
- Rate-limit middleware improvements in backend

### Fixed
- iOS deployment target set to 13.0 across all configs
- Android `key.properties` fallback to `System.getenv` for CI signing
- Backend CORS list updated to include GitHub Pages domain

### Changed
- Website host moved from Netlify to GitHub Pages (zero-config, no account needed)
- Backend `render.yaml` now includes `FLUTTERWAVE_ENCRYPT_KEY`

---

## [1.0.0] — 2025-03-15

### Added
- Initial release of PromptReel AI
- Flutter frontend (Android) with Riverpod state management
- FastAPI backend with async PostgreSQL
- 9-model AI fallback chain (OpenAI → Anthropic → Gemini → Groq → DeepSeek → Together → OpenRouter)
- Flutterwave payment integration (Creator $15/mo, Studio $35/mo)
- Google AdMob integration (banner, interstitial, rewarded, native)
- JWT authentication with refresh token rotation
- 12-file ZIP export package
- Go Router navigation with deep links
- Splash screen, onboarding, and splash animations
- Projects CRUD with pagination
- Tools screen with affiliate links
- AI Models screen showing fallback chain
