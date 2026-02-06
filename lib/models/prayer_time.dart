import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerTime {
  PrayerTime({
    required this.name,
    required this.start,
    required this.end,
  });

  final String name;
  TimeOfDay start;
  TimeOfDay end;

  int get startMinutes => start.hour * 60 + start.minute;
  int get endMinutes => end.hour * 60 + end.minute;

  Map<String, String> toMap() {
    return {
      'name': name,
      'start': _formatTime(start),
      'end': _formatTime(end),
    };
  }

  static PrayerTime fromMap(Map<String, String> map) {
    return PrayerTime(
      name: map['name'] ?? '',
      start: _parseTime(map['start'] ?? '06:00'),
      end: _parseTime(map['end'] ?? '06:10'),
    );
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static List<PrayerTime> defaultTimes() {
    return [
      PrayerTime(name: 'Fajr', start: const TimeOfDay(hour: 6, minute: 30), end: const TimeOfDay(hour: 6, minute: 40)),
      PrayerTime(name: 'Zuhr', start: const TimeOfDay(hour: 12, minute: 30), end: const TimeOfDay(hour: 12, minute: 40)),
      PrayerTime(name: 'Asr', start: const TimeOfDay(hour: 15, minute: 30), end: const TimeOfDay(hour: 15, minute: 40)),
      PrayerTime(name: 'Maghrib', start: const TimeOfDay(hour: 18, minute: 30), end: const TimeOfDay(hour: 18, minute: 40)),
      PrayerTime(name: 'Isha', start: const TimeOfDay(hour: 20, minute: 0), end: const TimeOfDay(hour: 20, minute: 10)),
    ];
  }

  static Future<List<PrayerTime>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('prayerTimes');
    if (saved == null || saved.isEmpty) {
      return defaultTimes();
    }

    return saved.map((entry) {
      final parts = entry.split('|');
      return PrayerTime(
        name: parts[0],
        start: _parseTime(parts[1]),
        end: _parseTime(parts[2]),
      );
    }).toList();
  }

  static Future<void> saveAll(List<PrayerTime> times) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = times
        .map((time) => '${time.name}|${_formatTime(time.start)}|${_formatTime(time.end)}')
        .toList();
    await prefs.setStringList('prayerTimes', payload);
  }
}
