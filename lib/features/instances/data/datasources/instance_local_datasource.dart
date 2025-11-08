import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/features/instances/data/models/instance_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InstanceLocalDataSource {
  final Logger _logger = AppLogger.getLogger('InstanceLocalDataSource');
  static const String _cacheKey = 'instances_cache';
  static const String _cacheTimestampKey = 'instances_cache_timestamp';
  static const Duration _cacheTTL = Duration(hours: 1);
  
  Future<List<InstanceModel>?> getInstances() async {
    _logger.info('getInstances: Entry');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);
      
      if (cacheTimestamp == null) {
        _logger.info('getInstances: No cache found');
        return null;
      }
      
      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(cacheTimestamp),
      );
      
      if (cacheAge > _cacheTTL) {
        _logger.info('getInstances: Cache expired');
        await clearCache();
        return null;
      }
      
      final json = prefs.getString(_cacheKey);
      if (json == null) {
        _logger.info('getInstances: Cache data not found');
        return null;
      }
      
      final List<dynamic> data = jsonDecode(json) as List<dynamic>;
      final instances = data
          .map((json) => InstanceModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      _logger.info('getInstances: Success (cached) - ${instances.length} instances');
      return instances;
    } catch (e, stackTrace) {
      _logger.severe('getInstances: Failure', e, stackTrace);
      return null;
    }
  }
  
  Future<void> cacheInstances(List<InstanceModel> instances) async {
    _logger.info('cacheInstances: Entry - ${instances.length} instances');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(
        instances.map((i) => i.toJson()).toList(),
      );
      
      await prefs.setString(_cacheKey, json);
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      
      _logger.info('cacheInstances: Success');
    } catch (e, stackTrace) {
      _logger.severe('cacheInstances: Failure', e, stackTrace);
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

