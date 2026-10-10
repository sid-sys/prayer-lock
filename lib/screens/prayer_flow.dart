import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/verses.dart';
import '../services/prayer_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

enum _Step { relationship, feeling, prayer, schedule, done }

class PrayerFlow extends StatefulWidget {
  const PrayerFlow({super.key});
  @override
  State<PrayerFlow> createState() => _PrayerFlowState();
}

class _PrayerFlowState extends State<PrayerFlow> {
  _Step _step = _Step.relationship;
  int _rel = 3;
  String? _feeling;
  String? _prayer;
  int _minutes = 0;

  Future<void> _loadPrayer() async {
    setState(() {
      _step = _Step.prayer;
      _prayer = null;
    });
    final p = await PrayerService.generate(_rel, _feeling!);
    if (mounted) setState(() => _prayer = p);
  }

  Future<void> _finish() async {
    final s = context.read<AppState>();
    _minutes = s.scheduleMinutes;
    await s.completePrayer(PrayerEntry(DateTime.now(), _rel, _feeling!), _minutes);
    if (mounted) setState(() => _step = _Step.done);
  }

  @override
  void initState() {
    super.initState();
    _minutes = context.read<AppState>().scheduleMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _step == _Step.done
            ? const SizedBox()
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(key: ValueKey(_step), child: _body()),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case _Step.relationship:
        return _relationship();
      case _Step.feeling:
        return _feelingStep();
      case _Step.prayer:
        return _prayerStep();
      case _Step.schedule:
        return _scheduleStep();
      case _Step.done:
        return _doneStep();
    }
  }

  Widget _relationship() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How is your relationship with God today?', style: serif(26)),
          const SizedBox(height: 28),
          for (var i = 1; i <= 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ChoiceChip(
                label: SizedBox(
                    width: double.infinity,
                    child: Text(PrayerService.relationshipLabels[i - 1],
                        style: const TextStyle(fontSize: 17))),
                selected: _rel == i,
                onSelected: (_) => setState(() => _rel = i),
                padding: const EdgeInsets.all(14),
              ),
            ),
          const Spacer(),
          FilledButton(
              onPressed: () => setState(() => _step = _Step.feeling),
              child: const Text('Next')),
        ],
      );

  Widget _feelingStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How are you feeling today?', style: serif(26)),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final f in PrayerService.feelings)
                ChoiceChip(
                  label: Text(f, style: const TextStyle(fontSize: 16)),
                  selected: _feeling == f,
                  onSelected: (_) => setState(() => _feeling = f),
                  padding: const EdgeInsets.all(12),
                ),
            ],
          ),
          const Spacer(),
          FilledButton(
              onPressed: _feeling == null ? null : _loadPrayer,
              child: const Text('Get my prayer')),
        ],
      );

  Widget _prayerStep() => Column(
        children: [
          Text('Read this prayer out loud', style: serif(20, color: AppColors.soft)),
          const SizedBox(height: 24),
          Expanded(
            child: _prayer == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Text(_prayer!,
                        textAlign: TextAlign.center, style: serif(24)),
                  ),
          ),
          FilledButton(
              onPressed: _prayer == null ? null : () => setState(() => _step = _Step.schedule),
              child: const Text("I've prayed today")),
        ],
      );

  Widget _scheduleStep() {
    final s = context.read<AppState>();
    return StatefulBuilder(builder: (context, set) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('When should your apps lock again?', style: serif(26)),
          const SizedBox(height: 24),
          for (final o in const [
            [0, 'Automatic'],
            [30, '30 minutes'],
            [50, '50 minutes'],
            [60, '1 hour'],
            [120, '2 hours'],
          ])
            RadioListTile<int>(
              value: o[0] as int,
              groupValue: _minutes,
              onChanged: (v) => set(() => _minutes = v!),
              title: Text(o[1] as String),
            ),
          const Spacer(),
          FilledButton(
            onPressed: () async {
              await s.setSchedule(_minutes);
              await _finish();
            },
            child: const Text('Unlock my apps'),
          ),
        ],
      );
    });
  }

  Widget _doneStep() {
    final s = context.watch<AppState>();
    final v = verseOfDay();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.local_fire_department, size: 80, color: AppColors.gold),
        Text('${s.streak}', style: serif(64)),
        Text(s.streak == 1 ? 'day streak' : 'day streak',
            style: const TextStyle(color: AppColors.soft, fontSize: 18)),
        const SizedBox(height: 32),
        Text('"${v.text}"', textAlign: TextAlign.center, style: serif(22)),
        const SizedBox(height: 8),
        Text(v.ref, style: const TextStyle(color: AppColors.gold)),
        const SizedBox(height: 40),
        FilledButton(
            onPressed: () => Navigator.pop(context), child: const Text('Amen')),
      ],
    );
  }
}
