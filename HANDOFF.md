# Prayer Lock: handoff notes (2026-10-21)

Read this first when you open the project from another account.

## What this is
Flutter app (Android + iPhone). User locks distracting apps. Opening one shows a prayer screen first
(2 questions, GPT short prayer, 10 second timer). 4 tabs: Home, Insights, Locked apps, Profile.
Developer: Tetra Developers, tetraheaddevelopers@gmail.com. Admin account: sidharthbabu9@gmail.com.

## Secrets (NOT in this repo, you must get them again)
- OpenAI key: only in the Firebase Cloud Function secret `OPENAI_API_KEY`. Never put it in code.
- App Store Connect API key (`.p8`, key ID, issuer ID): was in `C:\Users\sidha\Downloads\`. Also saved as GitHub
  Actions secrets `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`. For local API scripts, create a new key in
  App Store Connect > Users and Access > Integrations.
- Firebase login, Apple Developer login, Google Play login: use the owner account.

## IDs
- iPhone bundle ID `com.coreinteractive.prayerLock`, Android package `com.coreinteractive.prayer_lock`
- Apple Team ID `W3QA63P2YL`, App Group `group.com.coreinteractive.prayerLock`
- App Store Connect app: "Prayer Lock: Christian Habit", app ID `6822556636`
- Store products (same ID on both stores): `prayerlock_monthly`, `prayerlock_yearly`, `prayerlock_lifetime`
  (Apple IDs: monthly 6822692195, yearly 6822692169, lifetime 6822692170, group "Prayer Lock Plus")
- Prices now on Apple: monthly $7.99, yearly $39.99, lifetime $79.99, 7 day free trial on both subscriptions.
  (A lower price idea of $4.99 / $39.99 / $69.99 was started by mistake for the wrong app and undone.)

## Build flags
- `MOCK` (default true): admin panel open to everyone, test tools, FAKE purchases. Release must use `--dart-define=MOCK=false`.
- `DEMO`: sample data. `SHOTMODE`: screenshot mode (used by CI).

## CI (GitHub Actions)
- `ios-testflight.yml`: builds and uploads to TestFlight. Run by hand. Last good build: 6.
- `ios-screenshots.yml`: iPhone simulator screenshots. Artifacts kept 2 days.
- Always check `git status -sb` after `git push`. Pushes once failed silently.

## Work left (in order of importance)
1. **iPhone blocking not confirmed on a real phone.** A friend installed TestFlight build 5 and said the prayer did
   not show after opening a locked app. Build 6 added a Status card in the Locked apps tab, a notification
   permission prompt, and a "Lock my apps now" button. Still need friend's answers: did the peach "Pray first"
   screen show? Did the "Time to pray" notification show after "Pray now"? What does the Status card say?
   If the peach screen never shows: check `ios/Runner/ScreenTimePlugin.swift` `update()`, `applyShield()` in
   `ios/ScreenTimeShared/ScreenTimeShared.swift`, extension signing and entitlements.
2. **Payments.** Code is in `lib/services/purchase_service.dart` (`in_app_purchase`), not tested on a device.
   - Apple: accept the **Paid Apps** agreement and add bank/tax in App Store Connect > Business. Add the 3 products
     to the first app version when sending for review. Test with a sandbox account.
   - Google Play: create the app in Play Console, upload a release (closed test), then create the 3 products
     (subscriptions with 7 day free trial, lifetime as one-time product). Not done yet.
   - Server does not check receipts. Add RevenueCat or a Cloud Function before launch.
   - Prices on screen are fixed USD. Use real store prices (`ProductDetails.price`) later.
3. **Sign-in on iPhone.** Sign in with Apple and Google do not work on iOS yet: no `GoogleService-Info.plist`,
   no Sign in with Apple capability.
4. **Admin panel** uses mock data. Needs a real backend and a server-side admin check.
5. **Android, untested on a phone:** Usage access (progress report numbers) and the 3-day comeback notification.
6. **Before release:** set MOCK=false, hide the "Skip (test)" link, have a lawyer read the privacy policy and terms
   (drafts only), consider Firebase App Check against abuse, rotate the OpenAI key (an old one was shown in chat).
7. **App Store:** listing text is in `docs/app-store-listing.md`. Screenshots in `store/appstore`. Apple may ask for
   a demo video for the Family Controls feature.
8. Server limit: 30 prayers per account per day (`functions/index.js`). Cost and margin: `docs/openai-cost-and-margin.md`.

## Docs
`docs/app-store-listing.md`, `docs/openai-cost-and-margin.md`, `docs/apple-family-controls-request.md`,
`docs/admin-panel-prompt.md` (prompt to build the same admin panel for any app).
