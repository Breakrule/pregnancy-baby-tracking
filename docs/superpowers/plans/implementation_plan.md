# Nurture Enhancements — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver four major enhancements on top of the Phase 0 MVP — motion design, photo capture/gallery, English→Indonesian i18n, and an animated splash screen — plus a prioritized backlog of follow-on features, while preserving the hard rules: fully offline, zero network surface, app-private data, medical-support-not-replacement messaging.

**Architecture:** All enhancements layer onto the existing feature-first structure (`presentation → domain → data`). New capabilities follow the established patterns: Drift schema changes ship as versioned migrations behind repositories; shared services live in `lib/features/shared/` or `lib/core/`; pure Dart stays in `domain`/`core` and is unit-tested; every user-visible string ends up behind `AppLocalizations`.

**Tech Stack:** Flutter 3.44.x (Android), Dart 3.12+, flutter_riverpod, drift, go_router, flutter_localizations (gen_l10n), image_picker, `image` (pure-Dart compression — deliberately no new third-party native plugins where avoidable).

**Spec:** `docs/superpowers/specs/2026-08-30-pregnancy-newborn-monitoring-design.md`
**Prior plan:** `docs/superpowers/plans/2026-08-30-pregnancy-newborn-monitoring-phase-0-mvp.md`

---

## Current State (verified 2026-09-01)

| Fact | Where |
|---|---|
| Phase 0 MVP shipped: setup wizard, home dashboard, weekly content (weeks 3–16), weight, symptoms + red-flag alerts, medications + reminders, appointments, backup/restore, app lock | `lib/features/**` |
| Drift schema **version 1**, 7 tables (`Pregnancies`, `SettingsRows`, `WeightEntries`, `Symptoms`, `Medications`, `MedLogs`, `Appointments`) | `lib/data/db/app_database.dart`, `lib/data/db/tables.dart` |
| Backup is an AES-256-CBC encrypted **JSON envelope of DB tables only** — no files | `lib/data/backup/backup_service.dart` |
| Content loads from `assets/content/{weeks,red_flags,common_symptoms}.json` via `ContentLoader.load()` (no locale parameter) | `lib/content/content_loader.dart` |
| No l10n infrastructure; all UI strings are hard-coded English (~55 Dart files) | `lib/**` |
| Theme: Material 3, pregnancy seed `0xFFE8836F` (soft coral), baby seed `0xFF4DB6AC` (soft teal) | `lib/core/theme.dart` |
| Boot: `main()` awaits notification init, then `runApp`; `LockGate` wraps `MaterialApp.router` | `lib/main.dart`, `lib/app.dart` |
| Settings row holds units + lock config only | `SettingsRows` in `tables.dart` |

**Environment notes:**
- Repo root: `C:\Users\user\Documents\Qoder\2026-08-30\597244db` (git repo; CI runs `flutter analyze` + full tests).
- When adding a dependency, run `flutter pub add <package>` (no version) to pull the current compatible release, then pin nothing else. The pinned-versions era caused the `file_picker`/KGP constraints already documented in `pubspec.yaml`.
- Android build currently runs with `android.builtInKotlin=false` (legacy KGP mode). **Prefer pure-Dart packages or first-party plugins** for new work; any new third-party plugin must be checked for Kotlin Gradle Plugin usage before adoption (see Flutter issue #189133).

---

## Execution Order & Dependency Graph

```
Splash (D) ──────────────┐
Motion (A) ──────────────┼──► i18n (C)  ◄── do LAST (one mechanical string sweep
Photos (B) ──► backup v2 ┘                     catches strings added by A/B/D)
```

Recommended sequence: **D → A → B → C**.

- **D (Splash)** first: ~1–2 days, isolates boot sequencing that B and C benefit from.
- **A (Motion)** second: few new strings, mostly widget-layer changes.
- **B (Photos)** third: schema migration + backup v2; biggest storage feature.
- **C (i18n)** last: the string extraction sweep must capture everything A/B/D added; doing it earlier means double work.

B and C both need **schema migrations** (photos table; settings locale column). Implement them as **one migration to schema version 2** if B and C land close together, or two sequential versions if not — never two changes inside one version bump.

---

# Feature 1 — Animated Splash Screen (D)

## Technical Approach

A Flutter-side splash (not the Android native window — `launch_background.xml` stays a plain color so the native→Flutter handoff is seamless). The splash doubles as the **bootstrap gate**: it displays while initial data loads, then hands off to the existing `LockGate → MaterialApp.router` tree.

**Files:**
- Create: `lib/features/shared/splash/splash_screen.dart` — animated brand screen (coral→teal gradient, logo scale+fade, subtle progress shimmer).
- Create: `lib/features/shared/splash/app_bootstrap.dart` — `bootstrapProvider` (`FutureProvider<AppBootstrapState>`) that opens DB, loads settings, loads content bundle, and initializes reminders — in parallel where possible, with a minimum display duration.
- Create: `lib/features/shared/splash/pending_route_provider.dart` — holds a deep-link/notification route to navigate to after unlock.
- Modify: `lib/main.dart` — move `ReminderService` init out of `main()` into the bootstrap (removes blocking work before `runApp`).
- Modify: `lib/app.dart` — root widget shows `SplashScreen` until bootstrap completes.
- Test: `test/features/shared/splash/app_bootstrap_test.dart`, `test/features/shared/splash/splash_screen_test.dart`.

**Key contract — `app_bootstrap.dart`:**

```dart
class AppBootstrapState {
  const AppBootstrapState({required this.ready, this.error});
  final bool ready;
  final Object? error;
}

final bootstrapProvider = FutureProvider<AppBootstrapState>((ref) async {
  final started = DateTime.now();
  final results = await Future.wait<Object?>([
    ref.read(appDatabaseProvider).customSelect('SELECT 1').get(), // warm DB
    ref.read(settingsRepositoryProvider).get(),
    ref.read(contentProvider.future),
  ], eagerError: false);
  // Notifications are non-critical: never fail boot on them (same policy as today).
  await ref.read(reminderServiceProvider).initialize().catchError((_) {});
  final elapsed = DateTime.now().difference(started);
  const minDuration = Duration(milliseconds: 1400);
  if (elapsed < minDuration) {
    await Future<void>.delayed(minDuration - elapsed);
  }
  return const AppBootstrapState(ready: true);
});
```

Note: `reminderServiceProvider` throws unless overridden (see `lib/data/providers.dart`), so `main()` keeps constructing `ReminderService` and passing it via `ProviderScope(overrides: [...])` — but **without** awaiting `initialize()`, which moves into the bootstrap above.

**Animation behavior:**
- Logo: `AnimatedScale` 0.8→1.0 + `FadeTransition`, 700 ms, `Curves.easeOutCubic`.
- Tagline fades in with a 250 ms delay.
- `MediaQuery.disableAnimations` (Android "Remove animations" setting) → render a static frame and skip the minimum duration entirely.
- Exit: `AnimatedOpacity` 250 ms into the app tree; never block on animation completion before swapping the widget tree (swap happens on bootstrap completion; fade is cosmetic).

**Deep links / state restore:**
- Notification taps already route via `flutter_local_notifications` payload. Move payload capture into `pendingRouteProvider`; after bootstrap + unlock, `ref.read(routerProvider).go(pendingRoute)` and clear it.
- App killed mid-flow: no state to restore beyond DB; router redirect (setup gate) already handles first-run.

## Steps

- [ ] Create `app_bootstrap.dart` + failing test (providers overridden with fakes; assert ready state, assert min-duration respected via injected clock).
- [ ] Implement bootstrap; move reminder init out of `main.dart`; test passes.
- [ ] Create `splash_screen.dart`; widget test asserts static render under `disableAnimations: true`.
- [ ] Wire into `app.dart`; update `test/app_test.dart` (pump bootstrap to completion).
- [ ] Manual: cold start on device — splash covers full boot, no white flash, exits to lock screen/home.
- [ ] Commit: `feat: animated splash screen with async bootstrap`.

**Estimated effort:** 1–2 days.
**Dependencies:** None.
**Challenges:** (1) Keeping the native launch window visually continuous with the Flutter splash — match colors exactly (`launch_background.xml` ↔ splash gradient start). (2) Reminder init can hang on emulators without Play services — keep it non-fatal and time-boxed (`Future.any` with a 2 s timeout if flakes appear).
**Success criteria:** No blank/white frame between native launch and app; splash finishes ≤2.5 s warm / ≤4 s cold on a mid-range device; animation disabled under reduced-motion; boot never fails because of notifications; deep-link payload lands on the correct screen after unlock.

---

# Feature 2 — Micro-interactions & Motion Design (A)

## Technical Approach

No new dependencies — Flutter's animation primitives cover everything and keep the dependency surface minimal. Build a small **motion system** in `lib/core/motion/`, then adopt it screen by screen.

**Files:**
- Create: `lib/core/motion/motion_tokens.dart` — canonical durations/curves.
- Create: `lib/core/motion/reduced_motion.dart` — `bool get reduceMotion` extension on `BuildContext` reading `MediaQuery.disableAnimationsOf(context)`.
- Create: `lib/core/motion/entrance.dart` — `FadeSlideIn` (single child) and `StaggeredList` (indexed delays) widgets.
- Create: `lib/core/motion/pressable.dart` — `PressableScale` wrapper (press-down scale 0.97, spring back).
- Modify: `lib/core/theme.dart` — set `pageTransitionsTheme` (shared-axis or fade-up for all platforms).
- Modify: list screens (weight/symptom/appointment/medication history), home screen, track screen, edit forms, dialogs.
- Test: `test/core/motion/motion_tokens_test.dart`, widget tests for `PressableScale` + `FadeSlideIn` (both motion modes).

**Key contract — `motion_tokens.dart`:**

```dart
abstract final class MotionTokens {
  static const fast = Duration(milliseconds: 120);   // press states, toggles
  static const normal = Duration(milliseconds: 220); // entrances, tab switches
  static const slow = Duration(milliseconds: 350);   // hero cards, mode switch
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const staggerStep = Duration(milliseconds: 45);
}
```

**Adoption catalog (what animates where):**

| Pattern | Where | Technique |
|---|---|---|
| Screen entrance | Home hero card, dashboard cards | `StaggeredList` (fade + 12 px slide-up) |
| List insert/remove | All history screens | `AnimatedList` with `SizeTransition` + fade |
| Button press | FABs, quick-action buttons | `PressableScale` around `FilledButton`/`IconButton` |
| Card tap | Track/Learn tiles | Material `InkWell` splash only — no extra scale (avoid double feedback) |
| Tab switch | App shell | `pageTransitionsTheme: FadeUpwardsPageTransitionsBuilder` |
| Save confirmation | Entry forms | Existing SnackBar + animated check icon (`AnimatedSwitcher`) |
| Alert dialogs | Red-flag urgent dialog | Material default (intentionally no playful motion on urgent content) |
| Mode/theme accent | Pregnancy↔baby (future) | `AnimatedTheme` 350 ms crossfade |

**Performance rules (60 fps target):**
1. Animate **opacity and transforms only** (`FadeTransition`, `ScaleTransition`, `SlideTransition`) — compositor-cheap; never animate `width`/`height`/`padding` on hot paths.
2. Wrap independently-animating subtrees in `RepaintBoundary`.
3. Prefer implicit/`Animated*` widgets over manual `AnimationController` unless staggering; dispose controllers in `dispose()`.
4. No infinite/ambient animations on battery-sensitive screens (home dashboard); nothing loops except the splash shimmer, which dies on exit.
5. Verify with DevTools Performance: rasterized frames during list scroll + entrance must stay under 16 ms on the target device.

**Accessibility:**
- Every entrance respects `reduceMotion` (duration 0, final state rendered immediately).
- Motion never carries meaning alone; state changes always also change color/icon/text (existing spec rule).
- Urgent alerts stay visually calm (see catalog).

## Steps

- [ ] Create motion tokens + reduced-motion helper; unit test (token values, helper under both `MediaQueryData` variants).
- [ ] Build `FadeSlideIn`, `StaggeredList`, `PressableScale`; widget tests both motion modes.
- [ ] Theme: page transition builder; verify existing widget tests unaffected.
- [ ] Convert home screen + hero card to staggered entrance; commit `feat(motion): home entrances`.
- [ ] Convert the four history lists to `AnimatedList` insert/remove; commit.
- [ ] Add `PressableScale` to quick actions + FABs; commit.
- [ ] DevTools pass on device; fix any frame over 16 ms; commit `chore(motion): performance pass`.

**Estimated effort:** 2–3 days.
**Dependencies:** None (ideally after splash, not required).
**Challenges:** (1) `AnimatedList` requires key-based item tracking — history screens currently rebuild from streams; keep keys = DB row ids. (2) Over-animating makes a 3 a.m. logging app annoying — the adoption catalog is the guardrail; when in doubt, don't animate. (3) Existing widget tests that pump zero frames may need `tester.pumpAndSettle()` adjustments.
**Success criteria:** All adoption-catalog patterns live; `flutter test` green; DevTools shows no jank during entrance + scroll on target device; with "Remove animations" enabled in Android settings the app is fully functional with zero decorative motion; no animation delays saving a log entry.

---

# Feature 3 — Photo Capture & Gallery (B)

Three contexts on one shared engine: **belly photos** (by pregnancy week), **ultrasound images** (dated, tied to visits), **baby photos** (milestone journaling — UI scaffolded now, data model ready for Baby mode).

## Technical Approach

**New packages:**
- `image_picker` — first-party camera/gallery access (already Built-in-Kotlin clean).
- `image` — pure-Dart decode/resize/encode. Deliberate choice over `flutter_image_compress` (third-party native plugin, KGP risk, extra platform channel). Full-res JPEG re-encode costs ~1–2 s on device; acceptable because it happens once per save, off the render path.

**Storage design:**
- Files live in `getApplicationSupportDirectory()/photos/` (app-private, not user-visible Documents) + a `.nomedia` file so the media scanner never indexes private family photos.
- Each saved photo produces **two files**: full-quality (downscaled to ≤1600 px long edge, JPEG q82) and thumbnail (≤320 px, JPEG q70) for instant grid rendering.
- Filenames: `<uuid>.jpg` / `<uuid>_thumb.jpg` — no EXIF/location retained (`image`'s decode drops EXIF by default when re-encoding; verify in test).

**Schema — migration to version 2** (`tables.dart` + `app_database.dart`):

```dart
enum PhotoCategory { belly, ultrasound, baby }

class Photos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => textEnum<PhotoCategory>()();
  DateTimeColumn get takenAt => dateTime()();
  TextColumn get fileName => text()();            // relative to photos dir
  IntColumn get gestationalDays => integer().nullable()(); // belly/ultrasound
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

Migration in `MigrationStrategy.onUpgrade`: `onUpgrade: (m, from, to) async { if (from < 2) { await m.createTable(photos); } }`, and bump `schemaVersion => 2`. Add a migration test that opens a v1 DB, upgrades, and asserts the table exists with old data intact.

**Files:**
- Create: `lib/features/shared/photos/photo_service.dart` — pick/capture → compress → write files → return record-ready data. Pure-ish core (`compressBytes`) unit-testable.
- Create: `lib/data/repositories/photo_repository.dart` — CRUD + stream by category (`watchByCategory`).
- Create: `lib/features/shared/photos/photos_providers.dart`.
- Create screens: `lib/features/shared/photos/gallery_screen.dart` (grid, reusable per category), `photo_viewer_screen.dart` (full-screen, pinch-zoom via `InteractiveViewer`), `photo_add_sheet.dart` (camera vs. gallery choice + date + notes).
- Modify: `lib/core/router.dart` — routes `/photos/:category` (`belly|ultrasounds|baby`) + `/photos/:category/:id`.
- Modify: `lib/features/pregnancy/home/home_screen.dart` (belly-photo shortcut card), `lib/features/pregnancy/track/track_screen.dart` (ultrasound tile).
- Modify: `lib/data/backup/backup_service.dart` — **backup v2** (see below).
- Test: `test/features/shared/photos/photo_service_test.dart`, `test/data/repositories/photo_repository_test.dart`, migration test in `test/data/db/app_database_test.dart`, widget tests for gallery + add sheet.

**Key contract — `photo_service.dart`:**

```dart
class PhotoService {
  PhotoService(this._picker, this._storageDir);
  final ImagePicker _picker;
  final Future<Directory> Function() _storageDir;

  /// Returns null when the user cancels.
  Future<CapturedPhoto?> capture({required ImageSource source}) async;

  /// Downscale + re-encode. Pure function — unit tested with golden sizes.
  static Future<CompressedImage> compress(Uint8List bytes, {
    int maxLongEdge = 1600, int quality = 82,
  });
}

class CapturedPhoto {
  final String fileName; // full-size file already written
  final int sizeBytes;
}
```

**Backup v2 (photos in the encrypted export):**
- Extend the envelope: keep the existing JSON+AES shape but switch `payload` from "serialized tables" to an **encrypted ZIP** (`archive` package, pure Dart) containing `db.json` + `photos/*.jpg`.
- Envelope gains `"format": 2` (absent = format 1). Import path: format 1 loads exactly as today (backward compatible); format 2 unzips after decrypt, restores DB then copies photos into the photos dir, reconciling against `Photos` rows (orphan file → keep row only if file exists; orphan file without row → delete).
- `BackupService` gains a `PhotoStore` seam so tests run in-memory.

**Permissions (`android/app/src/main/AndroidManifest.xml`):**
- `android.permission.CAMERA` (required for capture; `image_picker` guards use).
- Gallery import via Android's photo picker needs **no permission** on API 33+; `READ_MEDIA_IMAGES` only if we later support API <33 gallery access (device minSdk decides — check `flutter.minSdkVersion` before adding).
- Still **no INTERNET permission** — hard rule unchanged.

## Steps

- [ ] `flutter pub add image_picker image archive`; verify build (`flutter build apk --debug`).
- [ ] Schema v2 + migration test (red → green). Commit `feat(photos): schema v2 photos table`.
- [ ] `PhotoService.compress` unit tests (fixture image → size/quality assertions, EXIF stripped) → implement. Commit.
- [ ] `PhotoRepository` + tests (in-memory Drift) → implement. Commit.
- [ ] Gallery/viewer/add-sheet screens + routes + widget tests (picker mocked). Commit `feat(photos): gallery screens`.
- [ ] Entry points: home shortcut card + track tile. Commit.
- [ ] Backup v2: format flag, zip payload, format-1 import still green, round-trip test with photos. Commit `feat(backup): include photos in encrypted backup`.
- [ ] Manual device pass: camera capture, gallery import, delete (file + row), export→wipe→import round trip incl. photos.

**Estimated effort:** 5–7 days (backup v2 ≈ 1.5–2 of those).
**Dependencies:** None for core; backup v2 must land with (not after) the feature so photos are never excluded from the user's only backup.
**Challenges:** (1) Memory: decoding a 12 MP JPEG fully in Dart spikes RAM — decode with `image`'s sampling/progressive decode options and compress on an isolate (`Isolate.run`). (2) Camera permission UX — explain before first capture; denial path shows gallery-only fallback. (3) Backup file size grows ~100–300 KB/photo — surface estimated size in the backup screen before export. (4) Deletion semantics: deleting a photo removes files immediately (privacy-first; no trash).
**Success criteria:** Capture/import works in all three categories; grids scroll at 60 fps using thumbnails only; photos never appear outside app-private storage or the encrypted backup; v1 backups still import; round-trip restores every photo; no new runtime permissions beyond CAMERA; `flutter analyze` + full test suite green.

---

# Feature 4 — Multi-language Support: English → Indonesian (C)

## Technical Approach

Standard Flutter gen_l10n. English default; Indonesian (`id`) first. RTL readiness is structural only (Indonesian is LTR): the sweep enforces direction-neutral layout so Arabic/Hebrew can be added later with zero refactor.

**Infrastructure:**
- `pubspec.yaml`: add `flutter_localizations` (sdk) under dependencies, and `generate: true` under `flutter:`.
- Create `l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

- `SettingsRows` gains `TextColumn get locale => text().withDefault(const Constant('en'))();` — fold into **the same schema v2 migration as photos** if landing together, else schema v3.
- Providers: `lib/features/shared/settings/locale_provider.dart` — `localeProvider` derives `Locale` from settings; changing it writes to `SettingsRows` and invalidates.
- `lib/app.dart` wiring:

```dart
MaterialApp.router(
  locale: ref.watch(localeProvider),
  supportedLocales: AppLocalizations.supportedLocales, // [en, id]
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  ...
)
```

**Files:**
- Create: `l10n.yaml`, `lib/l10n/app_en.arb`, `lib/l10n/app_id.arb`, `lib/features/shared/settings/locale_provider.dart`.
- Modify: `pubspec.yaml`, `tables.dart` + migration, `app.dart`, `settings_screen.dart` (Language section), **every screen/widget with literal strings** (~55 files).
- Test: `test/features/shared/settings/locale_switch_test.dart`, plus a **string-lint CI step** (see below).

**String sweep strategy (the bulk of the work):**
1. Extract per feature folder in one commit each: `pregnancy/setup`, `pregnancy/home`, `pregnancy/track+weight+symptoms`, `pregnancy/appointments+medications`, `pregnancy/learn`, `more+shared (settings, backup, app lock, splash, photos)`, `core widgets + router labels`.
2. Naming convention: `<screen><Element>` (e.g. `settingsTitle`, `homeWeekDayLabel`), placeholders typed in ARB (`@homeDaysLeft { @placeholder }`).
3. Medical/alert copy stays authoritative: red-flag messages move into ARB **too** — they are UI copy, even though trigger *thresholds* remain in content JSON.
4. Guardrail: after each feature commit, `grep` the folder for `Text('` / `Text("` leftovers must return zero hits; add CI check in the final step.

**Content asset localization (`weeks.json`, `red_flags.json`, `common_symptoms.json`):**
- Layout: `assets/content/en/*.json`, `assets/content/id/*.json` (move current files to `en/`).
- `ContentLoader.load(String locale)` with **English fallback per file** (missing `id` file → load `en`, never crash).
- `contentProvider` becomes `localeProvider`-dependent and invalidates on language switch.
- Translation volume is real: 14+ weeks × 5 sections. Phase: machine-translate → human review by the family → diff-check keys against `en` in a unit test (`content parity test`: same weeks/keys/counts in both locales).

**RTL readiness rules enforced during the sweep:**
- No `EdgeInsets.only(left: …)` / `Alignment.centerLeft` — use `EdgeInsetsDirectional` / `AlignmentDirectional` (add the `avoid_directional_widget_lints` note in code review; fix offenders found).
- No mirrored icons/text alignment hardcoding; rely on `Directionality` inheritance (default behavior).
- `localeProvider` keeps `scriptCode`/region support open (store full BCP-47 tag, parse with `Locale.fromSubtags`).

## Steps

- [ ] Infrastructure: deps, `l10n.yaml`, empty-ish `app_en.arb`/`app_id.arb` with 5 test keys, settings column + migration, `localeProvider`, `app.dart` wiring. Test: language switch updates `MaterialApp.locale`. Commit `feat(i18n): localization infrastructure`.
- [ ] Settings UI: Language section (English / Bahasa Indonesia radio) + test. Commit.
- [ ] Feature-folder sweep (one commit per folder as listed above; each commit: extract → replace literals → `flutter analyze` + folder tests green).
- [ ] Content localization: move assets to `en/`, loader locale param + fallback test, parity test skeleton. Commit `feat(i18n): locale-aware content loading`.
- [ ] Indonesian UI translation (all ARB keys) — commit per feature folder.
- [ ] Indonesian content translation (weeks 3–16, red flags, symptoms) + parity test green. Commit.
- [ ] CI string-lint step (fail if `Text('` literal remains under `lib/features`), RTL directional-widget audit, full suite. Commit `chore(i18n): lint + audit`.
- [ ] Manual device pass in both languages, including lock screen, alerts, backup flow, splash.

**Estimated effort:** 4–6 days engineering + 2–3 days translation/review (can overlap).
**Dependencies:** Land **after** Features A/B/D so their strings are captured in one pass. Uses the shared schema migration with photos.
**Challenges:** (1) Drift enums stored as English identifiers (`SymptomSeverity`, appointment types like `"OB visit"`) — identifiers stay English in the DB; only *display* maps to ARB. Free-text user notes are never translated. (2) Content JSON size makes manual key checking error-prone — the parity test is mandatory, not optional. (3) `intl` version coupling: gen_l10n needs the already-present `intl` (`^0.19.0`); if pub complains, `flutter pub upgrade intl`. (4) Date/number formatting must go through `MaterialLocalizations`/`intl` (e.g. `_formatDate` in `settings_screen.dart` currently hand-formats — switch to localized formatters during the sweep).
**Success criteria:** Full app usable in English and Indonesian with zero hard-coded strings left (CI lint enforces); language switch is instant, persists across restart, never loses data; content parity test green; layout shows no clipping/overflow in Indonesian (longer strings); directional-widget audit clean; alert copy medically identical in meaning across both languages (reviewed by a human).

---

# Feature Suggestions (post-plan backlog)

Ranked by user value per unit effort, all consistent with privacy/offline-first/medical-support values.

| # | Suggestion | Effort | User value | Why it fits |
|---|---|---|---|---|
| S1 | **Dark mode** | Small (1–2 d) | High | Theme is already seed-based (`AppTheme._base`); add `ThemeMode` + a Settings toggle + `darkTheme`. Night feeds in Baby mode make this disproportionately valuable. |
| S2 | **"Questions for my provider" notes + visit-prep card** | Small (2 d) | High | Directly serves the medical-support value: a per-appointment question list that flows into the future visit-summary PDF (P13). New table or JSON field on `Appointments` + entry UI. |
| S3 | **Belly-timeline collage export** | Medium (3–4 d) | High | Builds on Feature B: side-by-side week-by-week collage rendered offscreen (`RepaintBoundary.toImage`) and shared via system share sheet. Emotional keepsake; stays 100% offline. |
| S4 | **Android home-screen widget** | Medium (4–5 d) | Medium-High | Glanceable "Week 12, Day 3 · 196 days to go" via `home_widget`. Caveats: widget content is visible without app lock — show only gestational age, never health data. |
| S5 | **Accessibility hardening pass** | Small-Medium (2–3 d) | Medium | Dynamic-type audit at 200% scaling, `Semantics` labels for charts (value announcements), 48 px touch-target verification. Compounds Feature A's reduced-motion work. |

Recommended order: **S2 → S1 → S5 → S3 → S4** (S2 pairs with roadmap item P13; S1 is the cheapest big daily-life win).

---

# Cross-Cutting Test & Quality Notes

- **TDD as in the Phase 0 plan:** every repository/service/domain change lands with a failing test first; widget tests for each new screen; `flutter analyze` clean at every commit.
- **Migration policy:** exactly one logical change per schema version; every bump gets an upgrade test from v(N-1) with seeded legacy data.
- **CI additions:** string-lint step (Feature C), content parity test (Feature C); existing `flutter analyze` + `flutter test --coverage` stay the gate.
- **Privacy regression checks** (per feature): `grep` for new permissions in `AndroidManifest.xml`; confirm no `INTERNET`; photo files confirmed inside app-support dir; backup remains AES-encrypted with checksum verification.
- **Total estimated effort:** Splash 1–2 d, Motion 2–3 d, Photos 5–7 d, i18n 4–6 d (+2–3 d translation) ≈ **14–21 working days**, sequential.
