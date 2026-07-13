with open('lib/providers/admin_providers.dart', 'r') as f:
    content = f.read()

provider_code = """
final dashboardStatsProvider = FutureProvider.autoDispose<DashboardKpiData>((ref) {
  return ref.watch(adminOpsRepositoryProvider).getDashboardStats();
});

"""

if 'dashboardStatsProvider' not in content:
    content = content.replace(
        "// ── Admin Operations Providers ──────────────────────────────────────────────",
        "// ── Admin Operations Providers ──────────────────────────────────────────────\n" + provider_code
    )

    with open('lib/providers/admin_providers.dart', 'w') as f:
        f.write(content)
