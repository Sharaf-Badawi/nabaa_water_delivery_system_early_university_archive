# Local configuration

The public archive is intentionally disconnected from the original Firebase project.

## Firebase values

Each app reads these compile-time values:

```text
FIREBASE_API_KEY
FIREBASE_APP_ID
FIREBASE_MESSAGING_SENDER_ID
FIREBASE_PROJECT_ID
```

Use a private test Firebase project and pass them locally with `--dart-define`. Do not place real values in committed Dart files, screenshots, or documentation. Firebase client API keys are not equivalent to service-account private keys, but they should still be restricted and separated from the historical project.

## Notification endpoint

The customer and station/provider code accepts:

```text
NOTIFICATION_FUNCTION_URL
```

The default is `https://example.invalid/sendNotification`, which intentionally cannot contact a real service. The legacy notification fragment under `docs/legacy-fragments/` is incomplete and is not a deployable backend.

## Google Maps

Replace the Android manifest placeholder `REPLACE_WITH_GOOGLE_MAPS_API_KEY` only in a local working copy. Restrict any test key by application ID, signing certificate, and enabled APIs. Do not commit an unrestricted key.

## Android signing

The customer app now uses the debug signing key unless a private `android/key.properties` file exists. A non-secret template is provided at `apps/customer/android/key.properties.example`. Keep the real file and keystore outside Git.
