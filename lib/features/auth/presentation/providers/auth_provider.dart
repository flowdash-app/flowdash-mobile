import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flowdash_mobile/core/analytics/analytics_service.dart';
import 'package:flowdash_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flowdash_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flowdash_mobile/features/auth/domain/entities/user.dart' as domain;
import 'package:flowdash_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

final firebaseAuthProvider = Provider<firebase_auth.FirebaseAuth>((ref) {
  return firebase_auth.FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  // GoogleSignIn v7.0+ - constructor with scopes parameter
  // For Firebase Auth integration, we need email and profile scopes
  return GoogleSignIn.instance;
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final googleSignIn = ref.watch(googleSignInProvider);
  return AuthRemoteDataSource(
    firebaseAuth: firebaseAuth,
    googleSignIn: googleSignIn,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  ref.onDispose(remoteDataSource.dispose);
  return AuthRepositoryImpl(remoteDataSource);
});

final authStateProvider = StreamProvider<domain.User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
