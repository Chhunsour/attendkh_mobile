import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.darkSurface, AppColors.secondaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Super Admin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 4),
                  Text('Platform overview & management', style: TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // KPI Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _AdminKpiCard(title: 'Total Companies', value: '24', icon: Icons.business, color: AppColors.primary),
                _AdminKpiCard(title: 'Active Users', value: '1,248', icon: Icons.people, color: AppColors.success),
                _AdminKpiCard(title: 'Open Tickets', value: '7', icon: Icons.support, color: AppColors.warning),
                _AdminKpiCard(title: 'Revenue (MTD)', value: '\$45.2K', icon: Icons.monetization_on, color: AppColors.secondary),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Companies
            const Text('Recent Companies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey800)),
            const SizedBox(height: 12),
            ...List.generate(3, (i) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.business, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Company ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('Joined ${i + 1} day${i == 0 ? '' : 's'} ago', style: TextStyle(fontSize: 12, color: AppColors.grey400)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(6)),
                    child: const Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _AdminKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AdminKpiCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
        ],
      ),
    );
  }
}