import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper class for managing cached data with TTL and stale-while-revalidate support
class CacheHelper {
  static final Map<String, CachedData<dynamic>> _memoryCache = {};
  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences (call once at app startup)
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get cached data from memory or disk
  static Future<T?> get<T>({
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
    Duration? maxAge,
    Duration? staleAge,
  }) async {
    // Check memory cache first (fastest)
    if (_memoryCache.containsKey(key)) {
      final cached = _memoryCache[key]!;
      if (maxAge != null && cached.isValid(maxAge)) {
        return cached.data as T;
      } else if (staleAge != null && cached.isValid(staleAge)) {
        // Stale but acceptable - return it, will refresh in background
        return cached.data as T;
      }
    }

    // Check disk cache
    if (_prefs != null) {
      final cachedJson = _prefs!.getString(key);
      if (cachedJson != null) {
        try {
      final json = jsonDecode(cachedJson) as Map<String, dynamic>;
      final timestamp = DateTime.parse(json['timestamp'] as String);
      final cachedData = json['data'];
      
      if (maxAge != null && DateTime.now().difference(timestamp) < maxAge) {
        final data = fromJson(cachedData as Map<String, dynamic>);
        _memoryCache[key] = CachedData(data, timestamp);
        return data;
      } else if (staleAge != null && DateTime.now().difference(timestamp) < staleAge) {
        // Stale but acceptable
        final data = fromJson(cachedData as Map<String, dynamic>);
        _memoryCache[key] = CachedData(data, timestamp);
        return data;
      }
        } catch (e) {
          // Invalid cache data, remove it
          await _prefs!.remove(key);
        }
      }
    }

    return null;
  }

  /// Set cached data in both memory and disk
  static Future<void> set<T>({
    required String key,
    required T data,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    final cached = CachedData(data, DateTime.now());
    _memoryCache[key] = cached;

    if (_prefs != null) {
      try {
        await _prefs!.setString(
          key,
          jsonEncode(cached.toJson(toJson)),
        );
      } catch (e) {
        // Silently fail if disk write fails
      }
    }
  }

  /// Remove cached data
  static Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _prefs?.remove(key);
  }

  /// Clear all cache
  static Future<void> clear() async {
    _memoryCache.clear();
    await _prefs?.clear();
  }

  /// Check if cache exists and is valid
  static bool isValid(String key, Duration maxAge) {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key]!.isValid(maxAge);
    }
    return false;
  }
}

/// Wrapper for cached data with timestamp
class CachedData<T> {
  final T data;
  final DateTime timestamp;

  CachedData(this.data, this.timestamp);

  bool isValid(Duration ttl) {
    return DateTime.now().difference(timestamp) < ttl;
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) serializer) {
    return {
      'data': serializer(data),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CachedData.fromJson(Map<String, dynamic> json) {
    return CachedData(
      json['data'] as T,
      DateTime.parse(json['timestamp']),
    );
  }
}

