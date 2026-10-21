/// App-wide settings.
///
/// Build the real app with:  flutter build apk --dart-define=MOCK=false
const kDeveloperName = 'Tetra Developers';
const kContactEmail = 'tetraheaddevelopers@gmail.com';

/// Only this Google account can open the admin panel in the real build.
const kAdminEmail = 'sidharthbabu9@gmail.com';

/// Mock build: the admin panel is open to everyone and shows made-up data.
/// Turn off for the real release.
const bool kMockBuild = bool.fromEnvironment('MOCK', defaultValue: true);

/// Fills the app with 9 days of sample prayers (for store screenshots).
/// Not saved to the phone. Run with:  --dart-define=DEMO=true
const bool kDemoData =
    bool.fromEnvironment('DEMO', defaultValue: false) || kShotMode;

/// Screenshot build (used by GitHub Actions on an iPhone simulator).
/// The app opens straight on the screen named in the saved setting "shot",
/// with sample data. Never turn this on in a release build.
/// Build with:  --dart-define=SHOTMODE=true
const bool kShotMode = bool.fromEnvironment('SHOTMODE', defaultValue: false);

/// Show "Continue with Apple" on Android too, so it can be tested without an
/// iPhone. It opens Apple's sign in page in the browser (Firebase web flow).
/// In the real release (MOCK=false) Apple sign in is only shown on iPhone.
const bool kAppleOnAndroid =
    bool.fromEnvironment('APPLE_ON_ANDROID', defaultValue: kMockBuild);
