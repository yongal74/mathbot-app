# API Key Security

## IAP Verification Server

The `VERIFY_API_KEY` and `VERIFY_SERVER_URL` must be provided via `--dart-define` at build time.

### Development build
```
flutter run --dart-define=VERIFY_SERVER_URL=https://... --dart-define=VERIFY_API_KEY=your-key
```

### Production build (Android)
```
flutter build apk \
  --dart-define=VERIFY_SERVER_URL=https://asia-northeast3-mathbot-csat-tree.cloudfunctions.net \
  --dart-define=VERIFY_API_KEY=your-actual-key
```

### Production build (iOS)
```
flutter build ipa \
  --dart-define=VERIFY_SERVER_URL=https://... \
  --dart-define=VERIFY_API_KEY=your-actual-key
```

NEVER commit the actual API key to git.
