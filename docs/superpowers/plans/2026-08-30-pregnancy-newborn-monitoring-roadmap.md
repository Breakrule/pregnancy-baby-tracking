# Pregnancy & Newborn Monitoring App — Project Roadmap Plan

> **For agentic workers:** This is the project-level roadmap. The detailed, step-by-step plan for the current phase lives in `docs/superpowers/plans/2026-08-30-pregnancy-newborn-monitoring-phase-0-mvp.md`. Each subsequent phase gets its own detailed plan written when the previous phase completes.

**Goal:** Build a fully offline, private Flutter app that monitors a pregnancy from trimester 1 through birth, then transitions into monitoring the newborn — delivered in six phases, each a usable increment.

**Architecture:** Feature-first, 3 layers (presentation → domain → data). Pure-Dart domain core (gestational math, alert rules, WHO percentiles) with zero Flutter imports; Drift/SQLite data layer with repositories injected via Riverpod; a mode state machine (pregnancy → baby) driven by the existence of a birth record.

**Tech Stack:** Flutter (Android only), Dart, Riverpod, Drift, go_router, freezed, flutter_local_notifications, local_auth, fl_chart, pdf/printing, encrypt.

**Spec:** `docs/superpowers/specs/2026-08-30-pregnancy-newborn-monitoring-design.md` — the source of truth for features, data model, and acceptance criteria.

**Hard architectural rules (all phases):**
1. Zero network surface — no `INTERNET` permission, no analytics, no third-party SDKs, no remote calls.
2. All timestamps stored UTC; canonical units kg/cm/mg-dL; display conversion at the UI edge.
3. Every schema change ships as a numbered Drift migration.
4. Every educational screen shows the medical disclaimer.
5. Urgent alerts direct to a provider/ER, never to self-treatment.

---

## Whole-project file structure

```
lib/
  main.dart                          app entry, ProviderScope, lock gate
  app.dart                           MaterialApp.router, theme selection by mode
  core/
    theme.dart                       M3 themes: coral (pregnancy), teal (baby)
    router.dart                      go_router config, mode redirect, deep links
    widgets/                         disclaimer footer, empty/error/loading states,
                                     hero cards, section headers, alert dialogs
    units.dart                       kg/lb, cm/in, mg/dL/mmol-L converters
  domain/
    gestational/gestational_calculator.dart
    alerts/alert.dart, alert_engine.dart, alert_rules (per phase)
    growth/who_percentile.dart       LMS z-score engine
    growth/iom_weight_gain.dart      recommended gain ranges
    baby/age_calculator.dart         chronological + adjusted age
    baby/feeding_totals.dart, sleep_totals.dart
  data/
    db/app_database.dart, tables.dart, dao files per group
    repositories/                    one repository per aggregate
    backup/backup_service.dart       AES export/import, checksum, schema version
  content/
    models.dart                      typed models for bundled content
    content_loader.dart              asset JSON → typed models, startup provider
  features/
    pregnancy/
      setup/                         wizard (Phase 0)
      home/                          dashboard (Phase 0)
      weekly_content/                Learn tab article views (Phase 0 content, full set Phase 1)
      weight/                        (Phase 0)
      symptoms/                      journal + red-flag flow (Phase 0)
      medications/                   + reminders (Phase 0)
      appointments/                  + reminders (Phase 0)
      kick_counter/                  (Phase 1)
      test_results/                  photos + labs (Phase 1)
      checklists/                    trimester + hospital bag + birth plan (Phase 1-2)
      journal/                       diary + photos (Phase 1)
      reports/                       PDF visit summaries (Phase 1 pregnancy, Phase 4 baby)
      bp_glucose/                    BP + glucose logs (Phase 1)
      fundal_height/                 (Phase 2)
      contraction_timer/             (Phase 2)
      insights/                      trend engine (Phase 2 pregnancy, Phase 4 baby)
      emergency_card/                (Phase 2)
    baby/
      birth_record/                  birth form + mode switch (Phase 3)
      home/                          baby dashboard + quick-log (Phase 3)
      feeding/ diaper/ sleep/        (Phase 3)
      growth/                        WHO charts (Phase 3)
      milestones/ vaccinations/      (Phase 4)
      pumping/ health_log/           (Phase 4)
      insights/                      (Phase 4)
    shared/
      app_lock/                      PIN + biometric gate (Phase 0)
      settings/                      units, lock, due date edit (Phase 0)
      backup/                        export/import UI (Phase 0)
      reminders/reminder_service.dart (Phase 0)
      photos/                        private photo storage helper (Phase 1)
assets/content/
  weeks.json                         weeks 3-42 (3-16 Phase 0, rest Phase 1)
  red_flags.json                     red-flag symptoms/conditions + alert copy
  common_symptoms.json               symptom presets
  checklists.json                    trimester checklists (Phase 1), hospital bag (Phase 2)
  milestones.json                    (Phase 4)
  vaccines_who.json                  (Phase 4)
  who_lms/*.json                     WHO LMS tables (Phase 3)
  guides/*.md                        danger signs (Phase 0), labor (Phase 2), newborn care (Phase 3-4)
test/                                mirrors lib/ structure
integration_test/                    end-to-end flows
.github/workflows/ci.yml
```

---

## Phase 0 — MVP (detailed plan: `2026-08-30-pregnancy-newborn-monitoring-phase-0-mvp.md`)

Covers trimester-1 needs. 16 tasks: scaffold + CI; theme/router/shell; gestational engine; Drift DB + pregnancy table; repository/providers; app lock; settings/units; setup wizard; content pipeline + weeks 3–16; home dashboard; alert engine + symptom journal + red flags; weight tracking with IOM ranges; medications + reminders; appointments + reminders; encrypted backup/restore; integration polish + QA.

**Done when:** MVP runs end-to-end on an Android device fully offline; domain tests green; backup round-trip verified; app lock enforced; no network permission requested.

## Phase 1 — Diagnostics, records, kick counter

| Task | Features | Files |
|---|---|---|
| 1.1 | Blood pressure log + threshold alerts (P14) | `features/pregnancy/bp_glucose/`, alert rules in `domain/alerts/` |
| 1.2 | Blood glucose log + GDM target alerts (P15) | same feature folder, context enum fasting/1h/2h |
| 1.3 | Test results with ultrasound photos (P9) | `features/pregnancy/test_results/`, `features/shared/photos/`, private storage |
| 1.4 | Checklists: trimester checklists (P11 first part) | `features/pregnancy/checklists/`, `assets/content/checklists.json` |
| 1.5 | Journal: text diary + photos (P12) | `features/pregnancy/journal/` |
| 1.6 | Visit-summary PDF (P13) | `features/pregnancy/reports/` with `pdf` + `printing` + `share_plus` |
| 1.7 | Kick counter (P7) + deviation alert | `features/pregnancy/kick_counter/`, engine rule from rolling average of last 5 sessions |
| 1.8 | Weekly content weeks 17–42 | extend `assets/content/weeks.json` |

**Done when:** kick deviation, BP, and glucose alert rules each have passing unit tests at every threshold; PDF renders on-device and shares.

## Phase 2 — Birth preparation

| Task | Features | Files |
|---|---|---|
| 2.1 | Contraction timer + 5-1-1 banner (P8) | `features/pregnancy/contraction_timer/` |
| 2.2 | Hospital bag checklist + birth plan builder (P11 rest) | `checklists/` content + builder UI |
| 2.3 | Labor guide + Braxton Hicks vs labor (P20) | `assets/content/guides/labor.md` + reader screen |
| 2.4 | Fundal height log (P16) | `features/pregnancy/fundal_height/` |
| 2.5 | Trend insights: weight-gain pace + kick pattern (P17) | `features/pregnancy/insights/` |
| 2.6 | Emergency card (P19) | `features/pregnancy/emergency_card/` |

**Done when:** contraction interval math and 5-1-1 detection unit-tested; emergency card renders fully offline from stored clinic/hospital data.

## Phase 3 — Baby MVP

| Task | Features | Files |
|---|---|---|
| 3.1 | Birth record form + mode switch (B1) | `features/baby/birth_record/`, `appModeProvider` flip, router redirect to baby shell |
| 3.2 | Baby shell + home dashboard + quick-log (B2) | `features/baby/home/`, `core/router.dart` second shell |
| 3.3 | Feeding log + daily totals (B3) | `features/baby/feeding/`, `domain/baby/feeding_totals.dart` |
| 3.4 | Diaper + sleep logs (B4, B5) | `features/baby/diaper/`, `features/baby/sleep/` |
| 3.5 | WHO LMS asset pipeline + percentile engine (B6) | `assets/content/who_lms/`, `domain/growth/who_percentile.dart` validated against published WHO values |
| 3.6 | Growth charts + percentile display | `features/baby/growth/` with fl_chart |
| 3.7 | Newborn red flags incl. fever ≥38°C <3mo (B12) | alert rules + `red_flags.json` newborn section |
| 3.8 | Adjusted age for preterm (B13) | `domain/baby/age_calculator.dart` |

**Done when:** pregnancy→baby mode switch integration test passes; WHO percentiles match published reference values in tests.

## Phase 4 — Newborn development

| Task | Features | Files |
|---|---|---|
| 4.1 | Milestones + reminders (B7) | `features/baby/milestones/`, `assets/content/milestones.json` |
| 4.2 | Vaccinations + reminders (B8) | `features/baby/vaccinations/`, `assets/content/vaccines_who.json` |
| 4.3 | Pumping log (B15) | `features/baby/pumping/` |
| 4.4 | Health log: temp/meds/symptoms (B16) | `features/baby/health_log/` |
| 4.5 | Baby daily/weekly insights (B10) | `features/baby/insights/` |
| 4.6 | Percentile velocity alerts (B14) | engine rule: ≥2 band crossings between consecutive measurements |
| 4.7 | Baby visit reports PDF + photo journal monthly cards (B9, B11) | `reports/`, `photos/` |
| 4.8 | Care guides (B17) | `assets/content/guides/` newborn set |

**Done when:** milestone windows and vaccine schedule drive real local notifications; velocity alert unit-tested.

## Phase 5 — Optional extensions (by choice, not scheduled)

- Cloud sync between the two parents' phones (repository seam already exists; pick Supabase or self-hosted; reintroduces network surface → requires explicit privacy review and an opt-in).
- Second-child support (multi-pregnancy records, archive previous child).

---

## Plan decomposition rule

One detailed plan per phase. A phase's detailed plan is written only after the previous phase is merged and its acceptance criteria verified — later plans incorporate what earlier phases taught. The Phase 0 plan is written now and is the only step-by-step plan that exists today.
