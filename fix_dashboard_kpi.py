import re

with open('lib/pages/hr/company_admin_dashboard_screen.dart', 'r') as f:
    content = f.read()

imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/dialogs/logout_dialog.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
"""

content = re.sub(r'import.*?;\n(import.*?;\n)*', imports, content, count=1)

kpi_widget = """
          // ── Dashboard KPIs
          ref.watch(dashboardStatsProvider).when(
            data: (kpi) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Company Overview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey800, fontFamily: 'Inter'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard('Total Staff', kpi.totalEmployees.toString(), Icons.people, const Color(0xFF3B82F6)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard('On Leave', kpi.pendingLeaves.toString(), Icons.event_busy, const Color(0xFFEF4444)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard('Open Jobs', kpi.openJobs.toString(), Icons.work, const Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard('Assets', '${kpi.assignedAssets}/${kpi.totalAssets}', Icons.devices, const Color(0xFFF59E0B)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            error: (e, _) => Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(12)),
              child: Text('Error loading KPIs: $e', style: const TextStyle(color: AppColors.danger)),
            ),
          ),
"""

if 'dashboardStatsProvider' not in content:
    content = content.replace(
        "          const SizedBox(height: 24),\n\n          // ── Quick Operations Grid Menu",
        "          const SizedBox(height: 24),\n" + kpi_widget + "          // ── Quick Operations Grid Menu"
    )

kpi_builder = """
  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.grey500, fontFamily: 'Inter')),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey800, fontFamily: 'Inter')),
              ],
            ),
          ),
        ],
      ),
    );
  }
"""

if '_buildKpiCard' not in content:
    content = content.replace(
        "  Widget _buildWelcomeBanner(",
        kpi_builder + "\n  Widget _buildWelcomeBanner("
    )

with open('lib/pages/hr/company_admin_dashboard_screen.dart', 'w') as f:
    f.write(content)
