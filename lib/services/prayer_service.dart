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

  /// Sample prayer for screenshots.
  static const sample =
      'Dear God, today I feel grateful. I give this moment to You. I am weak, but You are strong. Give me the strength to put You first, to say no to what pulls me away, and to use my time with purpose. Thank You for Your love. Amen.';

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
        return 'Good morning, Jesus.$f I give You this new day. Guide my steps and '
            'guard my heart. Give me the strength to follow You and to love the people I meet today. Amen.';
      case 'night':
        return 'Thank You, Jesus, for this day.$f I lay my worries at Your feet. '
            'Forgive me where I fell short, and give me the strength to forgive, let go and rest in You tonight. Amen.';
      default:
        return 'Dear God,$f I give this moment to You. I am weak, but You are strong. '
            'Give me the strength to put You first, to say no to what pulls me away, and to use my time with purpose. Thank You for Your love. Amen.';
    }
  }
}
