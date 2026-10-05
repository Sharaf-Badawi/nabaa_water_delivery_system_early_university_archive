# Security audit of the supplied archive

## Scope

The audit covered the three Flutter projects, Android configuration, source files, assets, screenshots, and archive contents supplied as `nabaa_aritfact_project.zip`. The archive did not contain Git history, so previous commits, branches, and tags require a separate local audit.

## Findings

### Critical findings removed

- Firebase service-account private key in the station project assets.
- Android release keystore and signing credentials in the customer project.
- Hardcoded release-signing path and passwords in the customer Gradle file.

### High-risk configuration removed or replaced

- Firebase native configuration files.
- Firebase client initialization values tied to the original project.
- Google Maps key values and Google OAuth client identifier.
- Live notification function URLs and the FCM HTTP endpoint project identifier.
- Local machine paths and generated Android/Gradle/CMake state.

### Privacy findings

The screenshots displayed personal names, email addresses, phone numbers, order identifiers, residential details, and map locations. They were therefore excluded rather than published unchanged. Literal email addresses in source and localization content were replaced with `contact@example.invalid`.

## Sanitization performed

- Copied the three apps into `apps/customer`, `apps/station-provider`, and `apps/admin`.
- Removed credentials, signing files, native Firebase files, caches, local machine files, and generated registrant/plugin files.
- Replaced Firebase values with `--dart-define` placeholders.
- Replaced notification URLs with an `example.invalid` default.
- Removed cleartext traffic allowance from the customer Android manifest.
- Made customer release signing fall back to the debug key unless a private local signing configuration is supplied.
- Moved the incomplete notification fragment out of the app source and labelled it as historical reference material.
- Excluded screenshots containing identifiable data.

## Verification limits

No current Flutter SDK was available in the audit environment, so `flutter analyze` and `flutter build` could not be run here. The sanitized tree was checked for the known credential patterns, original project identifiers, private-key markers, signing files, local paths, and live notification endpoints. The build should still be treated as historical and may require toolchain updates.
