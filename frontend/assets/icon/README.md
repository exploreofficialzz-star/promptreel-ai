# assets/icon/

Place your app icon files here. These are required for the build to succeed.

## Required Files

| File | Size | Usage |
|---|---|---|
| `app_icon.png` | 1024×1024 px | Main app icon (Android, iOS, Web) |
| `app_icon_foreground.png` | 1024×1024 px | Android adaptive icon foreground layer |

## Rules
- Use **PNG format**, transparent background
- Keep the main subject in the **centre 66%** of the canvas for adaptive icon safe zone
- No rounded corners — the OS applies its own shape mask

## Generate all platform icons in one command

After adding `app_icon.png`, run from the `frontend/` directory:

```bash
dart run flutter_launcher_icons
```

This generates:
- `android/app/src/main/res/mipmap-*/` — all Android densities
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` — all iOS sizes
- `web/icons/` — 192 and 512 PNG icons for PWA

## Temporary: build without icon

If you want to do a test build before your icon is ready, you can
temporarily comment out the `adaptive_icon_foreground` line in `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  # adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"  # ← comment out
```
