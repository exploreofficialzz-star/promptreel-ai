# Web Icons

Place the following PNG files here (generated from your app icon):

| File | Size | Usage |
|---|---|---|
| `Icon-192.png` | 192×192 | PWA icon, favicon |
| `Icon-512.png` | 512×512 | PWA splash / install |
| `Icon-maskable-192.png` | 192×192 | Android adaptive icon (maskable) |
| `Icon-maskable-512.png` | 512×512 | Android adaptive icon (maskable) |

## How to generate
After adding your app icon to `assets/icon/app_icon.png`, run:

```bash
cd frontend
dart run flutter_launcher_icons
```

This auto-generates icons for Android, iOS, and web simultaneously.
