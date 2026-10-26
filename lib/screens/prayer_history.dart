import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/mood_face.dart';

/// One saved prayer as a card in a list.
class PrayerTile extends StatelessWidget {
  final PrayerEntry entry;
  const PrayerTile(this.entry, {super.key});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => showPrayerSheet(context, e),
        leading: Text(e.kind == 'morning' ? '🌅' : e.kind == 'night' ? '🌙' : '🔒',
            style: const TextStyle(fontSize: 26)),
        title: Text(e.feeling == 'Private' ? 'Private prayer' : 'Felt ${e.feeling.toLowerCase()}',
            style: h(16)),
        subtitle: Text('${moodWord((e.relationship - 1) / 4)} with God',
            style: const TextStyle(color: AppColors.soft)),
        trailing: Text(DateFormat('MMM d').format(e.date),
            style: const TextStyle(color: AppColors.soft)),
      ),
    );
  }
}

/// Open one saved prayer in a sheet.
void showPrayerSheet(BuildContext context, PrayerEntry e) {
  final kindName = e.kind == 'morning'
      ? 'Morning prayer 🌅'
      : e.kind == 'night'
          ? 'Night prayer 🌙'
          : 'Prayer before an app 🔒';
  final mood = moodWord((e.relationship - 1) / 4);
  Widget chip(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(18)),
        child: Text(t, style: h(14)),
      );
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                  color: AppColors.soft.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(height: 18),
          Text(kindName, style: h(24)),
          const SizedBox(height: 4),
          Text(DateFormat('EEEE, MMM d · h:mm a').format(e.date),
              style: h(14, color: AppColors.soft, w: FontWeight.w500)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            chip('💛 $mood with God', AppColors.yellow),
            chip(e.feeling == 'Private' ? '🤍 Kept private' : '✨ Felt ${e.feeling.toLowerCase()}',
                AppColors.mint),
          ]),
          const SizedBox(height: 22),
          if (e.prayer != null && e.prayer!.isNotEmpty)
            Text(e.prayer!, style: serif(22))
          else
            Text('The words of this prayer were not saved. New prayers are saved here.',
                style: h(15, color: AppColors.soft, w: FontWeight.w500)),
        ],
      ),
    ),
  );
}

/// Every prayer, newest first, grouped by month.
class PrayerHistoryScreen extends StatelessWidget {
  const PrayerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = context.watch<AppState>().history.reversed.toList();
    final rows = <Widget>[];
    String? month;
    for (final e in list) {
      final m = DateFormat('MMMM yyyy').format(e.date);
      if (m != month) {
        month = m;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
          child: Text(m, style: h(16, color: AppColors.soft)),
        ));
      }
      rows.add(PrayerTile(e));
    }
    return Scaffold(
      appBar: AppBar(title: Text('All prayers', style: h(20))),
      body: list.isEmpty
          ? Center(
              child: Text('No prayers yet. Your first one will show here.',
                  style: h(15, color: AppColors.soft, w: FontWeight.w500)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Text('${list.length} prayers. Tap one to read it.',
                      style: h(13, color: AppColors.soft, w: FontWeight.w600)),
                ),
                ...rows,
              ],
            ),
    );
  }
}
