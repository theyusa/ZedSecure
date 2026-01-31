import 'dart:convert';
import 'url.dart';

class WireGuardURL extends V2RayURL {
  WireGuardURL({required super.url});

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
      return 51820;
    }
  }

  @override
  String get remark {
    try {
      final uri = Uri.parse(url);
      if (uri.fragment.isNotEmpty) {
        return Uri.decodeComponent(uri.fragment);
      }
      return 'WireGuard';
    } catch (e) {
      return 'WireGuard';
    }
  }

  String get secretKey {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters['secretKey'] ?? '';
    } catch (e) {
      return '';
    }
  }

  String get publicKey {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters['publicKey'] ?? '';
    } catch (e) {
      return '';
    }
  }

  String get preSharedKey {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters['preSharedKey'] ?? '';
    } catch (e) {
      return '';
    }
  }

  String get localAddress {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters['localAddress'] ?? '172.16.0.2/32';
    } catch (e) {
      return '172.16.0.2/32';
    }
  }

  int get mtu {
    try {
      final uri = Uri.parse(url);
      return int.tryParse(uri.queryParameters['mtu'] ?? '1420') ?? 1420;
    } catch (e) {
      return 1420;
    }
  }

  List<int> get reserved {
    try {
      final uri = Uri.parse(url);
      final reservedStr = uri.queryParameters['reserved'] ?? '0,0,0';
      return reservedStr.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    } catch (e) {
      return [0, 0, 0];
    }
  }

  @override
  Map<String, dynamic> get outbound1 {
    return {
      'tag': 'proxy',
      'protocol': 'wireguard',
      'settings': {
        'secretKey': secretKey,
        'address': [localAddress],
        'peers': [
          {
            'publicKey': publicKey,
            'endpoint': '$address:$port',
            if (preSharedKey.isNotEmpty) 'preSharedKey': preSharedKey,
          }
        ],
        'mtu': mtu,
        'reserved': reserved,
      },
      'streamSettings': null,
      'mux': {'enabled': false, 'concurrency': -1}
    };
  }
}
