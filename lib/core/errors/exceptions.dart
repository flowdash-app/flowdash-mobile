abstract class AppException implements Exception {
  final String message;
  AppException(this.message);
  
  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message);
}

class UnauthorizedException extends AppException {
  UnauthorizedException() : super('Unauthorized');
}

class NotFoundException extends AppException {
  NotFoundException([String? resource]) 
      : super(resource != null ? '$resource not found' : 'Resource not found');
}

class ServerException extends AppException {
  ServerException([String? message]) 
      : super(message ?? 'Server error occurred');
}

class CacheException extends AppException {
  CacheException([String? message]) 
      : super(message ?? 'Cache error occurred');
}

