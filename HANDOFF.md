# Prayer Lock: handoff notes (updated 2026-10-21, second pass)

Read this first when you open the project from another account.

## What this is
Flutter app (Android + iPhone). User locks distracting apps. Opening one shows a prayer screen first
(2 questions, GPT short prayer, 10 second timer). 4 tabs: Home, Insights, Locked apps, Profile.
Developer: Tetra Developers, tetraheaddevelopers@gmail.com. Admin account: sidharthbabu9@gmail.com.

## App flow now
Onboarding (10 pages: hook, habit, 5x chart, solution, one mission, rhythm, goals,
where did you hear, distractions, permissions; rating sheet after the "where did you hear" page) ->
Commit (hold button) -> Sign up (Apple / Google first, email second, guest) -> Bell page (notification
permission) -> Paywall (7 day free trial, hard) -> Home.
Rating sheet (`lib/services/review_service.dart`): stars + Submit counts as a rating and stops the asking.
4-5 stars also opens the real store review box. "Not now" asks again after 7 days (checked when the app opens).

## Secrets (NOT in this repo, you must get them again)
- OpenAI key: only in the Firebase Cloud Function secret `OPENAI_API_KEY`. Never put it in code.
- App Store Connect API key (`.p8`, key ID, issuer ID): was in `C:\Users\sidha\Downloads\`. Also saved as GitHub
  Actions secrets `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`.
- Firebase login, Apple Developer login, Google Play login: use the owner account.

## IDs
- iPhone bundle ID `com.coreinteractive.prayerLock`, Android package `com.coreinteractive.prayer_lock`
- Apple Team ID `W3QA63P2YL`, App Group `group.com.coreinteractive.prayerLock`
- Firebase project `prayerlock-core-app` (Android app id `1:110455972954:android:239c73f3e606dbe98ca463`)
- App Store Connect app: "Prayer Lock: Christian Habit", app ID `6822556636`
- Store products (same ID on both stores): `prayerlock_pro_monthly`, `prayerlock_pro_yearly`, `prayerlock_pro_lifetime`
  (OLD Apple products with the old IDs `prayerlock_monthly/yearly/lifetime` exist (6822692195, 6822692169, 6822692170). Apple IDs cannot be renamed, so create 3 NEW Apple products with the new IDs.)
- Prices on Apple: monthly $7.99, yearly $39.99, lifetime $79.99, 7 day free trial on both subscriptions.

## Build flags
- `MOCK` (default FALSE = the real app). `--dart-define=MOCK=true` is for development only: admin panel with made-up data,
  test tools, FAKE purchases, "Skip (test)" on the paywall, Apple sign in button on Android.
  In the real app the admin panel is hidden until it has a real backend.
- `APPLE_ON_ANDROID` (default = MOCK): shows "Continue with Apple" on Android for testing without an iPhone.
- `DEMO`: sample data. `SHOTMODE`: screenshot mode (used by CI).
- Windows: `android/gradle.properties` has `kotlin.incremental=false` (pub cache on C:, project on D:).

## CI (GitHub Actions)
- `ios-testflight.yml`: builds and uploads to TestFlight. Run by hand. Last good build: 6.
- `ios-screenshots.yml`: iPhone simulator screenshots. Artifacts kept 2 days. Now also takes the new screens.
- Always check `git status -sb` after `git push`. Pushes once failed silently.

## Done in this pass (not yet committed or sent to TestFlight)
- New flow, onboarding pages, bell page, rating sheet, paywall spacing (all in `lib/screens`).
- Sign in with Apple code for iPhone (`Runner.entitlements` has the capability) and for Android test (Firebase web flow).
- Firebase Android app: added the debug SHA-1 and SHA-256, downloaded a new `google-services.json`
  (it now has the OAuth clients; Google sign in on Android needed this too).
- Admin panel redesigned (`lib/admin/*`): mock data, "Real users only" switch with rules in `admin_config.dart`,
  one chart with a toggle, tap a bar to see people, funnel, payment failures, sources, users, one user, feedback.
- iPhone: after praying the screen now says clearly that Apple does not let apps open other apps.
- Tested on a real Android phone over USB: prayer gate, open-app-after-prayer, usage numbers, alarms registered.

## Done in the third pass (2026-10-26, not committed)
- Lock intro screen ("Instagram is locked", Pray now / Not now). Morning and night prayers never lock or unlock apps.
- Morning/night reminder notifications open that prayer when tapped. Android: if a locked app is opened while open
  and a morning/night prayer is waiting, Prayer Lock nudges (max once per 45 min). iPhone: notifications only.
- Email sign up hides Apple and Google. Guest mode removed. Name question and time question in onboarding.
- "With and without" table in onboarding (page 6) and a measured version in Insights.
- Insights: last 10 prayers + Show more (all prayers), per-app locked stats, closeness line, feelings donut,
  time-of-day bars, 35-day consistency map. Events now store minutes open (gate_prayed value).
- Branding: app icon, logo, splash and praying-girl loader come from `Prayer Lock App Branding Showcase.png`
  (made by tools/make_brand_assets.ps1). The sheet is only 1536 px wide, so the art is soft. **Ask the designer for the
  original high-resolution files** (icon 1024, logo, girl frames, splash) and replace assets/icon/icon.png,
  assets/img/logo.png, assets/img/girl_pray_1..5.png, then run `dart run flutter_launcher_icons`.
- Splash: native launch screen is plain peach-pink #FEB498; Flutter splash (lib/screens/splash.dart) shows 1.6 s.
- Play screenshots: store/play (made by tools/make_play_shots.ps1 from phone screenshots taken with
  `--dart-define=DEMO=true --dart-define=MOCK=true`; DEMO data is in memory only and off in the real app).
- App checks: AI prayers fall back to a fixed prayer when the cloud function fails. Function logs show errors
  (see work left 1).

## Work left (in order of importance)
0. **Check AI prayers.** The phone showed the fixed fallback prayer. Cloud Function logs show an error on every
   call. Look at the OpenAI key, billing and quota, and add logging of the OpenAI status in functions/index.js.
1. **Apple sign in needs Apple + Firebase setup** (code is ready, Firebase says "not turned on yet"):
   - developer.apple.com > Identifiers > + > Services IDs, e.g. `com.coreinteractive.prayerLock.signin`.
     Turn on Sign in with Apple > Configure: domain `prayerlock-core-app.firebaseapp.com`,
     return URL `https://prayerlock-core-app.firebaseapp.com/__/auth/handler`.
   - Keys > + > Sign in with Apple > download the `.p8`, note the Key ID.
   - Identifiers > App ID `com.coreinteractive.prayerLock` > turn on Sign in with Apple.
   - Firebase console > Authentication > Sign-in method > Apple > turn on, enter Services ID, Team ID
     `W3QA63P2YL`, Key ID, paste the `.p8` text.
2. **iPhone blocking on a real phone**: friend's test (build 5/6): the shield showed "Pray first", but Prayer Lock did
   not open by itself and "go back" did not open Instagram. Both are Apple limits (an extension cannot open the app;
   no app can open another app). The notification "Time to pray" is the only way in. Still need a test of build 6+
   with notifications allowed, and the friend's answer on the Status card.
3. **Payments**: Apple Paid Apps agreement is done. Google Play: create the app, upload a closed-test release, create
   the 3 products (subscriptions with 7 day free trial, lifetime one-time). Server does not check receipts yet
   (add RevenueCat or a Cloud Function). Prices on screen are fixed USD; use `ProductDetails.price` later.
4. **Google sign in on iPhone**: needs `GoogleService-Info.plist` (get it with
   `firebase apps:sdkconfig IOS <appId> --project prayerlock-core-app`) and the reversed client ID URL scheme.
5. **Admin panel** is mock only. Needs a real backend: `devices` collection written by a Cloud Function, a daily
   uninstall check (FCM dry run), purchase checks from the store servers, server-side admin check.
6. **Release signing**: Android release build still uses the debug key. When a real key exists, add its SHA-1 and
   SHA-256 to the Firebase Android app (`firebase apps:android:sha:create`).
7. **Before release**: rotate the OpenAI key, consider Firebase App Check.
8. The "5x" and "20%" on the chart page are marketing numbers, not measured. Have a source or soften the claim.
9. Server limit: 30 prayers per account per day (`functions/index.js`). Cost: `docs/openai-cost-and-margin.md`.

## Docs
`docs/app-store-listing.md` (names, descriptions, keywords, screenshot paths), `docs/openai-cost-and-margin.md`,
`docs/apple-family-controls-request.md`, `docs/admin-panel-prompt.md`.
