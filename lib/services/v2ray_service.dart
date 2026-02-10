import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:http/http.dart' as http;
import 'package:zedsecure/models/v2ray_config.dart';
import 'package:zedsecure/models/subscription.dart';
import 'package:zedsecure/models/app_settings.dart';
import 'package:zedsecure/services/v2ray_config_builder.dart';
import 'package:zedsecure/services/log_service.dart';
import 'package:zedsecure/services/native_ping_service.dart';
import 'package:zedsecure/services/mmkv_manager.dart';

class V2RayService extends ChangeNotifier {
  bool _isInitialized = false;
  V2RayConfig? _activeConfig;
  V2RayStatus? _currentStatus;
  
  final Map<String, int?> _pingCache = {};
  final Map<String, Future<int?>?> _pendingPings = {};
  static const Duration _pingTimeout = Duration(seconds: 5);

  static final V2RayService _instance = V2RayService._internal();
  factory V2RayService() => _instance;

  late final V2ray _flutterV2ray;
  
  List<String> _customDnsServers = ['1.1.1.1', '1.0.0.1'];
  bool _useDns = true;
  String? _detectedCountryCode;
  String? _detectedIP;
  String? _detectedCity;
  String? _detectedRegion;
  String? _detectedASN;

  V2RayStatus? get currentStatus => _currentStatus;
  V2RayConfig? get activeConfig => _activeConfig;
  bool get isConnected => _activeConfig != null;
  String? get detectedCountryCode => _detectedCountryCode;
  String? get detectedIP => _detectedIP;
  String? get detectedCity => _detectedCity;
  String? get detectedRegion => _detectedRegion;
  String? get detectedASN => _detectedASN;
  bool get useDns => _useDns;
  List<String> get dnsServers => List.from(_customDnsServers);

  V2RayService._internal() {
    _flutterV2ray = V2ray(
      onStatusChanged: (status) {
        _currentStatus = status;
        _handleStatusChange(status);
        notifyListeners();
      },
    );
    _loadPingCache();
  }

  void _handleStatusChange(V2RayStatus status) {
    String statusString = status.toString().toLowerCase();
    if ((statusString.contains('disconnect') ||
            statusString.contains('stop') ||
            statusString.contains('idle')) &&
        _activeConfig != null) {
      _activeConfig = null;
      _clearActiveConfig();
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _flutterV2ray.initialize(
        notificationIconResourceType: "mipmap",
        notificationIconResourceName: "ic_launcher",
      );
      _isInitialized = true;
      await _loadDnsSettings();
      await _tryRestoreActiveConfig();
      detectRealCountry();
    }
  }

  Future<void> _loadDnsSettings() async {
    _useDns = MmkvManager.decodeSettingsBool('use_custom_dns', defaultValue: true);
    final dnsString = MmkvManager.decodeSettings('custom_dns_servers');
    if (dnsString != null && dnsString.isNotEmpty) {
      _customDnsServers = dnsString.split(',');
    }
  }
  
  Future<void> _loadPingCache() async {
    try {
      final cacheData = MmkvManager.loadPingCache();
      if (cacheData != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        cacheData.forEach((key, value) {
          if (value is Map && value['ping'] != null && value['timestamp'] != null) {
            final timestamp = value['timestamp'] as int;
            if (now - timestamp < 3600000) {
              _pingCache[key] = value['ping'] as int?;
            }
          }
        });
        debugPrint('Loaded ${_pingCache.length} cached ping results');
      }
    } catch (e) {
      debugPrint('Error loading ping cache: $e');
    }
  }
  
  Future<void> _savePingCache() async {
    try {
      final Map<String, dynamic> cacheData = {};
      final now = DateTime.now().millisecondsSinceEpoch;
      _pingCache.forEach((key, value) {
        if (value != null && value >= 0) {
          cacheData[key] = {
            'ping': value,
            'timestamp': now,
          };
        }
      });
      MmkvManager.savePingCache(cacheData);
    } catch (e) {
      debugPrint('Error saving ping cache: $e');
    }
  }
  
  Future<void> saveDnsSettings(bool enabled, List<String> servers) async {
    _useDns = enabled;
    _customDnsServers = servers;
    MmkvManager.encodeSettingsBool('use_custom_dns', enabled);
    MmkvManager.encodeSettings('custom_dns_servers', servers.join(','));
    notifyListeners();
  }
  
  Future<String?> detectRealCountry({int maxRetries = 3}) async {
    final ipInfoSources = [
      {
        'url': 'https://ipwho.is/',
        'parser': (Map<String, dynamic> data) {
          return {
            'country': data['country_code']?.toString().toUpperCase(),
            'ip': data['ip']?.toString(),
            'city': data['city']?.toString(),
            'region': data['region']?.toString(),
            'asn': data['connection']?['asn']?.toString(),
            'org': data['connection']?['org']?.toString(),
          };
        }
      },
      {
        'url': 'https://api.ip.sb/geoip/',
        'parser': (Map<String, dynamic> data) {
          return {
            'country': data['country_code']?.toString().toUpperCase(),
            'ip': data['ip']?.toString(),
            'city': data['city']?.toString(),
            'region': data['region']?.toString(),
            'asn': data['asn']?.toString(),
            'org': data['organization']?.toString(),
          };
        }
      },
      {
        'url': 'https://ipapi.co/json/',
        'parser': (Map<String, dynamic> data) {
          return {
            'country': data['country_code']?.toString().toUpperCase(),
            'ip': data['ip']?.toString(),
            'city': data['city']?.toString(),
            'region': data['region']?.toString(),
            'asn': data['asn']?.toString(),
            'org': data['org']?.toString(),
          };
        }
      },
      {
        'url': 'https://ipinfo.io/json',
        'parser': (Map<String, dynamic> data) {
          return {
            'country': data['country']?.toString().toUpperCase(),
            'ip': data['ip']?.toString(),
            'city': data['city']?.toString(),
            'region': data['region']?.toString(),
            'asn': null,
            'org': data['org']?.toString(),
          };
        }
      },
    ];
    
    HttpClient? httpClient;
    try {
      httpClient = HttpClient();
      
      if (isConnected) {
        final settingsJson = MmkvManager.decodeSettings('app_settings');
        AppSettings appSettings;
        if (settingsJson != null) {
          appSettings = AppSettings.fromJson(jsonDecode(settingsJson));
        } else {
          appSettings = AppSettings();
        }
        
        final proxyUrl = 'localhost:${appSettings.socksPort}';
        debugPrint('🔌 Using SOCKS proxy: $proxyUrl');
        
        httpClient.findProxy = (uri) {
          return 'PROXY $proxyUrl';
        };
      } else {
        debugPrint('📱 VPN not connected, using direct connection');
        httpClient.findProxy = (uri) {
          return 'DIRECT';
        };
      }
    } catch (e) {
      debugPrint('⚠️ HttpClient setup failed: $e');
      httpClient?.close();
      httpClient = null;
    }
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      for (final source in ipInfoSources) {
        try {
          debugPrint('📡 Attempt $attempt/$maxRetries with ${source['url']}...');
          
          if (httpClient != null) {
            final uri = Uri.parse(source['url'] as String);
            final request = await httpClient.getUrl(uri);
            final response = await request.close().timeout(const Duration(seconds: 10));
            
            if (response.statusCode == 200) {
              final responseBody = await response.transform(utf8.decoder).join();
              final data = jsonDecode(responseBody) as Map<String, dynamic>;
              final parser = source['parser'] as Map<String, dynamic> Function(Map<String, dynamic>);
              final parsed = parser(data);
              
              _detectedCountryCode = parsed['country'];
              _detectedIP = parsed['ip'];
              _detectedCity = parsed['city'];
              _detectedRegion = parsed['region'];
              _detectedASN = parsed['asn'] ?? parsed['org'];
              
              if (_detectedCountryCode != null && _detectedIP != null) {
                debugPrint('✅ Success with ${source['url']}!');
                debugPrint('   Country=$_detectedCountryCode, IP=$_detectedIP');
                debugPrint('   City=$_detectedCity, Region=$_detectedRegion, ASN=$_detectedASN');
                notifyListeners();
                
                httpClient.close();
                return _detectedCountryCode;
              }
            } else {
              debugPrint('❌ HTTP ${response.statusCode} from ${source['url']}');
            }
          } else {
            final response = await http.get(
              Uri.parse(source['url'] as String),
            ).timeout(const Duration(seconds: 10));
            
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body) as Map<String, dynamic>;
              final parser = source['parser'] as Map<String, dynamic> Function(Map<String, dynamic>);
              final parsed = parser(data);
              
              _detectedCountryCode = parsed['country'];
              _detectedIP = parsed['ip'];
              _detectedCity = parsed['city'];
              _detectedRegion = parsed['region'];
              _detectedASN = parsed['asn'] ?? parsed['org'];
              
              if (_detectedCountryCode != null && _detectedIP != null) {
                debugPrint('✅ Success with ${source['url']}!');
                debugPrint('   Country=$_detectedCountryCode, IP=$_detectedIP');
                debugPrint('   City=$_detectedCity, Region=$_detectedRegion, ASN=$_detectedASN');
                notifyListeners();
                return _detectedCountryCode;
              }
            } else {
              debugPrint('❌ HTTP ${response.statusCode} from ${source['url']}');
            }
          }
        } catch (e) {
          debugPrint('❌ Failed with ${source['url']}: $e');
          continue;
        }
      }
      
      if (attempt < maxRetries) {
        debugPrint('⏳ Waiting before retry $attempt...');
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    
    httpClient?.close();
    
    debugPrint('❌ All attempts failed with all sources');
    return null;
  }

  Future<bool> connect(V2RayConfig config, {AppSettings? settings}) async {
    final logger = LogService();
    try {
      logger.log('=== V2Ray Connection Start ===', level: LogLevel.info);
      logger.log('Config: ${config.remark}', level: LogLevel.info);
      logger.log('Address: ${config.address}:${config.port}', level: LogLevel.info);
      logger.log('Protocol: ${config.configType}', level: LogLevel.info);
      
      await initialize();
      logger.log('V2Ray initialized', level: LogLevel.info);

      AppSettings appSettings;
      if (settings != null) {
        appSettings = settings;
      } else {
        final settingsJson = MmkvManager.decodeSettings('app_settings');
        if (settingsJson != null) {
          appSettings = AppSettings.fromJson(jsonDecode(settingsJson));
        } else {
          appSettings = AppSettings();
        }
      }
      
      logger.log('App Settings loaded: proxyOnly=${appSettings.proxyOnlyMode}, mux=${appSettings.muxSettings.enabled}', level: LogLevel.info);

      final blockedAppsJson = MmkvManager.decodeSettings('blocked_apps');
      List<String>? blockedAppsList;
      if (blockedAppsJson != null && blockedAppsJson.isNotEmpty) {
        try {
          blockedAppsList = List<String>.from(jsonDecode(blockedAppsJson));
        } catch (e) {
          debugPrint('Error parsing blocked apps: $e');
        }
      }
      logger.log('Blocked apps count: ${blockedAppsList?.length ?? 0}', level: LogLevel.info);

      logger.log('Building full config...', level: LogLevel.info);
      final fullConfig = V2RayConfigBuilder.buildFullConfig(
        serverConfig: config,
        settings: appSettings,
        blockedApps: blockedAppsList,
      );

      final configJson = jsonEncode(fullConfig);
      logger.log('Config JSON generated: ${configJson.length} bytes', level: LogLevel.info);

      logger.log('Requesting VPN permission...', level: LogLevel.info);
      bool hasPermission = await _flutterV2ray.requestPermission();
      if (!hasPermission) {
        logger.log('VPN permission denied', level: LogLevel.error);
        return false;
      }
      logger.log('VPN permission granted', level: LogLevel.info);

      logger.log('Starting V2Ray core...', level: LogLevel.info);
      await _flutterV2ray.startV2Ray(
        remark: config.remark,
        config: configJson,
        blockedApps: blockedAppsList,
        proxyOnly: appSettings.proxyOnlyMode,
        notificationDisconnectButtonName: "DISCONNECT",
      );
      logger.log('V2Ray core start command sent', level: LogLevel.info);

      _activeConfig = config;
      await _saveActiveConfig(config);
      
      logger.log('Detecting country...', level: LogLevel.info);
      detectRealCountry();
      
      notifyListeners();

      logger.log('=== V2Ray Connection Success ===', level: LogLevel.info);
      return true;
    } catch (e, stackTrace) {
      logger.log('=== V2Ray Connection Error ===', level: LogLevel.error);
      logger.log('Error: $e', level: LogLevel.error);
      logger.log('Stack trace: $stackTrace', level: LogLevel.error);
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _flutterV2ray.stopV2Ray();
      _activeConfig = null;
      _detectedCountryCode = null;
      _detectedIP = null;
      _detectedCity = null;
      _detectedRegion = null;
      _detectedASN = null;
      await _clearActiveConfig();
      notifyListeners();
      detectRealCountry();
    } catch (e) {
      debugPrint('Error disconnecting from V2Ray: $e');
    }
  }

  Future<int?> getServerDelay(V2RayConfig config, {bool useCache = true}) async {
    final configId = config.id;
    final hostKey = '${config.address}:${config.port}';

    if (_pendingPings[configId] != null) {
      return _pendingPings[configId];
    }

    final completer = Completer<int?>();
    _pendingPings[configId] = completer.future;

    try {
      if (useCache && _pingCache.containsKey(hostKey)) {
        final cachedValue = _pingCache[hostKey];
        if (cachedValue != null && cachedValue >= 0) {
          completer.complete(cachedValue);
          return cachedValue;
        }
      }

      final timeoutFuture = Future.delayed(_pingTimeout, () => -1);
      final settingsJson = MmkvManager.decodeSettings('app_settings');
      AppSettings appSettings;
      if (settingsJson != null) {
        appSettings = AppSettings.fromJson(jsonDecode(settingsJson));
      } else {
        appSettings = AppSettings();
      }

      final speedtestConfig = V2RayConfigBuilder.buildConfigForSpeedtest(
        serverConfig: config,
        settings: appSettings,
      );

      final configJson = jsonEncode(speedtestConfig);
      final pingFuture = _flutterV2ray.measureOutboundDelay(
        config: configJson, 
        url: appSettings.connectionTestUrl
      ).timeout(
        _pingTimeout,
        onTimeout: () => -1,
      );

      final result = await Future.any([pingFuture, timeoutFuture]);
      
      if (result != null && result >= 0 && result < 10000) {
        _pingCache[hostKey] = result;
        _pingCache[configId] = result;
        if (useCache) _savePingCache();
      } else {
        _pingCache[hostKey] = -1;
        _pingCache[configId] = -1;
      }

      completer.complete(result);
      return result;
    } catch (e) {
      _pingCache[hostKey] = -1;
      completer.complete(-1);
      return -1;
    } finally {
      _pendingPings.remove(configId);
    }
  }

  void clearPingCache({String? configId}) {
    if (configId != null) {
      _pingCache.remove(configId);
    } else {
      _pingCache.clear();
    }
    _savePingCache();
  }

  Future<Map<String, dynamic>> parseSubscriptionUrl(String url, {String? subscriptionId, bool forceResolve = false}) async {
    try {
      debugPrint('Fetching subscription from: $url');
      
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception('Network timeout: Check your internet connection');
            },
          );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body length: ${response.body.length}');
      debugPrint('Response headers: ${response.headers}');

      if (response.statusCode != 200) {
        throw Exception('Failed to load subscription: HTTP ${response.statusCode}');
      }

      if (response.body.isEmpty) {
        throw Exception('Empty response from subscription URL');
      }

      final configs = await _parseContent(response.body, source: 'subscription', subscriptionId: subscriptionId, forceResolve: forceResolve);
      
      final subInfo = _parseSubscriptionInfo(response.headers);
      
      return {
        'configs': configs,
        'subInfo': subInfo,
      };
    } catch (e) {
      debugPrint('Error parsing subscription: $e');
      
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception('Network error: Check your internet connection');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Connection timeout: Server is not responding');
      } else if (e.toString().contains('Invalid URL')) {
        throw Exception('Invalid subscription URL format');
      } else if (e.toString().contains('No valid configurations')) {
        throw Exception('No valid servers found in subscription');
      } else {
        throw Exception('Failed to update subscription: ${e.toString()}');
      }
    }
  }

  Map<String, dynamic>? _parseSubscriptionInfo(Map<String, String> headers) {
    final subInfoStr = headers['subscription-userinfo'];
    if (subInfoStr == null) return null;

    try {
      final values = subInfoStr.split(';');
      final map = <String, int>{};
      
      for (final v in values) {
        final parts = v.split('=');
        if (parts.length == 2) {
          final key = parts[0].trim();
          final value = num.tryParse(parts[1].trim())?.toInt();
          if (value != null) {
            map[key] = value;
          }
        }
      }

      if (map.containsKey('upload') && map.containsKey('download') && map.containsKey('total')) {
        final upload = map['upload']!;
        final download = map['download']!;
        var total = map['total']!;
        var expire = map['expire'];

        const infiniteTrafficThreshold = 9223372036854775807;
        const infiniteTimeThreshold = 92233720368;

        if (total == 0) total = infiniteTrafficThreshold;
        if (expire == null || expire == 0) expire = infiniteTimeThreshold;

        return {
          'upload': upload,
          'download': download,
          'total': total,
          'expire': DateTime.fromMillisecondsSinceEpoch(expire * 1000),
        };
      }
    } catch (e) {
      debugPrint('Error parsing subscription info: $e');
    }

    return null;
  }

  Future<List<V2RayConfig>> parseSubscriptionContent(String content) async {
    try {
      return _parseContent(content, source: 'subscription', forceResolve: false);
    } catch (e) {
      debugPrint('Error parsing subscription content: $e');
      
      if (e.toString().contains('No valid configurations')) {
        throw Exception('No valid servers found in file');
      } else {
        throw Exception('Failed to parse subscription file: ${e.toString()}');
      }
    }
  }

  Future<V2RayConfig?> parseConfigFromClipboard(String clipboardText) async {
    try {
      final configs = await _parseContent(clipboardText, source: 'manual');
      if (configs.isNotEmpty) {
        final allConfigs = await loadConfigs();
        allConfigs.add(configs.first);
        await saveConfigs(allConfigs);
        return configs.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing clipboard config: $e');
      throw Exception('Invalid config format');
    }
  }

  Future<List<V2RayConfig>> _parseContent(String content, {String source = 'subscription', String? subscriptionId, bool forceResolve = false}) async {
    final List<V2RayConfig> configs = [];

    try {
      content = content.trim();
      
      if (_isBase64(content)) {
        debugPrint('Content is base64 encoded, decoding...');
        try {
          String normalized = content;
          normalized = normalized.replaceAll('-', '+').replaceAll('_', '/');
          
          while (normalized.length % 4 != 0) {
            normalized += '=';
          }
          
          final decoded = utf8.decode(base64.decode(normalized));
          debugPrint('Decoded content length: ${decoded.length}');
          content = decoded;
        } catch (e) {
          debugPrint('Base64 decode failed, trying original: $e');
        }
      }
    } catch (e) {
      debugPrint('Not a valid base64 content, using original: $e');
    }

    if (content.contains('inbounds') && content.contains('outbounds') && content.contains('routing')) {
      debugPrint('Detected JSON format subscription');
      try {
        final dynamic jsonData = jsonDecode(content);
        
        if (jsonData is List) {
          debugPrint('Processing JSON array with ${jsonData.length} configs');
          for (var i = jsonData.length - 1; i >= 0; i--) {
            try {
              final configJson = jsonData[i];
              if (configJson is Map<String, dynamic>) {
                final parsedConfig = await _parseJsonConfig(configJson, source, subscriptionId, forceResolve);
                if (parsedConfig != null) {
                  configs.add(parsedConfig);
                }
              }
            } catch (e) {
              debugPrint('Error parsing JSON config at index $i: $e');
            }
          }
          
          if (configs.isNotEmpty) {
            debugPrint('Total JSON configs parsed: ${configs.length}');
            return configs;
          }
        } else if (jsonData is Map<String, dynamic>) {
          debugPrint('Processing single JSON config');
          final parsedConfig = await _parseJsonConfig(jsonData, source, subscriptionId, forceResolve);
          if (parsedConfig != null) {
            configs.add(parsedConfig);
            return configs;
          }
        }
      } catch (e) {
        debugPrint('JSON parsing failed, falling back to line-by-line: $e');
      }
    }

    final List<String> lines = content.split('\n');
    debugPrint('Processing ${lines.length} lines');

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      try {
        if (line.startsWith('vmess://') ||
            line.startsWith('vless://') ||
            line.startsWith('trojan://') ||
            line.startsWith('ss://') ||
            line.startsWith('hysteria2://') ||
            line.startsWith('hy2://') ||
            line.startsWith('wireguard://') ||
            line.startsWith('wg://')) {
          V2RayURL parser = V2ray.parseFromURL(line);
          String configType = '';

          if (line.startsWith('vmess://')) {
            configType = 'vmess';
          } else if (line.startsWith('vless://')) {
            configType = 'vless';
          } else if (line.startsWith('ss://')) {
            configType = 'shadowsocks';
          } else if (line.startsWith('trojan://')) {
            configType = 'trojan';
          } else if (line.startsWith('hysteria2://') || line.startsWith('hy2://')) {
            configType = 'hysteria2';
          } else if (line.startsWith('wireguard://') || line.startsWith('wg://')) {
            configType = 'wireguard';
          }

          String address = parser.address;
          int port = parser.port;

          String modifiedConfig = line;
          String remark = parser.remark;
          if (forceResolve && address.isNotEmpty && !_isIpAddress(address)) {
            final resolvedIp = await _resolveHostname(address);
            if (resolvedIp != null) {
              remark = resolvedIp;
              modifiedConfig = _rewriteConfigWithIp(line, address, resolvedIp, configType);
            }
          }

          configs.add(
            V2RayConfig(
              id: DateTime.now().millisecondsSinceEpoch.toString() + configs.length.toString(),
              remark: remark,
              address: address,
              port: port,
              configType: configType,
              fullConfig: modifiedConfig,
              source: source,
              subscriptionId: subscriptionId,
            ),
          );
          debugPrint('Parsed config: $remark');
        }
      } catch (e) {
        debugPrint('Error parsing line: $e');
      }
    }

    debugPrint('Total configs parsed: ${configs.length}');

    if (configs.isEmpty) {
      throw Exception('No valid configurations found in subscription');
    }

    return configs;
  }

  Future<String?> _resolveHostname(String hostname) async {
    try {
      final result = await InternetAddress.lookup(hostname);
      if (result.isNotEmpty && result[0].address.isNotEmpty) {
        return result[0].address;
      }
    } catch (e) {
      debugPrint('Failed to resolve hostname $hostname: $e');
    }
    return null;
  }

  bool _isBase64(String str) {
    str = str.trim();
    if (str.length % 4 != 0) {
      return false;
    }
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/=]+$');
    return base64Pattern.hasMatch(str);
  }

  bool _isIpAddress(String address) {
    final ipPattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    return ipPattern.hasMatch(address);
  }

  String _rewriteConfigWithIp(String originalConfig, String originalAddress, String resolvedIp, String configType) {
    String modifiedConfig = originalConfig;
    bool needsSni = false;
    bool hasSni = false;
    String sniParam = 'sni';

    if (configType == 'vmess' || configType == 'vless' || configType == 'trojan' || configType == 'hysteria2') {
      if (configType == 'vmess' || configType == 'vless') {
        if (modifiedConfig.contains('security=tls') || modifiedConfig.contains('security=reality')) {
          needsSni = true;
        }
      } else if (configType == 'trojan') {
        needsSni = true;
      } else if (configType == 'hysteria2') {
        needsSni = true;
        sniParam = 'peer';
      }
      hasSni = modifiedConfig.contains('sni=') || modifiedConfig.contains('peer=');
    }

    if (needsSni && !hasSni) {
      final separator = modifiedConfig.contains('?') ? '&' : '?';
      modifiedConfig = '${modifiedConfig}${separator}$sniParam=${Uri.encodeComponent(originalAddress)}';
    }

    final addressPattern = RegExp(r'@(.*?):');
    final match = addressPattern.firstMatch(modifiedConfig);
    if (match != null) {
      final beforeMatch = modifiedConfig.substring(0, match.start + 1);
      final afterMatch = modifiedConfig.substring(match.end - 1);
      modifiedConfig = '$beforeMatch$resolvedIp$afterMatch';
    }
    
    return modifiedConfig;
  }

  void _preserveSniInJson(Map<String, dynamic> outbound, String originalAddress) {
    if (outbound['streamSettings'] != null) {
      final streamSettings = outbound['streamSettings'] as Map<String, dynamic>;
      
      if (streamSettings['tlsSettings'] != null) {
        final tlsSettings = streamSettings['tlsSettings'] as Map<String, dynamic>;
        if (tlsSettings['serverName'] == null || tlsSettings['serverName'].toString().isEmpty) {
          tlsSettings['serverName'] = originalAddress;
        }
      } else if (streamSettings['realitySettings'] != null) {
        final realitySettings = streamSettings['realitySettings'] as Map<String, dynamic>;
        if (realitySettings['serverNames'] != null && (realitySettings['serverNames'] as List).isEmpty) {
          realitySettings['serverNames'] = [originalAddress];
        }
      }
    } else if (outbound['protocol']?.toString().toLowerCase() == 'trojan') {
      final settings = outbound['settings'] as Map<String, dynamic>;
      if (settings['servers'] is List && (settings['servers'] as List).isNotEmpty) {
        final server = (settings['servers'] as List)[0] as Map<String, dynamic>;
        if (server['sni'] == null || server['sni'].toString().isEmpty) {
          server['sni'] = originalAddress;
        }
      }
    }
  }

  void _preserveHysteria2Sni(Map<String, dynamic> settings, String originalAddress) {
    if (settings['sni'] == null || settings['sni'].toString().isEmpty) {
      settings['sni'] = originalAddress;
    }
  }

  Future<String> _resolveHostnameForRemark(String address, String originalRemark) async {
    if (_isIpAddress(address) || address.isEmpty) {
      return originalRemark;
    }
    try {
      final resolvedIp = await _resolveHostname(address);
      return resolvedIp ?? originalRemark;
    } catch (e) {
      return originalRemark;
    }
  }

  Future<V2RayConfig?> _parseJsonConfig(Map<String, dynamic> configJson, String source, String? subscriptionId, bool forceResolve) async {
    try {
      final remark = configJson['remarks'] ?? 'Config ${DateTime.now().millisecondsSinceEpoch}';
      
      String address = '';
      int port = 0;
      String configType = 'custom';
      
      if (configJson['outbounds'] is List) {
        final outbounds = configJson['outbounds'] as List;
        
        for (var outbound in outbounds) {
          if (outbound is! Map) continue;
          final outboundMap = Map<String, dynamic>.from(outbound);
          
          final protocol = outboundMap['protocol']?.toString().toLowerCase() ?? '';
          
          if (protocol == 'vmess' || protocol == 'vless' || 
              protocol == 'trojan' || protocol == 'shadowsocks' ||
              protocol == 'socks' || protocol == 'http' ||
              protocol == 'wireguard' || protocol == 'hysteria2' || protocol == 'hysteria') {
            
            configType = protocol;
            
            if (outboundMap['settings'] != null) {
              final settings = outboundMap['settings'];
              
              if (protocol == 'vmess' || protocol == 'vless') {
                if (settings['vnext'] is List && (settings['vnext'] as List).isNotEmpty) {
                  final vnext = (settings['vnext'] as List)[0];
                  address = vnext['address'] ?? '';
                  port = vnext['port'] ?? 0;
                  
                  if (forceResolve && address.isNotEmpty && !_isIpAddress(address)) {
                    final resolvedIp = await _resolveHostname(address);
                    if (resolvedIp != null) {
                      vnext['address'] = resolvedIp;
                      _preserveSniInJson(outboundMap, address);
                    }
                  }
                }
              } else if (protocol == 'shadowsocks' || protocol == 'socks' || 
                         protocol == 'http' || protocol == 'trojan') {
                if (settings['servers'] is List && (settings['servers'] as List).isNotEmpty) {
                  final server = (settings['servers'] as List)[0];
                  address = server['address'] ?? '';
                  port = server['port'] ?? 0;
                  
                  if (forceResolve && address.isNotEmpty && !_isIpAddress(address) && protocol == 'trojan') {
                    final resolvedIp = await _resolveHostname(address);
                    if (resolvedIp != null) {
                      server['address'] = resolvedIp;
                      _preserveSniInJson(outboundMap, address);
                    }
                  }
                }
              } else if (protocol == 'wireguard') {
                if (settings['peers'] is List && (settings['peers'] as List).isNotEmpty) {
                  final peer = (settings['peers'] as List)[0];
                  final endpoint = peer['endpoint']?.toString() ?? '';
                  if (endpoint.contains(':')) {
                    final parts = endpoint.split(':');
                    address = parts[0];
                    port = int.tryParse(parts[1]) ?? 0;
                    
                    if (forceResolve && address.isNotEmpty && !_isIpAddress(address)) {
                      final resolvedIp = await _resolveHostname(address);
                      if (resolvedIp != null) {
                        peer['endpoint'] = '$resolvedIp:$port';
                      }
                    }
                  }
                }
              } else if (protocol == 'hysteria2' || protocol == 'hysteria') {
                address = settings['address']?.toString() ?? '';
                port = settings['port'] ?? 0;
                
                if (forceResolve && address.isNotEmpty && !_isIpAddress(address)) {
                  final resolvedIp = await _resolveHostname(address);
                  if (resolvedIp != null) {
                    final originalAddress = address;
                    settings['address'] = resolvedIp;
                    if (protocol == 'hysteria2') {
                      _preserveHysteria2Sni(settings, originalAddress);
                    } else {
                      _preserveSniInJson(outboundMap, originalAddress);
                    }
                  }
                }
              }
            }
            
            break;
          }
        }
      }
      
      final fullConfigStr = jsonEncode(configJson);
      final finalRemark = forceResolve ? await _resolveHostnameForRemark(address, remark) : remark;
      
      return V2RayConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + (address + port.toString()).hashCode.toString(),
        remark: finalRemark,
        address: address,
        port: port,
        configType: configType,
        fullConfig: fullConfigStr,
        source: source,
        subscriptionId: subscriptionId,
      );
    } catch (e) {
      debugPrint('Error parsing JSON config: $e');
      return null;
    }
  }

  Future<void> saveConfigs(List<V2RayConfig> configs) async {
    await MmkvManager.saveConfigs(configs);
    notifyListeners();
  }

  Future<List<V2RayConfig>> loadConfigs() async {
    return await MmkvManager.loadConfigs();
  }

  Future<void> saveSubscriptions(List<Subscription> subscriptions) async {
    await MmkvManager.saveSubscriptions(subscriptions);
  }

  Future<List<Subscription>> loadSubscriptions() async {
    return await MmkvManager.loadSubscriptions();
  }

  Future<void> _saveActiveConfig(V2RayConfig config) async {
    await MmkvManager.saveActiveConfig(config);
  }

  Future<void> _clearActiveConfig() async {
    await MmkvManager.clearActiveConfig();
  }

  Future<V2RayConfig?> _loadActiveConfig() async {
    return await MmkvManager.loadActiveConfig();
  }

  Future<void> saveSelectedConfig(V2RayConfig config) async {
    await MmkvManager.saveSelectedConfig(config);
    notifyListeners();
  }

  Future<V2RayConfig?> loadSelectedConfig() async {
    return await MmkvManager.loadSelectedConfig();
  }

  Future<int?> getConnectedServerDelay() async {
    try {
      debugPrint('📞 getConnectedServerDelay called, isConnected=$isConnected, activeConfig=${_activeConfig?.remark}');
      
      if (!isConnected || _activeConfig == null) {
        debugPrint('❌ Not connected or no active config');
        return null;
      }

      final settingsJson = MmkvManager.decodeSettings('app_settings');
      String testUrl = 'https://www.gstatic.com/generate_204';
      
      if (settingsJson != null) {
        try {
          final settings = AppSettings.fromJson(jsonDecode(settingsJson));
          testUrl = settings.connectionTestUrl;
        } catch (e) {
          debugPrint('Error loading test URL from settings: $e');
        }
      }

      debugPrint('🌐 Calling Flutter V2Ray getConnectedServerDelay with url: $testUrl');
      final delay = await _flutterV2ray.getConnectedServerDelay(url: testUrl);
      debugPrint('📊 Flutter V2Ray returned delay: $delay');
      
      if (delay >= 0) {
        return delay;
      }

      debugPrint('V2Ray delay failed, trying native ping...');
      final pingResult = await NativePingService.pingHost(
        host: _activeConfig!.address,
        port: _activeConfig!.port,
        timeoutMs: 5000,
        useCache: false,
      );

      if (pingResult.success) {
        return pingResult.latency;
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('Error getting connected server delay: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (_activeConfig != null) {
        try {
          final pingResult = await NativePingService.pingHost(
            host: _activeConfig!.address,
            port: _activeConfig!.port,
            timeoutMs: 5000,
            useCache: false,
          );

          if (pingResult.success) {
            return pingResult.latency;
          }
        } catch (pingError) {
          debugPrint('Native ping also failed: $pingError');
        }
      }
      
      return null;
    }
  }

  int? getCachedPing(String configId) {
    return _pingCache[configId];
  }

  Future<V2RayConfig?> parseWireGuardConfigFile(String fileContent) async {
    try {
      debugPrint('Parsing WireGuard config file...');
      
      final Map<String, String> interfaceParams = {};
      final Map<String, String> peerParams = {};
      String? currentSection;

      final lines = fileContent.split('\n');
      for (final line in lines) {
        final trimmedLine = line.trim();
        
        if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
          continue;
        }
        
        if (trimmedLine.toLowerCase().startsWith('[interface]')) {
          currentSection = 'Interface';
          continue;
        } else if (trimmedLine.toLowerCase().startsWith('[peer]')) {
          currentSection = 'Peer';
          continue;
        }
        
        if (currentSection != null && trimmedLine.contains('=')) {
          final parts = trimmedLine.split('=');
          if (parts.length == 2) {
            final key = parts[0].trim().toLowerCase();
            final value = parts[1].trim();
            
            if (currentSection == 'Interface') {
              interfaceParams[key] = value;
            } else if (currentSection == 'Peer') {
              peerParams[key] = value;
            }
          }
        }
      }
      
      final privateKey = interfaceParams['privatekey'] ?? '';
      final address = interfaceParams['address'] ?? '172.16.0.2/32';
      final mtu = interfaceParams['mtu'] ?? '1420';
      final publicKey = peerParams['publickey'] ?? '';
      final presharedKey = peerParams['presharedkey'];
      final endpoint = peerParams['endpoint'] ?? '';
      final reserved = peerParams['reserved'] ?? '0,0,0';
      
      if (privateKey.isEmpty || publicKey.isEmpty || endpoint.isEmpty) {
        throw Exception('Missing required WireGuard parameters');
      }
      
      final endpointParts = endpoint.split(':');
      final server = endpointParts[0];
      final port = endpointParts.length > 1 ? endpointParts[1] : '51820';
      
      final wireguardUrl = 'wireguard://$privateKey@$server:$port?'
          'publickey=$publicKey'
          '&address=${Uri.encodeComponent(address)}'
          '&mtu=$mtu'
          '&reserved=${Uri.encodeComponent(reserved)}'
          '${presharedKey != null ? '&presharedkey=$presharedKey' : ''}'
          '#WireGuard_${DateTime.now().millisecondsSinceEpoch}';
      
      debugPrint('Generated WireGuard URL: $wireguardUrl');
      
      return await parseConfigFromClipboard(wireguardUrl);
    } catch (e) {
      debugPrint('Error parsing WireGuard config file: $e');
      throw Exception('Failed to parse WireGuard config: ${e.toString()}');
    }
  }

  Future<void> _tryRestoreActiveConfig() async {
    try {
      final delay = await _flutterV2ray.getConnectedServerDelay();
      final isConnected = delay >= 0;

      if (isConnected) {
        final savedConfig = await _loadActiveConfig();
        if (savedConfig != null) {
          _activeConfig = savedConfig;
          debugPrint('Restored active config: ${savedConfig.remark}');
          notifyListeners();
        }
      } else {
        await _clearActiveConfig();
        _activeConfig = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error restoring active config: $e');
      await _clearActiveConfig();
      _activeConfig = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
