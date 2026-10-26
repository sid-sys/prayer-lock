import 'package:flutter/material.dart';
import '../services/blocker_service.dart';
import '../theme.dart';

/// Google Play "prominent disclosure" for the Accessibility service.
/// Shown before the phone's Accessibility settings open. The person must tap
/// "Agree and continue". Keep the words in sync with the Play Console form.
Future<void> askAccessibility(BuildContext context) async {
  final agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text('Prayer Lock needs the Accessibility service', style: h(20)),
      content: SingleChildScrollView(
        child: Text(
          'To lock the apps YOU choose, Prayer Lock uses Android\'s Accessibility service.\n\n'
          'What it does: it checks only which app is open in front, so Prayer Lock can show your prayer when you open an app you chose to lock.\n\n'
          'What it does not do: it does not read your screen, messages, passwords or anything you type. It does not collect, store or share any data from it.\n\n'
          'You can turn it off at any time in Settings > Accessibility.',
          style: h(15, w: FontWeight.w500).copyWith(height: 1.4),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('No thanks', style: h(15, color: AppColors.soft)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Agree and continue'),
        ),
      ],
    ),
  );
  if (agreed == true) await BlockerService.requestPermission();
}
