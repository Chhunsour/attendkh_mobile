import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
// removed
import 'package:mpg_hr_mobile_app/utils/image_compressor.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_companies_repository.dart';

final adminCompaniesProvider =
    FutureProvider.autoDispose<List<AdminCompany>>((ref) {
  return AdminCompaniesRepository().getCompanies();
});

String _getLogoUrl(String logo) {
  if (logo.startsWith('http://') || logo.startsWith('https://')) {
    return logo;
  }
  var cleanPath = logo;
  if (cleanPath.startsWith('/storage/')) {
    cleanPath = cleanPath.substring('/storage/'.length);
  } else if (cleanPath.startsWith('storage/')) {
    cleanPath = cleanPath.substring('storage/'.length);
  }
  if (cleanPath.startsWith('/')) {
    cleanPath = cleanPath.substring(1);
  }
  return '${DioClient.storageUrl}/$cleanPath';
}

class CompanyLogoImage extends StatelessWidget {
  final String logo;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallbackIcon;

  const CompanyLogoImage({
    super.key,
    required this.logo,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (logo.isEmpty) {
      return fallbackIcon ?? const Icon(Icons.business_rounded, color: AppColors.grey400);
    }

    final primaryUrl = _getLogoUrl(logo);

    var cleanPath = logo;
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      cleanPath = '';
    } else {
      if (cleanPath.startsWith('/storage/')) {
        cleanPath = cleanPath.substring('/storage/'.length);
      } else if (cleanPath.startsWith('storage/')) {
        cleanPath = cleanPath.substring('storage/'.length);
      }
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }
    }

    final secondaryUrl = cleanPath.isNotEmpty
        ? '${DioClient.instance.options.baseUrl.replaceAll('/api', '/storage/')}$cleanPath'
        : null;

    return CachedNetworkImage(
      imageUrl: primaryUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => SizedBox(
        width: width,
        height: height,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
      ),
      errorWidget: (context, url, error) {
        if (secondaryUrl != null && secondaryUrl != primaryUrl) {
          return CachedNetworkImage(
            imageUrl: secondaryUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: (context, url) => SizedBox(
              width: width,
              height: height,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            ),
            errorWidget: (context, url, error) =>
                fallbackIcon ?? const Icon(Icons.business_rounded, color: AppColors.grey400),
          );
        }
        return fallbackIcon ?? const Icon(Icons.business_rounded, color: AppColors.grey400);
      },
    );
  }
}


class AdminCompaniesScreen extends ConsumerWidget {
  const AdminCompaniesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(adminCompaniesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Companies',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.black87),
            onPressed: () => _showCreateEditDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(adminCompaniesProvider),
        child: companiesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => _buildError(context, err, ref),
          data: (companies) => _buildList(context, ref, companies),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object err, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load companies',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              err.toString(),
              style: TextStyle(fontSize: 12, color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminCompaniesProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
      BuildContext context, WidgetRef ref, List<AdminCompany> companies) {
    if (companies.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.business_rounded,
                size: 64, color: AppColors.grey300),
            const SizedBox(height: 16),
            Text(
              'No companies yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: companies.length,
      itemBuilder: (context, index) {
        final company = companies[index];
        final isActive = company.status == 'active';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFEEF2FF)
                        : AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: (company.logo != null && company.logo!.isNotEmpty)
                      ? CompanyLogoImage(
                          logo: company.logo!,
                          fit: BoxFit.cover,
                          fallbackIcon: Icon(
                            Icons.business_rounded,
                            color: isActive ? const Color(0xFF6366F1) : AppColors.danger,
                          ),
                        )
                      : Icon(
                          Icons.business_rounded,
                          color: isActive ? const Color(0xFF6366F1) : AppColors.danger,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.grey800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        company.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.successLight
                        : AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Suspended',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 8,
                  position: PopupMenuPosition.under,
                  offset: const Offset(0, 4),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: const Icon(Icons.more_horiz_rounded,
                        color: AppColors.grey700, size: 20),
                  ),
                  onSelected: (action) {
                    if (action == 'edit') {
                      _showCreateEditDialog(context, ref, company: company);
                    } else if (action == 'suspend') {
                      _confirmSuspend(context, ref, company);
                    } else if (action == 'activate') {
                      _confirmActivate(context, ref, company);
                    } else if (action == 'stats') {
                      _showStats(context, company);
                    } else if (action == 'delete') {
                      _confirmDelete(context, ref, company);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      height: 44,
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 20, color: AppColors.grey600),
                          SizedBox(width: 12),
                          Text('Edit', style: TextStyle(color: AppColors.grey800, fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'stats',
                      height: 44,
                      child: Row(
                        children: [
                          Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.info),
                          SizedBox(width: 12),
                          Text('Stats', style: TextStyle(color: AppColors.grey800, fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                    ),
                    if (isActive)
                      PopupMenuItem(
                        value: 'suspend',
                        height: 44,
                        child: Row(
                          children: [
                            Icon(Icons.block_rounded,
                                size: 20, color: AppColors.danger),
                            const SizedBox(width: 12),
                            const Text('Suspend',
                                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ),
                    if (!isActive)
                      PopupMenuItem(
                        value: 'activate',
                        height: 44,
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 20, color: AppColors.success),
                            const SizedBox(width: 12),
                            const Text('Activate',
                                style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      height: 44,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 20, color: AppColors.danger),
                          SizedBox(width: 12),
                          Text('Delete',
                              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmSuspend(
    BuildContext context,
    WidgetRef ref,
    AdminCompany company,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Suspend Company'),
        content: Text(
            'Are you sure you want to suspend "${company.name}"? This will deactivate their account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminCompaniesRepository().suspendCompany(company.id);
        ref.invalidate(adminCompaniesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${company.name} has been suspended'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: ${e.toString()}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmActivate(
    BuildContext context,
    WidgetRef ref,
    AdminCompany company,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Activate Company'),
        content: Text('Activate "${company.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Activate'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await AdminCompaniesRepository().activateCompany(company.id);
        ref.invalidate(adminCompaniesProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${company.name} activated'), backgroundColor: AppColors.success));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AdminCompany company,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Company'),
        content: Text('Permanently delete "${company.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await AdminCompaniesRepository().deleteCompany(company.id);
        ref.invalidate(adminCompaniesProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${company.name} deleted'), backgroundColor: AppColors.success));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  void _showStats(BuildContext context, AdminCompany company) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CompanyStatsSheet(company: company),
    );
  }

  void _showCreateEditDialog(
    BuildContext context,
    WidgetRef ref, {
    AdminCompany? company,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          _CompanyFormSheet(company: company, ref: ref),
    );
  }
}

class _CompanyFormSheet extends ConsumerStatefulWidget {
  final AdminCompany? company;
  final WidgetRef ref;

  const _CompanyFormSheet({this.company, required this.ref});

  @override
  ConsumerState<_CompanyFormSheet> createState() => _CompanyFormSheetState();
}

class _CompanyFormSheetState extends ConsumerState<_CompanyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _timezoneCtrl;
  late final TextEditingController _currencyCtrl;
  late final TextEditingController _adminNameCtrl;
  late final TextEditingController _adminEmailCtrl;
  late final TextEditingController _adminPasswordCtrl;
  String _status = 'active';
  bool _isSaving = false;
  bool _isLoadingLocation = false;
  File? _logoFile;
  final _picker = ImagePicker();
  
  List<Map<String, String>> _socialMediaList = [];

  bool get _isEditing => widget.company != null;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    final sm = c?.socialMedia;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _timezoneCtrl = TextEditingController(text: c?.timezone ?? 'UTC+7');
    _currencyCtrl = TextEditingController(text: c?.currency ?? 'USD');
    _adminNameCtrl = TextEditingController();
    _adminEmailCtrl = TextEditingController();
    _adminPasswordCtrl = TextEditingController();
    _status = c?.status ?? 'active';

    if (sm != null) {
      _socialMediaList = sm.map((e) {
        if (e is Map) {
          return {
            'platform': (e['platform'] ?? '').toString(),
            'url': (e['url'] ?? '').toString(),
          };
        }
        return {'platform': '', 'url': ''};
      }).toList();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _timezoneCtrl.dispose();
    _currencyCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // ignore: deprecated_member_use
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
        address = address.split(', ').where((part) => part.trim().isNotEmpty && part != 'null').join(', ');
        setState(() {
          _addressCtrl.text = address;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get location: $e'), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _pickLogo() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final compressedFile = await ImageCompressor.compressToWebp(picked.path);
      setState(() => _logoFile = compressedFile);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'timezone': _timezoneCtrl.text.trim(),
        'currency': _currencyCtrl.text.trim(),
        'social_media': _socialMediaList,
        'status': _status,
      };

      if (!_isEditing) {
        if (_adminNameCtrl.text.trim().isNotEmpty) {
          data['admin_name'] = _adminNameCtrl.text.trim();
        }
        if (_adminEmailCtrl.text.trim().isNotEmpty) {
          data['admin_email'] = _adminEmailCtrl.text.trim();
        }
        if (_adminPasswordCtrl.text.trim().isNotEmpty) {
          data['admin_password'] = _adminPasswordCtrl.text.trim();
        }
      }

      final repo = AdminCompaniesRepository();
      final logoPath = _logoFile?.path;
      AdminCompanyCreationResult? createRes;
      if (_isEditing) {
        await repo.updateCompany(widget.company!.id, data, logoPath: logoPath);
      } else {
        createRes = await repo.createCompany(data, logoPath: logoPath);
      }

      widget.ref.invalidate(adminCompaniesProvider);

      if (mounted) {
        Navigator.pop(context);
        if (createRes != null && createRes.ownerEmail != null) {
          final email = createRes.ownerEmail;
          final pass = createRes.ownerPassword ?? 'Password123!';
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Company Created'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Company Owner account created successfully! Use these credentials to log in:'),
                  const SizedBox(height: 12),
                  SelectableText('Email: $email', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SelectableText('Password: $pass', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing
                  ? 'Company updated successfully'
                  : 'Company created successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Edit Company' : 'Create Company',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey900,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildField('Company Name', _nameCtrl,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 14),
                    _buildField('Email', _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null),
                    if (!_isEditing) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Company Owner Account',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF9A3412)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Account automatically created for the owner. Leave blank to default to company email and password Password123!.',
                              style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                            ),
                            const SizedBox(height: 10),
                            _buildField('Owner Name', _adminNameCtrl),
                            const SizedBox(height: 10),
                            _buildField('Owner Login Email', _adminEmailCtrl, keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 10),
                            _buildField('Owner Password', _adminPasswordCtrl),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _buildField('Phone', _phoneCtrl,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 14),
                    // Address with location
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey600)),
                            TextButton.icon(
                              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                              icon: _isLoadingLocation 
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                : const Icon(Icons.my_location_rounded, size: 16, color: AppColors.primary),
                              label: Text(_isLoadingLocation ? 'Getting...' : 'Get Location', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _addressCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.grey200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.grey200)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField('Timezone', _timezoneCtrl),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField('Currency', _currencyCtrl),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Status dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.grey200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _status,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                    value: 'active', child: Text('Active')),
                                DropdownMenuItem(
                                    value: 'suspended',
                                    child: Text('Suspended')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _status = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Social Media section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.grey200),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF8FAFC),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Social Media Links',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.grey800,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _socialMediaList.add({'platform': '', 'url': ''});
                                  });
                                },
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Add', style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_socialMediaList.isEmpty)
                            const Text('No social media links added.', style: TextStyle(color: AppColors.grey500, fontSize: 13)),
                          ...List.generate(_socialMediaList.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      initialValue: _socialMediaList[index]['platform'],
                                      decoration: InputDecoration(
                                        hintText: 'Platform',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.grey200)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                      ),
                                      onChanged: (val) => _socialMediaList[index]['platform'] = val,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: _socialMediaList[index]['url'],
                                      decoration: InputDecoration(
                                        hintText: 'URL',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.grey200)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                      ),
                                      onChanged: (val) => _socialMediaList[index]['url'] = val,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _socialMediaList.removeAt(index);
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Logo upload
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Company Logo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickLogo,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 14),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.grey200, style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFFF8FAFC),
                            ),
                            child: _logoFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _logoFile!,
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : (widget.company?.logo != null && widget.company!.logo!.isNotEmpty)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CompanyLogoImage(
                                              logo: widget.company!.logo!,
                                              height: 100,
                                              width: double.infinity,
                                              fit: BoxFit.contain,
                                              fallbackIcon: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.business_rounded, color: AppColors.grey400, size: 22),
                                                  const SizedBox(width: 8),
                                                  Text('Tap to change logo', style: TextStyle(fontSize: 14, color: AppColors.grey500)),
                                                ],
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 4,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: 0.6),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.edit, color: Colors.white, size: 12),
                                                    SizedBox(width: 4),
                                                    Text('Tap to change logo', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.cloud_upload_outlined,
                                              color: AppColors.grey400, size: 22),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Tap to upload logo',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppColors.grey500,
                                            ),
                                          ),
                                        ],
                                      ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEditing ? 'Update Company' : 'Create Company',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.grey200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.grey200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.danger),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
      ],
    );
  }
}

class _CompanyStatsSheet extends StatefulWidget {
  final AdminCompany company;
  const _CompanyStatsSheet({required this.company});

  @override
  State<_CompanyStatsSheet> createState() => _CompanyStatsSheetState();
}

class _CompanyStatsSheetState extends State<_CompanyStatsSheet> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await AdminCompaniesRepository().getCompanyStats(widget.company.id);
      setState(() { _stats = stats; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Company Stats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.grey900)),
                  Text(widget.company.name, style: TextStyle(fontSize: 13, color: AppColors.grey500)),
                ]),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.error_outline, size: 48, color: AppColors.grey400),
                        const SizedBox(height: 12),
                        Text(_error!, style: TextStyle(color: AppColors.grey500, fontSize: 12)),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(onPressed: () { setState(() { _isLoading = true; _error = null; }); _loadStats(); }, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                      ]))
                    : _stats.isEmpty
                        ? Center(child: Text('No stats available', style: TextStyle(color: AppColors.grey400)))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _stats.entries.map((e) {
                                final value = e.value.toString();
                                final label = e.key.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
                                return Container(
                                  width: (MediaQuery.of(context).size.width - 52) / 2,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.grey200)),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.grey900)),
                                    const SizedBox(height: 4),
                                    Text(label, style: TextStyle(fontSize: 12, color: AppColors.grey500, fontWeight: FontWeight.w500)),
                                  ]),
                                );
                              }).toList(),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
