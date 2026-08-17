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

/// Formats a shift time range or single time into AM/PM format (e.g., "08:00 - 17:00" → "08:00 AM - 05:00 PM")
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
        return '$start - $end';
      }
    }
  } else if (trimmed.contains('-') && !trimmed.contains('T')) {
    final parts = trimmed.split('-');
    if (parts.length == 2 && parts[0].contains(':') && parts[1].contains(':')) {
      final start = formatTime(parts[0]);
      final end = formatTime(parts[1]);
      if (start != '—' && end != '—') {
        return '$start - $end';
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

/// Formats total hours into "Xh Ym" or "Xm" (e.g., 1.8 -> 1h 48m)
String formatDurationHours(num? totalHours) {
  if (totalHours == null || totalHours == 0) return '0m';
  final totalMinutes = (totalHours.abs() * 60).round();
  return formatDurationMinutes(totalMinutes);
}
