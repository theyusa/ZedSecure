import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mmkv/mmkv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zedsecure/models/v2ray_config.dart';
import 'package:zedsecure/models/subscription.dart';

class MmkvManager {
  static MMKV? _mainStorage;
  static MMKV? _serverConfigStorage;
  static MMKV? _serverAffStorage;
  static MMKV? _subscriptionStorage;
  static MMKV? _settingsStorage;
  
  static const String _keySelectedServer = 'SELECTED_SERVER';
  static const String _keyActiveServer = 'ACTIVE_SERVER';
  static const String _keyServerList = 'SERVER_LIST';
  static const String _keySubscriptionList = 'SUBSCRIPTION_LIST';
  static const String _keyPingCache = 'PING_CACHE';
  
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final rootDir = await MMKV.initialize();
      debugPrint('MMKV initialized at: $rootDir');
      
      _mainStorage = MMKV('MAIN', mode: MMKVMode.MULTI_PROCESS_MODE);
      _serverConfigStorage = MMKV('SERVER_CONFIG', mode: MMKVMode.MULTI_PROCESS_MODE);
      _serverAffStorage = MMKV('SERVER_AFF', mode: MMKVMode.MULTI_PROCESS_MODE);
      _subscriptionStorage = MMKV('SUBSCRIPTION', mode: MMKVMode.MULTI_PROCESS_MODE);
      _settingsStorage = MMKV('SETTINGS', mode: MMKVMode.MULTI_PROCESS_MODE);
      
      _isInitialized = true;
      debugPrint('MMKV Manager initialized successfully with MULTI_PROCESS_MODE');
    } catch (e) {
      debugPrint('Error initializing MMKV: $e');
      rethrow;
    }
  }

  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('MmkvManager not initialized. Call initialize() first.');
    }
  }

  static Future<void> migrateFromSharedPreferences() async {
    _ensureInitialized();
    debugPrint('Starting migration from SharedPreferences to MMKV...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final configsJson = prefs.getStringList('v2ray_configs');
      if (configsJson != null && configsJson.isNotEmpty) {
        debugPrint('Migrating ${configsJson.length} configs...');
        final configs = configsJson
            .map((json) => V2RayConfig.fromJson(jsonDecode(json)))
            .toList();
        await saveConfigs(configs);
      }
      
      final subscriptionsJson = prefs.getStringList('v2ray_subscriptions');
      if (subscriptionsJson != null && subscriptionsJson.isNotEmpty) {
        debugPrint('Migrating ${subscriptionsJson.length} subscriptions...');
        final subscriptions = subscriptionsJson
            .map((json) => Subscription.fromJson(jsonDecode(json)))
            .toList();
        await saveSubscriptions(subscriptions);
      }
      
      final selectedConfigJson = prefs.getString('selected_config');
      if (selectedConfigJson != null) {
        debugPrint('Migrating selected config...');
        final config = V2RayConfig.fromJson(jsonDecode(selectedConfigJson));
        await saveSelectedConfig(config);
      }
      
      final activeConfigJson = prefs.getString('active_config');
      if (activeConfigJson != null) {
        debugPrint('Migrating active config...');
        final config = V2RayConfig.fromJson(jsonDecode(activeConfigJson));
        await saveActiveConfig(config);
      }
      
      final pingCacheJson = prefs.getString('ping_cache');
      if (pingCacheJson != null) {
        debugPrint('Migrating ping cache...');
        _mainStorage!.encodeString(_keyPingCache, pingCacheJson);
      }
      
      final appSettingsJson = prefs.getString('app_settings');
      if (appSettingsJson != null) {
        debugPrint('Migrating app settings...');
        encodeSettings('app_settings', appSettingsJson);
      }
      
      final useDns = prefs.getBool('use_custom_dns');
      if (useDns != null) {
        encodeSettingsBool('use_custom_dns', useDns);
      }
      
      final dnsServers = prefs.getString('custom_dns_servers');
      if (dnsServers != null) {
        encodeSettings('custom_dns_servers', dnsServers);
      }
      
      final autoConnect = prefs.getBool('auto_connect');
      if (autoConnect != null) {
        encodeSettingsBool('auto_connect', autoConnect);
      }
      
      final darkMode = prefs.getBool('dark_mode');
      if (darkMode != null) {
        encodeSettingsBool('dark_mode', darkMode);
      }
      
      debugPrint('Migration completed successfully!');
    } catch (e) {
      debugPrint('Error during migration: $e');
    }
  }

  static Future<void> saveConfigs(List<V2RayConfig> configs) async {
    _ensureInitialized();
    
    final List<String> serverIds = [];
    
    for (final config in configs) {
      final configJson = jsonEncode(config.toJson());
      _serverConfigStorage!.encodeString(config.id, configJson);
      serverIds.add(config.id);
    }
    
    final serverListJson = jsonEncode(serverIds);
    _mainStorage!.encodeString(_keyServerList, serverListJson);
  }

  static Future<List<V2RayConfig>> loadConfigs() async {
    _ensureInitialized();
    
    final serverListJson = _mainStorage!.decodeString(_keyServerList);
    if (serverListJson == null || serverListJson.isEmpty) {
      return [];
    }
    
    try {
      final List<String> serverIds = List<String>.from(jsonDecode(serverListJson));
      final List<V2RayConfig> configs = [];
      
      for (final id in serverIds) {
        final configJson = _serverConfigStorage!.decodeString(id);
        if (configJson != null) {
          try {
            final config = V2RayConfig.fromJson(jsonDecode(configJson));
            configs.add(config);
          } catch (e) {
            debugPrint('Error parsing config $id: $e');
          }
        }
      }
      
      return configs;
    } catch (e) {
      debugPrint('Error loading configs: $e');
      return [];
    }
  }

  static Future<void> removeServer(String id) async {
    _ensureInitialized();
    
    _serverConfigStorage!.removeValue(id);
    _serverAffStorage!.removeValue(id);
    
    final configs = await loadConfigs();
    configs.removeWhere((config) => config.id == id);
    await saveConfigs(configs);
  }

  static Future<void> removeAllServers() async {
    _ensureInitialized();
    
    _serverConfigStorage!.clearAll();
    _serverAffStorage!.clearAll();
    _mainStorage!.removeValue(_keyServerList);
  }

  static Future<void> saveSubscriptions(List<Subscription> subscriptions) async {
    _ensureInitialized();
    
    final List<String> subIds = [];
    
    for (final sub in subscriptions) {
      final subJson = jsonEncode(sub.toJson());
      _subscriptionStorage!.encodeString(sub.id, subJson);
      subIds.add(sub.id);
    }
    
    final subListJson = jsonEncode(subIds);
    _mainStorage!.encodeString(_keySubscriptionList, subListJson);
  }

  static Future<List<Subscription>> loadSubscriptions() async {
    _ensureInitialized();
    
    final subListJson = _mainStorage!.decodeString(_keySubscriptionList);
    if (subListJson == null || subListJson.isEmpty) {
      return [];
    }
    
    try {
      final List<String> subIds = List<String>.from(jsonDecode(subListJson));
      final List<Subscription> subscriptions = [];
      
      for (final id in subIds) {
        final subJson = _subscriptionStorage!.decodeString(id);
        if (subJson != null) {
          try {
            final sub = Subscription.fromJson(jsonDecode(subJson));
            subscriptions.add(sub);
          } catch (e) {
            debugPrint('Error parsing subscription $id: $e');
          }
        }
      }
      
      return subscriptions;
    } catch (e) {
      debugPrint('Error loading subscriptions: $e');
      return [];
    }
  }

  static Future<Subscription?> loadSubscription(String id) async {
    _ensureInitialized();
    
    final subJson = _subscriptionStorage!.decodeString(id);
    if (subJson == null) return null;
    
    try {
      return Subscription.fromJson(jsonDecode(subJson));
    } catch (e) {
      debugPrint('Error loading subscription $id: $e');
      return null;
    }
  }

  static Future<void> saveSelectedConfig(V2RayConfig config) async {
    _ensureInitialized();
    
    final configJson = jsonEncode(config.toJson());
    _mainStorage!.encodeString(_keySelectedServer, configJson);
  }

  static Future<V2RayConfig?> loadSelectedConfig() async {
    _ensureInitialized();
    
    final configJson = _mainStorage!.decodeString(_keySelectedServer);
    if (configJson == null) return null;
    
    try {
      return V2RayConfig.fromJson(jsonDecode(configJson));
    } catch (e) {
      debugPrint('Error loading selected config: $e');
      return null;
    }
  }

  static Future<void> clearSelectedConfig() async {
    _ensureInitialized();
    _mainStorage!.removeValue(_keySelectedServer);
  }

  static Future<void> saveActiveConfig(V2RayConfig config) async {
    _ensureInitialized();
    
    final configJson = jsonEncode(config.toJson());
    _mainStorage!.encodeString(_keyActiveServer, configJson);
  }

  static Future<V2RayConfig?> loadActiveConfig() async {
    _ensureInitialized();
    
    final configJson = _mainStorage!.decodeString(_keyActiveServer);
    if (configJson == null) return null;
    
    try {
      return V2RayConfig.fromJson(jsonDecode(configJson));
    } catch (e) {
      debugPrint('Error loading active config: $e');
      return null;
    }
  }

  static Future<void> clearActiveConfig() async {
    _ensureInitialized();
    _mainStorage!.removeValue(_keyActiveServer);
  }

  static void encodeServerTestDelay(String serverId, int? delayMillis) {
    _ensureInitialized();
    
    if (delayMillis == null || delayMillis < 0) {
      _serverAffStorage!.removeValue('${serverId}_delay');
    } else {
      _serverAffStorage!.encodeInt('${serverId}_delay', delayMillis);
    }
  }

  static int? decodeServerTestDelay(String serverId) {
    _ensureInitialized();
    return _serverAffStorage!.decodeInt('${serverId}_delay');
  }

  static void clearAllTestDelays() {
    _ensureInitialized();
    _serverAffStorage!.clearAll();
  }

  static void savePingCache(Map<String, dynamic> cache) {
    _ensureInitialized();
    
    final cacheJson = jsonEncode(cache);
    _mainStorage!.encodeString(_keyPingCache, cacheJson);
  }

  static Map<String, dynamic>? loadPingCache() {
    _ensureInitialized();
    
    final cacheJson = _mainStorage!.decodeString(_keyPingCache);
    if (cacheJson == null) return null;
    
    try {
      return Map<String, dynamic>.from(jsonDecode(cacheJson));
    } catch (e) {
      debugPrint('Error loading ping cache: $e');
      return null;
    }
  }

  static void encodeSettings(String key, String value) {
    _ensureInitialized();
    _settingsStorage!.encodeString(key, value);
  }

  static String? decodeSettings(String key, {String? defaultValue}) {
    _ensureInitialized();
    return _settingsStorage!.decodeString(key) ?? defaultValue;
  }

  static void encodeSettingsBool(String key, bool value) {
    _ensureInitialized();
    _settingsStorage!.encodeBool(key, value);
  }

  static bool decodeSettingsBool(String key, {bool defaultValue = false}) {
    _ensureInitialized();
    return _settingsStorage!.decodeBool(key) ?? defaultValue;
  }

  static void encodeSettingsInt(String key, int value) {
    _ensureInitialized();
    _settingsStorage!.encodeInt(key, value);
  }

  static int? decodeSettingsInt(String key, {int? defaultValue}) {
    _ensureInitialized();
    return _settingsStorage!.decodeInt(key) ?? defaultValue;
  }

  static void removeSettings(String key) {
    _ensureInitialized();
    _settingsStorage!.removeValue(key);
  }

  static Future<void> clearAll() async {
    _ensureInitialized();
    
    _mainStorage!.clearAll();
    _serverConfigStorage!.clearAll();
    _serverAffStorage!.clearAll();
    _subscriptionStorage!.clearAll();
    _settingsStorage!.clearAll();
    
    debugPrint('All MMKV data cleared');
  }

  static void printStats() {
    _ensureInitialized();
    
    debugPrint('=== MMKV Stats ===');
    debugPrint('Main storage size: ${_mainStorage!.count} keys');
    debugPrint('Server config storage size: ${_serverConfigStorage!.count} keys');
    debugPrint('Server affiliation storage size: ${_serverAffStorage!.count} keys');
    debugPrint('Subscription storage size: ${_subscriptionStorage!.count} keys');
    debugPrint('Settings storage size: ${_settingsStorage!.count} keys');
  }
}
