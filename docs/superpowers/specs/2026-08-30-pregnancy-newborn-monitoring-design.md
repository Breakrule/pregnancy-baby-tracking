# Pregnancy & Newborn Monitoring App — Design Spec

**Date:** 2026-08-30
**Status:** Approved by user (brainstorming session)
**Type:** Greenfield Flutter mobile application

---

## 1. Overview

A personal family mobile app that monitors a pregnancy from trimester 1 through birth, then transitions seamlessly into monitoring the newborn's development. One shared record is used by both parents. The app is fully offline and private: all data stays on-device with encrypted file backup/export.

The app is a **support tool, not a medical device**. All educational content and alerts direct the user to their healthcare provider and carry an explicit disclaimer.

## 2. Confirmed Scope Decisions

| Decision | Choice |
|---|---|
| Audience | Personal family app — one family, no multi-user accounts, no social features |
| Data sharing | Shared record, both parents log. MVP: single primary device + export/import handoff. Optional cloud sync deferred to a later phase |
| Storage | Local-first: SQLite on-device, encrypted file backup/export |
| Delivery strategy | Full roadmap designed up front, implemented in phased increments |
| Platforms | Android only |
| Language | English only |
| Current stage | Planning / trimester 1 — early-pregnancy features have MVP priority |
| Educational content | Bundled static content (JSON/Markdown assets), fully offline |
| Maternal metrics | Weight, blood pressure + glucose, symptom journal, medications |
| Growth standard | WHO Child Growth Standards |
| Security | App lock: PIN + biometric |
| Doctor support | Appointment tracking + shareable PDF visit summaries |
| Tech stack | Flutter + Riverpod + Drift + go_router + freezed (Approach A, approved) |

## 3. Product Model

The app has two lifecycle modes around a single shared record:

- **Pregnancy Mode** — active from setup (LMP/due date) until birth. Home screen is a gestational-age dashboard.
- **Birth transition** — a one-time birth-record form (date/time, sex, measurements, delivery details). Submitting it switches the app.
- **Baby Mode** — active from birth onward. Newborn focus (0–3 months), usable to ~2 years via growth charts, milestones, and vaccines. Same shell, different home.

`AppMode` is derived state: no birth record → Pregnancy Mode; birth record exists → Baby Mode. The router redirects home based on mode. No duplicated app shell.

**Gestational definitions:** gestational age is counted in completed weeks + days from the reference date. If due date comes from LMP, gestational age = days since LMP; if from ultrasound dating, LMP is back-derived as due date minus 280 days and the same math applies. Trimester 1 = week 0 through 13+6, trimester 2 = week 14 through 27+6, trimester 3 = week 28 onward. Due date is editable at any time; all derived displays recompute.

## 4. Feature Set

### 4.1 Pregnancy — Basic

| ID | Feature | Detail |
|---|---|---|
| P1 | Setup wizard | Due date from LMP *or* ultrasound dating, pre-pregnancy weight/height (BMI), blood type, clinic/hospital info |
| P2 | Home dashboard | "Week 9, Day 3", trimester badge, due-date countdown, baby-size comparison, today's snapshot |
| P3 | Weekly content | Weeks 3–42: fetal development, size comparisons, body changes, common symptoms, partner tips, weekly checklist (bundled, offline) |
| P4 | Appointment tracker | OB visits, ultrasounds; reminders; notes + outcome per visit |
| P5 | Weight tracking | Chart vs. IOM recommended gain range for pre-pregnancy BMI; weekly gain pace |
| P6 | Symptom journal | Preset symptoms + severity + notes; red-flag symptoms trigger an immediate "contact your provider now" alert screen |
| P7 | Kick counter | Count-to-10 protocol, time-to-10, session history chart |
| P8 | Contraction timer | Per-contraction duration + intervals, 5-1-1 rule guidance, "time to head in" indicator |
| P9 | Test results | Ultrasound photos, lab values, notes, dated |
| P10 | Medications & supplements | Dose + schedule + reminders |
| P11 | Checklists | Trimester checklists, hospital bag, birth plan builder |
| P12 | Journal | Text diary + photo journal |
| P13 | Visit summary PDF | Gestational age, weight trend, BP/glucose readings, recent symptoms, meds, "questions for doctor" — share to any app |

### 4.2 Pregnancy — Advanced

| ID | Feature | Detail |
|---|---|---|
| P14 | Blood pressure log | Threshold flags: ≥140/90 warning, ≥160/110 urgent |
| P15 | Blood glucose log | Fasting/1h/2h readings with common GDM targets (<95 / <140 / <120 mg/dL), out-of-range flags |
| P16 | Fundal height log | Measurements from clinic visits, plotted by week |
| P17 | Trend insights | Cross-metric trends; weight-gain pace alerts; kick-count pattern deviation alerts |
| P18 | Danger-signs reference | Trimester-specific red flags (heavy bleeding, severe headache, reduced movement…) |
| P19 | Emergency card | One tap: provider phone, hospital address, blood type, due date, GBS status — works offline |
| P20 | Labor guide | Braxton Hicks vs. true labor, early-labor checklist |

### 4.3 Baby — Basic

| ID | Feature | Detail |
|---|---|---|
| B1 | Birth record | Date/time, sex, weight/length/HC, delivery type, Apgar scores; gestational age at birth (for prematurity) |
| B2 | Home dashboard | Age in days/weeks/months, today's feeding/diaper/sleep totals, quick-log buttons |
| B3 | Feeding log | Breast (side + minutes), expressed milk (ml), formula (ml); daily totals, time-since-last-feed |
| B4 | Diaper log | Wet/dirty counts per day |
| B5 | Sleep log | Sleep sessions, daily totals |
| B6 | Growth charts | Weight/length/HC entries plotted on WHO curves (weight-for-age, length-for-age, HC-for-age, weight-for-length) with percentiles |
| B7 | Milestones | Motor / fine-motor / language / cognitive / social categories, age windows, mark-achieved, upcoming reminders |
| B8 | Vaccinations | WHO/EPI schedule (editable), given-date log, reminders |
| B9 | Pediatrician visits | Appointment tracker + visit-summary PDF |
| B10 | Daily insights | Feeding/diaper/sleep charts by day and week |
| B11 | Photo journal | Monthly milestone cards |
| B12 | Newborn red flags | Fever ≥38°C under 3 months → emergency guidance, feeding refusal, jaundice signs |

### 4.4 Baby — Advanced

| ID | Feature | Detail |
|---|---|---|
| B13 | Adjusted age | Corrected-age display for preterm babies, used in milestone guidance |
| B14 | Percentile velocity alerts | Warns when two consecutive measurements cross two or more major WHO percentile bands (3rd, 15th, 50th, 85th, 97th) in the same direction |
| B15 | Pumping log | Separate from direct feeding totals |
| B16 | Health log | Temperature, vitamin D / meds, symptoms |
| B17 | Care guides | Sleep safety / SIDS prevention, feeding guides, common-illness reference |

### 4.5 Shared / Cross-cutting

- **App lock**: PIN + fingerprint, auto-lock when backgrounded.
- **Backup & restore**: AES-encrypted file export/import via Android file picker.
- **Units**: kg/lb, cm/in, mg/dL vs mmol/L for glucose.
- **Reminder engine**: medications, appointments, vaccines, kick-count nudges — all locally scheduled notifications.
- **Disclaimers**: every content screen carries "not medical advice" guidance.
- **Roadmap (post-v1)**: real cloud sync between the two parents' phones; second-child support.

## 5. Architecture

Feature-first, 3 layers: `presentation → domain → data`. Each feature folder owns its screens and Riverpod notifiers. Shared logic (gestational math, alert rules, WHO percentiles) lives in `domain` as pure Dart — no Flutter imports, trivially unit-testable.

```
lib/
  core/        theme, router, shared widgets, utils
  data/
    db/        Drift database, tables, DAOs
    repositories/
    backup/    export/import service
  features/
    pregnancy/ setup, home, weekly_content, weight, symptoms, medications,
               appointments, kick_counter, contraction_timer, test_results,
               checklists, journal, reports, emergency_card
    baby/      birth_record, home, feeding, diaper, sleep, growth,
               milestones, vaccinations, visits, insights, health_log
    shared/    app_lock, backup, settings, reminders, photos
  content/     loaders for bundled JSON assets
assets/content/
  weeks.json           week-by-week pregnancy content (weeks 3-42)
  baby_size.json       size comparisons per week
  milestones.json      milestone definitions with age windows
  vaccines_who.json    WHO/EPI vaccination schedule
  who_lms/*.json       WHO LMS tables (per sex, per indicator)
  red_flags.json       red-flag symptoms + alert copy, thresholds
  checklists.json      trimester + hospital bag checklists
  guides/*.md          danger signs, labor, newborn care guides
```

### Key dependencies

| Concern | Package |
|---|---|
| State / DI | `flutter_riverpod` (+ `riverpod_annotation` codegen optional) |
| Database | `drift` + `drift_dev` + `sqlite3_flutter_libs` |
| Models | `freezed` + `json_serializable` via `build_runner` |
| Navigation | `go_router` |
| Notifications | `flutter_local_notifications` + `timezone` |
| Biometrics | `local_auth` |
| Charts | `fl_chart` |
| PDF | `pdf` + `printing` |
| Sharing / files | `share_plus`, `file_picker`, `path_provider` |
| Encryption | `encrypt` (AES for backup files) |
| Date handling | `intl` |

### Key mechanisms

1. **Mode state machine** — `appModeProvider` derived from birth-record existence; router redirects accordingly.
2. **Alert rules engine** — pure functions evaluated on every save: BP ≥140/90 (warning) / ≥160/110 (urgent), glucose out of target per context, red-flag symptoms, baby fever ≥38°C <3 months, and kick-count deviation. Kick-count deviation is defined as: time-to-10 exceeds 1.5× the rolling average of the last 5 completed sessions, or fewer than 10 kicks felt within 2 hours. Each rule returns an `Alert(severity, message, action)`. Thresholds and copy live in `red_flags.json` so they're tunable without code changes. Fully unit-testable.
3. **WHO percentile computation** — WHO LMS tables bundled as JSON; z-score = `((X/M)^L − 1)/(L·S)`, converted to percentile via the normal CDF. Pure Dart, tested against published WHO reference values.
4. **Reminder engine** — `flutter_local_notifications` + timezone: recurring (medications, daily kick-count nudge) and one-shot (appointments, vaccines). All local; no push service.
5. **Reports** — `pdf` package builds visit summaries / growth reports; `share_plus` hands them to any app.
6. **Backup** — full DB export as an AES-encrypted file keyed by the app-lock passphrase; import validates schema version + checksum before replacing anything. Import is a deliberate, confirmed action.
7. **Content pipeline** — all educational content, checklists, milestone definitions, and vaccine schedules live in `assets/content`, parsed into typed models at startup. Content updates = edit JSON, no logic changes.

### Units & time

- All timestamps stored UTC; displayed in local time.
- Canonical storage units: kg, cm, mg/dL. Display conversion (lb, in, mmol/L) happens at the UI edge per user settings.

## 6. Data Model (Drift/SQLite)

| Group | Tables |
|-------|--------|
| Pregnancy | `pregnancy` (lmpDate, dueDate, conceptionSource, prePregnancyWeightKg, heightCm, bloodType, gbsStatus, clinicName, clinicPhone, hospitalName, hospitalAddress) |
| Birth | `birth_record` (pregnancyId, birthDateTime, sex, weightG, lengthCm, headCircumferenceCm, deliveryType, gestationalAgeAtBirthDays, apgar1, apgar5, notes) |
| Maternal logs | `weight_entries`, `bp_entries` (systolic, diastolic, pulse), `glucose_entries` (value, context: fasting/1h/2h), `fundal_height`, `symptoms` (type, severity, notes), `medications` + `med_logs` |
| Monitoring | `kick_sessions` (start, end, kickCount, completed), `contraction_events` (sessionId, start, end) |
| Care | `appointments` (datetime, provider, type, location, status, notes, outcome), `test_results` (date, type, notes, photo refs), `photos` |
| Lists & journal | `checklist_items` (listId, label, checked), `journal_entries` (datetime, text, photo refs) |
| Baby logs | `feedings` (datetime, type: breast_l/breast_r/bottle_expressed/bottle_formula, amountMl, durationMin, notes), `pumping` (datetime, amountMl), `diapers` (datetime, type: wet/dirty/both), `sleep_sessions` (start, end), `growth_entries` (date, weightG, lengthCm, headCircumferenceCm), `temperature_health` (datetime, tempC, meds, symptoms, notes) |
| Baby care | `milestones` (definitionId ref content, achievedDate, notes), `vaccinations` (scheduleDefId ref content, givenDate, batch, notes) |
| System | `reminders` (type, time, active, refId), `settings` (units, lock config), `backup_meta` |

Schema changes always ship as Drift migrations — the data must survive for years.

## 7. UI/UX

### Design language

- Material 3. Soft coral accent (pregnancy mode), soft teal (baby mode) — the mode switch visibly changes the theme.
- Large glanceable numbers, card-based layout, generous touch targets (3 a.m. one-handed logging is a real use case).
- Consistent `fl_chart` styling; empty states explain what to log and why.
- Accessibility: dynamic text scaling; alerts use color + icon + text, never color-only.

### Navigation (go_router)

**Pregnancy shell — 4 tabs**

| Tab | Contents |
|-----|----------|
| Home | Week+day hero card, baby-size comparison, today's snapshot (next appointment, meds due, checklist), quick actions (kick count, contraction timer, log something), red-flags shortcut |
| Track | Weight, BP, glucose, symptoms, meds, fundal height, appointments, test results |
| Learn | Current-week article, trimester guides, danger-signs reference, labor guide, checklists, birth plan |
| More | Journal, emergency card, reports (PDF), backup, settings, about + disclaimer |

**Baby shell — 4 tabs**

| Tab | Contents |
|-----|----------|
| Home | Age card (adjusted age if preterm), today's totals (feeds/diapers/sleep), quick-log buttons, time since last feed, next vaccine |
| Track | Feeding, diaper, sleep, pumping, growth entry, temperature/health, appointments |
| Grow | Growth charts, milestones, vaccinations |
| More | Insights, photo journal, visit reports, care guides, backup, settings |

Alert actions deep-link to the relevant screen (e.g., medication reminder opens the med screen).

### Key interaction flows

1. **Kick count** — big counter button; tap per movement; auto-stops at 10 showing time taken; history chart; deviation from her usual pattern triggers the alert engine.
2. **Contraction timer** — one toggle per contraction; live duration + gap list; 5-1-1 status banner ("contractions every ~5 min, lasting ~1 min, for ~1 hour → consider heading to hospital"); session saved to history.
3. **Baby quick-log** — one-tap home buttons for the three newborn hot paths: "Breastfeed left/right" (start/stop timer), "Bottle ___ ml", "Diaper wet/dirty". No navigation for 20×/day actions.
4. **Alert presentation** — warning: amber banner, dismissible. Urgent: full-screen red dialog with call-to-action (call provider / go to ER), not accidentally dismissible. Copy from `red_flags.json`, disclaimer footer.
5. **Visit report** — "Prepare for visit": date range picker → preview → share PDF.

## 8. State Management (Riverpod)

- One `AsyncNotifier` per feature (e.g., `weightNotifier`, `feedingNotifier`) owning CRUD through repositories.
- Drift reactive queries stream into UI via `StreamProvider` for live-updating lists/charts.
- Single `AppDatabase` provider; DAOs share one connection.
- Pure-domain providers: gestational-age calculator, WHO percentile service, alert-rules engine — synchronous, stateless, overridable in tests.
- App-state providers: `appModeProvider`, `settingsProvider`, `reminderSchedulerProvider`.
- Forms: local form state, `AutovalidateMode.onUserInteraction`; save goes through the notifier; alert engine runs immediately after save within the same flow; result shown inline.
- Uniform loading/error/empty handling via shared widgets: skeleton loaders, retryable error cards, explanatory empty states.

## 9. Testing Strategy

| Layer | Scope |
|-------|-------|
| Domain (pure Dart) | Due-date & gestational-week math (edge cases incl. week 42+), WHO z-scores vs. published WHO reference values, every alert rule, contraction interval logic, daily feeding totals, adjusted age, percentile-crossing detection |
| Repositories | Drift in-memory DB: CRUD, query correctness, migration tests |
| Widget | Home shells, kick counter, contraction timer, quick-log buttons, forms with validation, alert dialogs |
| Integration | Setup wizard → home; log → alert fires; pregnancy → birth → baby-mode switch; backup export → wipe → import round-trip |
| CI | GitHub Actions on push: `flutter analyze`, `dart format --set-exit-if-changed`, full tests with coverage; domain coverage gate ≥90% |

## 10. Security & Privacy

- **Zero network surface** — no analytics, no telemetry, no third-party SDKs. The app never phones home. This is a hard architectural rule (no `INTERNET` permission requested).
- App lock: PIN + fingerprint via `local_auth`, auto-lock on backgrounding.
- Backup files AES-encrypted with the user's passphrase; photos in app-private storage.
- Content honesty: every educational screen and alert states the app supports — never replaces — medical care; urgent alerts direct to provider/ER, never to self-treatment.

## 11. Phased Roadmap

| Phase | Contents | Target timing |
|-------|----------|---------------|
| **0 — MVP** | Project scaffold, app lock, pregnancy setup wizard, home dashboard + gestational engine, weekly content (weeks 3–16 at launch), weight tracking, symptom journal + red-flag alerts, medications + reminders, appointments, backup/restore | First — covers trimester 1 needs |
| **1** | BP + glucose logs, test results with ultrasound photos, checklists, journal, visit-summary PDF, kick counter | Before ~week 20 |
| **2** | Contraction timer, hospital bag, birth plan, labor guide, fundal height, trend insights, emergency card | Before ~week 28 |
| **3 — Baby MVP** | Birth record + mode switch, baby home, feeding/diaper/sleep logging, WHO growth charts | Before birth |
| **4** | Milestones, vaccinations + reminders, pumping log, health log, baby insights & reports | Birth → 6 months |
| **5 — optional** | Cloud sync between parents' phones, second-child support | Later, by choice |

Each phase ships a usable increment; nothing in a later phase blocks earlier daily use.

## 12. Acceptance Criteria

- MVP runs end-to-end on an Android device, fully offline.
- All domain-logic tests green; alert rules verified against each threshold.
- Backup export → import round-trip verified on a real device.
- App lock enforced; no network permission requested.
- Every content screen shows the medical disclaimer.

## 13. Out of Scope (YAGNI)

- Multi-user accounts, social/sharing features
- Cloud backend in phases 0–4 (data layer stays sync-ready, nothing more)
- Wearable / Google Fit / Apple Health integration
- Telemedicine, AI symptom diagnosis, or any feature implying medical advice
- iOS builds, additional languages (structure stays ready for both)
- White-noise/sleep sounds, shopping lists, name pickers — not monitoring features
