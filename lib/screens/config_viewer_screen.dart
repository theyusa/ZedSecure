import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zedsecure/models/v2ray_config.dart';
import 'package:zedsecure/models/app_settings.dart';
import 'package:zedsecure/services/v2ray_service.dart';
import 'package:zedsecure/services/v2ray_config_builder.dart';
import 'package:zedsecure/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ConfigViewerScreen extends StatefulWidget {
  final V2RayConfig config;
  final bool editable;

  const ConfigViewerScreen({
    super.key,
    required this.config,
    this.editable = false,
  });

  @override
  State<ConfigViewerScreen> createState() => _ConfigViewerScreenState();
}

class _ConfigViewerScreenState extends State<ConfigViewerScreen> {
  late TextEditingController _jsonController;
  String? _fullConfig;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController();
    _generateFullConfig();
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _generateFullConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('app_settings');
      AppSettings appSettings;
      if (settingsJson != null) {
        appSettings = AppSettings.fromJson(jsonDecode(settingsJson));
      } else {
        appSettings = AppSettings();
      }

      final blockedAppsList = prefs.getStringList('blocked_apps');

      final fullConfig = V2RayConfigBuilder.buildFullConfig(
        serverConfig: widget.config,
        settings: appSettings,
        blockedApps: blockedAppsList,
      );

      final jsonString = JsonEncoder.withIndent('  ').convert(fullConfig);

      if (mounted) {
        setState(() {
          _fullConfig = jsonString;
          _jsonController.text = jsonString;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fullConfig = 'Error generating config: $e';
          _jsonController.text = _fullConfig!;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _copyToClipboard() async {
    final textToCopy = _isEditing ? _jsonController.text : _fullConfig;
    if (textToCopy != null && textToCopy.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: textToCopy));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Config copied to clipboard'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _saveCustomConfig() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final jsonText = _jsonController.text.trim();
      if (jsonText.isEmpty) {
        throw Exception('Config cannot be empty');
      }

      final parsedJson = jsonDecode(jsonText);
      if (parsedJson is! Map<String, dynamic>) {
        throw Exception('Invalid JSON format');
      }

      final service = Provider.of<V2RayService>(context, listen: false);
      final configs = await service.loadConfigs();

      final index = configs.indexWhere((c) => c.id == widget.config.id);
      if (index == -1) {
        throw Exception('Config not found');
      }

      final remarks = parsedJson['remarks'] ?? widget.config.remark;
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

      final updatedConfig = V2RayConfig(
        id: widget.config.id,
        remark: remarks.toString(),
        address: server ?? widget.config.address,
        port: int.tryParse(serverPort ?? '') ?? widget.config.port,
        configType: 'custom',
        fullConfig: jsonText,
        source: widget.config.source,
      );

      configs[index] = updatedConfig;
      await service.saveConfigs(configs);
      service.clearPingCache(configId: widget.config.id);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Custom config saved successfully'),
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

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _jsonController.text = _fullConfig ?? '';
      }
    });
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
          _isEditing ? 'Edit Custom Config' : 'Full V2Ray Configuration',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (widget.editable && !_isEditing)
            IconButton(
              icon: Icon(CupertinoIcons.pencil, color: AppTheme.primaryBlue),
              onPressed: _toggleEditMode,
            ),
          if (_isEditing)
            IconButton(
              icon: Icon(CupertinoIcons.xmark, color: AppTheme.disconnectedRed),
              onPressed: _toggleEditMode,
            ),
          IconButton(
            icon: Icon(CupertinoIcons.doc_on_clipboard, color: AppTheme.primaryBlue),
            onPressed: _copyToClipboard,
          ),
          if (_isEditing)
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CupertinoActivityIndicator(),
                  )
                : TextButton(
                    onPressed: _saveCustomConfig,
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
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isEditing ? CupertinoIcons.pencil : CupertinoIcons.doc_text,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isEditing
                                ? 'Edit JSON Configuration'
                                : 'Complete V2Ray Core Configuration',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isEditing
                              ? AppTheme.primaryBlue.withOpacity(0.5)
                              : AppTheme.systemGray.withOpacity(0.3),
                          width: _isEditing ? 2 : 1,
                        ),
                      ),
                      child: _isEditing
                          ? TextField(
                              controller: _jsonController,
                              maxLines: null,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: isDark ? Colors.white70 : Colors.black87,
                                height: 1.4,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            )
                          : SelectableText(
                              _fullConfig ?? 'No config available',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: isDark ? Colors.white70 : Colors.black87,
                                height: 1.4,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isEditing
                          ? 'Edit the JSON configuration carefully. Invalid JSON will not be saved.'
                          : 'This is the complete JSON configuration that will be sent to V2Ray core for connection.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.systemGray,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
