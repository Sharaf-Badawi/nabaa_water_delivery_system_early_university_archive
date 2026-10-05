# Security and publication notice

This repository is an educational archive. It is not production-ready and must not be connected to the original live Firebase project.

## Items removed before publication

The source archive contained the following high-risk material, which is absent from this repository:

- a Firebase service-account JSON containing a private key, client email, and project metadata;
- an Android release keystore;
- Android signing passwords, aliases, and a local Windows path to the keystore;
- three `google-services.json` files containing live application configuration;
- Firebase client options and Google Maps configuration tied to the original project;
- live Cloud Functions notification URLs;
- generated Gradle/CMake caches and local machine configuration;
- original screenshots containing personal or potentially identifying information; the public archive contains only reviewed copies with those fields covered.

The service-account key and signing material were not merely hidden. They were removed from the public tree. The original archive was not rewritten in place.

## Required actions before public release

1. Revoke the Firebase service-account key found in the original station project and issue a new key only if a private backend still needs one.
2. Rotate any Firebase, Maps, OAuth, notification, or other credentials that were active when the original projects were used.
3. Do not push the old repositories, old tags, or old branches into the public repository. This archive did not include `.git` history; old history must be treated as a separate exposure risk.
4. Review Firebase Authentication, Firestore Rules, Storage Rules, App Check, Cloud Functions, and API-key restrictions in the original project before leaving it active.
5. Do not reuse the old Android release keystore or its passwords in a public build. If an app was distributed using that key, handle signing-key migration separately.

## Remaining design risks

Even after sanitization, the preserved application design has security risks if deployed:

- client applications read and write operational Firestore collections directly;
- authorization and role assumptions are spread through client code rather than enforced by a documented server boundary;
- the archive does not contain Firestore or Storage Rules;
- order state, completed-order copies, commissions, and totals are updated in several independent operations;
- notification calls were initiated from client code and depended on a live endpoint;
- location, phone, residential, and order information is handled throughout the UI without a demonstrated data-minimization model; the included screenshots are sanitized, but the application design itself still handles this data;
- the apps contain old dependencies and outdated Android build conventions.

Treat the repository as source to study, not as a secure deployment baseline.
