import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/features/error_workflows/data/models/error_workflow_setup_state.dart';
import 'package:flowdash_mobile/features/error_workflows/data/repositories/error_workflow_repository.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing error workflow setup lifecycle.
/// 
/// Handles:
/// - Automatic workflow creation in n8n
/// - Manual workflow template download
/// - Setup state persistence
/// - Test notification sending
class ErrorWorkflowService {
  final ErrorWorkflowRepository _repository;
  final SharedPreferences _prefs;
  final Logger _logger = AppLogger.getLogger('ErrorWorkflowService');

  static const String _stateKeyPrefix = 'error_workflow_state_';

  ErrorWorkflowService(this._repository, this._prefs);

  /// Create workflow automatically in user's n8n instance.
  /// 
  /// This is the recommended setup method - one tap and FlowDash
  /// creates the workflow directly in n8n.
  Future<Map<String, dynamic>> createWorkflowAutomatically({
    required String instanceId,
    CancelToken? cancelToken,
  }) async {
    _logger.info(
      'createWorkflowAutomatically: Entry - instance: $instanceId',
    );

    try {
      final result = await _repository.createWorkflowAutomatically(
        instanceId: instanceId,
        cancelToken: cancelToken,
      );

      // Save state after successful creation
      await markSetupComplete(
        instanceId: instanceId,
        method: 'automatic',
        workflowId: result['workflow_id'] as String?,
      );

      _logger.info('createWorkflowAutomatically: Success');
      return result;
    } catch (e, stackTrace) {
      _logger.severe(
        'createWorkflowAutomatically: Failure',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Download workflow template for manual import.
  /// 
  /// Gets the personalized JSON workflow and saves it to device,
  /// then opens the share sheet so user can access it.
  Future<String> downloadWorkflowTemplate({
    required String instanceId,
    required String instanceName,
    CancelToken? cancelToken,
  }) async {
    _logger.info('downloadWorkflowTemplate: Entry - instance: $instanceId');

    try {
      // Get template from API
      final template = await _repository.getWorkflowTemplate(
        instanceId: instanceId,
        cancelToken: cancelToken,
      );

      // Convert to JSON string
      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(template);

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      
      // Create filename with instance name (sanitized)
      final sanitizedName = instanceName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_');
      final fileName = 'flowdash_error_workflow_$sanitizedName.json';
      final file = File('${tempDir.path}/$fileName');

      // Write JSON to file
      await file.writeAsString(jsonString);

      _logger.info('downloadWorkflowTemplate: File created - $fileName');

      // Share the file (opens system share sheet)
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'FlowDash Error Workflow - $instanceName',
        text: 'Import this workflow into your n8n instance to receive error notifications.',
      );

      _logger.info('downloadWorkflowTemplate: Share completed');

      // Return file path
      return file.path;
    } catch (e, stackTrace) {
      _logger.severe('downloadWorkflowTemplate: Failure', e, stackTrace);
      rethrow;
    }
  }

  /// Send test notification to verify setup.
  /// 
  /// Creates a test payload and sends it through the error webhook
  /// flow to verify everything is working.
  Future<Map<String, dynamic>> sendTestNotification({
    required String instanceId,
    required String workflowId,
    required String workflowName,
    CancelToken? cancelToken,
  }) async {
    _logger.info('sendTestNotification: Entry - instance: $instanceId');

    try {
      final testPayload = {
        'executionId': 'test-${DateTime.now().millisecondsSinceEpoch}',
        'workflowId': workflowId,
        'workflowName': workflowName,
        'instanceId': instanceId,
        'severity': 'error',
        'error': {
          'message': 'This is a test notification from FlowDash mobile app',
        },
      };

      final result = await _repository.sendTestNotification(
        instanceId: instanceId,
        testPayload: testPayload,
        cancelToken: cancelToken,
      );

      // Update state to mark test as sent
      final state = await checkSetupStatus(instanceId);
      if (state != null) {
        await _saveState(
          state.copyWith(hasTestedNotification: true),
        );
      }

      _logger.info('sendTestNotification: Success');
      return result;
    } catch (e, stackTrace) {
      _logger.severe('sendTestNotification: Failure', e, stackTrace);
      rethrow;
    }
  }

  /// Mark setup as complete and save state.
  Future<void> markSetupComplete({
    required String instanceId,
    required String method, // 'automatic' or 'manual'
    String? workflowId,
  }) async {
    _logger.info(
      'markSetupComplete: Entry - instance: $instanceId, method: $method',
    );

    try {
      final state = ErrorWorkflowSetupState(
        instanceId: instanceId,
        isSetupComplete: true,
        setupMethod: method,
        workflowId: workflowId,
        lastSetupDate: DateTime.now(),
        hasTestedNotification: false,
      );

      await _saveState(state);
      _logger.info('markSetupComplete: Success');
    } catch (e, stackTrace) {
      _logger.severe('markSetupComplete: Failure', e, stackTrace);
      rethrow;
    }
  }

  /// Check current setup status for an instance.
  Future<ErrorWorkflowSetupState?> checkSetupStatus(String instanceId) async {
    _logger.info('checkSetupStatus: Entry - instance: $instanceId');

    try {
      final key = _stateKeyPrefix + instanceId;
      final jsonString = _prefs.getString(key);

      if (jsonString == null) {
        _logger.info('checkSetupStatus: No state found');
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final state = ErrorWorkflowSetupState.fromJson(json);

      _logger.info(
        'checkSetupStatus: Success - isComplete: ${state.isSetupComplete}, method: ${state.setupMethod}',
      );
      return state;
    } catch (e, stackTrace) {
      _logger.severe('checkSetupStatus: Failure', e, stackTrace);
      return null;
    }
  }

  /// Reset setup state (for re-setup).
  Future<void> resetSetup(String instanceId) async {
    _logger.info('resetSetup: Entry - instance: $instanceId');

    try {
      final key = _stateKeyPrefix + instanceId;
      await _prefs.remove(key);
      _logger.info('resetSetup: Success');
    } catch (e, stackTrace) {
      _logger.severe('resetSetup: Failure', e, stackTrace);
      rethrow;
    }
  }

  /// Save state to SharedPreferences.
  Future<void> _saveState(ErrorWorkflowSetupState state) async {
    try {
      final key = _stateKeyPrefix + state.instanceId;
      final jsonString = jsonEncode(state.toJson());
      await _prefs.setString(key, jsonString);
      _logger.info('_saveState: Success');
    } catch (e, stackTrace) {
      _logger.severe('_saveState: Failure', e, stackTrace);
      rethrow;
    }
  }
}

