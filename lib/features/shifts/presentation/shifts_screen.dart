import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/shifts/data/shifts_repository.dart';
import 'package:mpg_hr_mobile_app/features/shifts/presentation/shifts_provider.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/loading_indicator.dart';

class ShiftsScreen extends ConsumerWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(myShiftsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Shifts')),
      body: shiftsAsync.when(
        data: (shifts) {
          if (shifts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule_outlined, size: 64, color: AppColors.grey300),
                  SizedBox(height: 16),
                  Text('No shifts assigned', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey500)),
                  SizedBox(height: 8),
                  Text('Your assigned shifts will appear here.', style: TextStyle(fontSize: 13, color: AppColors.grey400)),
                ],
              ),
            );
          }

          final grouped = <String, List<AssignedShift>>{};
          for (final s in shifts) {
            final key = s.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
            grouped.putIfAbsent(key, () => []).add(s);
          }
          final sorted = grouped.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            itemBuilder: (context, i) {
              final date = sorted[i];
              return _ShiftDateGroup(date: date, shifts: grouped[date]!);
            },
          );
        },
        loading: () => const LoadingIndicator(message: 'Loading shifts...'),
        error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.grey400),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () => ref.invalidate(myShiftsProvider), icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ])),
      ),
    );
  }
}

class _ShiftDateGroup extends StatelessWidget {
  final String date;
  final List<AssignedShift> shifts;
  const _ShiftDateGroup({required this.date, required this.shifts});

  @override
  Widget build(BuildContext context) {
    String displayDate = date;
    try {
      final dt = DateTime.parse(date);
      displayDate = DateFormat('EEEE, dd MMM yyyy').format(dt);
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(children: [
          const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(displayDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.grey700)),
        ]),
        const SizedBox(height: 8),
        ...shifts.map((s) {
          final color = Color(int.tryParse(s.color?.replaceFirst('#', 'FF') ?? 'FFF97316') ?? 0xFFF97316);
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withAlpha(51))),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.schedule, color: color, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('${_fmt(s.startTime)} — ${_fmt(s.endTime)}', style: const TextStyle(fontSize: 13, color: AppColors.grey500)),
              ])),
            ]),
          );
        }),
      ],
    );
  }

  String _fmt(String t) {
    try {
      final parts = t.split(':');
      final h = int.parse(parts[0]);
      final period = h >= 12 ? 'PM' : 'AM';
      final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$dh:${parts[1]} $period';
    } catch (_) { return t; }
  }
}