import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zedsecure/services/v2ray_service.dart';
import 'package:zedsecure/services/theme_service.dart';
import 'package:zedsecure/models/v2ray_config.dart';
import 'package:zedsecure/models/subscription.dart';
import 'package:zedsecure/theme/app_theme.dart';
import 'package:zedsecure/screens/edit_config_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';

class ServersScreen extends StatefulWidget {
  const ServersScreen({super.key});

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> with SingleTickerProviderStateMixin {
  List<V2RayConfig> _configs = [];
  List<Subscription> _subscriptions = [];
  bool _isLoading = true;
  bool _isSorting = false;
  String _searchQuery = '';
  final Map<String, int?> _pingResults = {};
  String? _selectedConfigId;
  TabController? _tabController;
  String? _currentSubscriptionId;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
    _loadConfigs();
    _loadSelectedConfig();
    final service = Provider.of<V2RayService>(context, listen: false);
    service.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    final service = Provider.of<V2RayService>(context, listen: false);
    service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    _loadConfigs();
  }

  Future<void> _loadSubscriptions() async {
    final service = Provider.of<V2RayService>(context, listen: false);
    final subs = await service.loadSubscriptions();
    setState(() {
      _subscriptions = subs;
      _setupTabController();
    });
  }

  void _setupTabController() {
    _tabController?.dispose();
    final tabCount = _subscriptions.length + 1;
    _tabController = TabController(length: tabCount, vsync: this);
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        setState(() {
          if (_tabController!.index == 0) {
            _currentSubscriptionId = null;
          } else {
            _currentSubscriptionId = _subscriptions[_tabController!.index - 1].id;
          }
        });
      }
    });
  }

  Future<void> _loadSelectedConfig() async {
    final service = Provider.of<V2RayService>(context, listen: false);
    final selected = await service.loadSelectedConfig();
    if (selected != null) {
      setState(() => _selectedConfigId = selected.id);
    }
  }

  Future<void> _loadConfigs() async {
    setState(() => _isLoading = true);
    final service = Provider.of<V2RayService>(context, listen: false);
    final configs = await service.loadConfigs();
    
    for (final config in configs) {
      final hostKey = '${config.address}:${config.port}';
      final cachedPing = service.getCachedPing(hostKey) ?? service.getCachedPing(config.id);
      if (cachedPing != null) {
        _pingResults[config.id] = cachedPing;
      }
    }
    
    setState(() {
      _configs = configs;
      _isLoading = false;
    });
  }

  Future<void> _pingAllServers() async {
    setState(() {
      _isSorting = true;
      _pingResults.clear();
    });

    final service = Provider.of<V2RayService>(context, listen: false);
    
    for (int i = 0; i < _configs.length; i++) {
      if (!mounted) break;
      
      final config = _configs[i];
      try {
        final ping = await service.getServerDelay(config, useCache: false);
        if (mounted) {
          setState(() => _pingResults[config.id] = ping ?? -1);
        }
      } catch (e) {
        debugPrint('Ping error for ${config.remark}: $e');
        if (mounted) {
          setState(() => _pingResults[config.id] = -1);
        }
      }
      
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (mounted) {
      _sortByPing();
      setState(() => _isSorting = false);
    }
  }

  Future<void> _autoSelectBestServer() async {
    setState(() {
      _isSorting = true;
      _pingResults.clear();
    });

    final service = Provider.of<V2RayService>(context, listen: false);
    final configs = _currentSubscriptionId != null
        ? _configs.where((c) => c.subscriptionId == _currentSubscriptionId).toList()
        : _configs;

    if (configs.isEmpty) {
      _showSnackBar('No Servers', 'No servers available to test');
      setState(() => _isSorting = false);
      return;
    }

    V2RayConfig? bestConfig;
    int bestPing = 999999;

    for (int i = 0; i < configs.length; i++) {
      if (!mounted) break;

      final config = configs[i];
      try {
        final ping = await service.getServerDelay(config, useCache: false);
        if (mounted) {
          setState(() => _pingResults[config.id] = ping ?? -1);
        }

        if (ping != null && ping > 0 && ping < bestPing) {
          bestPing = ping;
          bestConfig = config;
        }
      } catch (e) {
        debugPrint('Ping error for ${config.remark}: $e');
        if (mounted) {
          setState(() => _pingResults[config.id] = -1);
        }
      }

      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (mounted) {
      _sortByPing();
      setState(() => _isSorting = false);

      if (bestConfig != null) {
        await _handleSelectConfig(bestConfig);
        
        if (service.isConnected) {
          final shouldReconnect = await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Auto Select'),
              content: Text('Best server found: ${bestConfig!.remark} (${bestPing}ms)\n\nReconnect to this server?'),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No'),
                ),
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes'),
                ),
              ],
            ),
          );

          if (shouldReconnect == true) {
            await _handleConnect(bestConfig);
          }
        } else {
          _showSnackBar('Best Server Selected', '${bestConfig.remark} (${bestPing}ms)');
        }
      } else {
        _showSnackBar('Auto Select Failed', 'No working servers found');
      }
    }
  }

  void _sortByPing() {
    setState(() {
      _configs.sort((a, b) {
        final pingA = _pingResults[a.id] ?? 999999;
        final pingB = _pingResults[b.id] ?? 999999;
        if (pingA == -1 && pingB == -1) return 0;
        if (pingA == -1) return 1;
        if (pingB == -1) return -1;
        return pingA.compareTo(pingB);
      });
    });
  }

  List<V2RayConfig> get _filteredConfigs {
    var configs = _configs;
    
    if (_currentSubscriptionId != null) {
      configs = configs.where((c) => c.subscriptionId == _currentSubscriptionId).toList();
    }
    
    if (_searchQuery.isEmpty) return configs;
    return configs.where((config) {
      return config.remark.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          config.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          config.configType.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<V2RayConfig> get _manualConfigs => _filteredConfigs.where((c) => c.source == 'manual').toList();
  List<V2RayConfig> get _subscriptionConfigs => _filteredConfigs.where((c) => c.source == 'subscription').toList();

  Future<void> _importFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData == null || clipboardData.text == null || clipboardData.text!.isEmpty) {
        _showSnackBar('Empty Clipboard', 'Please copy a config first');
        return;
      }
      
      final text = clipboardData.text!.trim();
      final service = Provider.of<V2RayService>(context, listen: false);
      
      final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
      final configLines = lines.where((line) {
        final trimmed = line.trim();
        return trimmed.startsWith('vmess://') ||
               trimmed.startsWith('vless://') ||
               trimmed.startsWith('trojan://') ||
               trimmed.startsWith('ss://') ||
               trimmed.startsWith('socks://') ||
               trimmed.startsWith('http://') ||
               trimmed.startsWith('https://') ||
               trimmed.startsWith('hysteria2://') ||
               trimmed.startsWith('hysteria://') ||
               trimmed.startsWith('wireguard://');
      }).toList();
      
      if (configLines.isEmpty) {
        _showSnackBar('No Configs Found', 'No valid configs in clipboard');
        return;
      }
      
      if (configLines.length == 1) {
        final config = await service.parseConfigFromClipboard(configLines[0]);
        if (config != null) {
          await _loadConfigs();
          _showSnackBar('Config Added', '${config.remark} added successfully');
        }
      } else {
        await _importMultipleConfigs(configLines);
      }
    } catch (e) {
      _showSnackBar('Import Failed', e.toString());
    }
  }
  
  Future<void> _importWireGuardFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) {
        return;
      }
      
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      
      if (!fileName.toLowerCase().endsWith('.conf')) {
        _showSnackBar('Invalid File', 'Please select a .conf file');
        return;
      }
      
      final content = await file.readAsString();
      
      final service = Provider.of<V2RayService>(context, listen: false);
      final config = await service.parseWireGuardConfigFile(content);
      
      if (config != null) {
        await _loadConfigs();
        _showSnackBar('WireGuard Config Added', '${config.remark} imported successfully');
      } else {
        _showSnackBar('Import Failed', 'Invalid WireGuard config file');
      }
    } catch (e) {
      _showSnackBar('Import Failed', e.toString());
    }
  }
  
  Future<void> _importMultipleConfigs(List<String> configLines) async {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BulkImportDialog(configLines: configLines),
    ).then((result) {
      if (result != null && result is Map) {
        final added = result['added'] as int;
        final failed = result['failed'] as int;
        _loadConfigs();
        _showSnackBar(
          'Import Complete',
          'Added: $added configs${failed > 0 ? ', Failed: $failed' : ''}',
        );
      }
    });
  }

  void _showSnackBar(String title, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(message, style: const TextStyle(fontSize: 12)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _showManualAddDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.add_circled_solid, color: AppTheme.primaryBlue, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Add Server Manually',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Select Protocol',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildProtocolChip('VMess', CupertinoIcons.shield_fill, const Color(0xFF5856D6), isDark),
                  _buildProtocolChip('VLESS', CupertinoIcons.shield_lefthalf_fill, AppTheme.primaryBlue, isDark),
                  _buildProtocolChip('Trojan', CupertinoIcons.lock_shield_fill, const Color(0xFFFF3B30), isDark),
                  _buildProtocolChip('Shadowsocks', CupertinoIcons.eye_slash_fill, const Color(0xFF34C759), isDark),
                  _buildProtocolChip('SOCKS', CupertinoIcons.arrow_right_arrow_left, const Color(0xFFFF9500), isDark),
                  _buildProtocolChip('HTTP', CupertinoIcons.globe, const Color(0xFF007AFF), isDark),
                  _buildProtocolChip('Hysteria2', CupertinoIcons.bolt_fill, const Color(0xFFAF52DE), isDark),
                  _buildProtocolChip('WireGuard', CupertinoIcons.antenna_radiowaves_left_right, const Color(0xFF00C7BE), isDark),
                  _buildProtocolChip('Custom JSON', CupertinoIcons.doc_text_fill, const Color(0xFFFF2D55), isDark, isCustom: true),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: isDark ? Colors.white12 : Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProtocolChip(String protocol, IconData icon, Color color, bool isDark, {bool isCustom = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (isCustom) {
          _showCustomConfigDialog();
        } else {
          _createManualConfig(protocol);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              protocol,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomConfigDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jsonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.doc_text_fill, color: const Color(0xFFFF2D55), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Import Custom Config',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Paste your complete V2Ray JSON configuration below:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.systemGray,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.systemGray.withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: jsonController,
                  maxLines: null,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '{\n  "log": {...},\n  "inbounds": [...],\n  ...\n}',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: isDark ? Colors.white12 : Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () {
                        Navigator.pop(context);
                        _importCustomConfig(jsonController.text);
                      },
                      child: const Text(
                        'Import',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importCustomConfig(String jsonText) async {
    try {
      if (jsonText.trim().isEmpty) {
        _showSnackBar('Error', 'Config cannot be empty');
        return;
      }

      final parsedJson = jsonDecode(jsonText);
      if (parsedJson is! Map<String, dynamic>) {
        _showSnackBar('Error', 'Invalid JSON format');
        return;
      }

      final remarks = parsedJson['remarks'] ?? 'Custom Config ${DateTime.now().millisecondsSinceEpoch}';
      String? server;
      String? serverPort;

      if (parsedJson['outbounds'] != null && parsedJson['outbounds'] is List) {
        final outbounds = parsedJson['outbounds'] as List;
        final proxyOutbound = outbounds.firstWhere(
          (o) => o['tag'] == 'proxy',
          orElse: () => outbounds.isNotEmpty ? outbounds[0] : null,
        );

        if (proxyOutbound != null) {
          if (proxyOutbound['settings'] != null) {
            final settings = proxyOutbound['settings'];
            if (settings['vnext'] != null && settings['vnext'] is List && settings['vnext'].isNotEmpty) {
              server = settings['vnext'][0]['address'];
              serverPort = settings['vnext'][0]['port']?.toString();
            } else if (settings['servers'] != null && settings['servers'] is List && settings['servers'].isNotEmpty) {
              server = settings['servers'][0]['address'];
              serverPort = settings['servers'][0]['port']?.toString();
            }
          }
        }
      }

      final service = Provider.of<V2RayService>(context, listen: false);
      final configs = await service.loadConfigs();

      final newConfig = V2RayConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        remark: remarks.toString(),
        address: server ?? 'custom.server',
        port: int.tryParse(serverPort ?? '') ?? 443,
        configType: 'custom',
        fullConfig: jsonText.trim(),
        source: 'manual',
      );

      configs.add(newConfig);
      await service.saveConfigs(configs);
      await _loadConfigs();

      _showSnackBar('Success', 'Custom config imported successfully');
    } catch (e) {
      _showSnackBar('Error', 'Failed to import: ${e.toString()}');
    }
  }

  Future<void> _createManualConfig(String protocol) async {
    final protocolLower = protocol.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    
    String configUrl = '';
    String configType = '';
    
    switch (protocolLower) {
      case 'vmess':
        configType = 'vmess';
        final vmessJson = {
          'v': '2',
          'ps': 'New VMess Server',
          'add': 'example.com',
          'port': '443',
          'id': '00000000-0000-0000-0000-000000000000',
          'aid': '0',
          'scy': 'auto',
          'net': 'tcp',
          'type': 'none',
          'host': '',
          'path': '',
          'tls': '',
          'sni': '',
          'fp': '',
          'alpn': '',
        };
        final jsonString = jsonEncode(vmessJson);
        final base64String = base64Encode(utf8.encode(jsonString));
        configUrl = 'vmess://$base64String';
        break;
        
      case 'vless':
        configType = 'vless';
        configUrl = 'vless://00000000-0000-0000-0000-000000000000@example.com:443?type=tcp&security=&sni=&fp=&alpn=&flow=#New%20VLESS%20Server';
        break;
        
      case 'trojan':
        configType = 'trojan';
        configUrl = 'trojan://password@example.com:443?type=tcp&security=tls&sni=example.com&fp=&alpn=#New%20Trojan%20Server';
        break;
        
      case 'shadowsocks':
        configType = 'shadowsocks';
        final userInfo = 'aes-256-gcm:password';
        final base64UserInfo = base64Encode(utf8.encode(userInfo));
        configUrl = 'ss://$base64UserInfo@example.com:443#New%20Shadowsocks%20Server';
        break;
        
      case 'socks':
        configType = 'socks';
        configUrl = 'socks://username:password@example.com:1080#New%20SOCKS%20Server';
        break;
        
      case 'http':
        configType = 'http';
        configUrl = 'http://username:password@example.com:8080#New%20HTTP%20Server';
        break;
        
      case 'hysteria2':
        configType = 'hysteria2';
        configUrl = 'hysteria2://password@example.com:443?security=tls&sni=example.com&alpn=h3&insecure=0#New%20Hysteria2%20Server';
        break;
        
      case 'wireguard':
        configType = 'wireguard';
        configUrl = 'wireguard://example.com:51820?secretKey=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=&publicKey=BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=&localAddress=172.16.0.2/32&mtu=1420&reserved=0,0,0#New%20WireGuard%20Server';
        break;
        
      default:
        _showSnackBar('Error', 'Unsupported protocol');
        return;
    }
    
    final newConfig = V2RayConfig(
      id: timestamp,
      remark: 'New $protocol Server',
      address: 'example.com',
      port: 443,
      configType: configType,
      fullConfig: configUrl,
      source: 'manual',
    );
    
    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditConfigScreen(config: newConfig),
        ),
      );
      
      if (result == true) {
        await _loadConfigs();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1C1C1E), Colors.black]
              : [const Color(0xFFF2F2F7), Colors.white],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(isDark),
            if (_subscriptions.isNotEmpty && _tabController != null)
              _buildTabBar(isDark),
            _buildSearchBar(isDark),
            Expanded(child: _buildServerList(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Servers',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Row(
            children: [
              _buildIconButton(CupertinoIcons.add_circled, _showManualAddDialog, isDark),
              _buildIconButton(CupertinoIcons.doc_on_clipboard, _importFromClipboard, isDark),
              _buildIconButton(CupertinoIcons.doc_text, _importWireGuardFile, isDark, tooltip: 'WireGuard File'),
              _buildIconButton(CupertinoIcons.qrcode_viewfinder, _scanQRCode, isDark),
              _buildIconButton(CupertinoIcons.wand_stars, _autoSelectBestServer, isDark, tooltip: 'Auto Select'),
              _isSorting
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CupertinoActivityIndicator(),
                    )
                  : _buildIconButton(CupertinoIcons.sort_down, _pingAllServers, isDark),
              _buildIconButton(CupertinoIcons.refresh, _loadConfigs, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, bool isDark, {String? tooltip}) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 22,
          color: AppTheme.primaryBlue,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: button,
      );
    }

    return button;
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: CupertinoSearchTextField(
        placeholder: 'Search servers...',
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: AppTheme.primaryBlue,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.square_grid_2x2, size: 16),
                const SizedBox(width: 6),
                Text('All (${_configs.length})'),
              ],
            ),
          ),
          ..._subscriptions.map((sub) {
            final count = _configs.where((c) => c.subscriptionId == sub.id).length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.cloud_fill, size: 16),
                  const SizedBox(width: 6),
                  Text('${sub.name} ($count)'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildServerList(bool isDark) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }
    
    if (_filteredConfigs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.rectangle_stack, size: 64, color: AppTheme.systemGray),
            const SizedBox(height: 16),
            Text(
              _currentSubscriptionId != null ? 'No servers in this subscription' : 'No servers found',
              style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              _currentSubscriptionId != null ? 'Update subscription to fetch servers' : 'Add servers from Subscriptions',
              style: TextStyle(fontSize: 14, color: AppTheme.systemGray),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        if (_currentSubscriptionId == null) ...[
          if (_manualConfigs.isNotEmpty) ...[
            _buildSectionHeader('Manual Configs', _manualConfigs.length, CupertinoIcons.pencil, isDark),
            ..._manualConfigs.map((c) => _buildServerCard(c, isDark)),
            const SizedBox(height: 24),
          ],
          if (_subscriptionConfigs.isNotEmpty) ...[
            _buildSectionHeader('Subscription Configs', _subscriptionConfigs.length, CupertinoIcons.cloud_download, isDark),
            ..._subscriptionConfigs.map((c) => _buildServerCard(c, isDark)),
          ],
        ] else ...[
          ..._filteredConfigs.map((c) => _buildServerCard(c, isDark)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryBlue),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard(V2RayConfig config, bool isDark) {
    final ping = _pingResults[config.id];
    final service = Provider.of<V2RayService>(context, listen: false);
    final isConnected = service.activeConfig?.id == config.id;
    final isSelected = _selectedConfigId == config.id;

    return GestureDetector(
      onTap: isConnected ? null : () => _handleSelectConfig(config),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          border: isSelected && !isConnected
              ? Border.all(color: AppTheme.primaryBlue, width: 2)
              : (isConnected ? Border.all(color: AppTheme.connectedGreen, width: 2) : null),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isConnected)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.connectedGreen,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          config.remark,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${config.address}:${config.port}',
                    style: TextStyle(fontSize: 12, color: AppTheme.systemGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                    ),
                    child: Text(
                      config.protocolDisplay,
                      style: TextStyle(fontSize: 10, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildPingBadge(ping),
            _buildActionButtons(config, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPingBadge(int? ping) {
    if (ping == null) return const SizedBox(width: 50);
    
    return Container(
      constraints: const BoxConstraints(minWidth: 50),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.getPingColor(ping).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        ping >= 0 ? '${ping}ms' : 'Fail',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppTheme.getPingColor(ping),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButtons(V2RayConfig config, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _editConfig(config),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(CupertinoIcons.pencil, size: 20, color: AppTheme.primaryBlue),
          ),
        ),
        GestureDetector(
          onTap: () => _pingSingleServer(config),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(CupertinoIcons.speedometer, size: 20, color: AppTheme.primaryBlue),
          ),
        ),
        GestureDetector(
          onTap: () => _showOptionsSheet(config),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(CupertinoIcons.ellipsis, size: 20, color: AppTheme.systemGray),
          ),
        ),
      ],
    );
  }

  IconData _getProtocolIcon(String type) {
    switch (type.toLowerCase()) {
      case 'vmess': return CupertinoIcons.shield;
      case 'vless': return CupertinoIcons.shield_fill;
      case 'trojan': return CupertinoIcons.lock_shield;
      case 'shadowsocks': return CupertinoIcons.lock_fill;
      default: return CupertinoIcons.rectangle_stack;
    }
  }

  void _showOptionsSheet(V2RayConfig config) {
    final service = Provider.of<V2RayService>(context, listen: false);
    final isConnected = service.activeConfig?.id == config.id;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(config.remark),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _handleConnect(config);
            },
            child: Text(isConnected ? 'Disconnect' : 'Connect'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _copyConfig(config);
            },
            child: const Text('Copy Config'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showQRCode(config);
            },
            child: const Text('Show QR Code'),
          ),
          if (!isConnected)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _deleteConfig(config);
              },
              child: const Text('Delete'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _handleSelectConfig(V2RayConfig config) async {
    setState(() => _selectedConfigId = config.id);
    final service = Provider.of<V2RayService>(context, listen: false);
    await service.saveSelectedConfig(config);
    _showSnackBar('Server Selected', '${config.remark} is now selected');
  }

  Future<void> _editConfig(V2RayConfig config) async {
    final result = await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => EditConfigScreen(config: config),
      ),
    );
    
    if (result == true) {
      await _loadConfigs();
    }
  }

  Future<void> _pingSingleServer(V2RayConfig config) async {
    setState(() => _pingResults[config.id] = null);
    final service = Provider.of<V2RayService>(context, listen: false);
    try {
      final ping = await service.getServerDelay(config, useCache: false);
      if (mounted) setState(() => _pingResults[config.id] = ping ?? -1);
    } catch (e) {
      debugPrint('Single ping error for ${config.remark}: $e');
      if (mounted) setState(() => _pingResults[config.id] = -1);
    }
  }

  Future<void> _handleConnect(V2RayConfig config) async {
    final service = Provider.of<V2RayService>(context, listen: false);
    if (service.activeConfig?.id == config.id) {
      await service.disconnect();
      _showSnackBar('Disconnected', 'VPN disconnected');
    } else {
      if (service.isConnected) await service.disconnect();
      final success = await service.connect(config);
      _showSnackBar(
        success ? 'Connected' : 'Connection Failed',
        success ? 'Connected to ${config.remark}' : 'Failed to connect',
      );
    }
  }

  Future<void> _copyConfig(V2RayConfig config) async {
    await Clipboard.setData(ClipboardData(text: config.fullConfig));
    _showSnackBar('Config Copied', '${config.remark} copied to clipboard');
  }

  Future<void> _showQRCode(V2RayConfig config) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                config.remark,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: config.fullConfig,
                  version: QrVersions.auto,
                  size: 260,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Scan to import config',
                style: TextStyle(fontSize: 13, color: AppTheme.systemGray),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteConfig(V2RayConfig config) async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Config'),
        content: Text('Are you sure you want to delete "${config.remark}"?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              final service = Provider.of<V2RayService>(context, listen: false);
              final configs = await service.loadConfigs();
              configs.removeWhere((c) => c.id == config.id);
              await service.saveConfigs(configs);
              service.clearPingCache(configId: config.id);
              await _loadConfigs();
              _showSnackBar('Config Deleted', '${config.remark} has been deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanQRCode() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _showSnackBar('Permission Denied', 'Camera permission is required');
      return;
    }

    if (mounted) {
      await Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => _QRScannerScreen(
            onQRScanned: (String code) async {
              Navigator.pop(context);
              try {
                final service = Provider.of<V2RayService>(context, listen: false);
                final config = await service.parseConfigFromClipboard(code);
                if (config != null) {
                  await _loadConfigs();
                  _showSnackBar('Config Added', '${config.remark} added from QR code');
                }
              } catch (e) {
                _showSnackBar('Invalid QR Code', e.toString());
              }
            },
          ),
        ),
      );
    }
  }
}

class _QRScannerScreen extends StatefulWidget {
  final Function(String) onQRScanned;
  const _QRScannerScreen({required this.onQRScanned});

  @override
  State<_QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<_QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isScanning = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (isScanning) {
      for (final barcode in capture.barcodes) {
        if (barcode.rawValue != null) {
          isScanning = false;
          controller.stop();
          widget.onQRScanned(barcode.rawValue!);
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Scan QR Code'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryBlue, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Position the QR code within the frame',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _BulkImportDialog extends StatefulWidget {
  final List<String> configLines;
  
  const _BulkImportDialog({required this.configLines});

  @override
  State<_BulkImportDialog> createState() => _BulkImportDialogState();
}

class _BulkImportDialogState extends State<_BulkImportDialog> {
  bool _isImporting = false;
  int _currentIndex = 0;
  int _addedCount = 0;
  int _failedCount = 0;
  String _currentConfig = '';
  
  @override
  void initState() {
    super.initState();
    _startImport();
  }
  
  Future<void> _startImport() async {
    setState(() => _isImporting = true);
    
    final service = Provider.of<V2RayService>(context, listen: false);
    final existingConfigs = await service.loadConfigs();
    
    for (int i = 0; i < widget.configLines.length; i++) {
      if (!mounted) break;
      
      setState(() {
        _currentIndex = i + 1;
        _currentConfig = widget.configLines[i];
      });
      
      try {
        final config = await service.parseConfigFromClipboard(widget.configLines[i]);
        if (config != null) {
          existingConfigs.add(config);
          setState(() => _addedCount++);
        } else {
          setState(() => _failedCount++);
        }
      } catch (e) {
        setState(() => _failedCount++);
      }
      
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    await service.saveConfigs(existingConfigs);
    
    setState(() => _isImporting = false);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      Navigator.pop(context, {
        'added': _addedCount,
        'failed': _failedCount,
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _currentIndex / widget.configLines.length;
    
    return CupertinoAlertDialog(
      title: Text(_isImporting ? 'Importing Configs' : 'Import Complete'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          if (_isImporting) ...[
            const CupertinoActivityIndicator(radius: 16),
            const SizedBox(height: 16),
            Text(
              'Processing $_currentIndex of ${widget.configLines.length}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.systemGray.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _truncateConfig(_currentConfig),
              style: TextStyle(fontSize: 11, color: AppTheme.systemGray),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            Icon(
              CupertinoIcons.check_mark_circled_solid,
              size: 48,
              color: AppTheme.connectedGreen,
            ),
            const SizedBox(height: 16),
            Text(
              'Added: $_addedCount configs',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (_failedCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Failed: $_failedCount configs',
                style: TextStyle(fontSize: 13, color: AppTheme.disconnectedRed),
              ),
            ],
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.connectedGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '✓ $_addedCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.connectedGreen,
                  ),
                ),
              ),
              if (_failedCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.disconnectedRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '✗ $_failedCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.disconnectedRed,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      actions: [
        if (!_isImporting)
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, {
              'added': _addedCount,
              'failed': _failedCount,
            }),
            child: const Text('Done'),
          ),
      ],
    );
  }
  
  String _truncateConfig(String config) {
    if (config.length <= 50) return config;
    return '${config.substring(0, 50)}...';
  }
}
