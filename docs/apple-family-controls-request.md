# Asking Apple for the "Family Controls" permission

Prayer Lock needs Apple's **Screen Time** tools to lock apps on iPhone. Apple calls the permission
**Family Controls**. You can test it on your own iPhone without approval (the "Development" version).
To send the app to friends with TestFlight, or to the App Store, Apple must approve the
**Family Controls (Distribution)** version first.

## Before you send the request

1. Your **Apple Developer account** must be paid and active.
2. Make the **app record** in App Store Connect (name: Prayer Lock, bundle ID below).
3. Have your **Team ID** ready (Apple Developer > Membership details).
4. Optional but helpful: a **30 to 60 second video** that shows the idea (the flow in the app).
   Apple sometimes asks for it.

## Where to send it

Open the Apple Developer website, sign in, and look for **Contact Us > Capability Requests**
(or search "Family Controls distribution entitlement request").
The form page is usually: https://developer.apple.com/contact/request/family-controls-distribution
(If this link has moved, use the search above.)

If there is no form, email Apple Developer Support from your Developer account page
(Contact Us > Membership and Account) and paste the text below.

## Names to use

| Item | Value |
|---|---|
| Developer name | Tetra Developers |
| Contact email | tetraheaddevelopers@gmail.com |
| App name | Prayer Lock |
| Main app bundle ID | com.coreinteractive.prayerLock |
| Extension bundle IDs | com.coreinteractive.prayerLock.ActivityMonitor, com.coreinteractive.prayerLock.ShieldConfiguration, com.coreinteractive.prayerLock.ShieldAction |
| Team ID | (put yours here) |

The extension names are the ones I will create. Keep them the same in the form.

---

## Text to paste (copy everything below)

**Subject:** Request for Family Controls (Distribution) entitlement for "Prayer Lock"

Hello Apple Developer Team,

My name is Sidharth Babu and I develop apps as **Tetra Developers** (contact: tetraheaddevelopers@gmail.com).
I would like to request the **Family Controls (Distribution)** entitlement for my app **Prayer Lock**
and its app extensions.

**App:** Prayer Lock (iPhone)
**Team ID:** [your Team ID]
**Main app bundle ID:** com.coreinteractive.prayerLock
**Extensions:** com.coreinteractive.prayerLock.ActivityMonitor (Device Activity Monitor),
com.coreinteractive.prayerLock.ShieldConfiguration, com.coreinteractive.prayerLock.ShieldAction

**What the app does**
Prayer Lock is a faith and digital wellbeing app for adults. A person chooses the apps that pull
their attention away (for example social media). When they try to open one of those apps, Prayer Lock
asks them to take a short moment to pray first. After a short prayer they can use the app again for a
time they choose, such as 30 minutes or 1 hour.

**Why we need Family Controls**
- We use `AuthorizationCenter` with **individual** authorization. The user is managing their own phone.
  This is not a parental control or monitoring tool.
- We use `FamilyActivityPicker` so the user can choose which apps and categories to pause.
- We use `ManagedSettings` shields to cover only those chosen apps, and `ShieldConfiguration` /
  `ShieldAction` to show our prayer message and an "Open Prayer Lock" button.
- We use `DeviceActivity` to put the shield back when the user's chosen time ends.

**How we treat data**
- The app tokens that Apple gives us stay on the device. We never read app names, and we never
  send the choices to a server.
- We do not use Screen Time information for ads, analytics, or tracking.
- The user can turn blocking off at any time, inside the app or in iOS Settings > Screen Time.
- Our privacy policy explains this in plain words.

I am happy to provide a demo video, screenshots, or a TestFlight build for review.

Thank you for your time.

Sidharth Babu
Tetra Developers
tetraheaddevelopers@gmail.com

---

## After Apple says yes

1. In Apple Developer > Identifiers, turn on **Family Controls** for the main app and all 3 extensions.
2. Make new provisioning profiles (I can do this through the App Store Connect API).
3. Build with GitHub Actions and upload to **TestFlight**.
4. Send the TestFlight link to your friend.

How long it takes: Apple does not say. It can be days or a few weeks, so send the request early.
