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
    // Handle bare time strings like "09:30:00" or "09:30"
    final parts = timeStr.split(':');
    if (parts.length >= 2 && !timeStr.contains('T') && !timeStr.contains('-')) {
      final hour   = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(0, 1, 1, hour, minute);
      return DateFormat('hh:mm a').format(dt);
    }
    // Handle full ISO datetime strings
    final dt = DateTime.parse(timeStr).toLocal();
    return DateFormat('hh:mm a').format(dt);
  } catch (_) {
    return timeStr;
  }
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
