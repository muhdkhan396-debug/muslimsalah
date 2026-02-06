import 'dart:async';

import 'package:flutter/material.dart';

import '../models/prayer_time.dart';
import '../services/silent_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<PrayerTime>> _loadFuture;
  List<PrayerTime> _prayerTimes = [];
  bool _hasPolicyAccess = true;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

  Future<List<PrayerTime>> _loadData() async {
    final times = await PrayerTime.loadAll();
    final hasAccess = await SilentService.hasPolicyAccess();
    if (mounted) {
      setState(() {
        _prayerTimes = times;
        _hasPolicyAccess = hasAccess;
      });
    }
    _ticker?.cancel();
    _ticker = SilentService.startForegroundTicker(times);
    return times;
  }

  Future<void> _pickTime(int index, bool isStart) async {
    final initial = isStart ? _prayerTimes[index].start : _prayerTimes[index].end;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _prayerTimes[index].start = picked;
        } else {
          _prayerTimes[index].end = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    await PrayerTime.saveAll(_prayerTimes);
    _ticker?.cancel();
    _ticker = SilentService.startForegroundTicker(_prayerTimes);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prayer times saved.')),
      );
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Widget _buildPermissionBanner() {
    if (_hasPolicyAccess) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.amber.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Permission required',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Allow Do Not Disturb access so the app can toggle silent mode during prayer times.',
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await SilentService.openPolicySettings();
              },
              child: const Text('Grant Access'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masjid Silent Mode'),
      ),
      body: FutureBuilder<List<PrayerTime>>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildPermissionBanner(),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _prayerTimes.length,
                  separatorBuilder: (_, __) => const Divider(height: 32),
                  itemBuilder: (context, index) {
                    final prayer = _prayerTimes[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prayer.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _TimeField(
                                label: 'Start',
                                time: prayer.start,
                                onTap: () => _pickTime(index, true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _TimeField(
                                label: 'End',
                                time: prayer.end,
                                onTap: () => _pickTime(index, false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Save Prayer Times'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatted = time.format(context);
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(formatted),
      ),
    );
  }
}
