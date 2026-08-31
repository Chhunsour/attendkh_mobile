import 'package:intl/intl.dart';

/// Formats a date string (yyyy-MM-dd) → "08 Jul 2026"
String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.trim().isEmpty) return '—';
  try {
    final dt = DateTime.parse(dateStr);
    return DateFormat('dd MMM yyyy').format(dt);
  } catch (_) {
    return dateStr;
  }
}

/// Formats a time string (HH:mm:ss or HH:mm or full ISO) → "09:30 AM"
String formatTime(String? timeStr) {
  if (timeStr == null || timeStr.trim().isEmpty) return '—';
  try {
    final trimmed = timeStr.trim();
    // Handle bare time strings like "09:30:00" or "09:30" or "9:30"
    final parts = trimmed.split(':');
    if (parts.length >= 2 && !trimmed.contains('T') && !trimmed.contains('-')) {
      final hour = int.parse(parts[0].trim());
      final minute = int.parse(parts[1].trim());
      final dt = DateTime(0, 1, 1, hour, minute);
      return DateFormat('hh:mm a').format(dt);
    }
    // Handle full ISO datetime strings
    final dt = DateTime.parse(trimmed).toLocal();
    return DateFormat('hh:mm a').format(dt);
  } catch (_) {
    return timeStr;
  }
}

/// A shift window is read at a glance, so it drops the padding zero and uses
/// an en dash: "08:00 - 17:00" → "8:00 AM – 5:00 PM".
String _shiftRange(String start, String end) =>
    '$start – $end'.replaceAll(RegExp(r'\b0(?=\d:)'), '');

/// Formats a shift time range or single time into AM/PM format
String formatShiftTime(String? shiftStr) {
  if (shiftStr == null || shiftStr.trim().isEmpty) return 'No shift today';
  final trimmed = shiftStr.trim();
  if (trimmed.toLowerCase().contains('no shift')) return trimmed;

  if (trimmed.contains(' - ')) {
    final parts = trimmed.split(' - ');
    if (parts.length == 2) {
      final start = formatTime(parts[0]);
      final end = formatTime(parts[1]);
      if (start != '—' && end != '—') {
        return _shiftRange(start, end);
      }
    }
  } else if (trimmed.contains('-') && !trimmed.contains('T')) {
    final parts = trimmed.split('-');
    if (parts.length == 2 && parts[0].contains(':') && parts[1].contains(':')) {
      final start = formatTime(parts[0]);
      final end = formatTime(parts[1]);
      if (start != '—' && end != '—') {
        return _shiftRange(start, end);
      }
    }
  }

  return formatTime(trimmed);
}

/// Formats a full ISO datetime string → "08 Jul 2026, 09:30 AM"
String formatDateTime(String? dateTimeStr) {
  if (dateTimeStr == null || dateTimeStr.trim().isEmpty) return '—';
  try {
    final dt = DateTime.parse(dateTimeStr).toLocal();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  } catch (_) {
    return dateTimeStr;
  }
}

/// Formats a date range → "01 Jul 2026 → 05 Jul 2026"
String formatDateRange(String? start, String? end) {
  return '${formatDate(start)} → ${formatDate(end)}';
}

/// Formats total minutes into "Xh Ym" or "Xm" (e.g., 110 -> 1h 50m)
String formatDurationMinutes(int? totalMinutes) {
  if (totalMinutes == null || totalMinutes == 0) return '0m';
  final m = totalMinutes.abs();
  final hours = m ~/ 60;
  final minutes = m % 60;
  if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
  if (hours > 0) return '${hours}h';
  return '${minutes}m';
}

/// Formats total seconds into "Xh Ym Zs", "Xm Ys", or "Xs" (e.g., 504 -> 8m 24s)
String formatDurationSeconds(int? totalSeconds) {
  if (totalSeconds == null || totalSeconds <= 0) return '0s';
  final s = totalSeconds.abs();
  final hours = s ~/ 3600;
  final minutes = (s % 3600) ~/ 60;
  final seconds = s % 60;
  if (hours > 0) {
    return '${hours}h ${minutes}m ${seconds}s';
  }
  if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  }
  return '${seconds}s';
}

/// Formats total hours into "Xh Ym Zs", "Xm Ys", or "Xs" (e.g., 0.14 -> 8m 24s)
String formatDurationHoursWithSeconds(num? totalHours) {
  if (totalHours == null || totalHours <= 0) return '0s';
  final totalSeconds = (totalHours.abs() * 3600).round();
  return formatDurationSeconds(totalSeconds);
}

/// Formats total hours into "Xh Ym" or "Xm" (e.g., 1.8 -> 1h 48m)
String formatDurationHours(num? totalHours) {
  if (totalHours == null || totalHours == 0) return '0m';
  final totalMinutes = (totalHours.abs() * 60).round();
  return formatDurationMinutes(totalMinutes);
}

/// The two halves of a shift range like "08:00 - 17:00", as minutes from
/// midnight. Null when the string is not a range we can read (a full ISO date
/// splits into more than two pieces, which is the null case).
List<int>? _shiftMinutes(String? shiftStr) {
  if (shiftStr == null || shiftStr.trim().isEmpty) return null;
  final parts = shiftStr.trim().split(RegExp(r'\s*-\s*'));
  if (parts.length != 2) return null;
  final out = <int>[];
  for (final part in parts) {
    final hm = part.split(':');
    if (hm.length < 2) return null;
    final h = int.tryParse(hm[0].trim());
    final m = int.tryParse(hm[1].trim());
    if (h == null || m == null) return null;
    out.add(h * 60 + m);
  }
  return out;
}

/// Minutes-from-midnight of the START of a shift range like "08:00 - 17:00".
int? shiftStartMinutes(String? shiftStr) => _shiftMinutes(shiftStr)?.first;

/// Minutes-from-midnight of the END of a shift range like "08:00 - 17:00".
/// Returns null when the string is not a range we can read.
int? shiftEndMinutes(String? shiftStr) => _shiftMinutes(shiftStr)?.last;

/// Minutes still left on the shift window, or null when the shift end is
/// unreadable or already past — i.e. non-null means "clocking out now is
/// early". The server recomputes this on clock-out and has the last word.
int? minutesUntilShiftEnd(String? shiftStr, {DateTime? now}) {
  final end = shiftEndMinutes(shiftStr);
  if (end == null) return null;
  final t = now ?? DateTime.now();
  final left = end - (t.hour * 60 + t.minute);
  return left > 0 ? left : null;
}

/// Late only once the grace period after the shift start has run out — 8:05
/// on an 8:00 shift with 15 minutes of grace is still on time.
/// [fallback] is used when the shift window is unreadable (no shift today,
/// or a shape we cannot parse), so the server keeps the last word there.
bool isLateNow(
  String? shiftStr,
  int graceMinutes, {
  DateTime? now,
  bool fallback = false,
}) {
  final start = shiftStartMinutes(shiftStr);
  if (start == null) return fallback;
  final t = now ?? DateTime.now();
  return t.hour * 60 + t.minute > start + graceMinutes;
}
