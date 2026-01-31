import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zedsecure/models/app_settings.dart';

class AppSettingsService extends ChangeNotifier {
  static const String _settingsKey = 'app_settings';
  
  AppSettings _settings = AppSettings();
  
  AppSettings get settings => _settings;
  
  bool get preferIpv6 => _settings.preferIpv6;
  bool get localDnsEnabled => _settings.localDnsEnabled;
  bool get fakeDnsEnabled => _settings.fakeDnsEnabled;
  bool get appendHttpProxy => _settings.appendHttpProxy;
  String get vpnInterfaceAddress => _settings.vpnInterfaceAddress;
  int get vpnMtu => _settings.vpnMtu;
  
  bool get sniffingEnabled => _settings.sniffingEnabled;
  bool get routeOnlyEnabled => _settings.routeOnlyEnabled;
  bool get proxySharingEnabled => _settings.proxySharingEnabled;
  bool get allowInsecure => _settings.allowInsecure;
  int get socksPort => _settings.socksPort;
  String get remoteDns => _settings.remoteDns;
  String get domesticDns => _settings.domesticDns;
  String get dnsHosts => _settings.dnsHosts;
  String get coreLogLevel => _settings.coreLogLevel;
  int get outboundDomainResolveMethod => _settings.outboundDomainResolveMethod;
  
  bool get autoUpdateSubscription => _settings.autoUpdateSubscription;
  int get autoUpdateInterval => _settings.autoUpdateInterval;
  
  bool get autoRemoveInvalidAfterTest => _settings.autoRemoveInvalidAfterTest;
  bool get autoSortAfterTest => _settings.autoSortAfterTest;
  String get ipApiUrl => _settings.ipApiUrl;
  
  bool get proxyOnlyMode => _settings.proxyOnlyMode;
  bool get bypassLan => _settings.bypassLan;
  String get connectionTestUrl => _settings.connectionTestUrl;
  List<String> get dnsServers => _settings.dnsServers;
  MuxSettings get muxSettings => _settings.muxSettings;
  FragmentSettings get fragmentSettings => _settings.fragmentSettings;
  
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _settings = AppSettings.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }
  
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_settings.toJson());
      await prefs.setString(_settingsKey, jsonString);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }
  
  Future<void> setPreferIpv6(bool value) async {
    _settings = _settings.copyWith(preferIpv6: value);
    await saveSettings();
  }
  
  Future<void> setLocalDnsEnabled(bool value) async {
    _settings = _settings.copyWith(localDnsEnabled: value);
    await saveSettings();
  }
  
  Future<void> setFakeDnsEnabled(bool value) async {
    _settings = _settings.copyWith(fakeDnsEnabled: value);
    await saveSettings();
  }
  
  Future<void> setAppendHttpProxy(bool value) async {
    _settings = _settings.copyWith(appendHttpProxy: value);
    await saveSettings();
  }
  
  Future<void> setVpnInterfaceAddress(String value) async {
    _settings = _settings.copyWith(vpnInterfaceAddress: value);
    await saveSettings();
  }
  
  Future<void> setVpnMtu(int value) async {
    _settings = _settings.copyWith(vpnMtu: value);
    await saveSettings();
  }
  
  Future<void> setSniffingEnabled(bool value) async {
    _settings = _settings.copyWith(sniffingEnabled: value);
    await saveSettings();
  }
  
  Future<void> setRouteOnlyEnabled(bool value) async {
    _settings = _settings.copyWith(routeOnlyEnabled: value);
    await saveSettings();
  }
  
  Future<void> setProxySharingEnabled(bool value) async {
    _settings = _settings.copyWith(proxySharingEnabled: value);
    await saveSettings();
  }
  
  Future<void> setAllowInsecure(bool value) async {
    _settings = _settings.copyWith(allowInsecure: value);
    await saveSettings();
  }
  
  Future<void> setSocksPort(int value) async {
    _settings = _settings.copyWith(socksPort: value);
    await saveSettings();
  }
  
  Future<void> setRemoteDns(String value) async {
    _settings = _settings.copyWith(remoteDns: value);
    await saveSettings();
  }
  
  Future<void> setDomesticDns(String value) async {
    _settings = _settings.copyWith(domesticDns: value);
    await saveSettings();
  }
  
  Future<void> setDnsHosts(String value) async {
    _settings = _settings.copyWith(dnsHosts: value);
    await saveSettings();
  }
  
  Future<void> setCoreLogLevel(String value) async {
    _settings = _settings.copyWith(coreLogLevel: value);
    await saveSettings();
  }
  
  Future<void> setOutboundDomainResolveMethod(int value) async {
    _settings = _settings.copyWith(outboundDomainResolveMethod: value);
    await saveSettings();
  }
  
  Future<void> setAutoUpdateSubscription(bool value) async {
    _settings = _settings.copyWith(autoUpdateSubscription: value);
    await saveSettings();
  }
  
  Future<void> setAutoUpdateInterval(int value) async {
    _settings = _settings.copyWith(autoUpdateInterval: value);
    await saveSettings();
  }
  
  Future<void> setAutoRemoveInvalidAfterTest(bool value) async {
    _settings = _settings.copyWith(autoRemoveInvalidAfterTest: value);
    await saveSettings();
  }
  
  Future<void> setAutoSortAfterTest(bool value) async {
    _settings = _settings.copyWith(autoSortAfterTest: value);
    await saveSettings();
  }
  
  Future<void> setIpApiUrl(String value) async {
    _settings = _settings.copyWith(ipApiUrl: value);
    await saveSettings();
  }
  
  Future<void> setProxyOnlyMode(bool value) async {
    _settings = _settings.copyWith(proxyOnlyMode: value);
    await saveSettings();
  }
  
  Future<void> setBypassLan(bool value) async {
    _settings = _settings.copyWith(bypassLan: value);
    await saveSettings();
  }
  
  Future<void> setConnectionTestUrl(String url) async {
    _settings = _settings.copyWith(connectionTestUrl: url);
    await saveSettings();
  }
  
  Future<void> setDnsServers(List<String> servers) async {
    _settings = _settings.copyWith(dnsServers: servers);
    await saveSettings();
  }
  
  Future<void> setMuxSettings(MuxSettings mux) async {
    _settings = _settings.copyWith(muxSettings: mux);
    await saveSettings();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mux_enabled', mux.enabled);
    await prefs.setInt('mux_concurrency', mux.concurrency);
    await prefs.setInt('mux_xudp_concurrency', mux.xudpConcurrency);
    await prefs.setString('mux_xudp_quic', mux.xudpQuic);
  }
  
  Future<void> setFragmentSettings(FragmentSettings fragment) async {
    _settings = _settings.copyWith(fragmentSettings: fragment);
    await saveSettings();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fragment_enabled', fragment.enabled);
    await prefs.setString('fragment_packets', fragment.packets);
    await prefs.setString('fragment_length', fragment.length);
    await prefs.setString('fragment_interval', fragment.interval);
  }
}
