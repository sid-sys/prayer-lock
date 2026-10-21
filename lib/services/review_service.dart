import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import '../config.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Asks for a rating: once in onboarding, then once a week until the person
/// gives a rating.
///
/// Neither store tells an app if someone really rated. So we show our own
/// small star sheet first. When the person taps stars and Submit, we count
/// that as a rating and stop asking. With 4 or 5 stars we also open the real
/// store review box (Google Play or App Store). "Not now" asks again in 7 days.
class ReviewService {
  static bool _open = false;

  /// Show the sheet if a rating is due (never rated, not asked in 7 days).
  static Future<void> maybeAsk(BuildContext context, AppState s) async {
    if (kShotMode || !s.reviewDue) return;
    await ask(context, s);
  }

  /// Show the sheet now.
  static Future<void> ask(BuildContext context, AppState s) async {
    if (_open) return;
    _open = true;
    await s.markReviewAsked();
    if (!context.mounted) {
      _open = false;
      return;
    }
    final stars = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ReviewSheet(),
    );
    _open = false;
    if (stars == null || stars == 0) return; // "Not now": ask again next week
    await s.markRated(stars);
    s.logEvent('rated_$stars');
    if (stars >= 4) {
      try {
        final r = InAppReview.instance;
        if (await r.isAvailable()) await r.requestReview();
      } catch (_) {}
    }
  }
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet();
  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _stars = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Pic('logo', size: 64),
            const SizedBox(height: 10),
            Text('Enjoying Prayer Lock?', style: h(24)),
            const SizedBox(height: 6),
            Text(
              'A quick rating helps other people find a calmer way to start with God 🙏',
              textAlign: TextAlign.center,
              style: h(14, color: AppColors.soft, w: FontWeight.w500),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    iconSize: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    onPressed: () => setState(() => _stars = i),
                    icon: Icon(
                      i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: i <= _stars ? const Color(0xFFFFB400) : Colors.black38,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: Colors.black26),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    onPressed: () => Navigator.pop(context, 0),
                    child: const Text('Not now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: _stars == 0 ? null : () => Navigator.pop(context, _stars),
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
