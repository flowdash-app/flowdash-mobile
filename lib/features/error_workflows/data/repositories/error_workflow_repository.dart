import 'package:dio/dio.dart';
import 'package:flowdash_mobile/core/network/api_client.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:logging/logging.dart';

/// Repository for managing error workflow setup operations.
/// 
/// Provides methods to:
/// - Automatically create workflows in n8n via API
/// - Download workflow templates for manual import
/// - Send test notifications to verify setup
class ErrorWorkflowRepository {
  final ApiClient _apiClient;
  final Logger _logger = AppLogger.getLogger('ErrorWorkflowRepository');

  ErrorWorkflowRepository(this._apiClient);

  /// Automatically create error workflow in user's n8n instance.
  /// 
  /// This calls the backend API which:
  /// 1. Uses the stored n8n API credentials
  /// 2. Creates or updates the error workflow
  /// 3. Activates the workflow
  /// 4. Returns the workflow details
  /// 
  /// Requires Pro+ plan.
  Future<Map<String, dynamic>> createWorkflowAutomatically({
    required String instanceId,
    CancelToken? cancelToken,
  }) async {
    _logger.info(
      'createWorkflowAutomatically: Entry - instance: $instanceId',
    );

    try {
      final response = await _apiClient.dio.post(
        '/error-workflows/create-in-n8n',
        queryParameters: {'instance_id': instanceId},
        cancelToken: cancelToken,
      );

      _logger.info(
        'createWorkflowAutomatically: Success - workflow_id: ${response.data['workflow_id']}',
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.severe(
        'createWorkflowAutomatically: Failure - ${e.message}',
        e,
        e.stackTrace,
      );
      rethrow;
    }
  }

  /// Get workflow template JSON for manual import.
  /// 
  /// Returns a personalized n8n workflow JSON with the instance_id
  /// embedded. User can save this and import it into n8n manually.
  Future<Map<String, dynamic>> getWorkflowTemplate({
    required String instanceId,
    CancelToken? cancelToken,
  }) async {
    _logger.info('getWorkflowTemplate: Entry - instance: $instanceId');

    try {
      final response = await _apiClient.dio.get(
        '/error-workflows/template',
        queryParameters: {'instance_id': instanceId},
        cancelToken: cancelToken,
      );

      _logger.info('getWorkflowTemplate: Success');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.severe(
        'getWorkflowTemplate: Failure - ${e.message}',
        e,
        e.stackTrace,
      );
      rethrow;
    }
  }

  /// Send test notification to verify error workflow setup.
  /// 
  /// Sends a test payload to the backend which triggers the error
  /// notification flow, allowing user to verify their setup is working.
  /// 
  /// Requires Pro+ plan.
  Future<Map<String, dynamic>> sendTestNotification({
    required String instanceId,
    required Map<String, dynamic> testPayload,
    CancelToken? cancelToken,
  }) async {
    _logger.info('sendTestNotification: Entry - instance: $instanceId');

    try {
      final response = await _apiClient.dio.post(
        '/webhooks/test-error',
        data: testPayload,
        cancelToken: cancelToken,
      );

      _logger.info('sendTestNotification: Success');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.severe(
        'sendTestNotification: Failure - ${e.message}',
        e,
        e.stackTrace,
      );
      rethrow;
    }
  }

  /// Get webhook URL information.
  /// 
  /// Returns the base webhook URL and required/optional fields.
  /// Useful for manual configuration.
  Future<Map<String, dynamic>> getWebhookUrl({
    CancelToken? cancelToken,
  }) async {
    _logger.info('getWebhookUrl: Entry');

    try {
      final response = await _apiClient.dio.get(
        '/error-workflows/webhook-url',
        cancelToken: cancelToken,
      );

      _logger.info('getWebhookUrl: Success');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.severe(
        'getWebhookUrl: Failure - ${e.message}',
        e,
        e.stackTrace,
      );
      rethrow;
    }
  }
}

