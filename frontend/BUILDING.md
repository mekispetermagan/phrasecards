# Building PhraseCards for Android

Run all commands from the `frontend/` directory.

## Production APK

The production backend requires the API key stored on `mekis.dev` in:

`/home/peter/apps/phrasecards/.env`

Build the APK by streaming that key directly into the Flutter build process. The key is not printed or stored in a local file:

```bash
ssh mekis.dev 'bash -lc '\''set -a; source /home/peter/apps/phrasecards/.env; printf %s "$API_KEY"'\''' \
  | bash -lc 'IFS= read -r phrasecards_prod_key; test -n "$phrasecards_prod_key"; flutter build apk --dart-define=API_BASE_URL=https://phrasecards.mekis.dev --dart-define=API_KEY="$phrasecards_prod_key"'
```

The generated release APK is:

`build/app/outputs/flutter-apk/app-release.apk`

Install it on a connected Android device with:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
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

## Local development

The default API URL is `http://127.0.0.1:8000`. On a physical Android device,
`127.0.0.1` refers to the device itself, not the development computer. Supply a
host reachable from the device when testing against a backend running elsewhere.

Do not rely on `backend/.env` for production builds. Its `API_KEY` may be empty
or different from the key configured on the production server.
