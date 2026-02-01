import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:zedsecure/models/app_settings.dart';
import 'package:zedsecure/models/v2ray_config.dart';

class V2RayConfigBuilder {
  static Map<String, dynamic> buildConfigForSpeedtest({
    required V2RayConfig serverConfig,
    required AppSettings settings,
  }) {
    try {
      debugPrint('Building speedtest config for: ${serverConfig.remark}');
      
      if (serverConfig.configType.toLowerCase() == 'custom') {
        debugPrint('Using custom JSON config for speedtest');
        try {
          final customConfig = jsonDecode(serverConfig.fullConfig);
          if (customConfig is Map<String, dynamic>) {
            return customConfig;
          } else {
            throw Exception('Custom config is not a valid JSON object');
          }
        } catch (e) {
          debugPrint('Error parsing custom config: $e');
          throw Exception('Invalid custom configuration JSON: $e');
        }
      }
      
      final mainOutbound = _parseServerConfig(serverConfig);
      if (mainOutbound == null) {
        debugPrint('ERROR: Failed to parse server config');
        throw Exception('Failed to parse server configuration');
      }
      
      mainOutbound['mux'] = null;
      
      final outbounds = <Map<String, dynamic>>[
        mainOutbound,
        {
          'tag': 'direct',
          'protocol': 'freedom',
          'settings': {},
        },
        {
          'tag': 'block',
          'protocol': 'blackhole',
          'settings': {},
        },
      ];
      
      final config = <String, dynamic>{
        'log': {
          'loglevel': 'warning',
        },
        'outbounds': outbounds,
        'remarks': serverConfig.remark,
      };
      
      debugPrint('Speedtest config built successfully');
      return config;
    } catch (e, stackTrace) {
      debugPrint('Error building speedtest config: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Map<String, dynamic> buildFullConfig({
    required V2RayConfig serverConfig,
    required AppSettings settings,
    List<String>? blockedApps,
  }) {
    try {
      debugPrint('Building config for: ${serverConfig.remark}');
      debugPrint('Protocol: ${serverConfig.configType}');
      
      if (serverConfig.configType.toLowerCase() == 'custom') {
        debugPrint('Using custom JSON config directly');
        try {
          final customConfig = jsonDecode(serverConfig.fullConfig);
          if (customConfig is Map<String, dynamic>) {
            debugPrint('Custom config parsed successfully');
            return customConfig;
          } else {
            throw Exception('Custom config is not a valid JSON object');
          }
        } catch (e) {
          debugPrint('Error parsing custom config: $e');
          throw Exception('Invalid custom configuration JSON: $e');
        }
      }
      
      debugPrint('Full config URL: ${serverConfig.fullConfig}');
      
      final config = <String, dynamic>{
        'dns': _buildDns(settings),
        'inbounds': _buildInbounds(settings),
        'log': _buildLog(settings),
        'outbounds': _buildOutbounds(serverConfig, settings),
        'remarks': serverConfig.remark,
        'routing': _buildRouting(settings),
      };

      if (settings.fakeDnsEnabled) {
        config['fakedns'] = _buildFakeDns();
      }

      if (settings.sniffingEnabled || settings.fakeDnsEnabled) {
        _applySniffing(config, settings);
      }

      debugPrint('Config built successfully');
      return config;
    } catch (e, stackTrace) {
      debugPrint('Error building V2Ray config: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Map<String, dynamic> _buildLog(AppSettings settings) {
    return {
      'loglevel': settings.coreLogLevel,
    };
  }

  static List<Map<String, dynamic>> _buildInbounds(AppSettings settings) {
    final inbounds = <Map<String, dynamic>>[];

    final socksInbound = {
      'listen': '127.0.0.1',
      'port': settings.socksPort,
      'protocol': 'socks',
      'settings': {
        'auth': 'noauth',
        'udp': true,
        'userLevel': 8,
      },
      'sniffing': {
        'destOverride': ['http', 'tls'],
        'enabled': true,
        'routeOnly': false,
      },
      'tag': 'socks',
    };
    inbounds.add(socksInbound);

    return inbounds;
  }

  static List<String> _buildSniffingDestOverride(AppSettings settings) {
    final destOverride = <String>[];
    
    if (settings.sniffingEnabled) {
      destOverride.addAll(['http', 'tls', 'quic']);
    }
    
    if (settings.fakeDnsEnabled) {
      destOverride.add('fakedns');
    }
    
    return destOverride;
  }

  static String _getVpnAddress(String interfaceAddress) {
    switch (interfaceAddress) {
      case '10.10.14.x':
        return '10.10.14.1/24';
      case '10.1.0.x':
        return '10.1.0.1/24';
      case '172.16.0.x':
        return '172.16.0.1/24';
      case '172.19.0.x':
        return '172.19.0.1/24';
      case '192.168.0.x':
        return '192.168.0.1/24';
      case '192.168.1.x':
        return '192.168.1.1/24';
      case '192.168.49.x':
        return '192.168.49.1/24';
      default:
        return '10.10.14.1/24';
    }
  }

  static List<Map<String, dynamic>> _buildOutbounds(
    V2RayConfig serverConfig,
    AppSettings settings,
  ) {
    final outbounds = <Map<String, dynamic>>[];

    debugPrint('Parsing server config URL...');
    final mainOutbound = _parseServerConfig(serverConfig);
    if (mainOutbound != null) {
      debugPrint('Main outbound created: ${mainOutbound['protocol']}');
      _applyMuxSettings(mainOutbound, settings);
      _applyFragmentSettings(mainOutbound, settings, outbounds);
      _applyAllowInsecure(mainOutbound, settings);
      
      outbounds.add(mainOutbound);
    } else {
      debugPrint('ERROR: Failed to parse server config');
      throw Exception('Failed to parse server configuration');
    }

    outbounds.add({
      'tag': 'direct',
      'protocol': 'freedom',
      'settings': {
        'domainStrategy': 'UseIP',
      },
    });

    outbounds.add({
      'tag': 'block',
      'protocol': 'blackhole',
      'settings': {
        'response': {
          'type': 'http',
        },
      },
    });

    return outbounds;
  }
  
  static Map<String, dynamic>? _parseServerConfig(V2RayConfig config) {
    try {
      final url = config.fullConfig;
      final protocol = config.configType.toLowerCase();
      
      debugPrint('Parsing $protocol config...');
      
      final uri = Uri.parse(url);
      
      if (protocol == 'vmess') {
        return _parseVMessConfig(uri);
      } else if (protocol == 'vless') {
        return _parseVLESSConfig(uri);
      } else if (protocol == 'trojan') {
        return _parseTrojanConfig(uri);
      } else if (protocol == 'shadowsocks') {
        return _parseShadowsocksConfig(uri);
      } else if (protocol == 'socks' || protocol == 'http') {
        return _parseSocksHttpConfig(uri, protocol);
      } else if (protocol == 'wireguard') {
        return _parseWireguardConfig(uri);
      } else if (protocol == 'hysteria2') {
        return _parseHysteria2Config(uri);
      }
      
      debugPrint('WARNING: Unsupported protocol: $protocol');
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error parsing server config: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
  
  static Map<String, dynamic> _parseVMessConfig(Uri uri) {
    final base64 = uri.host;
    final decoded = utf8.decode(base64Decode(base64));
    final json = jsonDecode(decoded);
    
    return {
      'tag': 'proxy',
      'protocol': 'vmess',
      'settings': {
        'vnext': [
          {
            'address': json['add'],
            'port': int.parse(json['port'].toString()),
            'users': [
              {
                'id': json['id'],
                'alterId': int.parse(json['aid']?.toString() ?? '0'),
                'security': json['scy'] ?? 'auto',
                'level': 8,
              }
            ]
          }
        ]
      },
      'streamSettings': _buildStreamSettings(
        network: json['net'] ?? 'tcp',
        security: json['tls'] ?? '',
        host: json['host'] ?? '',
        path: json['path'] ?? '',
        headerType: json['type'] ?? 'none',
        sni: json['sni'] ?? '',
        fingerprint: json['fp'] ?? '',
        alpn: json['alpn'] ?? '',
      ),
    };
  }
  
  static Map<String, dynamic> _parseVLESSConfig(Uri uri) {
    final params = uri.queryParameters;
    
    return {
      'tag': 'proxy',
      'protocol': 'vless',
      'settings': {
        'vnext': [
          {
            'address': uri.host,
            'port': uri.port,
            'users': [
              {
                'id': uri.userInfo,
                'encryption': params['encryption'] ?? 'none',
                'flow': params['flow'] ?? '',
                'level': 8,
              }
            ]
          }
        ]
      },
      'streamSettings': _buildStreamSettings(
        network: params['type'] ?? 'tcp',
        security: params['security'] ?? '',
        host: params['host'] ?? '',
        path: params['path'] ?? '',
        headerType: params['headerType'] ?? 'none',
        sni: params['sni'] ?? '',
        fingerprint: params['fp'] ?? '',
        alpn: params['alpn'] ?? '',
        publicKey: params['pbk'] ?? '',
        shortId: params['sid'] ?? '',
        spiderX: params['spx'] ?? '',
      ),
    };
  }
  
  static Map<String, dynamic> _parseTrojanConfig(Uri uri) {
    final params = uri.queryParameters;
    
    return {
      'tag': 'proxy',
      'protocol': 'trojan',
      'settings': {
        'servers': [
          {
            'address': uri.host,
            'port': uri.port,
            'password': uri.userInfo,
            'level': 8,
          }
        ]
      },
      'streamSettings': _buildStreamSettings(
        network: params['type'] ?? 'tcp',
        security: params['security'] ?? '',
        host: params['host'] ?? '',
        path: params['path'] ?? '',
        headerType: params['headerType'] ?? 'none',
        sni: params['sni'] ?? '',
        fingerprint: params['fp'] ?? '',
        alpn: params['alpn'] ?? '',
      ),
    };
  }
  
  static Map<String, dynamic> _parseShadowsocksConfig(Uri uri) {
    final userInfo = utf8.decode(base64Decode(uri.userInfo));
    final parts = userInfo.split(':');
    final method = parts[0];
    final password = parts.length > 1 ? parts[1] : '';
    
    return {
      'tag': 'proxy',
      'protocol': 'shadowsocks',
      'settings': {
        'servers': [
          {
            'address': uri.host,
            'port': uri.port,
            'method': method,
            'password': password,
            'level': 8,
          }
        ]
      },
    };
  }
  
  static Map<String, dynamic> _parseSocksHttpConfig(Uri uri, String protocol) {
    final userInfo = uri.userInfo.split(':');
    final username = userInfo.isNotEmpty ? userInfo[0] : '';
    final password = userInfo.length > 1 ? userInfo[1] : '';
    
    return {
      'tag': 'proxy',
      'protocol': protocol,
      'settings': {
        'servers': [
          {
            'address': uri.host,
            'port': uri.port,
            'users': username.isNotEmpty ? [
              {
                'user': username,
                'pass': password,
              }
            ] : null,
          }
        ]
      },
    };
  }
  
  static Map<String, dynamic> _parseWireguardConfig(Uri uri) {
    final params = uri.queryParameters;
    
    return {
      'tag': 'proxy',
      'protocol': 'wireguard',
      'settings': {
        'secretKey': params['secretKey'] ?? '',
        'address': [params['localAddress'] ?? '172.16.0.2/32'],
        'peers': [
          {
            'publicKey': params['publicKey'] ?? '',
            'endpoint': '${uri.host}:${uri.port}',
            'preSharedKey': params['preSharedKey'] ?? '',
          }
        ],
        'mtu': int.tryParse(params['mtu'] ?? '1420') ?? 1420,
        'reserved': params['reserved']?.split(',').map((e) => int.tryParse(e) ?? 0).toList() ?? [0, 0, 0],
      },
    };
  }
  
  static Map<String, dynamic> _parseHysteria2Config(Uri uri) {
    final params = uri.queryParameters;
    final password = uri.userInfo;
    
    final streamSettings = <String, dynamic>{
      'network': 'hysteria2',
      'security': 'tls',
      'tlsSettings': {
        'serverName': params['sni'] ?? uri.host,
        'alpn': (params['alpn'] ?? 'h3').split(','),
        'allowInsecure': params['insecure'] == '1' || params['insecure'] == 'true',
        if (params['fp'] != null && params['fp']!.isNotEmpty) 'fingerprint': params['fp'],
      },
    };
    
    if (params['obfs'] == 'salamander' && params['obfs-password'] != null) {
      streamSettings['udpmasks'] = [
        {
          'type': 'salamander',
          'settings': {
            'password': params['obfs-password'],
          }
        }
      ];
    }
    
    return {
      'tag': 'proxy',
      'protocol': 'hysteria2',
      'settings': {
        'address': uri.host,
        'port': uri.port,
        'password': password,
        if (params['up'] != null) 'up': params['up'],
        if (params['down'] != null) 'down': params['down'],
      },
      'streamSettings': streamSettings,
    };
  }
  
  static Map<String, dynamic> _buildStreamSettings({
    required String network,
    required String security,
    required String host,
    required String path,
    required String headerType,
    required String sni,
    required String fingerprint,
    required String alpn,
    String? publicKey,
    String? shortId,
    String? spiderX,
  }) {
    final streamSettings = <String, dynamic>{
      'network': network,
      'security': security,
    };
    
    if (network == 'tcp') {
      streamSettings['tcpSettings'] = {
        'header': {
          'type': headerType,
          if (headerType == 'http') 'request': {
            'path': path.isNotEmpty ? path.split(',') : ['/'],
            'headers': {
              'Host': host.isNotEmpty ? host.split(',') : [],
            }
          }
        }
      };
    } else if (network == 'kcp') {
      streamSettings['kcpSettings'] = {
        'mtu': 1350,
        'tti': 50,
        'uplinkCapacity': 12,
        'downlinkCapacity': 100,
        'congestion': false,
        'readBufferSize': 1,
        'writeBufferSize': 1,
        'header': {
          'type': headerType,
        },
        if (path.isNotEmpty) 'seed': path,
      };
    } else if (network == 'ws') {
      streamSettings['wsSettings'] = {
        'headers': {
          if (host.isNotEmpty) 'Host': host,
        },
        'path': path.isNotEmpty ? path : '/',
      };
    } else if (network == 'httpupgrade') {
      streamSettings['httpupgradeSettings'] = {
        'path': path.isNotEmpty ? path : '/',
        if (host.isNotEmpty) 'host': host,
      };
    } else if (network == 'xhttp') {
      streamSettings['xhttpSettings'] = {
        'path': path.isNotEmpty ? path : '/',
        if (host.isNotEmpty) 'host': host,
        'mode': headerType != 'none' ? headerType : 'auto',
      };
    } else if (network == 'h2') {
      streamSettings['httpSettings'] = {
        'path': path.isNotEmpty ? path : '/',
        'host': host.isNotEmpty ? host.split(',') : [],
      };
    } else if (network == 'grpc') {
      streamSettings['grpcSettings'] = {
        'serviceName': path,
        'multiMode': headerType == 'multi',
      };
    }
    
    if (security == 'tls') {
      streamSettings['tlsSettings'] = {
        'allowInsecure': false,
        if (fingerprint.isNotEmpty) 'fingerprint': fingerprint,
        if (sni.isNotEmpty) 'serverName': sni,
        'show': false,
      };
      if (alpn.isNotEmpty) {
        streamSettings['tlsSettings']['alpn'] = alpn.split(',');
      }
    } else if (security == 'reality') {
      streamSettings['realitySettings'] = {
        if (sni.isNotEmpty) 'serverName': sni,
        if (fingerprint.isNotEmpty) 'fingerprint': fingerprint,
        if (publicKey != null && publicKey.isNotEmpty) 'publicKey': publicKey,
        if (shortId != null && shortId.isNotEmpty) 'shortId': shortId,
        if (spiderX != null && spiderX.isNotEmpty) 'spiderX': spiderX,
      };
    }
    
    return streamSettings;
  }

  static void _applyMuxSettings(
    Map<String, dynamic> outbound,
    AppSettings settings,
  ) {
    final protocol = outbound['protocol']?.toString().toLowerCase() ?? '';
    
    final muxDisabledProtocols = [
      'shadowsocks',
      'socks',
      'http',
      'trojan',
      'wireguard',
      'hysteria2',
    ];

    if (muxDisabledProtocols.contains(protocol)) {
      outbound['mux'] = {
        'enabled': false,
        'concurrency': -1,
      };
      return;
    }

    final streamSettings = outbound['streamSettings'] as Map<String, dynamic>?;
    if (streamSettings != null && streamSettings['network'] == 'xhttp') {
      outbound['mux'] = {
        'enabled': false,
        'concurrency': -1,
      };
      return;
    }

    if (settings.muxSettings.enabled) {
      outbound['mux'] = {
        'enabled': true,
        'concurrency': settings.muxSettings.concurrency,
        'xudpConcurrency': settings.muxSettings.xudpConcurrency,
        'xudpProxyUDP443': settings.muxSettings.xudpQuic,
      };

      if (protocol == 'vless') {
        final settingsObj = outbound['settings'] as Map<String, dynamic>?;
        final vnext = settingsObj?['vnext'] as List?;
        if (vnext != null && vnext.isNotEmpty) {
          final users = (vnext[0] as Map)['users'] as List?;
          if (users != null && users.isNotEmpty) {
            final flow = (users[0] as Map)['flow']?.toString() ?? '';
            if (flow.isNotEmpty) {
              outbound['mux']!['concurrency'] = -1;
            }
          }
        }
      }
    } else {
      outbound['mux'] = {
        'enabled': false,
        'concurrency': -1,
      };
    }
  }

  static void _applyFragmentSettings(
    Map<String, dynamic> outbound,
    AppSettings settings,
    List<Map<String, dynamic>> outbounds,
  ) {
    if (!settings.fragmentSettings.enabled) {
      return;
    }

    final streamSettings = outbound['streamSettings'] as Map<String, dynamic>?;
    final security = streamSettings?['security']?.toString() ?? '';

    if (security != 'tls' && security != 'reality') {
      return;
    }

    var packets = settings.fragmentSettings.packets;
    if (security == 'reality' && packets == 'tlshello') {
      packets = '1-3';
    } else if (security == 'tls' && packets != 'tlshello') {
      packets = 'tlshello';
    }

    final fragmentOutbound = {
      'protocol': 'freedom',
      'tag': 'fragment',
      'settings': {
        'fragment': {
          'packets': packets,
          'length': settings.fragmentSettings.length,
          'interval': settings.fragmentSettings.interval,
        },
        'noises': [
          {
            'type': 'rand',
            'packet': '10-20',
            'delay': '10-16',
          }
        ],
      },
      'streamSettings': {
        'sockopt': {
          'tcpNoDelay': true,
          'mark': 255,
        }
      }
    };

    outbounds.add(fragmentOutbound);

    if (outbound['streamSettings'] == null) {
      outbound['streamSettings'] = <String, dynamic>{};
    }
    if (outbound['streamSettings']['sockopt'] == null) {
      outbound['streamSettings']['sockopt'] = <String, dynamic>{};
    }
    outbound['streamSettings']['sockopt']['dialerProxy'] = 'fragment';
  }

  static void _applyAllowInsecure(
    Map<String, dynamic> outbound,
    AppSettings settings,
  ) {
    if (!settings.allowInsecure) {
      return;
    }

    final streamSettings = outbound['streamSettings'] as Map<String, dynamic>?;
    if (streamSettings == null) {
      return;
    }

    final security = streamSettings['security']?.toString() ?? '';
    if (security == 'tls') {
      if (streamSettings['tlsSettings'] == null) {
        streamSettings['tlsSettings'] = <String, dynamic>{};
      }
      streamSettings['tlsSettings']['allowInsecure'] = true;
    } else if (security == 'reality') {
      if (streamSettings['realitySettings'] == null) {
        streamSettings['realitySettings'] = <String, dynamic>{};
      }
      streamSettings['realitySettings']['allowInsecure'] = true;
    }
  }

  static Map<String, dynamic> _buildRouting(AppSettings settings) {
    final rules = <Map<String, dynamic>>[];

    rules.add({
      'network': 'udp',
      'outboundTag': 'block',
      'port': '443',
      'type': 'field',
    });

    rules.add({
      'domain': ['geosite:google'],
      'outboundTag': 'proxy',
      'type': 'field',
    });

    rules.add({
      'ip': ['geoip:private'],
      'outboundTag': 'direct',
      'type': 'field',
    });

    rules.add({
      'domain': ['geosite:private'],
      'outboundTag': 'direct',
      'type': 'field',
    });

    rules.add({
      'ip': [
        '223.5.5.5',
        '223.6.6.6',
        '2400:3200::1',
        '2400:3200:baba::1',
        '119.29.29.29',
        '1.12.12.12',
        '120.53.53.53',
        '2402:4e00::',
        '2402:4e00:1::',
        '180.76.76.76',
        '2400:da00::6666',
        '114.114.114.114',
        '114.114.115.115',
        '114.114.114.119',
        '114.114.115.119',
        '114.114.114.110',
        '114.114.115.110',
        '180.184.1.1',
        '180.184.2.2',
        '101.226.4.6',
        '218.30.118.6',
        '123.125.81.6',
        '140.207.198.6',
        '1.2.4.8',
        '210.2.4.8',
        '52.80.66.66',
        '117.50.22.22',
        '2400:7fc0:849e:200::4',
        '2404:c2c0:85d8:901::4',
        '117.50.10.10',
        '52.80.52.52',
        '2400:7fc0:849e:200::8',
        '2404:c2c0:85d8:901::8',
        '117.50.60.30',
        '52.80.60.30',
      ],
      'outboundTag': 'direct',
      'type': 'field',
    });

    rules.add({
      'domain': [
        'domain:alidns.com',
        'domain:doh.pub',
        'domain:dot.pub',
        'domain:360.cn',
        'domain:onedns.net',
      ],
      'outboundTag': 'direct',
      'type': 'field',
    });

    rules.add({
      'ip': ['geoip:cn'],
      'outboundTag': 'direct',
      'type': 'field',
    });

    rules.add({
      'domain': ['geosite:cn'],
      'outboundTag': 'direct',
      'type': 'field',
    });

    rules.add({
      'inboundTag': ['domestic-dns'],
      'outboundTag': 'direct',
      'type': 'field',
    });

    rules.add({
      'inboundTag': ['dns-module'],
      'outboundTag': 'proxy',
      'type': 'field',
    });

    final domainStrategy = _getDomainStrategy(settings.outboundDomainResolveMethod);

    return {
      'domainStrategy': domainStrategy,
      'rules': rules,
    };
  }

  static String _getDomainStrategy(int method) {
    return 'AsIs';
  }

  static Map<String, dynamic> _buildDns(AppSettings settings) {
    final servers = <dynamic>[];
    final hosts = <String, dynamic>{};

    hosts['domain:googleapis.cn'] = 'googleapis.com';
    hosts['dns.alidns.com'] = [
      '223.5.5.5',
      '223.6.6.6',
      '2400:3200::1',
      '2400:3200:baba::1',
    ];
    hosts['one.one.one.one'] = [
      '1.1.1.1',
      '1.0.0.1',
      '2606:4700:4700::1111',
      '2606:4700:4700::1001',
    ];
    hosts['dns.cloudflare.com'] = [
      '104.16.132.229',
      '104.16.133.229',
      '2606:4700::6810:84e5',
      '2606:4700::6810:85e5',
    ];
    hosts['cloudflare-dns.com'] = [
      '104.16.248.249',
      '104.16.249.249',
      '2606:4700::6810:f8f9',
      '2606:4700::6810:f9f9',
    ];
    hosts['dot.pub'] = [
      '1.12.12.12',
      '120.53.53.53',
    ];
    hosts['dns.google'] = [
      '8.8.8.8',
      '8.8.4.4',
      '2001:4860:4860::8888',
      '2001:4860:4860::8844',
    ];
    hosts['dns.quad9.net'] = [
      '9.9.9.9',
      '149.112.112.112',
      '2620:fe::fe',
      '2620:fe::9',
    ];
    hosts['common.dot.dns.yandex.net'] = [
      '77.88.8.8',
      '77.88.8.1',
      '2a02:6b8::feed:0ff',
      '2a02:6b8:0:1::feed:0ff',
    ];

    servers.add('1.1.1.1');

    servers.add({
      'address': '1.1.1.1',
      'domains': ['geosite:google'],
    });

    servers.add({
      'address': '223.5.5.5',
      'domains': [
        'domain:alidns.com',
        'domain:doh.pub',
        'domain:dot.pub',
        'domain:360.cn',
        'domain:onedns.net',
        'geosite:cn',
      ],
      'expectIPs': ['geoip:cn'],
      'skipFallback': true,
      'tag': 'domestic-dns',
    });

    return {
      'hosts': hosts,
      'servers': servers,
      'tag': 'dns-module',
    };
  }

  static List<Map<String, dynamic>> _buildFakeDns() {
    return [
      {
        'ipPool': '198.18.0.0/15',
        'poolSize': 65535,
      }
    ];
  }

  static void _applySniffing(
    Map<String, dynamic> config,
    AppSettings settings,
  ) {
    final inbounds = config['inbounds'] as List?;
    if (inbounds == null) return;

    for (final inbound in inbounds) {
      if (inbound is! Map<String, dynamic>) continue;

      if (inbound['sniffing'] == null) {
        inbound['sniffing'] = <String, dynamic>{};
      }

      final sniffing = inbound['sniffing'] as Map<String, dynamic>;
      sniffing['enabled'] = settings.sniffingEnabled || settings.fakeDnsEnabled;
      sniffing['destOverride'] = _buildSniffingDestOverride(settings);
      sniffing['routeOnly'] = settings.routeOnlyEnabled;
    }
  }
}
