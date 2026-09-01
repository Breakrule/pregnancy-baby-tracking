# Nurture

Pregnancy and newborn monitoring for our family. Nurture tracks the pregnancy
week by week — gestational age, symptoms, weight gain against IOM guidelines,
medications, appointments, and danger signs — and will grow into newborn
development tracking after birth.

## Privacy

Nurture is fully offline and local-first:

- All data lives in an on-device SQLite database.
- The release build requests **no `INTERNET` permission** — the app has no
  network surface at all. (`INTERNET` appears only in the `debug`/`profile`
  manifests, where the Flutter tooling requires it for hot reload; it is not
  part of release builds.)
- Backups are AES-256-CBC encrypted files written through the system file
  picker; nothing leaves the device automatically.
- Reminders are local notifications scheduled on the device. No push service.

## Building

```bash
flutter pub get
flutter build apk --release
```

Install the APK from `build/app/outputs/flutter-apk/app-release.apk` on an
Android device.

## Tests

Unit and widget tests (no device needed):

```bash
flutter test
```

On-device integration test (golden path: setup → dashboard → symptom journal →
red-flag alert → weight entry), with a connected device/emulator:

```bash
flutter test integration_test
```

On Android 13+, grant notification permission once before running the
integration test:

```bash
adb shell pm grant com.family.nurture android.permission.POST_NOTIFICATIONS
```

Storage uses `sqlite3_flutter_libs`, which bundles SQLite for Android. On the
dev machine, drift's in-memory test databases load the system `sqlite3` native
library, so keep one available (e.g. Git for Windows Bash or MSYS2 provides
it).

## Roadmap

Phase 0 is the pregnancy MVP. See
`docs/superpowers/plans/2026-08-30-pregnancy-newborn-monitoring-roadmap.md`
for the full phase plan (BP/glucose, test results, journal, PDF reports, kick
counter, newborn milestones) and
`docs/superpowers/specs/2026-08-30-pregnancy-newborn-monitoring-design.md`
for the design spec.

## Medical disclaimer

Nurture is a personal tracking tool, not a medical device. Its content and
alerts are general information and are no substitute for professional medical
advice. Always contact your healthcare provider about concerns — and go to the
emergency department for urgent symptoms.
