import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/holidays_repository.dart';
import 'package:mpg_hr_mobile_app/providers/holidays_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

class HolidaysScreen extends ConsumerWidget {
  const HolidaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidaysAsync = ref.watch(holidaysProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Holidays')),
      body: holidaysAsync.when(
        data: (holidays) {
          if (holidays.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.celebration_outlined, size: 64, color: AppColors.grey300),
                  SizedBox(height: 16),
                  Text('No holidays listed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey500)),
                  SizedBox(height: 8),
                  Text('Holidays will appear here when added by your admin.', style: TextStyle(fontSize: 13, color: AppColors.grey400), textAlign: TextAlign.center),
                ],
              ),
            );
          }

          // Group by month
          final grouped = <String, List<Holiday>>{};
          for (final h in holidays) {
            try {
              final dt = DateTime.parse(h.date);
              final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
              grouped.putIfAbsent(key, () => []).add(h);
            } catch (_) {
              grouped.putIfAbsent('Other', () => []).add(h);
            }
          }

          final sortedKeys = grouped.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final key = sortedKeys[index];
              final items = grouped[key]!;
              return _MonthSection(monthKey: key, holidays: items);
            },
          );
        },
        loading: () => const LoadingIndicator(message: 'Loading holidays...'),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.grey400),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(holidaysProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  final String monthKey;
  final List<Holiday> holidays;

  const _MonthSection({required this.monthKey, required this.holidays});

  String get _monthName {
    try {
      final parts = monthKey.split('-');
      final m = int.parse(parts[1]);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[m - 1]} ${parts[0]}';
    } catch (_) {
      return monthKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(_monthName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.grey700)),
        const SizedBox(height: 8),
        ...holidays.map((h) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_dayOfMonth(h.date), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    if (h.description != null) ...[
                      const SizedBox(height: 2),
                      Text(h.description!, style: const TextStyle(fontSize: 12, color: AppColors.grey500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              if (h.isRecurring == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(4)),
                  child: const Text('Annual', style: TextStyle(fontSize: 10, color: AppColors.info)),
                ),
            ],
          ),
        )),
      ],
    );
  }

  String _dayOfMonth(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}';
    } catch (_) {
      return '?';
    }
  }
}