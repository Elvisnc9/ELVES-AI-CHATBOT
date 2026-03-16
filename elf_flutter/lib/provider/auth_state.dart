import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

import 'package:elf_flutter/main.dart';

// ─────────────────────────────────────────────
//  AUTH STATUS
// ─────────────────────────────────────────────

enum AuthStatus {
  loading,
  authenticated,
  unauthenticated, // guest — can still use the app freely
}

// ─────────────────────────────────────────────
//  AUTH STATE
// ─────────────────────────────────────────────

class AuthState {
  final AuthStatus status;
  final UserProfileModel? userProfile;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.userProfile,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UserProfileModel? userProfile,
    bool clearProfile = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      userProfile: clearProfile ? null : (userProfile ?? this.userProfile),
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─────────────────────────────────────────────
//  AUTH NOTIFIER
//
//  State is driven by callbacks from GoogleSignInWidget
//  (onAuthenticated / onError) which live in onboarding.dart.
//
//  main() already called client.auth.initialize(), so on
//  app start we check the client's current signed-in status
//  directly and fetch the profile if needed.
// ─────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Check whether initialize() already restored a valid session.
    _checkRestoredSession();
    // Start as unauthenticated; _checkRestoredSession will update if needed.
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  // ── Called once on startup ───────────────────────────────────────────────

  Future<void> _checkRestoredSession() async {
    // client.auth.isSignedIn tells us whether initialize() found
    // a valid stored session.
    if (!client.auth.isAuthenticated) return;

    state = state.copyWith(status: AuthStatus.loading);
    await _fetchProfile();
  }

  // ── Called by GoogleSignInWidget's onAuthenticated callback ─────────────

  Future<void> onSignedIn() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    await _fetchProfile();
  }

  // ── Called by GoogleSignInWidget's onError callback ─────────────────────

  void onSignInError(dynamic error) {
    final msg = error?.toString() ?? '';
    // Cancelled — silent guest fallback, no error shown.
    if (msg.toLowerCase().contains('cancel') ||
        msg.toLowerCase().contains('sign_in_canceled')) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearProfile: true,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearProfile: true,
        errorMessage: msg,
      );
    }
  }

  // ── Sign out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await client.auth.signOutDevice();
    } catch (_) {
      // Best-effort.
    }
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      userProfile: null,
    );
  }

  // ── Profile ──────────────────────────────────────────────────────────────

  Future<void> refreshProfile() async {
    if (state.isAuthenticated) await _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile =
          await client.modules.serverpod_auth_core.userProfileInfo.get();
      state = AuthState(
        status: AuthStatus.authenticated,
        userProfile: profile,
      );
    } catch (_) {
      // Profile fetch failed (stale token, network error).
      // Fall back to guest — the session is invalid.
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        userProfile: null,
        errorMessage: 'Session expired. Please sign in again.',
      );
    }
  }
}

// ─────────────────────────────────────────────
//  PROVIDERS
// ─────────────────────────────────────────────

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final authStatusProvider =
    Provider<AuthStatus>((ref) => ref.watch(authProvider).status);

final userProfileProvider = Provider<UserProfileModel?>(
    (ref) => ref.watch(authProvider).userProfile);