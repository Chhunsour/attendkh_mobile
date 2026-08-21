import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/top_employees_provider.dart';
import '../../models/top_employee.dart';
import '../../utils/theme/theme.dart';

class TopEmployeesScreen extends ConsumerStatefulWidget {
  const TopEmployeesScreen({super.key});

  @override
  ConsumerState<TopEmployeesScreen> createState() => _TopEmployeesScreenState();
}

class _TopEmployeesScreenState extends ConsumerState<TopEmployeesScreen> {
  DateTime selectedMonth = DateTime.now();
  String activeCategory = 'attendance';
  String activeSort = 'by_amount';

  final List<Map<String, dynamic>> categories = [
    {'key': 'attendance', 'label': 'Attendance', 'icon': Icons.check_circle_outline, 'color': Colors.green},
    {'key': 'leave', 'label': 'Leave', 'icon': Icons.calendar_today_outlined, 'color': Colors.amber},
    {'key': 'check_early', 'label': 'Check Early', 'icon': Icons.access_time, 'color': Colors.blue},
    {'key': 'check_late', 'label': 'Check Late', 'icon': Icons.error_outline, 'color': Colors.red},
    {'key': 'checkout_early', 'label': 'Checkout Early', 'icon': Icons.logout, 'color': Colors.orange},
    {'key': 'checkout_overtime', 'label': 'Overtime', 'icon': Icons.timer, 'color': Colors.indigo},
  ];

  @override
  Widget build(BuildContext context) {
    final monthStr = DateFormat('yyyy-MM').format(selectedMonth);
    final topEmployeesAsync = ref.watch(topEmployeesProvider(monthStr));

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text('Top Employees Leaderboard', style: TextStyle(color: AppColors.textPrimary(context))),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        centerTitle: true,
      ),
      body: topEmployeesAsync.when(
        data: (data) {
          final currentCategoryData = data[activeCategory] ?? {'by_amount': [], 'by_hours': []};
          final List<TopEmployee> currentList = currentCategoryData[activeSort] ?? [];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(selectedMonth).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedMonth,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => selectedMonth = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_month, size: 16),
                            label: const Text('Change Month'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tabs for Amount vs Hours
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => activeSort = 'by_amount'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: activeSort == 'by_amount' ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: activeSort == 'by_amount'
                                        ? [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4)]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'By Amount',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: activeSort == 'by_amount' ? Colors.black87 : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => activeSort = 'by_hours'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: activeSort == 'by_hours' ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: activeSort == 'by_hours'
                                        ? [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4)]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'By Hours',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: activeSort == 'by_hours' ? Colors.black87 : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Categories scroll
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: categories.map((c) {
                            final isActive = activeCategory == c['key'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Row(
                                  children: [
                                    Icon(c['icon'], size: 16, color: isActive ? Colors.white : c['color']),
                                    const SizedBox(width: 8),
                                    Text(c['label']),
                                  ],
                                ),
                                selected: isActive,
                                onSelected: (selected) {
                                  if (selected) setState(() => activeCategory = c['key']);
                                },
                                selectedColor: Colors.grey[900],
                                labelStyle: TextStyle(
                                  color: isActive ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // List
              if (currentList.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No Winners Yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No data available for this month.',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final emp = currentList[index];
                        
                        // Solid Colors for Badges (no gradients)
                        Color badgeColor = Colors.grey[200]!;
                        Color badgeTextColor = Colors.grey[700]!;
                        String suffix = "th";

                        if (index == 0) {
                          badgeColor = Colors.amber[400]!;
                          badgeTextColor = Colors.white;
                          suffix = "st";
                        } else if (index == 1) {
                          badgeColor = Colors.blueGrey[200]!;
                          badgeTextColor = Colors.blueGrey[900]!;
                          suffix = "nd";
                        } else if (index == 2) {
                          badgeColor = Colors.orange[400]!;
                          badgeTextColor = Colors.white;
                          suffix = "rd";
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surface(context),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: AppColors.border(context)),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Badge
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  shape: BoxShape.circle,
                                  boxShadow: index < 3 ? [
                                    BoxShadow(
                                      color: badgeColor.withAlpha(102),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ] : null,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: badgeTextColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        height: 1.0,
                                      ),
                                    ),
                                    Text(
                                      suffix,
                                      style: TextStyle(
                                        color: badgeTextColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        height: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Avatar
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.grey[100],
                                child: Text(
                                  emp.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      emp.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: AppColors.textPrimary(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Top Employee',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Score
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    activeSort == 'by_amount' ? emp.amount.toString() : emp.hours.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24,
                                      color: index == 0 ? Colors.amber[500] : (index == 1 ? Colors.blueGrey[400] : (index == 2 ? Colors.orange[500] : AppColors.primary)),
                                    ),
                                  ),
                                  Text(
                                    activeSort == 'by_amount' ? 'TIMES' : 'HOURS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.grey[400],
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: currentList.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error loading data: $err'),
        ),
      ),
    );
  }
}
