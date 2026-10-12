# Prompt: build an admin panel for any app

Copy everything inside the box into your AI coding tool. Fill in the [BRACKETS] first.

````text
Build an in-app ADMIN PANEL for my [Flutter / React Native / web] app "[APP NAME]".
Only I (the admin) can open it. Use the same visual style as the rest of the app
([describe: colors, fonts, rounded cards, dark/light]).

ADMIN IDENTITY
- Admin account: [your Google email]. In the real build only this signed-in account sees
  the admin entry (Profile > "Admin panel").
- Add a build flag MOCK (default true). In a mock build everyone can open the panel and
  it shows made-up data with a small "MOCK DATA" tag. Release builds must set MOCK=false.
- IMPORTANT: hiding the button in the app is NOT security. When real data is added later,
  the server (Firestore rules / Cloud Function / API) must also check that the caller is
  the admin email. Write that down in a README note.

DATA LAYER (so mock data can be swapped for real data later)
- Define models: AdminUser (id, name, email, country, joinedAt, lastSeen, onboardingComplete,
  [other funnel steps for my app], plan: none/monthly/yearly/lifetime, subscribedAt,
  payments[], events[] newest first, streak), AdminEvent (time, type, detail),
  AdminPayment (time, amount), AdminStats (computed from the users list).
- Define an abstract AdminRepository with loadUsers(). Write MockAdminRepository that makes
  about 50 believable users with a fixed random seed, so the numbers are the same every run.
  Mock rules: ~92% finish onboarding, a smaller share reach the paywall, about half of those
  try to pay, about 65% of those subscribe; subscribers use the app more; some users churn.
  Use the REAL store prices from my config for payments (yearly pays once, monthly every 30
  days, lifetime once).
- All screens read only from the repository, never from mock code directly.

DASHBOARD SCREEN (scrollable, pastel cards)
1. Header: "Signed in as <email>" and a refresh button.
2. 2-column metric cards, each with title, big number, small sub-line and an emoji:
   - Total users (+N this week)
   - Subscribed (% of users, paying count, lifetime count)
   - Active today (active this week)
   - Revenue (last 30 days underneath)
   - Profit before store cut (revenue minus my costs; show the costs underneath)
   - Profit after store cut (assume 15%)
3. "Daily active users" bar chart, last 14 days, today highlighted, count above each bar.
4. "From joining to subscribing" funnel: Joined > Finished onboarding > [my key step] >
   Reached paywall > Tried to pay > Subscribed. Each row shows count, % of Joined and a bar.
5. Button "See all N users".

USERS SCREEN
- Search by name or email, filter chips: All / Subscribed / Free / Active today.
- Each row: avatar with initials, name, email, "Joined <date> . Seen <time ago>",
  and a colored plan pill. Newest activity first.

USER DETAIL SCREEN (tap a user)
- Header card: avatar, name, email, plan pill, country, streak, Joined / Last seen / total actions.
- "Journey" checklist with green checks: onboarding complete, [my key step], reached paywall
  (how many times), tried to pay (how many attempts), subscribed (plan and date),
  and "Paid so far: $X in N payments".
- "Today": everything they did today with times. "Earlier activity": the last ~25 events
  with emoji, title, detail and date.

COSTS (be honest about profit)
- Compute costs from real numbers: [AI cost per request x number of requests] + [fixed
  monthly fees]. Put the cost constants in ONE config file with comments.

TRACKING THE REAL EVENTS (so real data has the same shape)
- Create a small Analytics service with log(type, detail) for: opened, onboarding_done,
  [key step], paywall_view, payment_attempt, subscribed, and my main feature events.
  Store counts locally for now; later send each one to Firestore under users/{uid}/events.

QUALITY RULES
- Plain readable code, small widgets, no giant files. Run the analyzer: zero errors.
- Works on small phones: no overflow, everything scrolls, 16px side padding.
- After building, run the app on a device or simulator and look at every admin screen.
  Fix anything cut off or misaligned. Show me screenshots.
- Do not hard-code my email or prices inside widgets. Put them in config.
````

## Tips

- Tell the AI what your app's "key step" is (for Prayer Lock it was "committed devotion").
- To go real later, ask: "Replace MockAdminRepository with FirestoreAdminRepository, add
  Firestore rules that only allow [admin email], and write events from the app".
- Keep the MOCK flag. It lets you demo the panel without any backend.
