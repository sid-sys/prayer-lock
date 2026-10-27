import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../theme.dart';

Future<void> emailSupport(BuildContext context, {String subject = 'Prayer Lock support'}) async {
  final uri = Uri.parse('mailto:$kContactEmail?subject=${Uri.encodeComponent(subject)}');
  final ok = await launchUrl(uri).catchError((_) => false);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Write to $kContactEmail')));
  }
}

class _Section {
  final String title;
  final String body;
  const _Section(this.title, this.body);
}

const _updated = 'Last updated: October 2026';

const _privacy = <_Section>[
  _Section('Who we are',
      '$kDeveloperName ("we", "us") makes Prayer Lock. Questions about this policy: $kContactEmail.'),
  _Section('What we collect',
      'Account: your email address, or your Google or Apple sign in ID. If you give your first name in the app, or sign in with Google or Apple, your name is saved with your account.\n\n'
      'Prayer check-ins: how close you feel to God, how you feel, and the prayers shown to you. These are stored on your phone.\n\n'
      'Locked apps: the list of apps you choose to lock. It is stored on your phone.\n\n'
      'Subscription status and simple usage events (for example: finished onboarding, saw the paywall, started a trial). We use these to run and improve the app.'),
  _Section('How AI prayers are made',
      'To write a prayer, our server sends only your closeness level and the feeling you picked (for example "close" and "grateful") to OpenAI. We do not send your name, email or any account details. If you choose "Keep it private", no feeling is sent.'),
  _Section('Android: Accessibility service',
      'Prayer Lock uses the Android Accessibility service for one purpose: to notice when you open an app that YOU chose to lock, so we can show the prayer screen first. It does not read what is on your screen, does not read text you type or passwords, and does not collect or share any data from other apps.'),
  _Section('iPhone: Screen Time',
      'On iPhone, app locking uses Apple\'s Screen Time (Family Controls) tools. Which apps you pick stays on your device and is not readable by us.'),
  _Section('Your progress report',
      'Prayer Lock counts how often it paused you before a locked app, how you ended each pause, and your prayers. These counts stay on your phone. On Android, if you turn on "usage access", Prayer Lock also reads how long you spend in the apps you chose to lock, so it can show your time and a before-and-after comparison. We do not send this to our servers, and we never read what is on your screen. Time "reclaimed" is an estimate, not a measurement. You can delete this history any time in Insights, and you can turn usage access off in your phone settings. On iPhone, Apple does not share per-app time with apps, so we do not collect it.'),
  _Section('Notifications',
      'We send morning and night prayer reminders at the times you choose. Notifications never show your prayers or feelings. You can turn them off in Profile.'),
  _Section('Who we share data with',
      'We do not sell your data. We use trusted service providers to run the app: Google Firebase (sign in and hosting), OpenAI (writing prayers, as described above), and Google Play or the Apple App Store (payments, which we never see in full).'),
  _Section('Keeping and deleting your data',
      'You can delete your account at any time in Profile > Delete account. This removes your account and the data on your phone. You can also email $kContactEmail and we will help.'),
  _Section('Children',
      'Prayer Lock is not directed to children under 13.'),
  _Section('Changes',
      'If we change this policy we will update the date above and, for big changes, tell you in the app.'),
];

const _terms = <_Section>[
  _Section('Using Prayer Lock',
      'By using Prayer Lock you agree to these terms. You must be old enough to agree to them where you live. Use the app only for lawful, personal use.'),
  _Section('Free trial and subscription',
      'New subscribers get a 7 day free trial. After the trial your plan renews automatically (monthly or yearly, as you chose) unless you cancel before the trial ends. Prices are shown before you start. Payment is taken by Google Play or the Apple App Store, and renewal and cancellation are managed in your store account settings as well as in Profile > Plan. Refunds follow the store\'s rules.\n\nLifetime plan: if offered, Lifetime is a one-time payment for access to Prayer Lock for as long as the app is available. It has no free trial and does not renew. If we ever stop running the app, we will tell you in advance.'),
  _Section('Not professional advice',
      'Prayers, verses and check-ins are for spiritual encouragement only. They are not medical, mental health or crisis advice. If you are in crisis, please contact local emergency services or a trusted professional.'),
  _Section('AI generated prayers',
      'Prayers are written by an AI model and may sometimes be imperfect. You are free to pray in your own words.'),
  _Section('App locking',
      'App locking depends on permissions you give your phone (Accessibility on Android, Screen Time on iPhone). It is a helper for your own habits and is not guaranteed to block every use. You can turn it off any time.'),
  _Section('Your account',
      'Keep your sign in details safe. You can delete your account in Profile at any time.'),
  _Section('Limits of liability',
      'The app is provided "as is". To the extent the law allows, $kDeveloperName is not responsible for indirect losses from using the app.'),
  _Section('Contact', '$kDeveloperName - $kContactEmail'),
];

enum LegalDoc { privacy, terms }

class LegalScreen extends StatelessWidget {
  final LegalDoc doc;
  const LegalScreen(this.doc, {super.key});

  @override
  Widget build(BuildContext context) {
    final isPrivacy = doc == LegalDoc.privacy;
    final sections = isPrivacy ? _privacy : _terms;
    return Scaffold(
      appBar: AppBar(title: Text(isPrivacy ? 'Privacy Policy' : 'Terms of Service', style: h(20))),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
          children: [
            Text(_updated, style: h(13, color: AppColors.soft, w: FontWeight.w500)),
            const SizedBox(height: 16),
            for (final s in sections) ...[
              Text(s.title, style: h(18)),
              const SizedBox(height: 6),
              Text(s.body, style: h(15, w: FontWeight.w500).copyWith(height: 1.45)),
              const SizedBox(height: 20),
            ],
            OutlinedButton.icon(
              onPressed: () => emailSupport(context),
              icon: const Icon(Icons.mail_outline),
              label: const Text(kContactEmail),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contact and about page.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contact us', style: h(20))),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [

            Center(child: Text('Prayer Lock', style: h(26))),
            Center(
              child: Text('by $kDeveloperName',
                  style: h(15, color: AppColors.soft, w: FontWeight.w500)),
            ),
            const SizedBox(height: 26),
            Card(
              child: ListTile(
                leading: const Text('✉️', style: TextStyle(fontSize: 26)),
                title: const Text('Email us'),
                subtitle: const Text(kContactEmail),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => emailSupport(context),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Text('🛠️', style: TextStyle(fontSize: 26)),
                title: const Text('Report a problem'),
                subtitle: const Text('Tell us what went wrong'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => emailSupport(context, subject: 'Prayer Lock problem report'),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Text('💡', style: TextStyle(fontSize: 26)),
                title: const Text('Share an idea'),
                subtitle: const Text('We read every message'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => emailSupport(context, subject: 'Prayer Lock idea'),
              ),
            ),
            const SizedBox(height: 26),
            Center(
              child: Text('© ${DateTime.now().year} $kDeveloperName',
                  style: h(13, color: AppColors.soft, w: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
