class MuxSettings {
  final bool enabled;
  final int concurrency;
  final int xudpConcurrency;
  final String xudpQuic;
  
  MuxSettings({
    this.enabled = false,
    this.concurrency = 8,
    this.xudpConcurrency = 8,
    this.xudpQuic = 'reject',
  });
  
  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'concurrency': concurrency,
    'xudpConcurrency': xudpConcurrency,
    'xudpQuic': xudpQuic,
  };
  
  factory MuxSettings.fromJson(Map<String, dynamic> json) => MuxSettings(
    enabled: json['enabled'] ?? false,
    concurrency: json['concurrency'] ?? 8,
    xudpConcurrency: json['xudpConcurrency'] ?? 8,
    xudpQuic: json['xudpQuic'] ?? 'reject',
  );
  
  MuxSettings copyWith({
    bool? enabled,
    int? concurrency,
    int? xudpConcurrency,
    String? xudpQuic,
  }) => MuxSettings(
    enabled: enabled ?? this.enabled,
    concurrency: concurrency ?? this.concurrency,
    xudpConcurrency: xudpConcurrency ?? this.xudpConcurrency,
    xudpQuic: xudpQuic ?? this.xudpQuic,
  );
}

class FragmentSettings {
  final bool enabled;
  final String packets;
  final String length;
  final String interval;
  
  FragmentSettings({
    this.enabled = false,
    this.packets = 'tlshello',
    this.length = '50-100',
    this.interval = '10-20',
  });
  
  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'packets': packets,
    'length': length,
    'interval': interval,
  };
  
  factory FragmentSettings.fromJson(Map<String, dynamic> json) => FragmentSettings(
    enabled: json['enabled'] ?? false,
    packets: json['packets'] ?? 'tlshello',
    length: json['length'] ?? '50-100',
    interval: json['interval'] ?? '10-20',
  );
  
  FragmentSettings copyWith({
    bool? enabled,
    String? packets,
    String? length,
    String? interval,
  }) => FragmentSettings(
    enabled: enabled ?? this.enabled,
    packets: packets ?? this.packets,
    length: length ?? this.length,
    interval: interval ?? this.interval,
  );
}

class AppSettings {
  final bool preferIpv6;
  final bool localDnsEnabled;
  final bool fakeDnsEnabled;
  final bool appendHttpProxy;
  final String vpnInterfaceAddress;
  final int vpnMtu;
  
  final bool sniffingEnabled;
  final bool routeOnlyEnabled;
  final bool proxySharingEnabled;
  final bool allowInsecure;
  final int socksPort;
  final String remoteDns;
  final String domesticDns;
  final String dnsHosts;
  final String coreLogLevel;
  final int outboundDomainResolveMethod;
  
  final bool autoUpdateSubscription;
  final int autoUpdateInterval;
  
  final bool autoRemoveInvalidAfterTest;
  final bool autoSortAfterTest;
  final String ipApiUrl;
  
  final bool proxyOnlyMode;
  final bool bypassLan;
  final String connectionTestUrl;
  final List<String> dnsServers;
  final MuxSettings muxSettings;
  final FragmentSettings fragmentSettings;
  
  final String uiModeNight;
  final bool useHevTunnel;
  final String hevTunnelLogLevel;
  final String hevTunnelRwTimeout;
  final String mode;
  
  AppSettings({
    this.preferIpv6 = false,
    this.localDnsEnabled = false,
    this.fakeDnsEnabled = false,
    this.appendHttpProxy = false,
    this.vpnInterfaceAddress = '10.10.14.x',
    this.vpnMtu = 1500,
    
    this.sniffingEnabled = true,
    this.routeOnlyEnabled = false,
    this.proxySharingEnabled = false,
    this.allowInsecure = false,
    this.socksPort = 10808,
    this.remoteDns = 'https://1.1.1.1/dns-query,https://8.8.8.8/dns-query',
    this.domesticDns = 'https+local://223.5.5.5/dns-query',
    this.dnsHosts = '',
    this.coreLogLevel = 'warning',
    this.outboundDomainResolveMethod = 1,
    
    this.autoUpdateSubscription = false,
    this.autoUpdateInterval = 1440,
    
    this.autoRemoveInvalidAfterTest = false,
    this.autoSortAfterTest = false,
    this.ipApiUrl = 'https://api.ip.sb/geoip',
    
    this.proxyOnlyMode = false,
    this.bypassLan = true,
    this.connectionTestUrl = 'https://www.gstatic.com/generate_204',
    this.dnsServers = const ['8.8.8.8', '8.8.4.4'],
    MuxSettings? muxSettings,
    FragmentSettings? fragmentSettings,
    
    this.uiModeNight = 'auto',
    this.useHevTunnel = true,
    this.hevTunnelLogLevel = 'warn',
    this.hevTunnelRwTimeout = '300,60',
    this.mode = 'VPN',
  }) : muxSettings = muxSettings ?? MuxSettings(),
       fragmentSettings = fragmentSettings ?? FragmentSettings();
  
  Map<String, dynamic> toJson() => {
    'preferIpv6': preferIpv6,
    'localDnsEnabled': localDnsEnabled,
    'fakeDnsEnabled': fakeDnsEnabled,
    'appendHttpProxy': appendHttpProxy,
    'vpnInterfaceAddress': vpnInterfaceAddress,
    'vpnMtu': vpnMtu,
    
    'sniffingEnabled': sniffingEnabled,
    'routeOnlyEnabled': routeOnlyEnabled,
    'proxySharingEnabled': proxySharingEnabled,
    'allowInsecure': allowInsecure,
    'socksPort': socksPort,
    'remoteDns': remoteDns,
    'domesticDns': domesticDns,
    'dnsHosts': dnsHosts,
    'coreLogLevel': coreLogLevel,
    'outboundDomainResolveMethod': outboundDomainResolveMethod,
    
    'autoUpdateSubscription': autoUpdateSubscription,
    'autoUpdateInterval': autoUpdateInterval,
    
    'autoRemoveInvalidAfterTest': autoRemoveInvalidAfterTest,
    'autoSortAfterTest': autoSortAfterTest,
    'ipApiUrl': ipApiUrl,
    
    'proxyOnlyMode': proxyOnlyMode,
    'bypassLan': bypassLan,
    'connectionTestUrl': connectionTestUrl,
    'dnsServers': dnsServers,
    'muxSettings': muxSettings.toJson(),
    'fragmentSettings': fragmentSettings.toJson(),
    
    'uiModeNight': uiModeNight,
    'useHevTunnel': useHevTunnel,
    'hevTunnelLogLevel': hevTunnelLogLevel,
    'hevTunnelRwTimeout': hevTunnelRwTimeout,
    'mode': mode,
  };
  
  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    preferIpv6: json['preferIpv6'] ?? false,
    localDnsEnabled: json['localDnsEnabled'] ?? false,
    fakeDnsEnabled: json['fakeDnsEnabled'] ?? false,
    appendHttpProxy: json['appendHttpProxy'] ?? false,
    vpnInterfaceAddress: json['vpnInterfaceAddress'] ?? '10.10.14.x',
    vpnMtu: json['vpnMtu'] ?? 1500,
    
    sniffingEnabled: json['sniffingEnabled'] ?? true,
    routeOnlyEnabled: json['routeOnlyEnabled'] ?? false,
    proxySharingEnabled: json['proxySharingEnabled'] ?? false,
    allowInsecure: json['allowInsecure'] ?? false,
    socksPort: json['socksPort'] ?? 10808,
    remoteDns: json['remoteDns'] ?? 'https://1.1.1.1/dns-query,https://8.8.8.8/dns-query',
    domesticDns: json['domesticDns'] ?? 'https+local://223.5.5.5/dns-query',
    dnsHosts: json['dnsHosts'] ?? '',
    coreLogLevel: json['coreLogLevel'] ?? 'warning',
    outboundDomainResolveMethod: json['outboundDomainResolveMethod'] ?? 1,
    
    autoUpdateSubscription: json['autoUpdateSubscription'] ?? false,
    autoUpdateInterval: json['autoUpdateInterval'] ?? 1440,
    
    autoRemoveInvalidAfterTest: json['autoRemoveInvalidAfterTest'] ?? false,
    autoSortAfterTest: json['autoSortAfterTest'] ?? false,
    ipApiUrl: json['ipApiUrl'] ?? 'https://api.ip.sb/geoip',
    
    proxyOnlyMode: json['proxyOnlyMode'] ?? false,
    bypassLan: json['bypassLan'] ?? true,
    connectionTestUrl: json['connectionTestUrl'] ?? 'https://www.gstatic.com/generate_204',
    dnsServers: (json['dnsServers'] as List?)?.cast<String>() ?? ['8.8.8.8', '8.8.4.4'],
    muxSettings: json['muxSettings'] != null ? MuxSettings.fromJson(json['muxSettings']) : null,
    fragmentSettings: json['fragmentSettings'] != null ? FragmentSettings.fromJson(json['fragmentSettings']) : null,
    
    uiModeNight: json['uiModeNight'] ?? 'auto',
    useHevTunnel: json['useHevTunnel'] ?? true,
    hevTunnelLogLevel: json['hevTunnelLogLevel'] ?? 'warn',
    hevTunnelRwTimeout: json['hevTunnelRwTimeout'] ?? '300,60',
    mode: json['mode'] ?? 'VPN',
  );
  
  AppSettings copyWith({
    bool? preferIpv6,
    bool? localDnsEnabled,
    bool? fakeDnsEnabled,
    bool? appendHttpProxy,
    String? vpnInterfaceAddress,
    int? vpnMtu,
    
    bool? sniffingEnabled,
    bool? routeOnlyEnabled,
    bool? proxySharingEnabled,
    bool? allowInsecure,
    int? socksPort,
    String? remoteDns,
    String? domesticDns,
    String? dnsHosts,
    String? coreLogLevel,
    int? outboundDomainResolveMethod,
    
    bool? autoUpdateSubscription,
    int? autoUpdateInterval,
    
    bool? autoRemoveInvalidAfterTest,
    bool? autoSortAfterTest,
    String? ipApiUrl,
    
    bool? proxyOnlyMode,
    bool? bypassLan,
    String? connectionTestUrl,
    List<String>? dnsServers,
    MuxSettings? muxSettings,
    FragmentSettings? fragmentSettings,
    
    String? uiModeNight,
    bool? useHevTunnel,
    String? hevTunnelLogLevel,
    String? hevTunnelRwTimeout,
    String? mode,
  }) => AppSettings(
    preferIpv6: preferIpv6 ?? this.preferIpv6,
    localDnsEnabled: localDnsEnabled ?? this.localDnsEnabled,
    fakeDnsEnabled: fakeDnsEnabled ?? this.fakeDnsEnabled,
    appendHttpProxy: appendHttpProxy ?? this.appendHttpProxy,
    vpnInterfaceAddress: vpnInterfaceAddress ?? this.vpnInterfaceAddress,
    vpnMtu: vpnMtu ?? this.vpnMtu,
    
    sniffingEnabled: sniffingEnabled ?? this.sniffingEnabled,
    routeOnlyEnabled: routeOnlyEnabled ?? this.routeOnlyEnabled,
    proxySharingEnabled: proxySharingEnabled ?? this.proxySharingEnabled,
    allowInsecure: allowInsecure ?? this.allowInsecure,
    socksPort: socksPort ?? this.socksPort,
    remoteDns: remoteDns ?? this.remoteDns,
    domesticDns: domesticDns ?? this.domesticDns,
    dnsHosts: dnsHosts ?? this.dnsHosts,
    coreLogLevel: coreLogLevel ?? this.coreLogLevel,
    outboundDomainResolveMethod: outboundDomainResolveMethod ?? this.outboundDomainResolveMethod,
    
    autoUpdateSubscription: autoUpdateSubscription ?? this.autoUpdateSubscription,
    autoUpdateInterval: autoUpdateInterval ?? this.autoUpdateInterval,
    
    autoRemoveInvalidAfterTest: autoRemoveInvalidAfterTest ?? this.autoRemoveInvalidAfterTest,
    autoSortAfterTest: autoSortAfterTest ?? this.autoSortAfterTest,
    ipApiUrl: ipApiUrl ?? this.ipApiUrl,
    
    proxyOnlyMode: proxyOnlyMode ?? this.proxyOnlyMode,
    bypassLan: bypassLan ?? this.bypassLan,
    connectionTestUrl: connectionTestUrl ?? this.connectionTestUrl,
    dnsServers: dnsServers ?? this.dnsServers,
    muxSettings: muxSettings ?? this.muxSettings,
    fragmentSettings: fragmentSettings ?? this.fragmentSettings,
    
    uiModeNight: uiModeNight ?? this.uiModeNight,
    useHevTunnel: useHevTunnel ?? this.useHevTunnel,
    hevTunnelLogLevel: hevTunnelLogLevel ?? this.hevTunnelLogLevel,
    hevTunnelRwTimeout: hevTunnelRwTimeout ?? this.hevTunnelRwTimeout,
    mode: mode ?? this.mode,
  );
}
