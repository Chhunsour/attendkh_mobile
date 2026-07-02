import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/core/network/exceptions.dart';
import 'package:mpg_hr_mobile_app/core/storage/secure_storage.dart';
import 'package:mpg_hr_mobile_app/features/auth/data/auth_repository.dart';

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

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.token,
    this.userId,
    this.userName,
    this.userEmail,
    this.companyId,
    this.companyName,
    this.roles = const [],
  });

  bool get isSuperAdmin => roles.contains('super_admin');

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? token,
    String? userId,
    String? userName,
    String? userEmail,
    String? companyId,
    String? companyName,
    List<String>? roles,
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
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      roles: roles ?? this.roles,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Auth notifier — manages authentication state with real API calls
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;

  AuthNotifier({AuthRepository? authRepo})
      : _authRepo = authRepo ?? AuthRepository(),
        super(const AuthState());

  /// Check if user is already logged in from stored token — calls GET /user
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final token = await SecureStorageService.instance.accessToken;
      if (token == null || token.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final currentUser = await _authRepo.getCurrentUser();
      await _persistUserData(currentUser);

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        token: token,
        userId: currentUser.id.toString(),
        userName: currentUser.name,
        userEmail: currentUser.email,
        companyId: currentUser.companyId.toString(),
        companyName: currentUser.companyName,
        roles: currentUser.roles,
      );

      AppLogger.i('Auth status checked — user: ${currentUser.name}');
    } on UnauthorizedException {
      // Token expired or invalid — clear it
      await SecureStorageService.instance.clearAuth();
      state = AuthState();
    } catch (e) {
      AppLogger.e('checkAuthStatus failed', e);
      // Keep existing token — might be a network issue
      state = state.copyWith(isLoading: false);
    }
  }

  /// Login — calls POST /login, stores token
  Future<void> login({
    required String login,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _authRepo.login(
        login: login,
        password: password,
        deviceName: 'mobile_app',
      );

      // Persist tokens and user data
      final storage = SecureStorageService.instance;
      await storage.setAccessToken(result.accessToken);
      await storage.setUserId(result.userId.toString());
      await storage.setUserName(result.userName);
      await storage.setCompanyId(result.companyId.toString());
      if (result.companyName != null) {
        await storage.setCompanyName(result.companyName!);
      }

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        token: result.accessToken,
        userId: result.userId.toString(),
        userName: result.userName,
        userEmail: result.userEmail,
        companyId: result.companyId.toString(),
        companyName: result.companyName,
        roles: result.roles,
      );

      AppLogger.i('Login success — user: ${result.userName}');
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      AppLogger.e('Login failed', e);
      state = state.copyWith(isLoading: false, error: 'Login failed. Please try again.');
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

  /// Persist user data to secure storage
  Future<void> _persistUserData(CurrentUser user) async {
    final storage = SecureStorageService.instance;
    await Future.wait([
      storage.setUserId(user.id.toString()),
      storage.setUserName(user.name),
      storage.setCompanyId(user.companyId.toString()),
      if (user.companyName != null) storage.setCompanyName(user.companyName!),
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