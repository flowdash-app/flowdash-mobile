import 'dart:async';

import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flowdash_mobile/features/auth/domain/entities/user.dart';
import 'package:flowdash_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:logging/logging.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final Logger _logger = AppLogger.getLogger('AuthRepositoryImpl');

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> signInWithGoogle() async {
    _logger.info('signInWithGoogle: Entry');

    try {
      await _remoteDataSource.signInWithGoogle();
      _logger.info('signInWithGoogle: Success');
    } catch (e, stackTrace) {
      _logger.severe('signInWithGoogle: Failure', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    _logger.info('signOut: Entry');

    try {
      await _remoteDataSource.signOut();
      _logger.info('signOut: Success');
    } catch (e, stackTrace) {
      _logger.severe('signOut: Failure', e, stackTrace);
      rethrow;
    }
  }

  @override
  Stream<User?> get authStateChanges {
    // Stream is managed by Riverpod StreamProvider, which automatically
    // cancels subscriptions when the provider is disposed.
    // No manual subscription management needed here.
    return _remoteDataSource.authStateChanges.map((firebaseUser) {
      return firebaseUser != null ? User.fromFirebaseUser(firebaseUser) : null;
    });
  }
  
  @override
  Future<String?> getAuthToken() async {
    _logger.info('getAuthToken: Entry');
    
    try {
      final token = await _remoteDataSource.getAuthToken();
      _logger.info('getAuthToken: Success');
      return token;
    } catch (e, stackTrace) {
      _logger.severe('getAuthToken: Failure', e, stackTrace);
      rethrow;
    }
  }
}
