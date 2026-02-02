import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zedsecure/models/v2ray_config.dart';
import 'package:zedsecure/models/app_settings.dart';
import 'package:zedsecure/services/v2ray_service.dart';
import 'package:zedsecure/services/v2ray_config_builder.dart';
import 'package:zedsecure/theme/app_theme.dart';
import 'package:zedsecure/screens/config_viewer_screen.dart';
import 'dart:convert';

class EditConfigScreen extends StatefulWidget {
  final V2RayConfig config;

  const EditConfigScreen({super.key, required this.config});

  @override
  State<EditConfigScreen> createState() => _EditConfigScreenState();
}

class _EditConfigScreenState extends State<EditConfigScreen> {
  late TextEditingController _remarkController;
  late TextEditingController _addressController;
  late TextEditingController _portController;
  late TextEditingController _idController;
  late TextEditingController _jsonController;
  
  late TextEditingController _usernameController;
  late TextEditingController _encryptionController;
  
  late TextEditingController _upBandwidthController;
  late TextEditingController _downBandwidthController;
  late TextEditingController _obfsPasswordController;
  late TextEditingController _portHoppingController;
  late TextEditingController _portHoppingIntervalController;
  late TextEditingController _pinSHA256Controller;
  
  late TextEditingController _publicKeyController;
  late TextEditingController _preSharedKeyController;
  late TextEditingController _reservedController;
  late TextEditingController _localAddressController;
  late TextEditingController _mtuController;
  
  late TextEditingController _hostController;
  late TextEditingController _pathController;
  late TextEditingController _extraController;
  
  late TextEditingController _sniController;
  late TextEditingController _echConfigListController;
  late TextEditingController _pinnedCA256Controller;
  late TextEditingController _realityPublicKeyController;
  late TextEditingController _shortIdController;
  late TextEditingController _spiderXController;
  late TextEditingController _mldsa65VerifyController;
  
  bool _isSaving = false;
  int _obfsType = 0;
  String _selectedMethod = 'auto';
  String _selectedFlow = '';
  String _selectedNetwork = 'tcp';
  String _selectedHeaderType = 'none';
  String _selectedStreamSecurity = '';
  String _selectedFingerprint = '';
  String _selectedAlpn = '';
  String _selectedAllowInsecure = 'false';
  String _selectedEchForceQuery = '';

  @override
  void initState() {
    super.initState();
    _remarkController = TextEditingController(text: widget.config.remark);
    _addressController = TextEditingController(text: widget.config.address);
    _portController = TextEditingController(text: widget.config.port.toString());
    _idController = TextEditingController(text: _extractId());
    _jsonController = TextEditingController(text: widget.config.fullConfig);
    
    _usernameController = TextEditingController();
    _encryptionController = TextEditingController(text: 'none');
    
    _upBandwidthController = TextEditingController(text: '100');
    _downBandwidthController = TextEditingController(text: '100');
    _obfsPasswordController = TextEditingController();
    _portHoppingController = TextEditingController();
    _portHoppingIntervalController = TextEditingController();
    _pinSHA256Controller = TextEditingController();
    
    _publicKeyController = TextEditingController();
    _preSharedKeyController = TextEditingController();
    _reservedController = TextEditingController(text: '0,0,0');
    _localAddressController = TextEditingController(text: '172.16.0.2/32');
    _mtuController = TextEditingController(text: '1420');
    
    _hostController = TextEditingController();
    _pathController = TextEditingController();
    _extraController = TextEditingController();
    
    _sniController = TextEditingController();
    _echConfigListController = TextEditingController();
    _pinnedCA256Controller = TextEditingController();
    _realityPublicKeyController = TextEditingController();
    _shortIdController = TextEditingController();
    _spiderXController = TextEditingController();
    _mldsa65VerifyController = TextEditingController();
    
    _parseConfigDetails();
  }
  
  void _parseConfigDetails() {
    try {
      final uri = Uri.parse(widget.config.fullConfig);
      final protocol = widget.config.configType.toLowerCase();
      
      if (protocol == 'vmess') {
        final base64 = uri.host;
        final decoded = utf8.decode(base64Decode(base64));
        final json = jsonDecode(decoded);
        
        _selectedNetwork = json['net'] ?? 'tcp';
        _selectedHeaderType = json['type'] ?? 'none';
        _hostController.text = json['host'] ?? '';
        _pathController.text = json['path'] ?? '';
        _selectedStreamSecurity = json['tls'] ?? '';
        _sniController.text = json['sni'] ?? '';
        _selectedFingerprint = json['fp'] ?? '';
        _selectedAlpn = json['alpn'] ?? '';
      } else if (protocol == 'vless' || protocol == 'trojan') {
        final params = uri.queryParameters;
        
        _selectedNetwork = params['type'] ?? 'tcp';
        _selectedHeaderType = params['headerType'] ?? 'none';
        _hostController.text = params['host'] ?? '';
        _pathController.text = params['path'] ?? '';
        _selectedStreamSecurity = params['security'] ?? '';
        _sniController.text = params['sni'] ?? '';
        _selectedFingerprint = params['fp'] ?? '';
        _selectedAlpn = params['alpn'] ?? '';
        _selectedFlow = params['flow'] ?? '';
        
        if (_selectedStreamSecurity == 'tls') {
          _echConfigListController.text = params['echConfigList'] ?? '';
          _selectedEchForceQuery = params['echForceQuery'] ?? '';
          _pinnedCA256Controller.text = params['pinnedCA256'] ?? '';
        } else if (_selectedStreamSecurity == 'reality') {
          _realityPublicKeyController.text = params['pbk'] ?? '';
          _shortIdController.text = params['sid'] ?? '';
          _spiderXController.text = params['spx'] ?? '';
          _mldsa65VerifyController.text = params['mldsa65Verify'] ?? '';
        }
        
        if (_selectedNetwork == 'xhttp') {
          _extraController.text = params['extra'] ?? '';
        }
      } else if (protocol == 'hysteria2' || protocol == 'hysteria') {
        final params = uri.queryParameters;
        
        _sniController.text = params['sni'] ?? '';
        _selectedAlpn = params['alpn'] ?? 'h3';
        _selectedAllowInsecure = (params['insecure'] == '1' || params['insecure'] == 'true') ? 'true' : 'false';
        _selectedFingerprint = params['fp'] ?? '';
        
        _upBandwidthController.text = params['up'] ?? '100';
        _downBandwidthController.text = params['down'] ?? '100';
        
        if (params['obfs'] == 'salamander') {
          _obfsType = 1;
          _obfsPasswordController.text = params['obfs-password'] ?? '';
        } else {
          _obfsType = 0;
        }
        
        _portHoppingController.text = params['mport'] ?? '';
        _portHoppingIntervalController.text = params['mportHopInt'] ?? '';
        _pinSHA256Controller.text = params['pinSHA256'] ?? '';
      } else if (protocol == 'wireguard') {
        final params = uri.queryParameters;
        
        _publicKeyController.text = params['publicKey'] ?? '';
        _preSharedKeyController.text = params['preSharedKey'] ?? '';
        _reservedController.text = params['reserved'] ?? '0,0,0';
        _localAddressController.text = params['localAddress'] ?? '172.16.0.2/32';
        _mtuController.text = params['mtu'] ?? '1420';
      }
    } catch (e) {
      debugPrint('Error parsing config details: $e');
    }
  }

  @override
  void dispose() {
    _remarkController.dispose();
    _addressController.dispose();
    _portController.dispose();
    _idController.dispose();
    _jsonController.dispose();
    _usernameController.dispose();
    _encryptionController.dispose();
    _upBandwidthController.dispose();
    _downBandwidthController.dispose();
    _obfsPasswordController.dispose();
    _portHoppingController.dispose();
    _portHoppingIntervalController.dispose();
    _pinSHA256Controller.dispose();
    _publicKeyController.dispose();
    _preSharedKeyController.dispose();
    _reservedController.dispose();
    _localAddressController.dispose();
    _mtuController.dispose();
    _hostController.dispose();
    _pathController.dispose();
    _extraController.dispose();
    _sniController.dispose();
    _echConfigListController.dispose();
    _pinnedCA256Controller.dispose();
    _realityPublicKeyController.dispose();
    _shortIdController.dispose();
    _spiderXController.dispose();
    _mldsa65VerifyController.dispose();
    super.dispose();
  }

  String _extractId() {
    try {
      final uri = Uri.parse(widget.config.fullConfig);
      final protocol = widget.config.configType.toLowerCase();
      
      if (protocol == 'vmess') {
        final base64 = uri.host;
        final decoded = utf8.decode(base64Decode(base64));
        final json = jsonDecode(decoded);
        return json['id'] ?? '';
      } else if (protocol == 'vless' || protocol == 'trojan') {
        return uri.userInfo;
      } else if (protocol == 'shadowsocks') {
        final userInfo = uri.userInfo;
        if (userInfo.contains(':')) {
          return userInfo.split(':').last;
        }
        return userInfo;
      } else if (protocol == 'hysteria2' || protocol == 'hysteria') {
        return uri.userInfo;
      } else if (protocol == 'wireguard') {
        final params = uri.queryParameters;
        return params['secretKey'] ?? '';
      }
    } catch (e) {
      debugPrint('Error extracting ID: $e');
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Config',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.doc_text, color: AppTheme.primaryBlue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConfigViewerScreen(
                    config: widget.config,
                    editable: widget.config.configType.toLowerCase() == 'custom',
                  ),
                ),
              );
            },
          ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CupertinoActivityIndicator(),
            )
          else
            TextButton(
              onPressed: _saveConfig,
              child: Text(
                'Save',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildFormEditor(isDark),
        ],
      ),
    );
  }

  Widget _buildFormEditor(bool isDark) {
    final protocol = widget.config.configType.toLowerCase();
    
    return Column(
      children: [
        _buildSection('BASIC INFORMATION', [
          _buildTextField('Remark', _remarkController, CupertinoIcons.tag, isDark),
          _buildTextField('Address', _addressController, CupertinoIcons.globe, isDark),
          _buildTextField('Port', _portController, CupertinoIcons.number, isDark, keyboardType: TextInputType.number),
        ], isDark),
        const SizedBox(height: 20),
        _buildProtocolSection(protocol, isDark),
        if (protocol != 'wireguard' && protocol != 'hysteria2' && protocol != 'hysteria') ...[
          const SizedBox(height: 20),
          _buildTransportSection(isDark),
          const SizedBox(height: 20),
          _buildTlsSection(isDark),
        ],
      ],
    );
  }

  Widget _buildProtocolSection(String protocol, bool isDark) {
    switch (protocol) {
      case 'vmess':
        return _buildVMessSection(isDark);
      case 'vless':
        return _buildVLESSSection(isDark);
      case 'trojan':
        return _buildTrojanSection(isDark);
      case 'shadowsocks':
        return _buildShadowsocksSection(isDark);
      case 'socks':
      case 'http':
        return _buildSocksHttpSection(isDark);
      case 'hysteria2':
      case 'hysteria':
        return _buildHysteria2Section(isDark);
      case 'wireguard':
        return _buildWireguardSection(isDark);
      default:
        return _buildGenericSection(isDark);
    }
  }

  Widget _buildVMessSection(bool isDark) {
    return _buildSection('VMESS SETTINGS', [
      _buildProtocolBadge('VMess', isDark),
      _buildTextField('UUID', _idController, CupertinoIcons.lock, isDark),
      _buildDropdown('Security', const ['chacha20-poly1305', 'aes-128-gcm', 'auto', 'none', 'zero'], _selectedMethod, (v) => setState(() => _selectedMethod = v!), isDark),
    ], isDark);
  }

  Widget _buildVLESSSection(bool isDark) {
    return _buildSection('VLESS SETTINGS', [
      _buildProtocolBadge('VLESS', isDark),
      _buildTextField('UUID', _idController, CupertinoIcons.lock, isDark),
      _buildTextField('Encryption', _encryptionController, CupertinoIcons.lock_shield, isDark, hint: 'none'),
      _buildDropdown('Flow', const ['', 'xtls-rprx-vision', 'xtls-rprx-vision-udp443'], _selectedFlow, (v) => setState(() => _selectedFlow = v!), isDark),
    ], isDark);
  }

  Widget _buildTrojanSection(bool isDark) {
    return _buildSection('TROJAN SETTINGS', [
      _buildProtocolBadge('Trojan', isDark),
      _buildTextField('Password', _idController, CupertinoIcons.lock, isDark),
    ], isDark);
  }

  Widget _buildShadowsocksSection(bool isDark) {
    return _buildSection('SHADOWSOCKS SETTINGS', [
      _buildProtocolBadge('Shadowsocks', isDark),
      _buildDropdown('Method', const ['aes-256-gcm', 'aes-128-gcm', 'chacha20-poly1305', 'chacha20-ietf-poly1305', 'xchacha20-poly1305', 'xchacha20-ietf-poly1305', 'none', 'plain', '2022-blake3-aes-128-gcm', '2022-blake3-aes-256-gcm', '2022-blake3-chacha20-poly1305'], _selectedMethod, (v) => setState(() => _selectedMethod = v!), isDark),
      _buildTextField('Password', _idController, CupertinoIcons.lock, isDark),
    ], isDark);
  }

  Widget _buildSocksHttpSection(bool isDark) {
    return _buildSection('${widget.config.configType.toUpperCase()} SETTINGS', [
      _buildProtocolBadge(widget.config.configType.toUpperCase(), isDark),
      _buildTextField('Username', _usernameController, CupertinoIcons.person, isDark),
      _buildTextField('Password', _idController, CupertinoIcons.lock, isDark),
    ], isDark);
  }

  Widget _buildGenericSection(bool isDark) {
    return _buildSection('PROTOCOL SETTINGS', [
      _buildProtocolBadge(widget.config.protocolDisplay, isDark),
      _buildTextField('ID / Password', _idController, CupertinoIcons.lock, isDark),
    ], isDark);
  }

  Widget _buildHysteria2Section(bool isDark) {
    return Column(
      children: [
        _buildSection('HYSTERIA2 SETTINGS', [
          _buildProtocolBadge('Hysteria2', isDark),
          _buildTextField('Password', _idController, CupertinoIcons.lock, isDark),
        ], isDark),
        const SizedBox(height: 20),
        _buildSection('BANDWIDTH', [
          _buildBandwidthFields(isDark),
        ], isDark),
        const SizedBox(height: 20),
        _buildSection('OBFUSCATION', [
          _buildObfuscationFields(isDark),
        ], isDark),
        const SizedBox(height: 20),
        _buildSection('PORT HOPPING', [
          _buildTextField('Port Hopping', _portHoppingController, CupertinoIcons.arrow_2_circlepath, isDark, hint: 'e.g., 1000-2000'),
          _buildTextField('Hop Interval (s)', _portHoppingIntervalController, CupertinoIcons.timer, isDark, keyboardType: TextInputType.number, hint: '30'),
        ], isDark),
        const SizedBox(height: 20),
        _buildSection('TLS SETTINGS', [
          _buildTextField('SNI', _sniController, CupertinoIcons.globe, isDark, hint: 'example.com'),
          _buildDropdown('ALPN', const ['', 'h3', 'h2', 'http/1.1'], _selectedAlpn.isEmpty ? 'h3' : _selectedAlpn, (v) => setState(() => _selectedAlpn = v!), isDark),
          _buildDropdown('Fingerprint', const ['', 'chrome', 'firefox', 'safari', 'ios', 'android', 'edge', '360', 'qq', 'random', 'randomized'], _selectedFingerprint, (v) => setState(() => _selectedFingerprint = v!), isDark),
          _buildDropdown('Allow Insecure', const ['false', 'true'], _selectedAllowInsecure.isEmpty ? 'false' : _selectedAllowInsecure, (v) => setState(() => _selectedAllowInsecure = v!), isDark),
          _buildTextField('Pin SHA256', _pinSHA256Controller, CupertinoIcons.lock_shield, isDark, hint: 'Optional'),
        ], isDark),
      ],
    );
  }

  Widget _buildWireguardSection(bool isDark) {
    return Column(
      children: [
        _buildSection('WIREGUARD SETTINGS', [
          _buildProtocolBadge('WireGuard', isDark),
          _buildTextField('Secret Key', _idController, CupertinoIcons.lock, isDark),
          _buildTextField('Public Key', _publicKeyController, CupertinoIcons.lock_fill, isDark),
          _buildTextField('Pre-Shared Key', _preSharedKeyController, CupertinoIcons.lock_shield, isDark, hint: 'Optional'),
          _buildTextField('Reserved', _reservedController, CupertinoIcons.number, isDark, hint: '0,0,0'),
        ], isDark),
        const SizedBox(height: 20),
        _buildSection('LOCAL SETTINGS', [
          _buildTextField('Local Address', _localAddressController, CupertinoIcons.location, isDark),
          _buildTextField('MTU', _mtuController, CupertinoIcons.number, isDark, keyboardType: TextInputType.number),
        ], isDark),
      ],
    );
  }

  Widget _buildBandwidthFields(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upload (Mbps)', style: TextStyle(fontSize: 12, color: AppTheme.systemGray)),
                const SizedBox(height: 6),
                TextField(
                  controller: _upBandwidthController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black),
                  decoration: _inputDecoration('100', isDark),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Download (Mbps)', style: TextStyle(fontSize: 12, color: AppTheme.systemGray)),
                const SizedBox(height: 6),
                TextField(
                  controller: _downBandwidthController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black),
                  decoration: _inputDecoration('100', isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObfuscationFields(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            ),
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _obfsType,
              children: const {
                0: Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12), child: Text('None', style: TextStyle(fontSize: 13))),
                1: Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12), child: Text('Salamander', style: TextStyle(fontSize: 13))),
              },
              onValueChanged: (value) {
                if (value != null) setState(() => _obfsType = value);
              },
            ),
          ),
          if (_obfsType == 1) ...[
            const SizedBox(height: 12),
            Text('Obfuscation Password', style: TextStyle(fontSize: 12, color: AppTheme.systemGray)),
            const SizedBox(height: 6),
            TextField(
              controller: _obfsPasswordController,
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black),
              decoration: _inputDecoration('Enter password', isDark),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransportSection(bool isDark) {
    final protocol = widget.config.configType.toLowerCase();
    final showTransport = protocol != 'socks' && protocol != 'http' && protocol != 'wireguard' && protocol != 'hysteria2' && protocol != 'hysteria';
    
    if (!showTransport) return const SizedBox.shrink();
    
    return _buildSection('TRANSPORT SETTINGS', [
      _buildDropdown('Network', const ['tcp', 'kcp', 'ws', 'httpupgrade', 'xhttp', 'h2', 'grpc'], _selectedNetwork, (v) {
        setState(() {
          _selectedNetwork = v!;
          if (_selectedNetwork == 'tcp') {
            _selectedHeaderType = 'none';
          } else if (_selectedNetwork == 'kcp') {
            _selectedHeaderType = 'none';
          } else if (_selectedNetwork == 'grpc') {
            _selectedHeaderType = 'gun';
          } else if (_selectedNetwork == 'xhttp') {
            _selectedHeaderType = 'auto';
          } else {
            _selectedHeaderType = 'none';
          }
        });
      }, isDark),
      _buildHeaderTypeDropdown(isDark),
      _buildTextField(_getHostLabel(), _hostController, CupertinoIcons.globe, isDark, hint: _getHostHint()),
      _buildTextField(_getPathLabel(), _pathController, CupertinoIcons.arrow_right, isDark, hint: _getPathHint()),
      if (_selectedNetwork == 'xhttp')
        _buildTextField('Extra (JSON)', _extraController, CupertinoIcons.doc_text, isDark, hint: '{"key":"value"}', maxLines: 3),
    ], isDark);
  }
  
  Widget _buildHeaderTypeDropdown(bool isDark) {
    List<String> headerTypes = [];
    String label = 'Header Type';
    
    if (_selectedNetwork == 'tcp') {
      headerTypes = ['none', 'http'];
      label = 'Header Type';
    } else if (_selectedNetwork == 'kcp') {
      headerTypes = ['none', 'srtp', 'utp', 'wechat-video', 'dtls', 'wireguard', 'dns'];
      label = 'Header Type';
    } else if (_selectedNetwork == 'grpc') {
      headerTypes = ['gun', 'multi'];
      label = 'Mode Type';
    } else if (_selectedNetwork == 'xhttp') {
      headerTypes = ['auto', 'packet-up', 'stream-up', 'stream-one'];
      label = 'XHTTP Mode';
    } else {
      headerTypes = ['none'];
      label = 'Header Type';
    }
    
    if (!headerTypes.contains(_selectedHeaderType)) {
      _selectedHeaderType = headerTypes.first;
    }
    
    return _buildDropdown(label, headerTypes, _selectedHeaderType, (v) => setState(() => _selectedHeaderType = v!), isDark);
  }
  
  String _getHostLabel() {
    switch (_selectedNetwork) {
      case 'tcp':
        return 'Request Host (HTTP)';
      case 'ws':
        return 'Request Host (WS)';
      case 'httpupgrade':
        return 'Request Host (HTTP Upgrade)';
      case 'xhttp':
        return 'Request Host (XHTTP)';
      case 'h2':
        return 'Request Host (H2)';
      case 'grpc':
        return 'Authority (gRPC)';
      default:
        return 'Request Host';
    }
  }
  
  String _getHostHint() {
    switch (_selectedNetwork) {
      case 'grpc':
        return 'example.com';
      default:
        return 'example.com';
    }
  }
  
  String _getPathLabel() {
    switch (_selectedNetwork) {
      case 'kcp':
        return 'Seed (KCP)';
      case 'ws':
        return 'Path (WS)';
      case 'httpupgrade':
        return 'Path (HTTP Upgrade)';
      case 'xhttp':
        return 'Path (XHTTP)';
      case 'h2':
        return 'Path (H2)';
      case 'grpc':
        return 'Service Name (gRPC)';
      default:
        return 'Path';
    }
  }
  
  String _getPathHint() {
    switch (_selectedNetwork) {
      case 'kcp':
        return 'seed value';
      case 'grpc':
        return 'serviceName';
      default:
        return '/path';
    }
  }

  Widget _buildTlsSection(bool isDark) {
    final protocol = widget.config.configType.toLowerCase();
    final showTls = protocol != 'socks' && protocol != 'http' && protocol != 'wireguard' && protocol != 'hysteria2' && protocol != 'hysteria';
    
    if (!showTls) return const SizedBox.shrink();
    
    return _buildSection('TLS / SECURITY SETTINGS', [
      _buildDropdown('Stream Security', const ['', 'tls', 'reality'], _selectedStreamSecurity, (v) {
        setState(() => _selectedStreamSecurity = v!);
      }, isDark),
      if (_selectedStreamSecurity.isNotEmpty) ...[
        _buildTextField('SNI', _sniController, CupertinoIcons.globe, isDark, hint: 'example.com'),
        _buildDropdown('Fingerprint', const ['', 'chrome', 'firefox', 'safari', 'ios', 'android', 'edge', '360', 'qq', 'random', 'randomized'], _selectedFingerprint, (v) => setState(() => _selectedFingerprint = v!), isDark),
      ],
      if (_selectedStreamSecurity == 'tls') ...[
        _buildDropdown('ALPN', const ['', 'h3', 'h2', 'http/1.1', 'h3,h2,http/1.1', 'h3,h2', 'h2,http/1.1'], _selectedAlpn, (v) => setState(() => _selectedAlpn = v!), isDark),
        _buildDropdown('Allow Insecure', const ['false', 'true'], _selectedAllowInsecure.isEmpty ? 'false' : _selectedAllowInsecure, (v) => setState(() => _selectedAllowInsecure = v!), isDark),
        _buildTextField('ECH Config List', _echConfigListController, CupertinoIcons.lock_shield, isDark, hint: 'Optional'),
        _buildDropdown('ECH Force Query', const ['', 'none', 'half', 'full'], _selectedEchForceQuery, (v) => setState(() => _selectedEchForceQuery = v!), isDark),
        _buildTextField('Pinned CA256', _pinnedCA256Controller, CupertinoIcons.lock_shield, isDark, hint: 'Optional'),
      ],
      if (_selectedStreamSecurity == 'reality') ...[
        _buildTextField('Public Key', _realityPublicKeyController, CupertinoIcons.lock_fill, isDark, hint: 'Required for REALITY'),
        _buildTextField('Short ID', _shortIdController, CupertinoIcons.number, isDark, hint: 'Optional'),
        _buildTextField('Spider X', _spiderXController, CupertinoIcons.arrow_branch, isDark, hint: 'Optional'),
        _buildTextField('MLDSA65 Verify', _mldsa65VerifyController, CupertinoIcons.checkmark_shield, isDark, hint: 'Optional'),
      ],
    ], isDark);
  }

  Widget _buildSection(String title, List<Widget> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.systemGray,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final isLast = entry.key == children.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 60),
                      child: Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, bool isDark, {TextInputType? keyboardType, String? hint, int? maxLines}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Icon(icon, color: AppTheme.primaryBlue, size: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.systemGray,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines ?? 1,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: TextStyle(color: AppTheme.systemGray.withOpacity(0.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, ValueChanged<String?> onChanged, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Icon(CupertinoIcons.chevron_down, color: AppTheme.primaryBlue, size: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.systemGray,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: items.contains(value) ? value : items.first,
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black),
                  dropdownColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  items: items.map((item) => DropdownMenuItem(value: item, child: Text(item.isEmpty ? 'None' : item))).toList(),
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolBadge(String protocol, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Icon(CupertinoIcons.shield_fill, color: AppTheme.primaryBlue, size: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Protocol',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.systemGray,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                  ),
                  child: Text(
                    protocol,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.systemGray),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Future<void> _saveConfig() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final service = Provider.of<V2RayService>(context, listen: false);
      final configs = await service.loadConfigs();
      
      final index = configs.indexWhere((c) => c.id == widget.config.id);
      if (index == -1) {
        throw Exception('Config not found');
      }

      final newFullConfig = _buildConfigUrl();
      final updatedConfig = widget.config.copyWith(
        remark: _remarkController.text.trim(),
        address: _addressController.text.trim(),
        port: int.tryParse(_portController.text.trim()) ?? widget.config.port,
        fullConfig: newFullConfig,
      );

      configs[index] = updatedConfig;
      await service.saveConfigs(configs);
      service.clearPingCache(configId: widget.config.id);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Config updated successfully'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
  String _buildConfigUrl() {
    final protocol = widget.config.configType.toLowerCase();
    final address = _addressController.text.trim();
    final port = _portController.text.trim();
    final remark = _remarkController.text.trim();
    
    switch (protocol) {
      case 'vmess':
        return _buildVMessUrl(address, port, remark);
      case 'vless':
        return _buildVLESSUrl(address, port, remark);
      case 'trojan':
        return _buildTrojanUrl(address, port, remark);
      case 'shadowsocks':
        return _buildShadowsocksUrl(address, port, remark);
      case 'socks':
      case 'http':
        return _buildSocksHttpUrl(protocol, address, port, remark);
      case 'hysteria2':
      case 'hysteria':
        return _buildHysteria2Url(address, port, remark);
      case 'wireguard':
        return _buildWireguardUrl(address, port, remark);
      default:
        return widget.config.fullConfig;
    }
  }
  
  String _buildVMessUrl(String address, String port, String remark) {
    final vmessJson = {
      'v': '2',
      'ps': remark,
      'add': address,
      'port': port,
      'id': _idController.text.trim(),
      'aid': '0',
      'scy': _selectedMethod,
      'net': _selectedNetwork,
      'type': _selectedHeaderType,
      'host': _hostController.text.trim(),
      'path': _pathController.text.trim(),
      'tls': _selectedStreamSecurity,
      'sni': _sniController.text.trim(),
      'fp': _selectedFingerprint,
      'alpn': _selectedAlpn,
    };
    
    final jsonString = jsonEncode(vmessJson);
    final base64String = base64Encode(utf8.encode(jsonString));
    return 'vmess://$base64String';
  }
  
  String _buildVLESSUrl(String address, String port, String remark) {
    final params = <String, String>{
      'type': _selectedNetwork,
      'security': _selectedStreamSecurity,
    };
    
    if (_selectedHeaderType.isNotEmpty && _selectedHeaderType != 'none') {
      params['headerType'] = _selectedHeaderType;
    }
    if (_hostController.text.trim().isNotEmpty) {
      params['host'] = _hostController.text.trim();
    }
    if (_pathController.text.trim().isNotEmpty) {
      params['path'] = _pathController.text.trim();
    }
    if (_selectedStreamSecurity.isNotEmpty) {
      if (_sniController.text.trim().isNotEmpty) {
        params['sni'] = _sniController.text.trim();
      }
      if (_selectedFingerprint.isNotEmpty) {
        params['fp'] = _selectedFingerprint;
      }
      if (_selectedStreamSecurity == 'tls') {
        if (_selectedAlpn.isNotEmpty) {
          params['alpn'] = _selectedAlpn;
        }
        if (_echConfigListController.text.trim().isNotEmpty) {
          params['echConfigList'] = _echConfigListController.text.trim();
        }
        if (_selectedEchForceQuery.isNotEmpty) {
          params['echForceQuery'] = _selectedEchForceQuery;
        }
        if (_pinnedCA256Controller.text.trim().isNotEmpty) {
          params['pinnedCA256'] = _pinnedCA256Controller.text.trim();
        }
      } else if (_selectedStreamSecurity == 'reality') {
        if (_realityPublicKeyController.text.trim().isNotEmpty) {
          params['pbk'] = _realityPublicKeyController.text.trim();
        }
        if (_shortIdController.text.trim().isNotEmpty) {
          params['sid'] = _shortIdController.text.trim();
        }
        if (_spiderXController.text.trim().isNotEmpty) {
          params['spx'] = _spiderXController.text.trim();
        }
        if (_mldsa65VerifyController.text.trim().isNotEmpty) {
          params['mldsa65Verify'] = _mldsa65VerifyController.text.trim();
        }
      }
    }
    if (_selectedFlow.isNotEmpty) {
      params['flow'] = _selectedFlow;
    }
    if (_encryptionController.text.trim().isNotEmpty) {
      params['encryption'] = _encryptionController.text.trim();
    }
    if (_selectedNetwork == 'xhttp' && _extraController.text.trim().isNotEmpty) {
      params['extra'] = _extraController.text.trim();
    }
    
    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final encodedRemark = Uri.encodeComponent(remark);
    return 'vless://${_idController.text.trim()}@$address:$port?$queryString#$encodedRemark';
  }
  
  String _buildTrojanUrl(String address, String port, String remark) {
    final params = <String, String>{
      'type': _selectedNetwork,
      'security': _selectedStreamSecurity,
    };
    
    if (_selectedHeaderType.isNotEmpty && _selectedHeaderType != 'none') {
      params['headerType'] = _selectedHeaderType;
    }
    if (_hostController.text.trim().isNotEmpty) {
      params['host'] = _hostController.text.trim();
    }
    if (_pathController.text.trim().isNotEmpty) {
      params['path'] = _pathController.text.trim();
    }
    if (_selectedStreamSecurity.isNotEmpty) {
      if (_sniController.text.trim().isNotEmpty) {
        params['sni'] = _sniController.text.trim();
      }
      if (_selectedFingerprint.isNotEmpty) {
        params['fp'] = _selectedFingerprint;
      }
      if (_selectedStreamSecurity == 'tls') {
        if (_selectedAlpn.isNotEmpty) {
          params['alpn'] = _selectedAlpn;
        }
        if (_echConfigListController.text.trim().isNotEmpty) {
          params['echConfigList'] = _echConfigListController.text.trim();
        }
        if (_selectedEchForceQuery.isNotEmpty) {
          params['echForceQuery'] = _selectedEchForceQuery;
        }
        if (_pinnedCA256Controller.text.trim().isNotEmpty) {
          params['pinnedCA256'] = _pinnedCA256Controller.text.trim();
        }
      } else if (_selectedStreamSecurity == 'reality') {
        if (_realityPublicKeyController.text.trim().isNotEmpty) {
          params['pbk'] = _realityPublicKeyController.text.trim();
        }
        if (_shortIdController.text.trim().isNotEmpty) {
          params['sid'] = _shortIdController.text.trim();
        }
        if (_spiderXController.text.trim().isNotEmpty) {
          params['spx'] = _spiderXController.text.trim();
        }
        if (_mldsa65VerifyController.text.trim().isNotEmpty) {
          params['mldsa65Verify'] = _mldsa65VerifyController.text.trim();
        }
      }
    }
    if (_selectedNetwork == 'xhttp' && _extraController.text.trim().isNotEmpty) {
      params['extra'] = _extraController.text.trim();
    }
    
    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final encodedRemark = Uri.encodeComponent(remark);
    return 'trojan://${_idController.text.trim()}@$address:$port?$queryString#$encodedRemark';
  }
  
  String _buildShadowsocksUrl(String address, String port, String remark) {
    final userInfo = '${_selectedMethod}:${_idController.text.trim()}';
    final base64UserInfo = base64Encode(utf8.encode(userInfo));
    final encodedRemark = Uri.encodeComponent(remark);
    return 'ss://$base64UserInfo@$address:$port#$encodedRemark';
  }
  
  String _buildSocksHttpUrl(String protocol, String address, String port, String remark) {
    final username = _usernameController.text.trim();
    final password = _idController.text.trim();
    final encodedRemark = Uri.encodeComponent(remark);
    
    if (username.isNotEmpty && password.isNotEmpty) {
      return '$protocol://$username:$password@$address:$port#$encodedRemark';
    } else {
      return '$protocol://$address:$port#$encodedRemark';
    }
  }
  
  String _buildHysteria2Url(String address, String port, String remark) {
    final params = <String, String>{};
    
    if (_upBandwidthController.text.trim().isNotEmpty) {
      params['up'] = _upBandwidthController.text.trim();
    }
    if (_downBandwidthController.text.trim().isNotEmpty) {
      params['down'] = _downBandwidthController.text.trim();
    }
    if (_obfsType == 1 && _obfsPasswordController.text.trim().isNotEmpty) {
      params['obfs'] = 'salamander';
      params['obfs-password'] = _obfsPasswordController.text.trim();
    }
    if (_portHoppingController.text.trim().isNotEmpty) {
      params['mport'] = _portHoppingController.text.trim();
    }
    if (_portHoppingIntervalController.text.trim().isNotEmpty) {
      params['mportHopInt'] = _portHoppingIntervalController.text.trim();
    }
    if (_sniController.text.trim().isNotEmpty) {
      params['sni'] = _sniController.text.trim();
    }
    if (_selectedAllowInsecure == 'true') {
      params['insecure'] = '1';
    } else {
      params['insecure'] = '0';
    }
    if (_pinSHA256Controller.text.trim().isNotEmpty) {
      params['pinSHA256'] = _pinSHA256Controller.text.trim();
    }
    if (_selectedFingerprint.isNotEmpty) {
      params['fp'] = _selectedFingerprint;
    }
    if (_selectedAlpn.isNotEmpty) {
      params['alpn'] = _selectedAlpn;
    } else {
      params['alpn'] = 'h3';
    }
    
    final password = _idController.text.trim();
    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final encodedRemark = Uri.encodeComponent(remark);
    return 'hysteria2://$password@$address:$port?$queryString#$encodedRemark';
  }
  
  String _buildWireguardUrl(String address, String port, String remark) {
    final params = <String, String>{
      'secretKey': _idController.text.trim(),
      'publicKey': _publicKeyController.text.trim(),
    };
    
    if (_preSharedKeyController.text.trim().isNotEmpty) {
      params['preSharedKey'] = _preSharedKeyController.text.trim();
    }
    if (_reservedController.text.trim().isNotEmpty) {
      params['reserved'] = _reservedController.text.trim();
    }
    if (_localAddressController.text.trim().isNotEmpty) {
      params['localAddress'] = _localAddressController.text.trim();
    }
    if (_mtuController.text.trim().isNotEmpty) {
      params['mtu'] = _mtuController.text.trim();
    }
    
    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final encodedRemark = Uri.encodeComponent(remark);
    return 'wireguard://$address:$port?$queryString#$encodedRemark';
  }
}
