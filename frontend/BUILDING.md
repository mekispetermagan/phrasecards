# Building PhraseCards

Run all commands from the `frontend/` directory.

## Linux development

Linux is the everyday development target. Run a debug build with hot reload:

```bash
flutter pub get
flutter run -d linux
```

The default API URL is `http://127.0.0.1:8000`. To use the production API:

```bash
flutter run -d linux --dart-define=API_BASE_URL=https://phrasecards.mekis.dev
```

## Android release APK

PhraseCards is tested on Samsung A14 devices, so its Android release APK is
intentionally built for ARM64 only. Keeping the build to one Android ABI avoids
generating the much larger ARM32 and x86/x86-64 native build artifacts.

The production backend requires the API key stored on `mekis.dev` in:

`/home/peter/apps/phrasecards/.env`

Build the APK by streaming that key directly into the Flutter build process. The
key is not printed or stored in a local file:

```bash
ssh mekis.dev 'bash -lc '\''set -a; source /home/peter/apps/phrasecards/.env; printf %s "$API_KEY"'\''' \
  | bash -lc 'IFS= read -r phrasecards_prod_key; test -n "$phrasecards_prod_key"; flutter build apk --release --target-platform android-arm64 --dart-define=API_BASE_URL=https://phrasecards.mekis.dev --dart-define=API_KEY="$phrasecards_prod_key"'
```

Do not omit `--target-platform android-arm64`: without it, Flutter produces a
multi-architecture build and retains substantially larger Gradle intermediates.
The resulting APK will not run on ARM32-only or x86/x86-64 Android devices.

The generated release APK is:

`build/app/outputs/flutter-apk/app-release.apk`

Confirm the connected device uses ARM64, then install the APK:

```bash
adb shell getprop ro.product.cpu.abi
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

The expected ABI for the current Samsung A14 test devices is `arm64-v8a`.

## Checks

Before producing the APK, run:

```bash
flutter analyze
flutter test
```

## Verify the production backend

Check that the server is running:

```bash
curl -i https://phrasecards.mekis.dev/api/health
```

Verify the protected phrases endpoint without displaying the key:

```bash
ssh mekis.dev 'bash -lc '\''set -a; source /home/peter/apps/phrasecards/.env; curl -sS --max-time 15 -o /dev/null -w "%{http_code}\n" -H "X-PhraseCards-Key: $API_KEY" https://phrasecards.mekis.dev/api/phrases'\'''
```

The expected status is `200`.

Do not rely on `backend/.env` for production builds. Its `API_KEY` may be empty
or different from the key configured on the production server.

## Disk usage and cleanup

Use `flutter clean` only when generated artifacts are stale or disk space is
needed. The next build recreates the artifacts required by its target.
