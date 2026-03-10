// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

// import 'package:elf_client/elf_client.dart';
// import 'package:elf_flutter/main.dart';

// // Define the state for your authentication
// enum AuthStatus {
//   initial,
//   loading,
//   authenticated,
//   unauthenticated,
//   error,
// }

// class AuthState {
//   final AuthStatus status;
//   final UserProfileModel? userProfile;
//   final String? errorMessage;

//   AuthState({
//     required this.status,
//     this.userProfile,
//     this.errorMessage,
//   });

//   AuthState copyWith({
//     AuthStatus? status,
//     UserProfileModel? userProfile,
//     String? errorMessage,
//   }) {
//     return AuthState(
//       status: status ?? this.status,
//       userProfile: userProfile ?? this.userProfile,
//       errorMessage: errorMessage ?? this.errorMessage,
//     );
//   }
// }

// // Provider for the Serverpod client (assuming it's globally accessible)
// final clientProvider = Provider<Client>((ref) => client); // 'client' from your main.dart

// // AuthController for Riverpod
// final authControllerProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// class AuthNotifier extends Notifier<AuthState> {
//   late GoogleAuthController _googleAuthController;
//   late Client _client;

//   @override
//   AuthState build() {
//     _client = ref.read(clientProvider);

//     _googleAuthController = GoogleAuthController(
//       client: _client,
//       onAuthenticated: _onAuthenticated,
//       onError: _onError,
//       attemptLightweightSignIn: false,
//       scopes: const [
//         'https://www.googleapis.com/auth/userinfo.email',
//         'https://www.googleapis.com/auth/userinfo.profile',
//       ],
//     );

//     _googleAuthController.addListener(_updateStateFromController);
//     ref.onDispose(() {
//       _googleAuthController.removeListener(_updateStateFromController);
//       _googleAuthController.dispose();
//     });

//     // Initial state based on client.auth (Serverpod's session manager)
//     if (_client.auth.isAuthenticated) {
//       _fetchUserProfile();
//       return AuthState(status: AuthStatus.authenticated);
//     }
//     return AuthState(status: AuthStatus.unauthenticated);
//   }

//   void _updateStateFromController() {
//     switch (_googleAuthController.state) {
//       case GoogleAuthState.initializing:
//       case GoogleAuthState.idle:
//         // No change, or handled by isAuthenticated check
//         break;
//       case GoogleAuthState.loading:
//         state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
//         break;
//       case GoogleAuthState.error:
//         state = state.copyWith(status: AuthStatus.error, errorMessage: _googleAuthController.errorMessage);
//         break;
//       case GoogleAuthState.authenticated:
//         _fetchUserProfile(); // Fetch profile when authenticated
//         break;
//     }
//   }

//   Future<void> _onAuthenticated() async {
//     // This callback means Serverpod has successfully authenticated the user.
//     await _fetchUserProfile();
//   }

//  void _onError(dynamic error) {
//     // Detect cancellation by checking error text to avoid referencing an undefined type.
//     final message = error?.toString() ?? '';
//     if (message.contains('canceled') || message.contains('cancelled')) {
//       // User explicitly cancelled the sign-in flow.
//       // You might reset the state or just log it without showing an error to the user.
//       print('Google Sign-In cancelled by user.');
//       state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: null); // Reset to unauthenticated
//     } else {
//       // Other types of errors (e.g., network issues, configuration errors)
//       print('Google Sign-In error: $error');
//       state = state.copyWith(status: AuthStatus.error, errorMessage: message);
//     }
//   }
//   Future<void> signInWithGoogle() async {
//     if (state.status == AuthStatus.loading) return;
//     state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
//     await _googleAuthController.signIn();
//   }

//   Future<void> signOut() async {
//     state = state.copyWith(status: AuthStatus.loading);
//     await _client.auth.signOutDevice();
//     state = AuthState(status: AuthStatus.unauthenticated, userProfile: null);
//   }

//   Future<void> _fetchUserProfile() async {
//     try {
//       final userProfile = await _client.modules.serverpod_auth_core.userProfileInfo.get();
//       state = AuthState(status: AuthStatus.authenticated, userProfile: userProfile, errorMessage: null);
//         } catch (e) {
//       state = AuthState(status: AuthStatus.error, errorMessage: 'Failed to fetch user profile: $e');
//     }
//   }

//   // Method to manually refresh user profile (e.g., after updating it)
//   Future<void> refreshUserProfile() async {
//     if (state.status == AuthStatus.authenticated) {
//       await _fetchUserProfile();
//     }
//   }
// }

