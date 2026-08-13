import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/services/network/exceptions.dart';
import 'package:mpg_hr_mobile_app/utils/storage/secure_storage.dart';
import 'package:mpg_hr_mobile_app/services/fcm_service.dart';
import 'package:mpg_hr_mobile_app/services/auth_repository.dart';

/// Auth state
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? token;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? companyId;
  final String? companyName;
  final List<String> roles;
  final String? employeeId;

  final String? emailVerifiedAt;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.token,
    this.userId,
    this.userName,
    this.userEmail,
    this.emailVerifiedAt,
    this.companyId,
    this.companyName,
    this.roles = const [],
    this.employeeId,
  });

  bool get isSuperAdmin => roles.contains('super_admin');
  bool get isCompanyOwner => roles.contains('company_owner');
  bool get isCompanyAdmin =>
      roles.contains('company_admin') ||
      roles.contains('admin') ||
      roles.contains('company_owner');
  bool get isBranchManager => roles.contains('branch_manager');

  /// True when the auth state has enough data to consider the user logged in
  bool get hasLocalSession =>
      token != null && token!.isNotEmpty && userId != null;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? token,
    String? userId,
    String? userName,
    String? userEmail,
    String? emailVerifiedAt,
    String? companyId,
    String? companyName,
    List<String>? roles,
    String? employeeId,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      roles: roles ?? this.roles,
      employeeId: employeeId ?? this.employeeId,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Auth notifier — manages authentication state with real API calls
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;

  AuthNotifier({AuthRepository? authRepo})
    : _authRepo = authRepo ?? AuthRepository(),
      super(const AuthState(isLoading: true));

  /// Check if user is already logged in from stored token.
  ///
  /// Strategy (offline-first):
  /// 1. If no token exists locally → not authenticated (go to login).
  /// 2. If token exists, try to call GET /user to validate it.
  ///    - Success → update state from server response (source of truth).
  ///    - 401 → token may be expired, but we still restore from local storage
  ///      so the user stays logged in without a forced re-login. The 401
  ///      will be handled naturally when the user performs an API action.
  ///    - Network/other error → restore session from locally stored data.
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final token = await SecureStorageService.instance.accessToken;
      if (token == null || token.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      try {
        final currentUser = await _authRepo.getCurrentUser();
        await _persistUserData(currentUser);

        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          token: token,
          userId: currentUser.id.toString(),
          userName: currentUser.name,
          userEmail: currentUser.email,
          emailVerifiedAt: currentUser.emailVerifiedAt,
          companyId: currentUser.companyId > 0
              ? currentUser.companyId.toString()
              : null,
          companyName: currentUser.companyName,
          roles: currentUser.roles,
          employeeId: currentUser.employeeId?.toString(),
        );

        // Sync FCM token
        FcmService.instance.syncTokenWithBackend();

        AppLogger.i('Auth status checked — user: ${currentUser.name}');
        return;
      } on UnauthorizedException {
        // Token is definitively expired/invalid — clear and force re-login.
        AppLogger.w(
          'Token validation returned 401 — clearing auth, user must re-login',
        );
        await SecureStorageService.instance.clearAuth();
        state = const AuthState();
        return;
      }
      // Other exceptions (network, etc.) fall through to restore below
    } catch (_) {
      // Network or unexpected error — restore from local storage below
    }

    // ── Server unreachable: restore session from local storage ──
    AppLogger.w(
      'Server unreachable during auth check — restoring session from local storage',
    );
    await _restoreFromLocalStorage();
  }

  /// Restore authentication state purely from locally stored data.
  /// This allows the user to stay logged in even when the server is
  /// temporarily unreachable (e.g. slow network, app restart in airplane mode).
  Future<void> _restoreFromLocalStorage() async {
    final storage = SecureStorageService.instance;
    final token = await storage.accessToken;

    if (token == null || token.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final userId = await storage.userId;
    if (userId == null || userId.isEmpty) {
      // Token exists but no user data — treat as not authenticated
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(
      isAuthenticated: true,
      isLoading: false,
      token: token,
      userId: userId,
      userName: await storage.userName,
      userEmail: await storage.userEmail,
      emailVerifiedAt: await storage.userEmailVerifiedAt,
      companyId: await storage.companyId,
      companyName: await storage.companyName,
      roles: await storage.roles,
      employeeId: await storage.employeeId,
    );

    // Sync FCM token
    FcmService.instance.syncTokenWithBackend();

    AppLogger.i('Session restored from local storage — userId: $userId');
  }

  /// Login — calls POST /login, stores token and all user data
  Future<void> login({required String login, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _authRepo.login(
        login: login,
        password: password,
        deviceName: 'mobile_app',
      );

      // Persist tokens and user data to secure storage
      await _persistLoginResult(result);

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        token: result.accessToken,
        userId: result.userId.toString(),
        userName: result.userName,
        userEmail: result.userEmail,
        emailVerifiedAt: result.emailVerifiedAt,
        companyId: result.companyId > 0 ? result.companyId.toString() : null,
        companyName: result.companyName,
        roles: result.roles,
        employeeId: result.employeeId?.toString(),
      );

      // Sync FCM token
      FcmService.instance.syncTokenWithBackend();

      AppLogger.i('User logged in successfully: ${result.userName}');
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      AppLogger.e('Login failed', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed. Please try again.',
      );
    }
  }

  /// Logout — calls POST /logout, clears all stored data
  Future<void> logout() async {
    try {
      await _authRepo.logout();
    } catch (e) {
      AppLogger.w('Logout API call failed — clearing local data anyway');
    }
    await SecureStorageService.instance.clearAll();
    state = const AuthState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Persist login result to secure storage (all fields)
  Future<void> _persistLoginResult(LoginResult result) async {
    final storage = SecureStorageService.instance;
    await Future.wait([
      storage.setAccessToken(result.accessToken),
      storage.setUserId(result.userId.toString()),
      storage.setUserName(result.userName),
      if (result.userEmail != null) storage.setUserEmail(result.userEmail!),
      if (result.emailVerifiedAt != null)
        storage.setUserEmailVerifiedAt(result.emailVerifiedAt!),
      storage.setCompanyId(result.companyId.toString()),
      if (result.companyName != null)
        storage.setCompanyName(result.companyName!),
      storage.setRoles(result.roles),
      if (result.employeeId != null)
        storage.setEmployeeId(result.employeeId!.toString()),
    ]);
  }

  /// Persist current user data to secure storage (from GET /user)
  Future<void> _persistUserData(CurrentUser user) async {
    final storage = SecureStorageService.instance;
    await Future.wait([
      storage.setUserId(user.id.toString()),
      storage.setUserName(user.name),
      if (user.email != null) storage.setUserEmail(user.email!),
      if (user.emailVerifiedAt != null)
        storage.setUserEmailVerifiedAt(user.emailVerifiedAt!),
      storage.setCompanyId(user.companyId.toString()),
      if (user.companyName != null) storage.setCompanyName(user.companyName!),
      storage.setRoles(user.roles),
      if (user.employeeId != null)
        storage.setEmployeeId(user.employeeId!.toString()),
    ]);
  }
}

/// Provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Derived providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});

final currentUserNameProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).userName;
});

final currentCompanyNameProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).companyName;
});

final isSuperAdminProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isSuperAdmin;
});

final isBranchManagerProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isBranchManager;
});
