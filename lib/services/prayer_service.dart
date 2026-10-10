import 'package:cloud_functions/cloud_functions.dart';

class PrayerService {
  static const relationshipLabels = [
    'Distant',
    'Struggling',
    'Okay',
    'Close',
    'Very close',
  ];

  static const feelings = [
    'Grateful',
    'Anxious',
    'Tired',
    'Hopeful',
    'Sad',
    'Stressed',
    'Peaceful',
    'Lost',
  ];

  static Future<String> generate(int relationship, String feeling) async {
    try {
      final res = await FirebaseFunctions.instance
          .httpsCallable('generatePrayer',
              options: HttpsCallableOptions(timeout: const Duration(seconds: 25)))
          .call({'relationship': relationship, 'feeling': feeling});
      final t = (res.data['prayer'] as String?)?.trim();
      if (t != null && t.isNotEmpty) return t;
    } catch (_) {}
    return _fallback(feeling);
  }

  static String _fallback(String feeling) =>
      'Dear God, today I feel ${feeling.toLowerCase()}. '
      'I give this moment to You. Hold me, guide my steps, and help me use my '
      'time with purpose. Thank You for Your love that never leaves me. Amen.';
}
