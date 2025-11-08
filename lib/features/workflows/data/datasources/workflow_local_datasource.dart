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
      
      _logger.info('getWorkflows: Success (cached) - ${workflows.length} workflows');
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
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      
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
}

