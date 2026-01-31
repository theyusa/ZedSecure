import 'dart:convert';
import 'url.dart';

class Hysteria2URL extends V2RayURL {
  Hysteria2URL({required super.url});

  @override
  String get address {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return '';
    }
  }

  @override
  int get port {
    try {
      final uri = Uri.parse(url);
      return uri.port;
    } catch (e) {
      return 443;
    }
  }

  @override
  String get remark {
    try {
      final uri = Uri.parse(url);
      if (uri.fragment.isNotEmpty) {
        return Uri.decodeComponent(uri.fragment);
      }
      return 'Hysteria2';
    } catch (e) {
      return 'Hysteria2';
    }
  }

  String get password {
    try {
      final uri = Uri.parse(url);
      return uri.userInfo;
    } catch (e) {
      return '';
    }
  }

  @override
  Map<String, dynamic> get outbound1 {
    final uri = Uri.parse(url);
    final params = uri.queryParameters;

    final sni = params['sni'] ?? address;
    final alpn = params['alpn'] ?? 'h3';
    final allowInsecure = params['insecure'] == '1' || params['insecure'] == 'true';

    populateTransportSettings(
      transport: 'hysteria2',
      headerType: null,
      host: sni,
      path: null,
      seed: null,
      quicSecurity: null,
      key: null,
      mode: null,
      serviceName: null,
    );

    populateTlsSettings(
      streamSecurity: 'tls',
      allowInsecure: allowInsecure,
      sni: sni,
      fingerprint: params['fp'] ?? '',
      alpns: alpn,
      publicKey: null,
      shortId: null,
      spiderX: null,
    );

    final settings = <String, dynamic>{
      'address': address,
      'port': port,
      'password': password,
    };

    if (params['up'] != null) {
      settings['up'] = params['up'];
    }
    if (params['down'] != null) {
      settings['down'] = params['down'];
    }

    if (params['obfs'] == 'salamander' && params['obfs-password'] != null) {
      streamSetting['udpmasks'] = [
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
      'settings': settings,
      'streamSettings': streamSetting,
      'mux': {'enabled': false, 'concurrency': -1}
    };
  }
}
