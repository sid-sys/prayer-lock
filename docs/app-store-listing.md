# App Store and Google Play listing (ASO text)

Updated 2026-10-21. Letters are counted, not guessed.

## Apple App Store (iPhone)

| Field | Text | Letters (max) |
|---|---|---|
| App name | **Prayer Lock: Christian Habit** | 28 (30) |
| Subtitle | **Bible Verses & App Blocker** | 26 (30) |
| Keywords | see box below | 99 (100) |
| Promotional text | see below | 131 (170) |

The name and subtitle share no words with the keyword box on purpose. Apple reads all three together, so a word
repeated is a word wasted. Words already used: prayer, lock, christian, habit, bible, verses, app, blocker.

If App Store Connect says the name is taken, use `Prayer Lock: Pray First` or `Prayer Lock: Daily Prayer`.

Keyword box (paste with no spaces after the commas):

```
jesus,devotional,scripture,god,faith,church,screen time,focus,streak,morning,night,daily,pray,quiet
```

Promotional text (can change any time, no new version needed):

```
Pray before you scroll. Lock distracting apps, read a short prayer, build a daily streak and make room for Jesus morning and night.
```

### Description (App Store, max 4000 letters)

```
Pray first. Then scroll.

Prayer Lock is a Christian prayer app that helps you put God before your phone. Pick the apps that steal your time. When you open one, Prayer Lock pauses it and asks you for one short prayer first. Pray for a few seconds, then carry on with your day.

HOW IT WORKS
1. Choose the apps you want to lock: social media, video, games, anything.
2. Open one of them. Prayer Lock shows a calm "Pray first" screen.
3. Tell us how you feel. Read a short, personal prayer. Take ten quiet seconds with Jesus.
4. Your apps open again. Your day goes on, with God first.

WHAT YOU GET
• Pray before you scroll: a gentle pause between you and your distractions
• Short prayers for how you feel today: grateful, anxious, tired, hopeful, stressed and more
• Morning and night prayer with Bible verses, so your day starts and ends with Him
• Prayer streaks and badges that celebrate faithfulness, not guilt
• A progress report: prayers completed, pauses, and how your screen time changes
• Gentle reminders at the times you choose, and a kind "come back" note if you have been away
• Private by design: your prayers and feelings stay on your phone

WHO IT IS FOR
Anyone who wants a stronger daily prayer habit, a calmer relationship with their phone, and a simple way to spend time with Jesus every day.

SUBSCRIPTION
Try Prayer Lock free for 7 days. After the free trial, choose monthly or yearly, or buy Lifetime once. Subscriptions renew automatically unless you cancel at least 24 hours before the period ends. You can manage or cancel in your App Store account settings. Lifetime is a one-time purchase with no renewal.

Terms of Use and Privacy Policy are linked inside the app.

Prayer Lock uses Apple's Screen Time tools (Family Controls) to cover the apps you choose. You pick the apps yourself. Apple keeps your choice private on your phone. We never see which apps you pick.
```

Honest note for the reviewer and for users: on iPhone, Apple does not let an app open another app. After you pray, you
go back to your app yourself. The app says this on screen.

## Google Play listing text (emojis, ASO)

Title (30 max): `Prayer Lock: Bible & Prayer` (27)

Short description (80 max, 80 used):

```
🙏 Lock distracting apps. Pray first, then scroll. Daily prayer, Bible verses ✝️
```

Full description (4000 max):

```
🙏 PRAY FIRST. THEN SCROLL.

Prayer Lock is a Christian prayer app that helps you put God before your phone. Choose the apps that steal your time. When you open one, Prayer Lock pauses it and asks for one short prayer first. Pray, then carry on with your day. ✝️

🔒 HOW IT WORKS
1️⃣ Pick the apps you want to lock: Instagram, TikTok, YouTube, games, anything
2️⃣ Open one of them. Prayer Lock shows a calm "Pray first" screen
3️⃣ Tell us how you feel, read a short personal prayer, and take ten quiet seconds with Jesus
4️⃣ Your apps open. Your day goes on, with God first 💛

✨ WHAT YOU GET
🙏 A prayer written for how you feel today: grateful, anxious, tired, hopeful, stressed and more
💪 Prayers that ask God for strength to say no to distractions
📖 A Bible verse of the day with every prayer
🌅 Morning prayer and 🌙 night prayer at the times you choose
🔥 Daily prayer streaks and badges that celebrate faithfulness, not guilt
📊 Insights: how often each app paused you, how long it stayed open, and your time with and without Prayer Lock
💛 See how your feelings and closeness to God change over time, with simple animated charts
🔔 Gentle reminders and a kind "come back" note if you have been away
🔐 Private by design: your prayers and feelings stay on your phone

👤 WHO IT IS FOR
Anyone who wants a stronger daily prayer habit, less scrolling, more peace, and a simple way to spend time with Jesus every day.

💎 FREE TRIAL AND PLANS
Start with a 7 day free trial. Then choose monthly or yearly, or pay once for Lifetime. Cancel any time in Google Play.

⚠️ ACCESSIBILITY SERVICE (please read)
To notice when you open an app that YOU chose to lock, Prayer Lock uses Android's Accessibility Service. It only checks which app is in front. It does not read your screen, messages, passwords or anything you type, and it shares nothing. You turn it on yourself in Settings and can turn it off at any time.

🕊️ Small moments. Big faith.
```

## Files to upload to Play Console

| What | File (in `D:\SCRATCH\Prayerapp`) | Size |
|---|---|---|
| App icon | `store\play\app_icon_512.png` | 512 x 512 |
| Featured image (feature graphic) | `store\play\feature_graphic_1024x500.png` | 1024 x 500 |
| Phone screenshots (8) | `store\play\01_pray_before_you_scroll.png` to `08_understand_your_heart.png` | 1080 x 1920 |
| App bundle | `build\app\outputs\bundle\release\app-release.aab` | |
| Privacy policy link | `https://prayerlock-core-app.web.app/privacy.html` | |
| Delete account link | `https://prayerlock-core-app.web.app/delete-account.html` | |

## Screenshots: where they are

| Store | Folder (inside the project) | Notes |
|---|---|---|
| App Store (final, with captions) | `store/appstore` | 9 pictures, 1320 x 2868 (iPhone 6.9 inch) |
| iPhone simulator, plain | `store/ios` | made by the GitHub workflow "iOS screenshots" |
| Google Play | `store/play` | 1080 x 1920 |
| Raw pictures before captions | `store/raw` | |

These pictures were made BEFORE the new onboarding, sign up and paywall screens. To make new ones: GitHub > Actions >
"iOS screenshots" > Run workflow. It now also takes the new screens (`onboarding_2`, `onboarding_4`, `onboarding_7`,
`reminder`). Then put captions on the best 6 to 8 and replace the files in `store/appstore`.

Good order for the store: 1 hook, 2 chart (5x), 3 how it works (one prayer, one mission), 4 prayer screen,
5 streak and badges, 6 locked apps, 7 insights, 8 paywall.

## IDs (cannot change after publishing)

- iPhone bundle ID: `com.coreinteractive.prayerLock`
- Android package ID: `com.coreinteractive.prayer_lock`
- Apple Team ID: `W3QA63P2YL`
- App Group: `group.com.coreinteractive.prayerLock`
- Store products (same on both stores): `prayerlock_pro_monthly`, `prayerlock_pro_yearly`, `prayerlock_pro_lifetime`

Name, subtitle and keywords CAN be changed later with a new app version.
