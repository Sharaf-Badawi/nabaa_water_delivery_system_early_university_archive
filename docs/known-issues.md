# Known architectural and technical issues

This list describes the project as found. It is intentionally diagnostic rather than a claim that the archive has been modernized.

| Area | Observed issue | Likely consequence |
|---|---|---|
| Data access | Widgets call Firestore directly and repeat collection/field names | Business rules are difficult to test, audit, and change consistently |
| Authorization | Admin, station, and customer behavior is mostly selected in client code | Client checks alone cannot enforce roles or prevent unauthorized writes |
| Order lifecycle | Status changes, completed-order copies, totals, and commissions use separate writes | Partial failures, duplicate completion, or inconsistent financial values are possible |
| Data model | Many `Map<String, dynamic>` values and string keys are used without typed models | Runtime crashes and silent schema drift are likely |
| State management | GetX controllers, widget state, and Shared Preferences overlap | Stale state and lifecycle-dependent behavior are difficult to reason about |
| Queries | Some screens fetch broad station/product/order collections and then filter locally | Higher reads, slower screens, and unnecessary exposure of records |
| Notifications | Multiple notification approaches coexist, including an incomplete Dart fragment named `.js` | Delivery behavior is duplicated and the security boundary is unclear |
| Configuration | Firebase, Maps, package identifiers, and deployment assumptions were embedded in app/platform files | Environments are difficult to separate safely |
| Backend | No complete Cloud Functions project or Firestore/Storage Rules were included | Server-side validation and least-privilege behavior cannot be verified |
| Build system | Gradle, Kotlin, Java, and Flutter dependencies are historical and inconsistent between apps | Current toolchains may fail before the Dart code runs |
| Testing | No meaningful automated test suite or CI workflow was included | Regressions are difficult to detect during refactoring |
| Privacy | Screens and code handled identity, phone, location, and residential information | Public demos require anonymized data and explicit privacy controls |

## Refactoring sequence for future branches

If the project is modernized later, use one focused branch per major change, for example:

```text
fix/security-boundary
fix/firebase-configuration
refactor/order-domain
refactor/firestore-repositories
fix/notification-service
chore/modernize-flutter-toolchain
test/order-lifecycle
```

Keep the sanitized historical baseline tagged separately so that later improvements do not erase the original artifact.
