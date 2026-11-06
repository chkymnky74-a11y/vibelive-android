# VibeLive — Android & Google Play Preparation
Prepared: 2026-10-21 (America/Vancouver). Status: PREP ONLY — nothing here is built,
submitted, or approved yet. Do not treat any line as Play readiness.

## Identity (decided, unique to VibeLive)
- App name: VibeLive
- Package ID (applicationId): **com.shelleywrites.vibelive**
  - Chosen for VibeLive only. It is not OpenCircle's ID and must never be reused
    for another app — Play treats the package ID as permanent once published.
- Version scheme: versionName 0.1.0 for the first closed-test build,
  versionCode starts at 1 and increments every upload.

## Packaging approach (recommended)
- **Capacitor** wrapping the same web app code (the VibeLive web build), so the
  Android app and web app stay one codebase. The app talks to Supabase
  (auth/data/realtime/storage) and LiveKit exactly as the web version does;
  only the PUBLIC publishable key ships in the app. The service-role key and
  the LiveKit API secret never ship anywhere — tokens come from the
  livekit-token Edge Function.
- Native pieces Capacitor must declare: camera + microphone permissions
  (with in-app explanations before the system prompt), notifications later.
- Signing: Play App Signing with an upload key. The upload keystore is a
  secret — it will be generated at build time and stored via secure flow,
  never in chat, never in the repo.

## Build environment — honest status
- This workspace currently has Node/npm/git but NO Java and NO Android SDK,
  so a signed .aab cannot be produced here yet. Before the Android stage:
  install OpenJDK + Android command-line tools + Gradle (all free) under the
  workspace, then `npx cap add android`, configure, and build
  `app-release.aab`. The .aab's exact path, version name and version code
  will be recorded here after a real build succeeds.

## Money — the one unavoidable cost (needs Shelley's explicit approval first)
- Google Play Console developer account: **US$25 one-time** registration fee,
  paid by Shelley to Google in her own account. This conflicts with the
  $0-first rule, so it happens ONLY when she explicitly approves it and only
  when the app is genuinely ready for closed testing. Nothing else in the
  Android path requires payment: Supabase Free + LiveKit Build stay free,
  Capacitor/Android tooling is free.

## Play Console declarations to prepare (drafts, not yet submitted)
- Privacy policy URL (required — camera/mic + accounts): to be hosted before
  submission; must describe accounts, profiles, messages, streams, gifts,
  reporting/blocking, and data deletion.
- Account deletion: Play requires an in-app deletion path AND a web deletion
  link. (Database supports it via profile/auth deletion; UI + web page are
  still to build — tracked as not yet implemented.)
- Content rating questionnaire: social/streaming app with user-generated
  content, user interaction, and reporting/blocking — answer honestly
  (likely Teen/Mature 17+ territory depending on answers; do not understate).
- Data safety section: email address, profile info, photos, messages,
  in-app purchase/virtual-currency data; encrypted in transit; deletion
  available.
- Target audience: adults 18+ (live streaming + virtual gifts). Age gate /
  minor-protection wording goes in the listing and the app.
- In-app purchases: coins are virtual credits with NO cash value and NO
  payout. Any coin selling in the Android app must use Google Play Billing.
  Not implemented in the web build and not to be described as available
  until it really is.

## Tester path (when the .aab exists)
1. Play Console → Closed testing track (needs the developer account above).
2. Add tester emails (start with Shelley's own), publish the test release.
3. Testers opt in via the Play link, install on real devices.
4. Run the 14 core-journey tests (signup, profiles, two-device stream,
   viewer list, messaging, gift balances, Quick Exit, block/report, etc.)
   and record pass/fail honestly before any wider release.

## Blockers before any of this can be called ready
- livekit-token Edge Function deployment (one paste + Deploy in Supabase).
- First end-to-end account tests in the web app (signup → confirm → sign in).
- Two-device streaming test passing.
- Java/Android SDK installation in the build environment.
- Shelley's explicit approval of the US$25 Play Console fee when reached.
