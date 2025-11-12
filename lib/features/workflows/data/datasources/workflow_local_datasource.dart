import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/features/workflows/data/models/workflow_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkflowLocalDataSource {
  final Logger _logger = AppLogger.getLogger('WorkflowLocalDataSource');
  static const String _cacheKey = 'workflows_cache';
  static const String _cacheTimestampKey = 'workflows_cache_timestamp';
  static const Duration _cacheTTL = Duration(hours: 1);

  WorkflowLocalDataSource();

  Future<List<WorkflowModel>?> getWorkflows() async {
    _logger.info('getWorkflows: Entry');

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);

      if (cacheTimestamp == null) {
        _logger.info('getWorkflows: No cache found');
        return null;
      }

      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(cacheTimestamp),
      );

      if (cacheAge > _cacheTTL) {
        _logger.info('getWorkflows: Cache expired');
        await clearCache();
        return null;
      }

      final json = prefs.getString(_cacheKey);
      if (json == null) {
        _logger.info('getWorkflows: Cache data not found');
        return null;
      }

      final List<dynamic> data = jsonDecode(json) as List<dynamic>;
      final workflows = data
          .map((json) => WorkflowModel.fromJson(json as Map<String, dynamic>))
          .toList();

      _logger.info(
          'getWorkflows: Success (cached) - ${workflows.length} workflows');
      return workflows;
    } catch (e, stackTrace) {
      _logger.severe('getWorkflows: Failure', e, stackTrace);
      return null;
    }
  }

  Future<void> cacheWorkflows(List<WorkflowModel> workflows) async {
    _logger.info('cacheWorkflows: Entry - ${workflows.length} workflows');

    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(
        workflows.map((w) => w.toJson()).toList(),
      );

      await prefs.setString(_cacheKey, json);
      await prefs.setInt(
          _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);

      _logger.info('cacheWorkflows: Success');
    } catch (e, stackTrace) {
      _logger.severe('cacheWorkflows: Failure', e, stackTrace);
    }
  }

  Future<void> clearCache() async {
    _logger.info('clearCache: Entry');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      _logger.info('clearCache: Success');
    } catch (e, stackTrace) {
      _logger.severe('clearCache: Failure', e, stackTrace);
    }
  }

  Future<bool> updateWorkflow(String id, bool active) async {
    _logger.info('updateWorkflow: Entry - id: $id, active: $active');

    try {
      final cached = await getWorkflows();
      if (cached == null || cached.isEmpty) {
        _logger.info('updateWorkflow: No cache found, cannot update');
        return false;
      }

      final index = cached.indexWhere((w) => w.id == id);
      if (index == -1) {
        _logger.info('updateWorkflow: Workflow not found in cache - $id');
        return false;
      }

      // Update the workflow's active status
      final updatedWorkflow = cached[index].copyWith(active: active);
      cached[index] = updatedWorkflow;

      // Save updated list back to cache
      await cacheWorkflows(cached);

      _logger.info('updateWorkflow: Success - $id');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('updateWorkflow: Failure', e, stackTrace);
      return false;
    }
  }

  Future<int> updateWorkflows(List<WorkflowModel> workflows) async {
    _logger.info('updateWorkflows: Entry - ${workflows.length} workflows');

    try {
      final cached = await getWorkflows();
      if (cached == null || cached.isEmpty) {
        _logger.info('updateWorkflows: No cache found, cannot update');
        return 0;
      }

      int updatedCount = 0;
      final updatedCache = <WorkflowModel>[];

      // Create a map of workflows to update for quick lookup
      final workflowsToUpdate = {
        for (var w in workflows) w.id: w
      };

      // Update existing workflows or add new ones
      for (var cachedWorkflow in cached) {
        if (workflowsToUpdate.containsKey(cachedWorkflow.id)) {
          updatedCache.add(workflowsToUpdate[cachedWorkflow.id]!);
          updatedCount++;
        } else {
          updatedCache.add(cachedWorkflow);
        }
      }

      // Add any new workflows that weren't in cache
      for (var workflow in workflows) {
        if (!cached.any((w) => w.id == workflow.id)) {
          updatedCache.add(workflow);
          updatedCount++;
        }
      }

      // Save updated list back to cache
      await cacheWorkflows(updatedCache);

      _logger.info('updateWorkflows: Success - $updatedCount workflows updated');
      return updatedCount;
    } catch (e, stackTrace) {
      _logger.severe('updateWorkflows: Failure', e, stackTrace);
      return 0;
    }
  }
}
