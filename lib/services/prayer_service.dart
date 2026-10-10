import 'package:cloud_functions/cloud_functions.dart';

class PrayerService {
  static const relationshipLabels = [
    'Distant',
    'Struggling',
    'Okay',
    'Close',
    'Very close',
  ];

  /// (emoji, name). The name is sent to the server, so keep it in sync
  /// with the list in functions/index.js.
  static const feelings = [
    ('🙏', 'Grateful'),
    ('😰', 'Anxious'),
    ('😴', 'Tired'),
    ('🌈', 'Hopeful'),
    ('😢', 'Sad'),
    ('🤯', 'Stressed'),
    ('🕊️', 'Peaceful'),
    ('🧭', 'Lost'),
  ];

  static Future<String> generate(int relationship, String feeling, String kind) async {
    try {
      final res = await FirebaseFunctions.instance
          .httpsCallable('generatePrayer',
              options: HttpsCallableOptions(timeout: const Duration(seconds: 25)))
          .call({'relationship': relationship, 'feeling': feeling, 'kind': kind});
      final t = (res.data['prayer'] as String?)?.trim();
      if (t != null && t.isNotEmpty) return t;
    } catch (_) {}
    return _fallback(feeling, kind);
  }

  static String _fallback(String feeling, String kind) {
    final f = feeling.isEmpty ? '' : ' Today I feel ${feeling.toLowerCase()}.';
    switch (kind) {
      case 'morning':
        return 'Good morning, Jesus.$f I give You this new day. Guide my steps, '
            'guard my heart, and help me love the people I meet. Amen.';
      case 'night':
        return 'Thank You, Jesus, for this day.$f I lay my worries at Your feet. '
            'Forgive me where I fell short, and give me peaceful rest tonight. Amen.';
      default:
        return 'Dear God,$f I give this moment to You. Hold me, guide my steps, '
            'and help me use my time with purpose. Thank You for Your love. Amen.';
    }
  }
}
